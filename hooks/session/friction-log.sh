#!/usr/bin/env bash
# Stop hook: log DETERMINISTIC friction signals from the turn's transcript.
#
# Why: the report's headline friction KPIs (user-rejected, failed actions) were inferred from
# offline transcript analysis and live nowhere in the harness. This logs the part that IS a
# deterministic machine fact — tool_result entries with is_error == true — classified by their
# fixed shape, NOT by guessing the user's intent from prompt keywords (that noise is exactly
# what lessons-nudge.sh deliberately avoids). It does NOT attempt the semantic "wrong_approach"
# label — that stays with offline analysis.
#
# Classes (deterministic):
#   denied  — the harness's standard tool-rejection text ("user doesn't want to proceed", "rejected")
#   blocked — a PreToolUse hook blocked it ("hook error", "BLOCKED:")
#   error   — any other is_error (command exited non-zero, tool failed)
#
# Delta-tracked against this session's friction-seen.json so re-fired Stop hooks never double-count.
# Output: appends {event:"friction", class, count} lines to .claude/skills/_metrics.jsonl.
# Fail-open: any error / missing transcript / no jq exits 0 with no output.
set -uo pipefail

INPUT=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Per-session state isolation (see lessons-learned: hook-state-not-session-keyed).
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9._-') || SID=""
[ -z "$SID" ] && SID=default
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STATE_DIR="$PROJECT_DIR/.claude/state/$SID"
METRICS="$PROJECT_DIR/.claude/skills/_metrics.jsonl"
SEEN_FILE="$STATE_DIR/friction-seen.json"

TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null) || exit 0
[ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || exit 0

mkdir -p "$STATE_DIR" "$(dirname "$METRICS")" 2>/dev/null || exit 0
[ -f "$SEEN_FILE" ] || echo '{"denied":0,"blocked":0,"error":0}' > "$SEEN_FILE"

# Extract every is_error tool_result's text from the transcript (content may be string or array).
TEXTS=$(jq -rc '
  select((.message.content // empty) | type == "array")
  | .message.content[]
  | select((type == "object") and (.type == "tool_result") and (.is_error == true))
  | (if (.content | type) == "array" then (.content | map(.text? // "") | join(" ")) else (.content | tostring) end)
' "$TRANSCRIPT" 2>/dev/null) || exit 0

# Current totals by class (priority: denied > blocked > error).
cur_denied=$(printf '%s\n' "$TEXTS" | grep -ciE "user (doesn'?t|does not|did ?n'?t) want|user rejected|user declined|don'?t want to proceed" 2>/dev/null || echo 0)
cur_blocked=$(printf '%s\n' "$TEXTS" | grep -ciE 'hook error|BLOCKED:' 2>/dev/null || echo 0)
cur_total=$(printf '%s\n' "$TEXTS" | grep -c . 2>/dev/null || echo 0)
cur_error=$(( cur_total - cur_denied - cur_blocked ))
(( cur_error < 0 )) && cur_error=0

s_denied=$(jq -r '.denied // 0' "$SEEN_FILE" 2>/dev/null || echo 0)
s_blocked=$(jq -r '.blocked // 0' "$SEEN_FILE" 2>/dev/null || echo 0)
s_error=$(jq -r '.error // 0' "$SEEN_FILE" 2>/dev/null || echo 0)

emit() { # class, delta
  local cls="$1" d="$2"
  (( d > 0 )) || return 0
  jq -cn --arg c "$cls" --argjson n "$d" '{event:"friction", class:$c, count:$n}' >> "$METRICS" 2>/dev/null || true
}
emit denied  $(( cur_denied  - s_denied ))
emit blocked $(( cur_blocked - s_blocked ))
emit error   $(( cur_error   - s_error ))

jq -cn --argjson d "$cur_denied" --argjson b "$cur_blocked" --argjson e "$cur_error" \
  '{denied:$d, blocked:$b, error:$e}' > "$SEEN_FILE.tmp" 2>/dev/null && mv "$SEEN_FILE.tmp" "$SEEN_FILE"

exit 0
