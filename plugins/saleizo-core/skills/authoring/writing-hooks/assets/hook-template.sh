#!/bin/bash
# <NAME> hook — <event> (matcher: <matcher>). Form A (exit-code): 0 = allow, 2 = block.
# Fail-open is an invariant: any own-error / missing dep / unparseable input → exit 0.

# --- fail-open guards: never disrupt real work because of THIS hook's own failure ---
command -v jq >/dev/null 2>&1 || exit 0            # missing dependency → allow
INPUT=$(cat 2>/dev/null) || exit 0                 # unreadable stdin → allow
FIELD=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
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
