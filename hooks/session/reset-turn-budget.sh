#!/usr/bin/env bash
# UserPromptSubmit hook: reset per-turn state (budget + skill tracking) and cache user prompt.
set -euo pipefail

INPUT=$(cat 2>/dev/null) || INPUT=""
# Per-session state isolation (see lessons-learned: hook-state-not-session-keyed): key the
# per-turn state dir by session_id so parallel sessions don't reset each other's turn budget.
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9._-') || SID=""
[ -z "$SID" ] && SID=default
STATE_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/state/$SID"
mkdir -p "$STATE_DIR"

echo '{"bytes":0,"tools":[]}' > "$STATE_DIR/turn-budget.json"
echo '[]' > "$STATE_DIR/turn-skills-invoked.json"
echo '[]' > "$STATE_DIR/turn-reads.json"
echo '{"count":0}' > "$STATE_DIR/turn-tool-count.json"
rm -f "$STATE_DIR/turn-bypass-warned.flag"
rm -f "$STATE_DIR/turn-lessons-nudged.flag"

# Save prompt for Stop hook (skill usage analysis). INPUT was read at the top for session_id.
# Fail open: per-turn state was already reset above; non-JSON stdin just skips caching.
printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1 || exit 0
PROMPT=$(echo "$INPUT" | jq -r '.prompt // .user_prompt // ""')
printf '%s' "$PROMPT" > "$STATE_DIR/last-prompt.txt"

exit 0
