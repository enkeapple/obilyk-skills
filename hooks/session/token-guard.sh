#!/usr/bin/env bash
# PostToolUse hook: estimate tokens from tool output size, warn/block on overuse.
# Input: JSON on stdin from Claude Code (tool_name, tool_input, tool_response).
# Output: stderr for warnings (visible to model); exit 2 to block next tool call.

set -euo pipefail

INPUT=$(cat 2>/dev/null) || exit 0
# Fail open: unreadable / non-JSON stdin must not disrupt the tool call (or spam jq errors).
printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1 || exit 0

# Per-session state isolation: parallel Claude Code sessions must not share budget/accounting
# files. Key the state dir by session_id from the payload; absent → "default" (single-session,
# no regression). See lessons-learned: hook-state-not-session-keyed.
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9._-') || SID=""
[ -z "$SID" ] && SID=default
STATE_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/state/$SID"
TURN_FILE="$STATE_DIR/turn-budget.json"
SESSION_FILE="$STATE_DIR/session-budget.json"
BY_MODEL_FILE="$STATE_DIR/by-model-budget.json"

# Thresholds in TOKENS (byte/4 heuristic applied below). 3x baseline.
WARN_PER_TOOL=60000
WARN_PER_TURN=80000
HARD_STOP_PER_TURN=450000
WARN_PER_SESSION=3000000
# Premium-tier (opus) session ceiling: research/review should NOT run on the most-capable
# tier (see .claude/rules/common/model-selection.md). Advisory only — warns, never blocks.
WARN_OPUS_PER_SESSION=1500000

mkdir -p "$STATE_DIR"
[[ -f "$TURN_FILE" ]] || echo '{"bytes":0,"tools":[]}' > "$TURN_FILE"
[[ -f "$SESSION_FILE" ]] || echo "{\"bytes\":0,\"started_at\":\"$(date -u +%FT%TZ)\"}" > "$SESSION_FILE"
[[ -f "$BY_MODEL_FILE" ]] || echo '{}' > "$BY_MODEL_FILE"

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
# tool_response is either string or object; stringify for size measurement
RESP_BYTES=$(echo "$INPUT" | jq -r '.tool_response | if type=="string" then . else tostring end' | wc -c | tr -d ' ')
RESP_TOKENS=$(( RESP_BYTES / 4 ))

# Update turn budget
TURN_BYTES=$(jq -r '.bytes' "$TURN_FILE")
NEW_TURN_BYTES=$(( TURN_BYTES + RESP_BYTES ))
jq --argjson b "$NEW_TURN_BYTES" --arg n "$TOOL_NAME" --argjson tb "$RESP_BYTES" --arg ts "$(date -u +%FT%TZ)" \
   '.bytes=$b | .tools += [{name:$n, bytes:$tb, ts:$ts}]' \
   "$TURN_FILE" > "$TURN_FILE.tmp" && mv "$TURN_FILE.tmp" "$TURN_FILE"

# Update session budget
SESS_BYTES=$(jq -r '.bytes' "$SESSION_FILE")
NEW_SESS_BYTES=$(( SESS_BYTES + RESP_BYTES ))
jq --argjson b "$NEW_SESS_BYTES" '.bytes=$b' "$SESSION_FILE" > "$SESSION_FILE.tmp" && mv "$SESSION_FILE.tmp" "$SESSION_FILE"

# Per-model accounting: bucket bytes by the dispatched model so the vault can measure adherence
# to model-selection.md (premium tier reserved for implement, not research/review). A call with
# no model override (main-context / inherited) buckets under "inherited".
MODEL=$(echo "$INPUT" | jq -r '.tool_input.model // "inherited"')
jq --arg m "$MODEL" --argjson b "$RESP_BYTES" '.[$m] = ((.[$m] // 0) + $b)' \
   "$BY_MODEL_FILE" > "$BY_MODEL_FILE.tmp" && mv "$BY_MODEL_FILE.tmp" "$BY_MODEL_FILE"

TURN_TOKENS=$(( NEW_TURN_BYTES / 4 ))
SESS_TOKENS=$(( NEW_SESS_BYTES / 4 ))

# Warnings
if (( RESP_TOKENS > WARN_PER_TOOL )); then
  echo "TOKEN-GUARD warn: tool '$TOOL_NAME' returned ~${RESP_TOKENS} tokens (threshold ${WARN_PER_TOOL}). Narrow next read." >&2
fi

if (( TURN_TOKENS > HARD_STOP_PER_TURN )); then
  echo "TOKEN-GUARD hard-stop: turn consumed ~${TURN_TOKENS} tokens (>${HARD_STOP_PER_TURN}). Stop. Summarize findings and ask user before continuing." >&2
  exit 2
fi

if (( TURN_TOKENS > WARN_PER_TURN )); then
  echo "TOKEN-GUARD warn: turn at ~${TURN_TOKENS} tokens (threshold ${WARN_PER_TURN}). Consider wrapping up." >&2
fi

if (( SESS_TOKENS > WARN_PER_SESSION )); then
  echo "TOKEN-GUARD warn: session at ~${SESS_TOKENS} tokens (>${WARN_PER_SESSION}). Consider switching to Sonnet subagent or /compact." >&2
fi

OPUS_TOKENS=$(( $(jq -r '.["opus"] // 0' "$BY_MODEL_FILE") / 4 ))
if (( OPUS_TOKENS > WARN_OPUS_PER_SESSION )); then
  echo "TOKEN-GUARD warn: premium-tier (opus) session usage ~${OPUS_TOKENS} tokens (>${WARN_OPUS_PER_SESSION}). Route research/review off the most-capable tier per model-selection.md." >&2
fi

exit 0
