#!/usr/bin/env bash
# Run every <hook>.sh.cases fixture against its real hook; assert per-case decision.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"   # hooks resolve ${CLAUDE_PROJECT_DIR:-.} and repo-root-relative transcript_path against cwd; pin it so the suite is deterministic from any invocation cwd
fail=0; total=0
ERRF="$(mktemp)"; trap 'rm -f "$ERRF"' EXIT
for cases in "$ROOT"/plugins/guardrails-kit/hooks/tests/*.sh.cases \
             "$ROOT"/hooks/guards/tests/*.sh.cases; do
  [ -e "$cases" ] || continue
  hook="$(dirname "$(dirname "$cases")")/$(basename "$cases" .cases)"   # tests/x.sh.cases -> ../x.sh
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    total=$((total+1))
    name=$(jq -r '.name' <<<"$line")
    if jq -e 'has("stdin_raw")' >/dev/null <<<"$line"; then in=$(jq -r '.stdin_raw' <<<"$line"); else in=$(jq -c '.stdin' <<<"$line"); fi
    want_exit=$(jq -r '.expect_exit' <<<"$line")
    out=$(printf '%s' "$in" | bash "$hook" 2>"$ERRF"); got=$?
    err=$(cat "$ERRF")
    ok=1; why=""
    [ "$got" = "$want_exit" ] || { ok=0; why="$why [exit]"; }
    sj=$(jq -r '.expect_stdout_jq // empty' <<<"$line"); if [ -n "$sj" ]; then printf '%s' "$out" | jq -e "$sj" >/dev/null 2>&1 || { ok=0; why="$why [stdout_jq]"; }; fi
    sg=$(jq -r '.expect_stderr_grep // empty' <<<"$line"); if [ -n "$sg" ]; then printf '%s' "$err" | grep -qE "$sg" || { ok=0; why="$why [stderr_grep]"; }; fi
    se=$(jq -r '.expect_stdout_empty // empty' <<<"$line"); if [ "$se" = "true" ]; then [ -z "$out" ] || { ok=0; why="$why [stdout_empty]"; }; fi
    if [ "$ok" = 1 ]; then echo "PASS $(basename "$hook") :: $name"; else echo "FAIL $(basename "$hook") :: $name (exit $got want $want_exit)$why"; fail=1; fi
  done < "$cases"
done
echo "fixtures: $total run"; exit $fail
