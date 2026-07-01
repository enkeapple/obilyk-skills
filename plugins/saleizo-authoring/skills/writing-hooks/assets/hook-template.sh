#!/bin/bash
# <NAME> hook — <event> (matcher: <matcher>). Form A (exit-code): 0 = allow, 2 = block.
# Fail-open is an invariant: any own-error / missing dep / unparseable input → exit 0.

# --- shared preamble: source the repo's hook lib if present, fail-open if missing ---
HOOK_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"      # illustrative path — your repo may differ
[ -r "$HOOK_LIB" ] || exit 0                        # unreadable/missing lib → allow (fail-open)
. "$HOOK_LIB"

# --- fail-open guards: never disrupt real work because of THIS hook's own failure ---
command -v jq >/dev/null 2>&1 || exit 0            # missing dependency → allow
INPUT=$(cat 2>/dev/null) || exit 0                 # unreadable stdin → allow
FIELD=$(hook_field "$INPUT" '.tool_input.file_path // empty')
[ -z "$FIELD" ] && exit 0                            # empty target field → allow

# --- the ONE specific, verified condition this hook gates ---
if printf '%s' "$FIELD" | grep -qiE '<pattern>'; then
  echo "BLOCKED: <reason the model will see on stderr>." >&2
  exit 2
fi

exit 0

# A logger variant ends the same way: replace the block branch with an append to a
# log file, and let every path still reach `exit 0` (a logger never blocks).
#
# Form B (JSON-stdout deny, only when a model-visible structured reason is needed):
#   printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"<reason>"}}\n'
#   exit 0
# Do NOT emit both Form A (exit 2) and Form B (JSON) together.
#
# A state-writing variant (e.g. a session/quality hook persisting a counter) updates its
# JSON state file via hook_json_update, never a hand-rolled tmp+mv:
#   STATE_FILE="$(hook_state_dir "$(hook_sid "$INPUT")")/my-hook.json"
#   hook_json_update "$STATE_FILE" --arg k "$FIELD" '.count += 1 | .last = $k' || exit 0
