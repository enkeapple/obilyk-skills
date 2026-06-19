# Relocate Domain Rules Implementation Plan

**Goal:** Restructure the domain rules: relocate to `.claude/rules/domains/`, rename `domains-glossary.md`→`glossary.md`, and rename the skills `*-domain-rules`→`*-glossary` — fixing every live reference so nothing dangles.
**Architecture:** Four tasks. Task 1 (relocation) is already applied; Task 2 completes it (4 concept refs the first pass missed + table split); Task 3 renames the glossary file; Task 4 renames the two skills (structural + ~14 refs). Each verifies with the vault's real checks — the "test" is `ls`/`find`/`readlink`/`jq` + a **broad** bare-token grep (lesson `relocate-reference-undercount`: never `dir/specific-file`). No build.

> **In-flight:** Task 1's git mv + most edits are on disk uncommitted. Tasks 2–4 are the remaining work. Commit split decided at the end (≈2 commits).
**Tech stack:** Markdown docs; bash (`git mv`, `grep`, `test -f`) for verification. No test runner exists in this vault.

## Global constraints

- Source of truth for every exact before→after string: `docs/specs/2026-06-19-relocate-domain-rules.md` → Contracts. Copy verbatim.
- **Sequencing is load-bearing:** `git mv` FIRST, then edit `framework.md` at its NEW path (`.claude/rules/domains/`). Editing before the move races the move.
- D3: do NOT touch `docs/specs/**` or `docs/plans/**`.
- Out of scope: `framework.md` line-44 `[lessons-learned.md](./lessons-learned.md)` oddity — leave it.
- `domains/` and `common/` are the same nesting depth, so `../../` / `../../../` links in moved files are depth-invariant — do NOT edit them.
- Single commit at the end (the relocation is atomic; no valid partial state).

## Task 1: Relocate the two files and fix every reference — APPLIED (uncommitted)

> Already on disk (steps below ran). Task 2 completes the references this task's too-narrow grep missed. Kept for the record; do not re-run step 10's commit (the split is decided at the end).

**Files:**
- `.claude/rules/common/domains-glossary.md` → `.claude/rules/domains/domains-glossary.md` (MOVE)
- `.claude/rules/common/framework.md` → `.claude/rules/domains/framework.md` (MOVE, then edit)
- `.claude/rules/common/agnostic-skill-authoring.md` (EDIT — stays)
- `.claude/rules/common/scoping-skill-value.md` (EDIT — stays)
- `.claude/CLAUDE.md`, `CLAUDE.md` (EDIT)
- `skills/foundation/bootstrapping-domain-rules/SKILL.md` (EDIT)
- `skills/foundation/auditing-domain-rules/SKILL.md` (EDIT)
- `skills/foundation/bootstrapping-claude-md/references/operating-manual-template.md` (EDIT ×3)
- `skills/foundation/bootstrapping-claude-md/references/root-claude-md-template.md` (EDIT)

**Interfaces:**
- Consumes: nothing (first/only task).
- Produces: canonical paths `.claude/rules/domains/framework.md` and `.claude/rules/domains/domains-glossary.md`; `.claude/rules/common/` no longer contains either.

### Steps

- [ ] **1. RED — confirm the target does not exist yet.**

  ```bash
  ls .claude/rules/domains/framework.md 2>&1
  # expect: ls: .claude/rules/domains/framework.md: No such file or directory
  ```

- [ ] **2. Create the folder and `git mv` both files (history-preserving).**

  ```bash
  mkdir -p .claude/rules/domains
  git mv .claude/rules/common/domains-glossary.md .claude/rules/domains/domains-glossary.md
  git mv .claude/rules/common/framework.md        .claude/rules/domains/framework.md
  ls -1 .claude/rules/domains/
  # expect: domains-glossary.md  framework.md
  ```

- [ ] **3. Fix the one intra-`rules/` link inside the moved `framework.md`** (line ~10, link to a rule that stays in `common/`).

  Edit `.claude/rules/domains/framework.md`:

  ```text
  old:  exists (see [skill-routing-sync.md](./skill-routing-sync.md)).
  new:  exists (see [skill-routing-sync.md](../common/skill-routing-sync.md)).
  ```

  (Leave line 3 `[domains-glossary.md](./domains-glossary.md)` — both files moved together. Leave line 44 `lessons-learned.md` — out of scope.)

- [ ] **4. Fix the two links in staying files that point at the now-moved `framework.md`.**

  Edit `.claude/rules/common/agnostic-skill-authoring.md` (line ~15):

  ```text
  old:  enforced as a check in [framework.md](./framework.md) → "Suspicion Protocol" #2
  new:  enforced as a check in [framework.md](../domains/framework.md) → "Suspicion Protocol" #2
  ```

  Edit `.claude/rules/common/scoping-skill-value.md` (line ~50):

  ```text
  old:  inherits the vault's operating manual ([framework.md](./framework.md): the Iron Law,
  new:  inherits the vault's operating manual ([framework.md](../domains/framework.md): the Iron Law,
  ```

- [ ] **5. Update the live path references in both CLAUDE.md files.**

  Edit `.claude/CLAUDE.md` (lines ~114-115):

  ```text
  old:  - Process basics (Implementation/Suspicion protocols, evidence-based verification, question discipline): [rules/common/framework.md](./rules/common/framework.md)
        - Domain glossary: [rules/common/domains-glossary.md](./rules/common/domains-glossary.md)
  new:  - Process basics (Implementation/Suspicion protocols, evidence-based verification, question discipline): [rules/domains/framework.md](./rules/domains/framework.md)
        - Domain glossary: [rules/domains/domains-glossary.md](./rules/domains/domains-glossary.md)
  ```

  Edit `CLAUDE.md` (line ~59) — swap `rules/common/` → `rules/domains/` in all four occurrences (two text labels + two link targets):

  ```text
  old:  ...: [.claude/rules/common/framework.md](./.claude/rules/common/framework.md). Domain glossary: [.claude/rules/common/domains-glossary.md](./.claude/rules/common/domains-glossary.md).
  new:  ...: [.claude/rules/domains/framework.md](./.claude/rules/domains/framework.md). Domain glossary: [.claude/rules/domains/domains-glossary.md](./.claude/rules/domains/domains-glossary.md).
  ```

- [ ] **6. Update the taught convention in the two domain-rules skills (D2).**

  Edit `skills/foundation/bootstrapping-domain-rules/SKILL.md` (line ~24):

  ```text
  old:  - A new or unruled project: there is no `.claude/rules/common/` glossary or framework yet.
  new:  - A new or unruled project: there is no `.claude/rules/domains/` glossary or framework yet.
  ```

  Edit `skills/foundation/auditing-domain-rules/SKILL.md` — frontmatter `description` (line ~5):

  ```text
  old:  charter under .claude/rules/common/) still match the current code, and to
  new:  charter under .claude/rules/domains/) still match the current code, and to
  ```

  and When-to-use (line ~21):

  ```text
  old:  - Periodic maintenance of `.claude/rules/common/` (glossary, framework) — especially
  new:  - Periodic maintenance of `.claude/rules/domains/` (glossary, framework) — especially
  ```

- [ ] **7. Update the taught convention in the two claude-md templates (D2).**

  Edit `skills/foundation/bootstrapping-claude-md/references/operating-manual-template.md`:

  ```text
  line ~67:  old: ...is defined in [rules/common/framework.md](./rules/common/framework.md). Temp-file...
             new: ...is defined in [rules/domains/framework.md](./rules/domains/framework.md). Temp-file...
  line ~124: old: - Process basics: [rules/common/framework.md](./rules/common/framework.md)
             new: - Process basics: [rules/domains/framework.md](./rules/domains/framework.md)
  line ~125: old: - Domain glossary: [rules/common/<glossary>.md](./rules/common/)
             new: - Domain glossary: [rules/domains/<glossary>.md](./rules/domains/)
  ```

  Edit `skills/foundation/bootstrapping-claude-md/references/root-claude-md-template.md` (line ~84):

  ```text
  old:  ...): [.claude/rules/common/framework.md](./.claude/rules/common/framework.md).
  new:  ...): [.claude/rules/domains/framework.md](./.claude/rules/domains/framework.md).
  ```

- [ ] **8. GREEN — dangling-reference grep over live files returns nothing.**

  ```bash
  grep -rn "rules/common/\(framework\|domains-glossary\)" \
    --include="*.md" skills/ CLAUDE.md .claude/CLAUDE.md hooks/
  # expect: no output (exit 1)
  ```

- [ ] **9. GREEN — every relative link in the moved + edited rule files resolves.**

  ```bash
  # framework.md's rewritten link target exists:
  test -f .claude/rules/common/skill-routing-sync.md && echo "OK skill-routing-sync"
  # the two staying files' rewritten targets exist:
  test -f .claude/rules/domains/framework.md && echo "OK framework target"
  # glossary's depth-invariant links still resolve from the new location:
  test -f .claude/rules/domains/../../../CLAUDE.md && echo "OK root CLAUDE"
  test -f .claude/rules/domains/../../lessons-learned.md && echo "OK lessons"
  # expect: all four OK lines
  ```

- [ ] **10. Commit.**

  ```bash
  git add -A
  git commit -m "refactor(rules): relocate domain rules to rules/domains/"
  ```

  (Per the git boundary, the human runs the commit — propose this message; do not commit autonomously.)

## Task 2: Complete the relocate — the 4 concept references the first pass missed

**Files:** root `CLAUDE.md` (lines 19, 51), `skills/foundation/bootstrapping-domain-rules/SKILL.md` (line 13), `bootstrapping-claude-md/references/root-claude-md-template.md` (line 75).
**Interfaces:** Consumes Task 1's `rules/domains/` layout. Produces a fully-consistent taught convention.

- [ ] **1. RED — broad bare-token grep shows the misses.**

  ```bash
  grep -rn "rules/common/" --include="*.md" --include="*.sh" skills/ CLAUDE.md .claude/CLAUDE.md hooks/ .claude/rules/ \
    | grep -vE "phase-task-visualization|skill-routing-sync|git-conventions|markdown-style|agnostic-skill-authoring|scoping-skill-value|dogfood-generator-sync" \
    | grep -vE "audit-report-example\.md.*\| path"
  # expect (RED): 4 hits — bootstrapping-domain-rules:13, CLAUDE.md:19, CLAUDE.md:51, root-claude-md-template:75
  ```

- [ ] **2. Edit `bootstrapping-domain-rules/SKILL.md` line 13** (taught convention):

  ```text
  old:  Create the two foundational, always-on rules every other rule hangs off, by default under `.claude/rules/common/`:
  new:  Create the two foundational, always-on rules every other rule hangs off, by default under `.claude/rules/domains/`:
  ```

- [ ] **3. Edit root `CLAUDE.md` line 19** (prose):

  ```text
  old:  …(gates + logging), `.claude/rules/common/` (framework + domain glossary), `.claude/skills-routing.json`, `.claude/state/`.
  new:  …(gates + logging), `.claude/rules/domains/` (framework + domain glossary) and `.claude/rules/common/` (cross-cutting rules), `.claude/skills-routing.json`, `.claude/state/`.
  ```

- [ ] **4. Edit root `CLAUDE.md` line 51** — split the "Where rules live" row into two:

  ```text
  old:  | Cross-cutting process & policy (framework, domain glossary) | [.claude/rules/common/](./.claude/rules/common/) |
  new:  | Domain rules (glossary, framework charter) | [.claude/rules/domains/](./.claude/rules/domains/) |
        | Cross-cutting process & policy (code style, routing-sync, file org, …) | [.claude/rules/common/](./.claude/rules/common/) |
  ```

- [ ] **5. Edit `root-claude-md-template.md` line 75** — split likewise (agnostic GENERATOR; dogfood-generator-sync twin of step 4):

  ```text
  old:  | Cross-cutting process & policy (framework, code style, file org, security, error handling, domain glossary) | [.claude/rules/common/](./.claude/rules/common/) |
  new:  | Domain rules (glossary, framework charter) | [.claude/rules/domains/](./.claude/rules/domains/) |
        | Cross-cutting process & policy (code style, file org, security, error handling) | [.claude/rules/common/](./.claude/rules/common/) |
  ```

- [ ] **6. GREEN — same broad grep returns empty.** (the command from step 1 → no output)

## Task 3: Rename the glossary file `domains-glossary.md` → `glossary.md`

**Files:** the file itself + 6 references (framework.md:3, `.claude/CLAUDE.md:115`, `CLAUDE.md:59`, `skill-gate.sh:26,99`, `audit-report-example.md:6`).
**Interfaces:** Produces `.claude/rules/domains/glossary.md`.

- [ ] **1. RED:** `ls .claude/rules/domains/glossary.md 2>&1` → No such file.
- [ ] **2. Move:** `git mv .claude/rules/domains/domains-glossary.md .claude/rules/domains/glossary.md`
- [ ] **3. Edit the 6 references** (`domains-glossary` → `glossary`):
  - `.claude/rules/domains/framework.md:3`: `[domains-glossary.md](./domains-glossary.md)` → `[glossary.md](./glossary.md)`
  - `.claude/CLAUDE.md:115`: `[rules/domains/domains-glossary.md](./rules/domains/domains-glossary.md)` → `…/glossary.md`
  - `CLAUDE.md:59`: `[.claude/rules/domains/domains-glossary.md](…)` → `…/glossary.md`
  - `hooks/routing/skill-gate.sh:26`: `(e.g. domains-glossary.md)` → `(e.g. glossary.md)`
  - `hooks/routing/skill-gate.sh:99`: `domains-glossary.md carry no skill body` → `glossary.md carry no skill body`
  - `auditing-domain-rules/references/audit-report-example.md:6`: `# Domain-Rules Audit — domains-glossary.md` → `— glossary.md`
- [ ] **4. GREEN:**

  ```bash
  ls .claude/rules/domains/glossary.md   # exists
  grep -rn "domains-glossary" --include="*.md" --include="*.sh" skills/ CLAUDE.md .claude/CLAUDE.md hooks/ .claude/rules/   # expect: no output
  ```

## Task 4: Rename skills `*-domain-rules` → `*-glossary`

**Files:** two skill dirs + symlinks + routing JSON + ~14 name references (see spec §6).
**Interfaces:** Produces routable skills `bootstrapping-glossary`, `auditing-glossary` (key === dir === `name:` === symlink).

- [ ] **1. RED:** `grep -rln "domain-rules" --include="*.md" --include="*.json" .claude/skills-routing.json skills/ CLAUDE.md` → many hits; `ls .claude/skills/ | grep glossary` → none.
- [ ] **2. Move dirs (history-preserving), recreate symlinks:**

  ```bash
  git mv skills/foundation/bootstrapping-domain-rules skills/foundation/bootstrapping-glossary
  git mv skills/foundation/auditing-domain-rules      skills/foundation/auditing-glossary
  rm .claude/skills/bootstrapping-domain-rules .claude/skills/auditing-domain-rules
  ln -s ../../skills/foundation/bootstrapping-glossary .claude/skills/bootstrapping-glossary
  ln -s ../../skills/foundation/auditing-glossary      .claude/skills/auditing-glossary
  ```

- [ ] **3. Edit `name:` + H1** in each moved `SKILL.md` (at the NEW path):
  - `bootstrapping-glossary/SKILL.md`: `name: bootstrapping-domain-rules`→`name: bootstrapping-glossary`; `# Bootstrapping Domain Rules`→`# Bootstrapping Glossary`
  - `auditing-glossary/SKILL.md`: `name: auditing-domain-rules`→`name: auditing-glossary`; `# Auditing Domain Rules`→`# Auditing Glossary`
- [ ] **4. Edit `skills-routing.json`** — rename keys `bootstrapping-domain-rules`/`auditing-domain-rules` → `*-glossary`, and `files` paths → `.claude/skills/bootstrapping-glossary/SKILL.md` / `.claude/skills/auditing-glossary/SKILL.md`.
- [ ] **5. Edit the name references** (`bootstrapping-domain-rules`→`bootstrapping-glossary`, `auditing-domain-rules`→`auditing-glossary`), at post-rename paths:
  - root `CLAUDE.md`:40, :53
  - `.claude/rules/domains/glossary.md`:19 (`auditing-domain-rules`)
  - `skills/design/improve-codebase-architecture/SKILL.md`:63, :64
  - `bootstrapping-glossary/SKILL.md`:30 (`auditing-domain-rules`); `bootstrapping-glossary/references/domain-glossary-template.md`:57
  - `auditing-glossary/SKILL.md`:17, :27 (`bootstrapping-domain-rules`)
  - `bootstrapping-claude-md/SKILL.md`:20, :30; `bootstrapping-claude-md/references/intake-questions.md`:19
  - `auditing-claude-md/SKILL.md`:17, :27
  - `writing-rules/SKILL.md`:28
- [ ] **6. GREEN:**

  ```bash
  grep -rn "domain-rules" --include="*.md" --include="*.json" --include="*.sh" skills/ CLAUDE.md .claude/CLAUDE.md hooks/ .claude/skills-routing.json   # expect: no output
  find skills/foundation -maxdepth 1 -name "*-glossary" -type d   # bootstrapping-glossary, auditing-glossary
  for s in bootstrapping-glossary auditing-glossary; do test -L .claude/skills/$s && readlink .claude/skills/$s; grep -q "^name: $s$" skills/foundation/$s/SKILL.md && echo "OK name $s"; done
  jq -e '.skills["bootstrapping-glossary"] and .skills["auditing-glossary"]' .claude/skills-routing.json && jq . .claude/skills-routing.json >/dev/null && echo "routing OK"
  ```

## Verification (whole-plan)

- `ls -1 .claude/rules/domains/` → exactly `domains-glossary.md`, `framework.md`; `.claude/rules/common/` no longer lists either.
- Step 8 grep empty over the live tree (`docs/` excluded by design).
- Step 9 prints all four `OK` lines.
- GREEN subagent: a fresh agent told "open the framework charter / domain glossary for this repo" follows `.claude/CLAUDE.md` Pointers to `.claude/rules/domains/` with no broken-link detour. (This is also re-checked in phase 7, `spec-drift-audit`.)
