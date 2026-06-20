#!/usr/bin/env bash
# PostToolUse hook (matcher: Edit|MultiEdit|Write): advisory quality pass, branched by file class.
# Replaces the split lint-fix.sh + test-quick.sh with ONE agnostic hook:
#   - Vault docs (a SKILL.md, or any file under a .claude/rules/ tree): run the vault's own
#     structural validators -- frontmatter <=1024 bytes, balanced code fences, and for a SKILL.md
#     the name regex (^[a-z0-9-]+$ and name == dir), plus reference-link resolution.
#   - Consumer code (.ts/.tsx/.js/.jsx): run `eslint --fix` + `jest`, but ONLY if `npx` resolves.
# Fail-open and non-blocking: every check warns to stderr; the hook always exits 0. In this vault
# (no node toolchain, no .ts/.js) the code branch is a silent no-op; in a consumer repo with no
# SKILL.md / .claude/rules the docs branch never fires. The same hook is correct in either repo --
# which is why it is branched by file class, not pinned to one stack.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat 2>/dev/null) || exit 0
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
[ -n "$FILE" ] || exit 0
[ -f "$FILE" ] || exit 0
base=$(basename "$FILE")

case "$FILE" in
  *.md)
    # Only validate vault docs: a SKILL.md, or a file under a .claude/rules/ tree.
    if [ "$base" = "SKILL.md" ] || printf '%s' "$FILE" | grep -q '/\.claude/rules/'; then

      # frontmatter <= 1024 bytes (only when a leading --- block exists)
      if head -1 "$FILE" | grep -q '^---[[:space:]]*$'; then
        fm=$(awk 'NR==1&&/^---[[:space:]]*$/{f=1;next} f&&/^---[[:space:]]*$/{exit} f{print}' "$FILE")
        bytes=$(printf '%s' "$fm" | wc -c | tr -d ' ')
        [ "${bytes:-0}" -le 1024 ] || echo "QUALITY warn: $FILE frontmatter is ${bytes} bytes (>1024)." >&2
      fi

      # balanced code fences (even number of ``` lines). grep -c always prints a count and
      # exits 1 when that count is 0 -- capture the number, ignore the exit code (no `|| echo`,
      # which would print a SECOND line and break the arithmetic).
      fences=$(grep -c '^```' "$FILE" 2>/dev/null); fences=${fences:-0}
      if [ $(( fences % 2 )) -ne 0 ]; then
        echo "QUALITY warn: $FILE has an odd number of code fences (${fences}) -- unbalanced." >&2
      fi

      # SKILL.md name regex + name == dir
      if [ "$base" = "SKILL.md" ]; then
        nm=$(grep -m1 '^name:' "$FILE" | sed 's/^name:[[:space:]]*//' | tr -d '"' | tr -d "'")
        dir=$(basename "$(dirname "$FILE")")
        if [ -n "$nm" ]; then
          printf '%s' "$nm" | grep -qE '^[a-z0-9-]+$' || echo "QUALITY warn: $FILE name '$nm' fails ^[a-z0-9-]+$." >&2
          [ "$nm" = "$dir" ] || echo "QUALITY warn: $FILE name '$nm' != dir '$dir'." >&2
        fi
      fi

      # reference links resolve (skip illustrative links shown inside inline backticks)
      dirpath=$(dirname "$FILE")
      grep -nE '\]\([^)]+\.md[^)]*\)' "$FILE" 2>/dev/null | while IFS= read -r line; do
        printf '%s' "$line" | grep -q '`[^`]*\](' && continue
        target=$(printf '%s' "$line" | sed -E 's/.*\]\(([^)#]+\.md)[^)]*\).*/\1/')
        case "$target" in
          http*|/*) continue ;;
        esac
        [ -e "$dirpath/$target" ] || echo "QUALITY warn: $FILE references missing path '$target'." >&2
      done
    fi
    ;;

  *.ts|*.tsx|*.js|*.jsx)
    # Consumer code only; no-op in this vault (no node toolchain). Lint and test are DISTINCT
    # checks with DISTINCT conditions -- do not lump them onto one trigger:
    #   - Lint: `eslint --fix` on the touched file itself (any source or test file).
    #   - Test: `jest`, keyed to the file's ROLE -- a test file (*.test.* / *.spec.*) is run
    #     directly; a source file does NOT "run itself", so jest runs only the tests RELATED to
    #     it (--findRelatedTests), i.e. the .test/.spec files that import it.
    command -v npx >/dev/null 2>&1 || exit 0
    npx eslint --fix "$FILE" 2>/dev/null || true
    case "$base" in
      *.test.*|*.spec.*) npx jest "$FILE" --passWithNoTests 2>/dev/null || true ;;
      *)                 npx jest --findRelatedTests "$FILE" --passWithNoTests 2>/dev/null || true ;;
    esac
    ;;
esac

exit 0
