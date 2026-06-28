#!/usr/bin/env bash
# SessionStart hook: inject a compact routing-telemetry digest on a FRESH session start.
#
# Why: the guardrails telemetry (bypasses, friction) is only acted on if someone looks at it.
# Surfacing a compact health line at the start of a new session — plus a nudge to the
# reviewing-telemetry skill for the per-skill triage — puts routing health in front of the
# agent without anyone running a report by hand. A hook cannot invoke a skill, so it REUSES the
# repo's metrics-report.sh for the canonical aggregates and points to the skill for the deep dive.
#
# Deliberately narrow to avoid becoming wallpaper (the lessons-nudge anti-noise rationale):
# fires ONLY on source=="startup" (a fresh session — not resume/clear/compact) AND only when at
# least one bypass is recorded (nothing actionable → stay silent).
#
# Contract (verified against official Claude Code SessionStart docs): stdin JSON has `source`
# (startup|resume|clear|compact). To inject: stdout {hookSpecificOutput:{hookEventName:
# "SessionStart", additionalContext:<text>}}. SessionStart cannot block; exit 0 always.
# Fail-open: missing lib / absent jq / non-JSON stdin / missing report script / no data → exit 0, no output.
set -uo pipefail

GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib → fail open (`.` is special: guard readability first)
. "$GUARDRAILS_LIB"
command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat 2>/dev/null) || exit 0
hook_require_json "$INPUT"   # non-JSON → exits 0 (bare statement, terminates the hook)

# Gate 1: only a fresh startup (silent on resume/clear/compact and missing source).
SRC=$(printf '%s' "$INPUT" | jq -r '.source // ""' 2>/dev/null) || exit 0
[ "$SRC" = "startup" ] || exit 0

# Reuse the repo's metrics-report script for canonical aggregates; absent → silent (fail-open).
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
REPORT="$PROJECT_DIR/scripts/metrics-report.sh"
[ -f "$REPORT" ] || exit 0
OUT=$(bash "$REPORT" "$PROJECT_DIR" 2>/dev/null) || exit 0

# Gate 2: only when at least one bypass is recorded (else nothing actionable → silent).
printf '%s' "$OUT" | grep -q '^- bypass:' || exit 0

# Compact digest = Skill-routing + Friction sections only (drop the title and token-spend section).
DIGEST=$(printf '%s\n' "$OUT" | awk '/^## Skill routing/{p=1} /^## Token spend/{p=0} p{print}')
[ -n "$DIGEST" ] || exit 0
CONTEXT=$(printf '%s\n\n→ Run the reviewing-telemetry skill for the per-skill triage and recommended actions.' "$DIGEST")

jq -cn --arg c "$CONTEXT" \
  '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}' \
  2>/dev/null || exit 0
exit 0
