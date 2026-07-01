# Shared hook preamble helpers. Sourced by guardrail hooks; defines functions only —
# no side effects at source time (never reads stdin / touches the fs on source).
#
# Sourced, not executed: no shebang-exec, no `chmod +x`, no `set`. Each hook locates this file
# relative to its own path and fails open if it is missing:
#     GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
#     [ -r "$GUARDRAILS_LIB" ] || exit 0
#     . "$GUARDRAILS_LIB"
# The readability guard is REQUIRED: `.` is a POSIX special builtin, so under `set -e` its
# open-failure exits the shell BEFORE a trailing `|| exit 0` can run — `. lib || exit 0` would
# fail CLOSED (exit 1). Guarding `[ -r ]` first is the only fail-open form under errexit.

# hook_sid <raw-stdin-json> -> echoes the sanitized session id, or "default".
# Safe on empty/garbage input and when jq is absent (-> "default").
hook_sid() {
  local sid
  sid=$(printf '%s' "${1:-}" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9._-') || sid=""
  [ -z "$sid" ] && sid=default
  printf '%s' "$sid"
}

# hook_state_dir <sanitized-sid> -> echoes the per-session state dir.
hook_state_dir() {
  printf '%s' "${CLAUDE_PROJECT_DIR:-.}/.claude/state/${1:-default}"
}

# hook_require_json <raw-stdin-json> -> EXITS the calling hook 0 (fail-open) if not valid JSON.
# MUST be called as a bare statement (not in $(...)) so its exit terminates the hook, not a
# subshell. `exit` in bash always terminates the shell regardless of `set -e`, so this works
# under both `set -euo pipefail` and `set -uo pipefail`.
hook_require_json() {
  printf '%s' "${1:-}" | jq -e . >/dev/null 2>&1 || exit 0
}

# hook_field <raw-json-string> <jq-filter> -> echoes the extracted value (jq -r).
# Fail-safe: empty/garbage input or jq absent -> empty string, never errors.
hook_field() {
  printf '%s' "${1:-}" | jq -r "${2:-empty}" 2>/dev/null || printf ''
}

# hook_json_update <file> [jq-args...] <filter>
# Atomic in-place read-modify-write: jq reads <file>, result replaces <file>. Last positional
# arg is the jq filter; args between <file> and it pass to jq verbatim (--arg/--argjson, any count).
# mv happens ONLY on jq success -> <file> untouched on failure. Returns jq's exit status.
# Self-contained: does NOT rely on the caller's `set -e`. Callers wanting fail-open write `|| exit 0`.
hook_json_update() {
  local file="$1"; shift
  local filter="${*: -1}"           # last positional = jq filter
  set -- "${@:1:$(($#-1))}"         # remaining = jq args
  jq "$@" "$filter" "$file" > "$file.tmp" 2>/dev/null && mv "$file.tmp" "$file"
}
