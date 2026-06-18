# Categorized Hook Layout — Implementation Plan

**Goal:** Move the vault's 12 hooks into top-level `hooks/<category>/<name>.sh` and expose them via committed flat symlinks in `.claude/hooks/`, with `.claude/settings.json` unchanged.

**Architecture:** Mirror of the shipped skills migration (variant B). Real hook files live under `hooks/<category>/`; `.claude/hooks/` holds only flat symlinks (`<name>.sh` → `../../hooks/<category>/<name>.sh`). `settings.json` keeps pointing at the flat symlink path, so wiring and all relative doc links resolve unchanged.

**Tech stack:** Bash, `git mv`, relative symlinks, `jq`. No build/test pipeline — "tests" are shell verification commands (RED before, GREEN after) + a live hook-fire check.

## Global constraints

- **Execution split — every step is tagged `[CLAUDE]` or `[HUMAN]`.** `security-guard.sh` (PreToolUse) blocks `git mv … .claude/hooks` (Rule 9). When Claude calls Bash the guard fires; when the human runs a command via `!` in the session it does NOT go through PreToolUse hooks. So all `git mv` of hooks + `link-hooks.sh` are `[HUMAN]` via `!`. Claude must NOT attempt `git mv .claude/hooks/...` through the Bash tool — it will be blocked. (spec → Scope, Edge cases)
- `.claude/settings.json` is NOT edited; its mixed path quoting is NOT tidied. (spec → Out of scope)
- Symlinks are repo-relative (`../../hooks/...`), never absolute; use `git mv` (not delete+create) for history. (spec → Risks)
- The human owns commits; each task ends with a proposed Conventional Commit, not an executed one. (CLAUDE.md → Git boundary)

## Taxonomy (verbatim from spec → Contracts)

```text
guards/    security-guard.sh read-guard.sh bash-read-guard.sh edit-write-guard.sh
routing/   skill-gate.sh detect-bypass.sh log-skill-usage.sh
quality/   lint-fix.sh test-quick.sh
session/   reset-turn-budget.sh token-guard.sh lessons-nudge.sh
```

---

## Task 1 — `[CLAUDE]` Write `scripts/link-hooks.sh`

**Files:** `scripts/link-hooks.sh` (NEW).

**Interfaces:**
- Consumes: nothing yet (the `hooks/` tree is populated by the human in Task 2).
- Produces: `scripts/link-hooks.sh` — idempotent regenerator. Discovery `find hooks -name '*.sh'`; symlink targets a FILE `<name>.sh` (the one divergence from `link-skills.sh`, which targets a dir).

Steps:

- [ ] **`[CLAUDE]` RED — script absent.**
  ```bash
  test -f scripts/link-hooks.sh && echo EXISTS || echo "RED: absent"
  ```
  Expected: `RED: absent`.

- [ ] **`[CLAUDE]` Write `scripts/link-hooks.sh`** (exact content):
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail

  # Regenerate flat discovery symlinks .claude/hooks/<name>.sh -> ../../hooks/<category>/<name>.sh
  # for every hooks/**/*.sh. Idempotent. Self-symlink + clobber guards.

  REPO="$(cd "$(dirname "$0")/.." && pwd)"
  SRC="$REPO/hooks"
  DEST="$REPO/.claude/hooks"

  # Self-symlink guard: .claude/hooks must be a real dir, not a symlink into this repo.
  if [ -L "$DEST" ]; then
    echo "error: $DEST is a symlink; expected a real directory. Remove it and re-run." >&2
    exit 1
  fi

  mkdir -p "$DEST"

  find "$SRC" -name '*.sh' -print0 |
  while IFS= read -r -d '' f; do
    name="$(basename "$f")"                 # <name>.sh  (file target)
    rel="../../hooks/${f#"$SRC"/}"          # ../../hooks/<category>/<name>.sh
    target="$DEST/$name"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "error: $target exists and is not a symlink; refusing to clobber." >&2
      exit 1
    fi
    ln -sfn "$rel" "$target"
    echo "linked $name -> $rel"
  done
  ```

- [ ] **`[CLAUDE]` Make executable.**
  ```bash
  chmod +x scripts/link-hooks.sh && echo OK-exec
  ```

- [ ] **`[CLAUDE]` GREEN — script present, executable, clean no-op against an empty `hooks/`** (create the dir first so `find` doesn't error under `set -euo pipefail`):
  ```bash
  test -x scripts/link-hooks.sh && echo OK-exists
  mkdir -p hooks && ./scripts/link-hooks.sh && echo OK-noop-run   # empty hooks/ → find matches nothing → exit 0
  ```
  Expected: `OK-exists` then `OK-noop-run`, with no `linked …` lines yet. The `mkdir -p hooks` also seeds the source tree the human's `git mv` fills in Task 2.

- [ ] **`[CLAUDE]` Propose commit** (do not run):
  ```text
  feat(hooks): add link-hooks.sh symlink regenerator
  ```

---

## Task 2 — `[HUMAN]` Relocate the 12 hooks and generate symlinks

**Files:** `hooks/<category>/<name>.sh` ×12 (NEW via `git mv`); `.claude/hooks/<name>.sh` ×12 (NEW symlinks via `link-hooks.sh`).

**Interfaces:**
- Consumes: `scripts/link-hooks.sh` from Task 1; the 12 real files in `.claude/hooks/`.
- Produces: 12 files under `hooks/<category>/`; 12 resolving symlinks at `.claude/hooks/<name>.sh`. Restores hook wiring through the symlinks.

Steps:

- [ ] **`[CLAUDE]` RED — no `hooks/` tree, zero symlinks.**
  ```bash
  find hooks -name '*.sh' 2>/dev/null | wc -l | tr -d ' '        # expect 0 (or no such dir)
  find .claude/hooks -maxdepth 1 -type l | wc -l | tr -d ' '     # expect 0
  ```

- [ ] **`[HUMAN]` Run the relocation block via `!` in the session** (Claude cannot — `git mv … .claude/hooks` is blocked by `security-guard.sh` Rule 9; the `!` prefix runs it as the user, bypassing PreToolUse hooks). Copy-paste exactly:
  ```bash
  mkdir -p hooks/guards hooks/routing hooks/quality hooks/session && \
  git mv .claude/hooks/security-guard.sh    hooks/guards/security-guard.sh && \
  git mv .claude/hooks/read-guard.sh        hooks/guards/read-guard.sh && \
  git mv .claude/hooks/bash-read-guard.sh   hooks/guards/bash-read-guard.sh && \
  git mv .claude/hooks/edit-write-guard.sh  hooks/guards/edit-write-guard.sh && \
  git mv .claude/hooks/skill-gate.sh        hooks/routing/skill-gate.sh && \
  git mv .claude/hooks/detect-bypass.sh     hooks/routing/detect-bypass.sh && \
  git mv .claude/hooks/log-skill-usage.sh   hooks/routing/log-skill-usage.sh && \
  git mv .claude/hooks/lint-fix.sh          hooks/quality/lint-fix.sh && \
  git mv .claude/hooks/test-quick.sh        hooks/quality/test-quick.sh && \
  git mv .claude/hooks/reset-turn-budget.sh hooks/session/reset-turn-budget.sh && \
  git mv .claude/hooks/token-guard.sh       hooks/session/token-guard.sh && \
  git mv .claude/hooks/lessons-nudge.sh     hooks/session/lessons-nudge.sh && \
  ./scripts/link-hooks.sh
  ```
  Expected tail: 12 `linked <name>.sh -> ../../hooks/<category>/<name>.sh` lines.

- [ ] **`[CLAUDE]` GREEN — 12 files relocated, 12 resolving symlinks, none real left at flat root** (reads, not blocked):
  ```bash
  find hooks -name '*.sh' | wc -l | tr -d ' '                       # expect 12
  [ "$(find .claude/hooks -maxdepth 1 -type l | wc -l | tr -d ' ')" = 12 ] && echo OK-12
  find .claude/hooks -maxdepth 1 -type f                            # expect: empty
  for l in .claude/hooks/*.sh; do test -f "$l" || echo "BROKEN: $l"; done   # expect: none
  ```

- [ ] **`[CLAUDE]` GREEN — idempotency** (re-run via `[HUMAN]` only if you want to confirm; `ln` is not guard-blocked, but per decision the human owns this run):
  ```bash
  # [HUMAN] optional: ./scripts/link-hooks.sh  → re-prints 12 linked lines, no clobber error
  echo "idempotency: re-run link-hooks.sh as HUMAN if confirming"
  ```

- [ ] **`[CLAUDE]` Propose commit** (do not run):
  ```text
  refactor(hooks): relocate hooks into hooks/<category>/ + flat symlinks
  ```

---

## Task 3 — `[CLAUDE]` Update the docs (not guard-blocked)

**Files (all EDIT):** `.claude/rules/common/domains-glossary.md` (row #3 L29, path list L13); `CLAUDE.md` (L19).

**Interfaces:**
- Consumes: the new layout from Tasks 1–2.
- Produces: glossary hook row describing source `hooks/*/<name>.sh` + flat-symlink discovery; light mentions consistent with the skills edits. No `<category>` injected into stable references (lesson `doc-over-coupled-volatile-detail`).

Steps:

- [ ] **`[CLAUDE]` RED — glossary still asserts the flat hook home.**
  ```bash
  grep -n '`.claude/hooks/\*.sh`' .claude/rules/common/domains-glossary.md   # expect: L29 hit
  ```

- [ ] **`[CLAUDE]` Edit glossary row #3 (L29)** — replace the "Lives in" cell:
  ```text
  | 3 | **hook** | source `hooks/*/<name>.sh`; surfaced via flat symlink `.claude/hooks/<name>.sh`, wired by `settings.json` | runs on tool events | a gate/logger (`detect-bypass`, `skill-gate`, `token-guard`, `lessons-nudge`, …) |
  ```

- [ ] **`[CLAUDE]` Edit glossary L13** — the read-or-edit path list, add the real source:
  ```text
  - Anytime you read or edit `.claude/skills/**`, `.claude/rules/**`, `hooks/**` (surfaced via `.claude/hooks/**`), or `.claude/skills-routing.json`.
  ```

- [ ] **`[CLAUDE]` Edit `CLAUDE.md` L19** — extend the harness clause so hooks parallel the skills phrasing:
  ```text
  … plus the harness around them: hooks authored under `hooks/` and surfaced via flat symlinks in `.claude/hooks/` (gates + logging), `.claude/rules/common/` (framework + domain glossary), `.claude/skills-routing.json`, `.claude/state/`. No application code, no `package.json`, no build.
  ```

- [ ] **`[CLAUDE]` GREEN — old assertion gone, no `<category>` leaked into hook docs:**
  ```bash
  grep -rn '`.claude/hooks/\*.sh`' .claude/rules/common/domains-glossary.md   # expect: empty
  grep -rn 'hooks/<category>' .claude/rules/ CLAUDE.md                        # expect: empty
  ```

- [ ] **`[CLAUDE]` Propose commit** (do not run):
  ```text
  docs(rules): describe categorized hook source + symlink surface
  ```

---

## Task 4 — Final acceptance (verification block + live hook-fire)

**Files:** none changed — verification only.

**Interfaces:**
- Consumes: complete state from Tasks 1–3.
- Produces: pasted evidence that every spec acceptance criterion holds.

Steps:

- [ ] **`[CLAUDE]` Spec Verification block** (commands #1–#6):
  ```bash
  # #1 12 symlinks, no real .sh at flat root
  [ "$(find .claude/hooks -maxdepth 1 -type l | wc -l | tr -d ' ')" = 12 ] && echo OK-12
  find .claude/hooks -maxdepth 1 -type f                                  # expect empty
  # #2 every symlink resolves
  for l in .claude/hooks/*.sh; do test -f "$l" || echo "BROKEN: $l"; done
  # #3 settings.json byte-for-byte unchanged
  git diff --exit-code -- .claude/settings.json && echo OK-settings-untouched
  # #4 settings.json hook paths resolve through the symlink
  grep -oE '\.claude/hooks/[a-z-]+\.sh' .claude/settings.json | sort -u | while read -r p; do test -f "$p" || echo "MISSING: $p"; done
  # #5a doc links resolve through the flat symlink (as written from .claude/rules/common/: ../../hooks/<name>.sh -> .claude/hooks/<name>.sh)
  for p in detect-bypass skill-gate log-skill-usage; do test -f .claude/rules/common/../../hooks/$p.sh && echo "OK-link $p"; done
  # #5b the real categorized source file exists (top-level hooks/, three levels up from the rules dir)
  for p in detect-bypass skill-gate log-skill-usage; do test -f hooks/routing/$p.sh && echo "OK-src $p"; done
  # #6 git mv preserved per-hook history
  git log --follow --oneline -1 -- hooks/guards/security-guard.sh
  ```
  Note #5: the markdown links are written `../../hooks/<name>.sh`; from `.claude/rules/common/` that resolves to `.claude/hooks/<name>.sh` (the flat symlink) — #5a proves the link target exists, #5b proves the real categorized source behind it exists.

- [ ] **`[CLAUDE]` Live hook-fire check.** Run a command `security-guard.sh` inspects and confirm it still fires (proves the symlinked hook is invoked by `settings.json`):
  ```bash
  # Run via Bash tool a command the guard blocks (e.g. one combining a .claude/hooks mutation pattern).
  # Expected: PreToolUse:Bash hook error from security-guard.sh — i.e. the moved+symlinked hook fired.
  ```
  Expected: the guard's `BLOCKED:` message appears → the relocated hook is live.

- [ ] **`[CLAUDE]` Paste the full block output** as acceptance evidence in the status block.

- [ ] **No commit** — Task 4 is verification only.

---

## Out of scope (carried from spec — do NOT implement)

- Editing `.claude/settings.json`; tidying its mixed path quoting.
- A generic unified skills+hooks linker (future abstraction).
- Pruning dangling symlinks (link-hooks.sh is additive-only, as link-skills.sh).
- The categories-inside-`.claude/hooks/` variant; taxonomy affecting the wiring.
