#!/usr/bin/env bash
# PostToolUse hook (matcher: Read|Skill|Edit|Write|MultiEdit): detect skill bypass.
# Triggers three warnings:
#   (1)  Read on a file registered as a skill body without invoking the Skill tool earlier in the turn.
#   (1b) Edit/Write/MultiEdit on lessons-learned.md without invoking the writing-lessons Skill this turn.
#   (2)  After N tool calls without Skill, if the user prompt matched any skill's triggers -- remind.
# Also logs events to metrics. (Edit/Write/MultiEdit events are needed for check 1b.)
set -euo pipefail

STATE_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/state"
ROUTING="${CLAUDE_PROJECT_DIR:-.}/.claude/skills-routing.json"
METRICS="${CLAUDE_PROJECT_DIR:-.}/.claude/skills/_metrics.jsonl"
TURN_SKILLS_FILE="$STATE_DIR/turn-skills-invoked.json"
TURN_READS_FILE="$STATE_DIR/turn-reads.json"
TURN_TOOL_COUNT_FILE="$STATE_DIR/turn-tool-count.json"
LAST_PROMPT_FILE="$STATE_DIR/last-prompt.txt"
BYPASS_WARNED_FILE="$STATE_DIR/turn-bypass-warned.flag"

# Threshold: after this many non-Skill tool calls in a turn with a matched trigger, warn.
TRIGGER_BYPASS_THRESHOLD=3

mkdir -p "$STATE_DIR" "$(dirname "$METRICS")"
[[ -f "$ROUTING" ]] || exit 0
[[ -f "$TURN_SKILLS_FILE" ]] || echo '[]' > "$TURN_SKILLS_FILE"
[[ -f "$TURN_TOOL_COUNT_FILE" ]] || echo '{"count":0}' > "$TURN_TOOL_COUNT_FILE"

INPUT=$(cat 2>/dev/null) || exit 0
# Fail open: unreadable / non-JSON stdin must not disrupt the tool call (or spam jq errors).
printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1 || exit 0
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Track Skill invocations -- reset bypass-warned flag, record skill name, exit.
if [[ "$TOOL" == "Skill" ]]; then
  SKILL_NAME=$(echo "$INPUT" | jq -r '.tool_input.skill // ""')
  if [[ -n "$SKILL_NAME" ]]; then
    jq --arg s "$SKILL_NAME" '. + [$s] | unique' "$TURN_SKILLS_FILE" > "$TURN_SKILLS_FILE.tmp" && mv "$TURN_SKILLS_FILE.tmp" "$TURN_SKILLS_FILE"
  fi
  exit 0
fi

# Bump non-Skill tool counter.
COUNT=$(jq -r '.count' "$TURN_TOOL_COUNT_FILE")
NEW_COUNT=$(( COUNT + 1 ))
jq --argjson c "$NEW_COUNT" '.count=$c' "$TURN_TOOL_COUNT_FILE" > "$TURN_TOOL_COUNT_FILE.tmp" && mv "$TURN_TOOL_COUNT_FILE.tmp" "$TURN_TOOL_COUNT_FILE"

# Record every Read's relative path this turn so skill-gate.sh can verify a gated
# rule file was actually loaded before allowing an edit (ruleGates barrier, gap #2).
if [[ "$TOOL" == "Read" ]]; then
  RP=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
  if [[ -n "$RP" ]]; then
    PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    RP_REL="${RP#$PROJECT_DIR/}"
    [[ -f "$TURN_READS_FILE" ]] || echo '[]' > "$TURN_READS_FILE"
    jq --arg p "$RP_REL" '. + [$p] | unique' "$TURN_READS_FILE" > "$TURN_READS_FILE.tmp" 2>/dev/null \
      && mv "$TURN_READS_FILE.tmp" "$TURN_READS_FILE"
  fi
fi

# (1) Read-on-skill-body check (original behavior).
if [[ "$TOOL" == "Read" ]]; then
  READ_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
  if [[ -n "$READ_PATH" ]]; then
    PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    REL_PATH="${READ_PATH#$PROJECT_DIR/}"
    MATCHED_SKILL=$(jq -r --arg p "$REL_PATH" --arg abs "$READ_PATH" '
      .skills | to_entries[] | select(
        (.value.files // []) as $files |
        ($files | index($p)) != null or ($files | index($abs)) != null
      ) | .key
    ' "$ROUTING" 2>/dev/null | head -1)
    if [[ -n "$MATCHED_SKILL" ]]; then
      INVOKED=$(jq -r --arg s "$MATCHED_SKILL" 'index($s) // empty' "$TURN_SKILLS_FILE")
      if [[ -z "$INVOKED" ]]; then
        echo "SKILL-BYPASS warn: you read '$REL_PATH' which is registered as body of Skill '$MATCHED_SKILL'. Next time invoke the Skill tool instead -- body is loaded lazily and description goes to metrics." >&2
        jq -cn --arg ts "$(date -u +%FT%TZ)" --arg s "$MATCHED_SKILL" --arg p "$REL_PATH" \
          '{ts:$ts, event:"read_instead_of_skill", skill:$s, path:$p}' >> "$METRICS"
      fi
    fi
  fi
fi

# (1b) Direct-write-to-lessons-log check: editing lessons-learned.md without first invoking
# the writing-lessons skill bypasses its cause-tag discipline + promotion-debt scan.
if [[ "$TOOL" == "Edit" || "$TOOL" == "Write" || "$TOOL" == "MultiEdit" ]]; then
  WRITE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
  if [[ "$WRITE_PATH" == *lessons-learned.md ]]; then
    INVOKED=$(jq -r 'index("writing-lessons") // empty' "$TURN_SKILLS_FILE")
    if [[ -z "$INVOKED" ]]; then
      echo "SKILL-BYPASS warn: you edited 'lessons-learned.md' directly without invoking the 'writing-lessons' Skill. That skill owns cause-tag reuse and the promotion-debt scan -- a direct edit skips both. Invoke the Skill tool to capture lessons." >&2
      jq -cn --arg ts "$(date -u +%FT%TZ)" --arg p "$WRITE_PATH" \
        '{ts:$ts, event:"direct_edit_lessons_log", path:$p}' >> "$METRICS"
    fi
  fi
fi

# (2) Trigger-based bypass: once per turn, after threshold, if prompt matched a skill trigger and skill not invoked, remind.
if [[ -f "$BYPASS_WARNED_FILE" ]]; then
  exit 0
fi
if (( NEW_COUNT < TRIGGER_BYPASS_THRESHOLD )); then
  exit 0
fi
[[ -f "$LAST_PROMPT_FILE" ]] || exit 0
USER_PROMPT=$(cat "$LAST_PROMPT_FILE")
[[ -n "$USER_PROMPT" ]] || exit 0

# Find first skill whose trigger fires on the prompt AND which was not invoked.
MATCHED_MISSED=$(jq -r '.skills | to_entries[] | "\(.key)\t\(.value.triggers // [] | join("|"))"' "$ROUTING" | while IFS=$'\t' read -r skill trigger_union; do
  [[ -n "$trigger_union" ]] || continue
  if echo "$USER_PROMPT" | grep -qiE "$trigger_union"; then
    INVOKED=$(jq -r --arg s "$skill" 'index($s) // "null"' "$TURN_SKILLS_FILE")
    if [[ "$INVOKED" == "null" ]]; then
      echo "$skill"
      break
    fi
  fi
done | head -1)

if [[ -n "$MATCHED_MISSED" ]]; then
  echo "SKILL-BYPASS warn: user prompt matched trigger for Skill '$MATCHED_MISSED' and you have run ${NEW_COUNT} tools without invoking it. If the task touches that domain, invoke Skill('$MATCHED_MISSED') to load the relevant rules before continuing." >&2
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg s "$MATCHED_MISSED" --argjson c "$NEW_COUNT" \
    '{ts:$ts, event:"trigger_bypass_warn", skill:$s, tool_count:$c}' >> "$METRICS"
  touch "$BYPASS_WARNED_FILE"
fi

exit 0
