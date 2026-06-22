#!/usr/bin/env bash
# Stop hook: analyze last turn's tool usage vs user prompt triggers.
# Emit per-turn metrics: bypass (triggered, no skill), unused (skill invoked, body not read),
# used_correctly (triggered + skill invoked).
set -euo pipefail

INPUT=$(cat 2>/dev/null) || exit 0
# Fail open: unreadable / non-JSON stdin must not disrupt turn end (or spam jq errors).
printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1 || exit 0
# Per-session state isolation (see lessons-learned: hook-state-not-session-keyed).
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9._-') || SID=""
[ -z "$SID" ] && SID=default
STATE_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/state/$SID"
ROUTING="${CLAUDE_PROJECT_DIR:-.}/.claude/skills-routing.json"
METRICS="${CLAUDE_PROJECT_DIR:-.}/.claude/skills/_metrics.jsonl"
TURN_SKILLS_FILE="$STATE_DIR/turn-skills-invoked.json"
LAST_PROMPT_FILE="$STATE_DIR/last-prompt.txt"

mkdir -p "$STATE_DIR" "$(dirname "$METRICS")"
[[ -f "$ROUTING" ]] || exit 0

# Stop hook receives session info. Read transcript_path if provided.
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# Recover last user prompt (stored by reset-turn-budget if we extend it; otherwise best-effort from transcript)
USER_PROMPT=""
if [[ -f "$LAST_PROMPT_FILE" ]]; then
  USER_PROMPT=$(cat "$LAST_PROMPT_FILE")
elif [[ -f "$TRANSCRIPT" ]]; then
  # Extract last user message text from JSONL transcript
  USER_PROMPT=$(tail -r "$TRANSCRIPT" 2>/dev/null | grep -m1 '"role":"user"' | jq -r '.message.content // .content // ""' 2>/dev/null || echo "")
fi

[[ -n "$USER_PROMPT" ]] || exit 0

PROMPT_HASH=$(printf '%s' "$USER_PROMPT" | shasum -a 256 | cut -c1-16)

INVOKED_SKILLS=$([[ -f "$TURN_SKILLS_FILE" ]] && cat "$TURN_SKILLS_FILE" || echo '[]')

# For each skill in routing, check triggers against prompt
jq -r '.skills | to_entries[] | "\(.key)\t\(.value.triggers // [] | join("|"))"' "$ROUTING" | while IFS=$'\t' read -r skill trigger_union; do
  [[ -n "$trigger_union" ]] || continue
  MATCHED=""
  if echo "$USER_PROMPT" | grep -qiE "$trigger_union"; then
    MATCHED="yes"
  fi
  INVOKED=$(echo "$INVOKED_SKILLS" | jq -r --arg s "$skill" 'index($s) // "null"')

  if [[ "$MATCHED" == "yes" && "$INVOKED" == "null" ]]; then
    EVENT="bypass"
  elif [[ "$MATCHED" == "yes" && "$INVOKED" != "null" ]]; then
    EVENT="used_correctly"
  elif [[ "$MATCHED" != "yes" && "$INVOKED" != "null" ]]; then
    EVENT="invoked_without_trigger"
  else
    continue
  fi

  jq -cn --arg ts "$(date -u +%FT%TZ)" \
         --arg h "$PROMPT_HASH" \
         --arg s "$skill" \
         --arg e "$EVENT" \
         --arg t "$trigger_union" \
         '{ts:$ts, prompt_hash:$h, skill:$s, event:$e, triggers:$t}' >> "$METRICS"
done

# Clear per-turn skill tracking
echo '[]' > "$TURN_SKILLS_FILE"
exit 0
