#!/usr/bin/env bash
# PreCompact hook: advisory handoff nudge on auto-compaction.
#
# Why: auto-compaction near the context limit is where an in-context plan/state is silently
# lost. This injects an advisory checkpoint (hookSpecificOutput.additionalContext) that SURVIVES
# the compaction, telling the agent to persist resumable work via the `handoff` skill before the
# squeeze. Advisory only -- never blocks (a suggestive signal must not wedge the session; same
# rationale as lessons-nudge.sh). Fires ONLY on trigger=="auto" AND when the consumer has a
# `handoff` skill routed; silent on manual /compact and when handoff is not routed.
#
# Contract (verified against official Claude Code PreCompact docs):
#   stdin JSON: hook_event_name, trigger ("auto"|"manual"), session_id, transcript_path, cwd.
#   To nudge: stdout {systemMessage, hookSpecificOutput:{hookEventName:"PreCompact",additionalContext}}.
#   exit 0 ALWAYS (advisory). $CLAUDE_PROJECT_DIR available.
# Fail-open: missing lib / absent jq / non-JSON stdin / missing routing -> exit 0, no output.
set -uo pipefail

GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib → fail open (`.` is special: guard readability first)
. "$GUARDRAILS_LIB"
command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat 2>/dev/null) || exit 0
hook_require_json "$INPUT"   # non-JSON → exits 0 (bare statement, terminates the hook)

# Gate 1: only auto-compaction (silent on manual /compact and missing/garbage trigger).
TRIGGER=$(printf '%s' "$INPUT" | jq -r '.trigger // ""' 2>/dev/null) || exit 0
[ "$TRIGGER" = "auto" ] || exit 0

# Gate 2: only when the consumer has a `handoff` skill routed (else the nudge is pointless).
ROUTING="${CLAUDE_PROJECT_DIR:-.}/.claude/skills-routing.json"
jq -e '.skills.handoff' "$ROUTING" >/dev/null 2>&1 || exit 0

CONTEXT="Context is about to be auto-compacted. If you have unfinished work whose plan or state lives only in this context (not yet on disk), invoke the handoff skill now to persist a resumable plan before the compaction, and re-read that file afterwards."
MSG="PreCompact: unfinished work? consider the handoff skill before context is compacted."

jq -cn --arg c "$CONTEXT" --arg m "$MSG" \
  '{systemMessage:$m, hookSpecificOutput:{hookEventName:"PreCompact", additionalContext:$c}}' \
  2>/dev/null || exit 0
exit 0
