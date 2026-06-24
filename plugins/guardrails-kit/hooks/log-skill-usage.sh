#!/usr/bin/env bash
# Stop hook: analyze last turn's tool usage vs user prompt triggers.
# Emit per-turn metrics: bypass (triggered, no skill), unused (skill invoked, body not read),
# used_correctly (triggered + skill invoked).
set -euo pipefail

GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib → fail open (`.` is a special builtin: under set -e its open-failure exits the shell before `|| exit 0` can run, so guard readability first)
. "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || exit 0
hook_require_json "$INPUT"
SID=$(hook_sid "$INPUT")
STATE_DIR=$(hook_state_dir "$SID")
ROUTING="${CLAUDE_PROJECT_DIR:-.}/.claude/skills-routing.json"
METRICS="${CLAUDE_PROJECT_DIR:-.}/.claude/state/_metrics.jsonl"
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
jq -r '.skills // {} | to_entries[] | "\(.key)\t\(.value.triggers // [] | join("|"))"' "$ROUTING" | while IFS=$'\t' read -r skill trigger_union; do
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
  else
    continue
  fi

  jq -cn --arg ts "$(date -u +%FT%TZ)" \
         --arg sid "$SID" \
         --arg h "$PROMPT_HASH" \
         --arg s "$skill" \
         --arg e "$EVENT" \
         '{v:1, type:"skill_event", ts:$ts, session:$sid, prompt_hash:$h, skill:$s, event:$e}' >> "$METRICS"
done

# --- Prompt-corpus finalize (single writer). Only if reset-turn-budget opened a record. ---
PENDING="$STATE_DIR/pending-prompt.json"
if [[ -f "$PENDING" ]]; then
  PROMPTS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/state/prompts"
  mkdir -p "$PROMPTS_DIR"
  # skills whose trigger union matches the prompt (same match as the metric loop above)
  TRIGGERS_MATCHED=$(jq -r '.skills // {} | to_entries[] | "\(.key)\t\(.value.triggers // [] | join("|"))"' "$ROUTING" \
    | while IFS=$'\t' read -r skill trig; do
        [[ -n "$trig" ]] || continue
        echo "$USER_PROMPT" | grep -qiE "$trig" && printf '%s\n' "$skill"
      done | jq -R . | jq -cs .)
  TOOLS_USED=$(jq -r '.count // 0' "$STATE_DIR/turn-tool-count.json" 2>/dev/null || echo 0)
  FRICTION=$(cat "$STATE_DIR/friction-seen.json" 2>/dev/null || echo '{"denied":0,"blocked":0,"error":0}')
  BYPASS=$(printf '%s' "$TRIGGERS_MATCHED" | jq --argjson inv "$INVOKED_SKILLS" 'map(select(($inv | index(.)) | not)) | length > 0')
  jq -cn --slurpfile pend "$PENDING" \
        --argjson tm "$TRIGGERS_MATCHED" --argjson inv "$INVOKED_SKILLS" \
        --argjson tu "$TOOLS_USED" --argjson fr "$FRICTION" --argjson bp "$BYPASS" \
        '$pend[0] + {triggers_matched:$tm, skills_invoked:$inv,
                     lang:(if ($pend[0].prompt|test("[Ѐ-ӿ]")) then "ru" else "en" end),
                     outcome:{tools_used:$tu, friction:$fr, bypass:$bp}}' \
    >> "$PROMPTS_DIR/$(date -u +%F).jsonl" 2>/dev/null || true
  rm -f "$PENDING"
fi

# Clear per-turn skill tracking
echo '[]' > "$TURN_SKILLS_FILE"
exit 0
