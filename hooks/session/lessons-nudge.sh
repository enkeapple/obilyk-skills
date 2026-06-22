#!/usr/bin/env bash
# Stop hook: discipline nudge for the lessons-learned loop.
#
# Why this exists: the lessons promotion path (.claude/CLAUDE.md "Lessons promotion path")
# only fires if I actually append to lessons-learned.md. That has been pure discipline, and
# discipline under context pressure is exactly what slips. A Stop hook cannot read my mind to
# know "I caught a mistake" -- there is no machine event for that. But there IS one precise,
# low-false-positive signal already captured this turn: turn-bypass-warned.flag, set by
# detect-bypass.sh when a skill trigger fired and the skill was NOT invoked. A skill-bypass is
# very often the moment a lesson should be recorded (wrong domain, missed rule). So: if that
# flag exists this turn AND lessons-learned.md was not modified this turn, remind -- once.
#
# Deliberately narrow: keyed on the bypass flag, not on edits-happened or prompt keywords,
# because those produce noise that trains me to ignore the nudge. Stop hooks only write stderr
# (no deny), so this is a visible reminder, not a barrier -- which is the right strength for a
# signal that is suggestive, not certain.
#
# Contract: stdin JSON (session info, transcript_path). $CLAUDE_PROJECT_DIR available.
# Fail-open: any error exits 0 with no output.
set -uo pipefail

INPUT=$(cat 2>/dev/null) || INPUT=""
# Per-session state isolation (see lessons-learned: hook-state-not-session-keyed): read this
# session's own bypass/nudge flags so a parallel session's flags don't cross-trigger.
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9._-') || SID=""
[ -z "$SID" ] && SID=default
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_DIR="$PROJECT_DIR/.claude/state/$SID"
BYPASS_FLAG="$STATE_DIR/turn-bypass-warned.flag"
NUDGED_FLAG="$STATE_DIR/turn-lessons-nudged.flag"
LESSONS="$PROJECT_DIR/.claude/lessons-learned.md"

# Nothing to nudge about unless a skill-bypass was caught this turn.
[[ -f "$BYPASS_FLAG" ]] || exit 0
# Only nudge once per turn (Stop can fire more than once).
[[ -f "$NUDGED_FLAG" ]] && exit 0

# If lessons-learned.md was modified within the last few minutes, assume the lesson was
# already captured this turn -- stay quiet. (mtime within 600s of now.)
if [[ -f "$LESSONS" ]]; then
  NOW=$(date +%s 2>/dev/null || echo 0)
  MT=$(stat -f %m "$LESSONS" 2>/dev/null || stat -c %Y "$LESSONS" 2>/dev/null || echo 0)
  if [[ "$NOW" -gt 0 && "$MT" -gt 0 ]]; then
    AGE=$(( NOW - MT ))
    if [[ "$AGE" -ge 0 && "$AGE" -lt 600 ]]; then
      exit 0
    fi
  fi
fi

touch "$NUDGED_FLAG" 2>/dev/null || true
echo "LESSONS-NUDGE: a skill-bypass was flagged this turn but .claude/lessons-learned.md was not updated. If this turn exposed a wrong assumption, hallucinated symbol, missed duplication, or wrong-domain edit, append a lesson now (non-negotiable #8) -- the loop only pays off if the fact lands in git, not in my head." >&2

exit 0
