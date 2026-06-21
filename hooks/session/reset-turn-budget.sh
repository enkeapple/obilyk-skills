#!/usr/bin/env bash
# UserPromptSubmit hook: reset per-turn state (budget + skill tracking) and cache user prompt.
set -euo pipefail
STATE_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/state"
mkdir -p "$STATE_DIR"

echo '{"bytes":0,"tools":[]}' > "$STATE_DIR/turn-budget.json"
echo '[]' > "$STATE_DIR/turn-skills-invoked.json"
echo '[]' > "$STATE_DIR/turn-reads.json"
echo '{"count":0}' > "$STATE_DIR/turn-tool-count.json"
rm -f "$STATE_DIR/turn-bypass-warned.flag"
rm -f "$STATE_DIR/turn-lessons-nudged.flag"

# Save prompt for Stop hook (skill usage analysis).
# Fail open: per-turn state was already reset above; unreadable / non-JSON stdin
# must not crash the prompt event — just skip caching the prompt.
INPUT=$(cat 2>/dev/null) || exit 0
printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1 || exit 0
PROMPT=$(echo "$INPUT" | jq -r '.prompt // .user_prompt // ""')
printf '%s' "$PROMPT" > "$STATE_DIR/last-prompt.txt"

exit 0
