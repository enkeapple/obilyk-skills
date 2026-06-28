#!/usr/bin/env bash
# UserPromptSubmit hook: reset per-turn state (budget + skill tracking) and cache user prompt.
set -euo pipefail

GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib → fail open (`.` is a special builtin: under set -e its open-failure exits the shell before `|| exit 0` can run, so guard readability first)
. "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || INPUT=""
SID=$(hook_sid "$INPUT")
STATE_DIR=$(hook_state_dir "$SID")
mkdir -p "$STATE_DIR"
touch "$STATE_DIR"   # refresh mtime: mkdir -p is a no-op (no mtime bump) on an existing dir, so a
                     # resumed >GC_DAYS-old session dir would otherwise be deleted by the GC below.

# Opportunistic GC: a single GC_DAYS-window sweep, run AFTER the touch above so the current
# session's dir (fresh mtime) is never collected. Prunes by mtime: (1) dated telemetry + corpus
# day-files and the pre-3b legacy _metrics.jsonl, (2) per-session scratch dirs (kept until build
# 3c relocates scratch to ${TMPDIR}). Fail-open: a GC error must not disrupt the turn reset.
GC_DAYS=14
STATE_BASE="${CLAUDE_PROJECT_DIR:-.}/.claude/state"
# (1) Dated day-files (metrics/, prompts/) + the legacy single file, older than GC_DAYS.
#     Three -maxdepth-1 roots: STATE_BASE (legacy _metrics.jsonl) + metrics/ + prompts/.
find "$STATE_BASE" "$STATE_BASE/metrics" "$STATE_BASE/prompts" \
  -maxdepth 1 -type f -name '*.jsonl' -mtime +"$GC_DAYS" -delete 2>/dev/null || true
# (2) Per-session scratch dirs older than GC_DAYS (stopgap until build 3c moves scratch to ${TMPDIR}).
find "$STATE_BASE" -mindepth 1 -maxdepth 1 -type d -mtime +"$GC_DAYS" -exec rm -rf {} + 2>/dev/null || true

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

# Open the prompt-corpus record (finalized at Stop by log-skill-usage). Monotone session-turn
# counter (NOT among the per-turn files reset above). Guarded: a failure must not abort the reset.
TURN_N_FILE="$STATE_DIR/session-turn.json"
[ -f "$TURN_N_FILE" ] || echo '{"n":0}' > "$TURN_N_FILE"
TURN_N=$(( $(jq -r '.n // 0' "$TURN_N_FILE" 2>/dev/null || echo 0) + 1 ))
jq -cn --argjson n "$TURN_N" '{n:$n}' > "$TURN_N_FILE.tmp" 2>/dev/null && mv "$TURN_N_FILE.tmp" "$TURN_N_FILE" || true
jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --argjson turn "$TURN_N" --arg p "$PROMPT" \
  '{v:1, type:"prompt", ts:$ts, session:$sid, turn:$turn, prompt:$p, chars:($p|length)}' \
  > "$STATE_DIR/pending-prompt.json.tmp" 2>/dev/null \
  && mv "$STATE_DIR/pending-prompt.json.tmp" "$STATE_DIR/pending-prompt.json" || true

exit 0
