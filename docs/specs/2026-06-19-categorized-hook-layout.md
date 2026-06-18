# Spec: Categorized hook layout (top-level `hooks/` + flat symlinks)

Status: approved-design → spec for review. Source: `grilling` + readiness-review, this session. Parallel of the shipped `docs/specs/2026-06-19-categorized-skill-layout.md` — same form, hook-specific differences called out.

## Goal

Move the vault's 12 hooks into top-level `hooks/<category>/<name>.sh` and expose them through committed flat symlinks in `.claude/hooks/`, mirroring the skills layout — without editing `.claude/settings.json` or breaking any relative doc link. Driver: a uniform source/symlink shape for a future cross-project migration abstraction.

## Scope

- Create top-level `hooks/` with 4 category dirs and relocate each of the 12 `.claude/hooks/*.sh` into `hooks/<category>/<name>.sh`.
- Add 12 committed flat symlinks `.claude/hooks/<name>.sh` → `../../hooks/<category>/<name>.sh`.
- Add `scripts/link-hooks.sh` — idempotent symlink regenerator for the `hooks/` tree (parallel to `scripts/link-skills.sh`, with hook-specific discovery).
- Update the one doc that asserts hook ownership (glossary row #3) + two light mentions (glossary L13, CLAUDE.md L19).
- **The file-relocation operations (`git mv` + symlink creation) are run by the human**, because `security-guard.sh` blocks them; Claude writes the script + the exact command block + all doc edits.

## Out of scope

- Editing `.claude/settings.json` — it points at `$CLAUDE_PROJECT_DIR/.claude/hooks/<name>.sh` (the symlink) and stays byte-for-byte unchanged. Its mixed path quoting (`"$CLAUDE_PROJECT_DIR"/...` vs `$CLAUDE_PROJECT_DIR/...`) is NOT to be "tidied".
- A generic unified skills+hooks linker (the deferred future abstraction).
- Taxonomy leaking into the wiring; the categories-inside-`.claude/hooks/` variant.
- Pruning dangling symlinks on future rename/delete — `link-hooks.sh` is additive-only, same as `link-skills.sh` (recorded limitation, N/A for this 12→12 move).
- Fixing/rewriting any hook's behavior.

## Contracts

**Taxonomy (12 hooks → 4 categories, 1:1 verified against `ls`):**

```text
hooks/
  guards/    security-guard.sh read-guard.sh bash-read-guard.sh edit-write-guard.sh
  routing/   skill-gate.sh detect-bypass.sh log-skill-usage.sh
  quality/   lint-fix.sh test-quick.sh
  session/   reset-turn-budget.sh token-guard.sh lessons-nudge.sh
```

**Symlink shape** — relative, targets a FILE (not a dir, unlike skills):

```text
.claude/hooks/security-guard.sh   -> ../../hooks/guards/security-guard.sh
.claude/hooks/detect-bypass.sh    -> ../../hooks/routing/detect-bypass.sh
# ... 12 total. Resolving `.claude/hooks/<name>.sh` reaches the real file.
```

**`settings.json` wiring — UNCHANGED** (points at the symlink, which resolves):

```text
"$CLAUDE_PROJECT_DIR"/.claude/hooks/security-guard.sh   # still valid via symlink
```

**`scripts/link-hooks.sh` contract** — mirrors `link-skills.sh` with two hook-specific differences (discovery predicate + file target):

```bash
#!/usr/bin/env bash
set -euo pipefail
# Regenerate flat symlinks .claude/hooks/<name>.sh -> ../../hooks/<category>/<name>.sh
# for every hooks/**/*.sh. Idempotent. Self-symlink + clobber guards.
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/hooks"; DEST="$REPO/.claude/hooks"
[ -L "$DEST" ] && { echo "error: $DEST is a symlink; expected a real dir." >&2; exit 1; }
mkdir -p "$DEST"
find "$SRC" -name '*.sh' -print0 | while IFS= read -r -d '' f; do   # *.sh, not SKILL.md
  name="$(basename "$f")"                                            # <name>.sh (file target)
  rel="../../hooks/${f#"$SRC"/}"                                     # ../../hooks/<category>/<name>.sh
  target="$DEST/$name"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "error: $target exists and is not a symlink; refusing to clobber." >&2; exit 1
  fi
  ln -sfn "$rel" "$target"; echo "linked $name -> $rel"
done
```

## Files touched

| File(s) | Kind | Why |
| --- | --- | --- |
| `hooks/<category>/<name>.sh` ×12 | NEW (human runs `git mv` from `.claude/hooks/<name>.sh`) | real hook files relocate under category folders; preserves history |
| `.claude/hooks/<name>.sh` ×12 | NEW (human runs `link-hooks.sh`) | flat symlink surface → `../../hooks/<category>/<name>.sh`; keeps `settings.json` + doc links valid |
| `scripts/link-hooks.sh` | NEW (Claude writes) | idempotent symlink regenerator, hook-specific discovery (`*.sh`, file target) |
| `.claude/rules/common/domains-glossary.md` | EDIT (Claude, row #3 L29) | hook ownership: source `hooks/*/<name>.sh`, surfaced via flat symlink `.claude/hooks/<name>.sh`, wired by `settings.json` |
| `.claude/rules/common/domains-glossary.md` | EDIT (Claude, L13) | when-to-read path list: note real source `hooks/` alongside `.claude/hooks/` |
| `CLAUDE.md` | EDIT (Claude, L19) | harness mention: hooks authored under `hooks/`, surfaced via `.claude/hooks/` symlinks |
| `.claude/settings.json` | UNCHANGED | points at the symlink; deliberately untouched |
| `skill-routing-sync.md` L22, `framework.md` L10, `CLAUDE.md` L40 | UNCHANGED | relative links / layer ref resolve through the symlink; no `<category>` injected (lesson `doc-over-coupled-volatile-detail`) |

## Edge cases

- **Empty / leftover:** after `git mv`, no real `.sh` may remain directly under `.claude/hooks/` — only symlinks. Verify: `find .claude/hooks -maxdepth 1 -type f` returns nothing.
- **Broken symlink:** every `.claude/hooks/<name>.sh` must resolve to an existing file. Dangling = failure. Verify per-link with `test -f`.
- **`security-guard.sh` self-block (the load-bearing risk):** `git mv .claude/hooks/security-guard.sh hooks/guards/` matches Rule 9 (`mv … .claude/hooks`) → blocked if Claude runs it via Bash. Resolution: the human runs all `git mv` + the `link-hooks.sh` step. `ln -s` into `.claude/hooks/` is NOT currently blocked, but is still human-run to avoid depending on the guard's blind spot.
- **Hooks still fire after move:** because `settings.json` is unchanged and symlinks resolve, every event hook (PreToolUse / PostToolUse / Stop / UserPromptSubmit) must still trigger. A guard firing on a test command is positive evidence.
- **`git mv` history:** human uses `git mv` (not delete+create) so per-hook history follows (R100 rename, as in the skills migration).
- **Relative symlink targets:** `../../hooks/<category>/<name>.sh`, never absolute, so clones/worktrees resolve.

## Verification

Real commands (run from repo root). The `git mv` + `link-hooks.sh` are **human-run**; these checks run after:

```bash
# 1. 12 symlinks, no real .sh left at the flat root
[ "$(find .claude/hooks -maxdepth 1 -type l | wc -l | tr -d ' ')" = 12 ] && echo OK-12
find .claude/hooks -maxdepth 1 -type f   # expect: empty

# 2. Every flat symlink resolves to a real hook file
for l in .claude/hooks/*.sh; do test -f "$l" || echo "BROKEN: $l"; done

# 3. settings.json byte-for-byte unchanged
git diff --exit-code -- .claude/settings.json && echo OK-settings-untouched

# 4. Every settings.json hook path resolves (through the symlink)
grep -oE '\.claude/hooks/[a-z-]+\.sh' .claude/settings.json | sort -u | while read -r p; do test -f "$p" || echo "MISSING: $p"; done

# 5. Relative doc links to hooks resolve (from .claude/rules/common/)
for p in detect-bypass skill-gate log-skill-usage; do test -f .claude/rules/common/../../hooks/$p.sh && echo "OK $p"; done

# 6. git mv preserved per-hook history
git log --follow --oneline -1 -- hooks/guards/security-guard.sh
```

Plus a **live hook-fire check**: trigger a guarded action (e.g. a Bash command security-guard inspects) and confirm the guard still responds — proves the symlinked hook is invoked by `settings.json`.

## Risks

- **Self-blocking guard:** mitigated by human-run file-ops (above). The spec's command block for the human must be copy-pasteable.
- **`link-hooks.sh` is not a pure mirror:** discovery is `find hooks -name '*.sh'` and the symlink targets a file `<name>.sh` (skills target a dir). Pinning this in Contracts prevents a blind copy of `-name SKILL.md`.
- **Future `ln` hardening:** if Rule 9 ever adds `ln`, an automated `link-hooks.sh` would break — keeping it human-run sidesteps this; noted so a later hardening PR knows the dependency.
- **History loss:** use `git mv`, not delete+create.
