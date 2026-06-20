# writing-skills authoring skill — Implementation Plan

**Goal:** Build the new vault skill `writing-skills` (active, user-invoked; create/edit branches + a self-contained subagent-driven validate gate) and reconcile the defunct `writing-great-skills` references.
**Architecture:** A process-spine `SKILL.md` with inline discipline, six `references/*.md` files (vocabulary, testing method, frontmatter spec, validation checklist, validation-subagent prompt, persisted test-cases). Validation is a two-layer gate fully inside the skill folder — no `hooks/` dependency. Verification = structural validators + RED/GREEN subagent runs (NO build/unit-test pipeline).
**Tech stack:** Markdown skill files under `skills/authoring/writing-skills/**`; flat symlink under `.claude/skills/`; validators = grep/structural checks + subagent pressure runs.

## Global constraints

- Spec: `docs/specs/2026-06-21-writing-skills-authoring-skill.md` — contracts copied verbatim below; do not re-derive.
- AUTHOR mode, Iron Law: the SKILL.md task (Task 7) is gated by a real RED subagent run captured in Task 1; no skill body written before RED is observed.
- Agnostic-by-default (`agnostic-skill-authoring`): the skill body and its references name no vault path/command as normative; reconciliation edits to `CLAUDE.md`/rules are vault-internal harness (exempt).
- `disable-model-invocation: true` ⇒ NO `skills-routing.json` key, NO triggers; invariant `name === dir === symlink name`.
- No git ops beyond the per-task commit *proposal*; the human runs commits. No edits to `.claude/hooks/**` or `settings.json`.
- Reconciliation is per-occurrence with a re-read of the surrounding claim — never a blind global `sed`.
- `skills/authoring/writing-skills/` already exists as an empty dir on disk; Task 1's first write populates it (the `test ! -f` RED checks still hold). The in-vault `writing-great-skills` symlink is already broken (target gone) — only the root `~/.claude/skills/writing-great-skills` resolves.
- **Discipline-RED contamination (`scoping-skill-value`):** a subagent dispatched inside this vault inherits the operating manual (Iron Law, read-before-assert), so a discipline-RED run may "comply" by obeying the inherited manual, not by lacking the skill — a false no-failure. Every discipline-RED in this plan (Task 1's create/edit/validate scenarios) must run with the operating manual suppressed (a controlled system prompt or a real consumer repo), or aim at a failure the manual does not already prevent. Shaping/output-shape checks stay measurable in-vault.

---

## Task 1: RED baseline + author `references/test-cases.md`

**Files:**
- Create: `skills/authoring/writing-skills/references/test-cases.md`

**Interfaces:**
- Consumes: nothing (first task).
- Produces: the persisted test-case set (ids, setup, RED/GREEN expectations) that Task 7 GREEN must satisfy and that the validate gate (Task 6) loads.

- [ ] **Step 1: RED — run baseline pressure scenarios WITHOUT the skill.** Dispatch three cold `general-purpose` subagents, no `writing-skills` in context. **Suppress the inherited operating manual** (controlled system prompt or a real consumer repo) per the Global-constraints contamination note — otherwise the create/edit discipline scenarios may falsely "comply" by obeying the vault's Iron Law rather than the absent skill:
  - `create`: "Author a new discipline skill for X" — expect: writes skill before any failing test (Iron Law violation), no rationalization table.
  - `edit`: "Add a section to skill Y" — expect: edits without a failing test first.
  - `validate`: "Is skill Z any good?" — expect: eyeballs it, no subagent test run, declares done on static read.
  Record verbatim failures.
- [ ] **Step 2: Confirm RED.** Each subagent exhibited the failure (skill-before-test / static-only validation). If any complied cold, note it — that scenario is a no-op and must be re-aimed (`scoping-skill-value`).
```bash
test ! -f skills/authoring/writing-skills/references/test-cases.md && echo "RED: test-cases absent"
```
Expected: prints `RED: test-cases absent`.
- [ ] **Step 3: Write `references/test-cases.md`** per the spec Contracts (`test-cases.md` block): one block per scenario with `id/title`, `setup`, `baseline expectation (RED)` from Step 1 verbatim, `with-skill expectation (GREEN)`, and the Review-Checklist/contract item it exercises. Cover create, edit, and validate.
- [ ] **Step 4: Validate structure** — fences balanced, each block has all five fields.
```bash
grep -c '^### ' skills/authoring/writing-skills/references/test-cases.md   # >=3 scenarios
```
- [ ] **Step 5: Commit (proposal).** `git add skills/authoring/writing-skills/references/test-cases.md && git commit -m "feat(writing-skills): capture RED baseline test cases"`

---

## Task 2: `references/vocabulary.md` (leading-words glossary)

**Files:**
- Create: `skills/authoring/writing-skills/references/vocabulary.md`

**Interfaces:**
- Consumes: nothing.
- Produces: definitions for the leading words SKILL.md uses (predictability, information hierarchy, progressive disclosure, leading word, completion criterion, premature completion, no-op, sediment, sprawl, co-location, granularity, branch, context pointer).

- [ ] **Step 1: RED — file absent.**
```bash
test ! -f skills/authoring/writing-skills/references/vocabulary.md && echo "RED: vocabulary absent"
```
- [ ] **Step 2: Write `vocabulary.md`** — port the term set from the root `~/.claude/skills/writing-great-skills/SKILL.md` (read this session), adapted to bold-term + one-paragraph definition form. Agnostic: no vault paths in definitions.
- [ ] **Step 3: Validate** — every bold term SKILL.md will reference exists here.
```bash
grep -ciE 'predictability|progressive disclosure|leading word|premature completion|no-op|sediment|sprawl|co-location|granularity' skills/authoring/writing-skills/references/vocabulary.md
```
Expected: ≥ 9.
- [ ] **Step 4: Commit (proposal).** `git commit -m "feat(writing-skills): add leading-words vocabulary reference"`

---

## Task 3: `references/frontmatter-reference.md` (field set + allowed-tools/model)

**Files:**
- Create: `skills/authoring/writing-skills/references/frontmatter-reference.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the authoritative frontmatter field list + per-field format/trade-off — consumed by Task 5 (checklist) and the create/edit branches.

- [ ] **Step 1: RED — file absent.**
```bash
test ! -f skills/authoring/writing-skills/references/frontmatter-reference.md && echo "RED: frontmatter-ref absent"
```
- [ ] **Step 2: Write the file** with the verified field set (from the spec Contracts) and explicit notes for the two new fields:
```text
Fields: name, description, when_to_use, argument-hint, arguments, disable-model-invocation,
user-invocable, allowed-tools, disallowed-tools, model, effort, context, agent, hooks, paths, shell
- allowed-tools: space/comma string OR YAML list. AUTO-GRANTS listed tools; does not restrict the rest.
- model: full model ID | alias (opus/sonnet/haiku) | inherit. Overrides session model while active.
```
Include the create/edit "offer these optional fields with trade-offs" guidance (context-load vs control).
- [ ] **Step 3: Validate** — both new fields documented with format + semantics.
```bash
grep -c -E 'allowed-tools|model' skills/authoring/writing-skills/references/frontmatter-reference.md
```
Expected: ≥ 2.
- [ ] **Step 4: Commit (proposal).** `git commit -m "feat(writing-skills): add frontmatter field reference"`

---

## Task 4: `references/testing-with-subagents.md` (RED/GREEN method)

**Files:**
- Create: `skills/authoring/writing-skills/references/testing-with-subagents.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the pressure-scenario + micro-test methodology SKILL.md and the validate gate reference.

- [ ] **Step 1: Fetch sources.** `WebFetch` the superpowers reference files (`testing-skills-with-subagents.md`, and skim `anthropic-best-practices.md`) at `https://raw.githubusercontent.com/obra/superpowers/main/skills/writing-skills/<file>`. These are evidence for the *shape*, not to copy verbatim.
- [ ] **Step 2: RED — file absent.**
```bash
test ! -f skills/authoring/writing-skills/references/testing-with-subagents.md && echo "RED: testing-ref absent"
```
- [ ] **Step 3: Write the file** — adapt (agnostic) the pressure-types (time/sunk-cost/authority/exhaustion), the no-guidance control requirement, 5+ reps, read-every-match, micro-test-before-full-scenario. Note the `scoping-skill-value` caveat: an in-vault subagent inherits the operating manual, so a true discipline baseline needs a clean environment.
- [ ] **Step 4: Validate** — covers control + reps + pressure types.
```bash
grep -ciE 'control|reps|pressure|baseline' skills/authoring/writing-skills/references/testing-with-subagents.md
```
Expected: ≥ 4.
- [ ] **Step 5: Commit (proposal).** `git commit -m "feat(writing-skills): add subagent testing methodology reference"`

---

## Task 5: `references/validation-checklist.md` (Layer-1 static checks)

**Files:**
- Create: `skills/authoring/writing-skills/references/validation-checklist.md`

**Interfaces:**
- Consumes: the field set from Task 3.
- Produces: the Layer-1 check list the pre-flight and the validation subagent both apply.

- [ ] **Step 1: RED — file absent.**
```bash
test ! -f skills/authoring/writing-skills/references/validation-checklist.md && echo "RED: checklist absent"
```
- [ ] **Step 2: Write the checklist** (spec Contracts, Layer 1) with a CONCRETE word-count threshold (reviewer rec #3): frontmatter ≤ 1024 bytes; `name` matches `^[a-z0-9-]+$`; `name == dir == symlink name`; fences balanced; every `references/*.md` link resolves; **SKILL.md body ≤ 500 words for a frequently-loaded skill, ≤ ~1500 words otherwise — warn past the bound, not a hard fail**; every frontmatter key ∈ the Task-3 field set and well-formed; routing invariant (`disable-model-invocation` ⇒ absent from `skills-routing.json`, else present).
- [ ] **Step 3: Validate** — the word-count bound is a concrete number, not "sane".
```bash
grep -E '500|1500|word' skills/authoring/writing-skills/references/validation-checklist.md
```
- [ ] **Step 4: Commit (proposal).** `git commit -m "feat(writing-skills): add layer-1 validation checklist"`

---

## Task 6: `references/validation-subagent-prompt.md` (Layer-2 gate)

**Files:**
- Create: `skills/authoring/writing-skills/references/validation-subagent-prompt.md`

**Interfaces:**
- Consumes: `test-cases.md` contract (Task 1), `validation-checklist.md` (Task 5).
- Produces: the dispatched-subagent prompt — input/behavior/output contract for the dynamic gate.

- [ ] **Step 1: RED — file absent.**
```bash
test ! -f skills/authoring/writing-skills/references/validation-subagent-prompt.md && echo "RED: validate-prompt absent"
```
- [ ] **Step 2: Write the prompt** matching the vault `*-reviewer-prompt.md` pattern and the spec's Layer-2 contract: INPUT = target skill path + test cases; SOURCE rule (load `references/test-cases.md` if present, else SYNTHESIZE from the skill's contract and mark `synthesized`); BEHAVIOR = run each case WITH the skill, confirm GREEN + requirement compliance; OUTPUT = per-case pass/fail with VERBATIM evidence + overall verdict.
- [ ] **Step 3: Validate** — contains the synthesize-fallback and verbatim-evidence requirements.
```bash
grep -ciE 'synthesi|verbatim|pass/fail|test case' skills/authoring/writing-skills/references/validation-subagent-prompt.md
```
Expected: ≥ 3.
- [ ] **Step 4: Commit (proposal).** `git commit -m "feat(writing-skills): add validation-subagent prompt"`

---

## Task 7: `SKILL.md` — process spine + inline discipline (the GREEN gate)

**Files:**
- Create: `skills/authoring/writing-skills/SKILL.md`

**Interfaces:**
- Consumes: all six references (Tasks 1–6).
- Produces: the skill itself; the GREEN proof for Task 1's scenarios.

- [ ] **Step 1: RED confirmed (from Task 1).** The three baseline scenarios already failed without the skill — do not write the body before re-reading those recorded failures.
- [ ] **Step 2: Write the frontmatter** verbatim from the spec Contracts:
```yaml
---
name: writing-skills
description: <human-facing one line — no trigger list>
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Task, Skill
---
```
- [ ] **Step 3: Write the body** — mode-classification step 0 (create/edit/validate) → create branch (RED→form→GREEN→offer allowed-tools/model→REFACTOR→validate) → edit branch (Iron Law on edits, diff-scoped RED/GREEN→validate) → shared validate gate (pre-flight then dispatch the Task-6 subagent). Inline discipline: Iron Law, rationalization table, Red Flags, "Match the Form to the Failure". Link each reference via a context pointer; bold terms defined in `vocabulary.md`.
- [ ] **Step 4: GREEN — re-run Task 1's three scenarios WITH the skill.** Dispatch three fresh subagents with the skill in context; confirm each now complies (test-first observed, dynamic validation invoked). Paste verbatim compliance.
- [ ] **Step 5: Validate structure.**
```bash
nm=$(grep -m1 '^name:' skills/authoring/writing-skills/SKILL.md | sed 's/name:[[:space:]]*//'); \
[ "$nm" = "writing-skills" ] && echo "name ok"; \
for f in vocabulary testing-with-subagents frontmatter-reference validation-subagent-prompt validation-checklist test-cases; do \
  test -f skills/authoring/writing-skills/references/$f.md || echo "MISSING ref: $f"; done
```
Expected: `name ok`, no MISSING lines.
- [ ] **Step 6: Commit (proposal).** `git commit -m "feat(writing-skills): add SKILL.md spine + inline discipline"`

---

## Task 8: Flat symlink — create new, delete stale

**Files:**
- Create symlink: `.claude/skills/writing-skills` → `../../skills/authoring/writing-skills`
- Delete symlink: `.claude/skills/writing-great-skills`

**Interfaces:**
- Consumes: the skill dir (Task 7).
- Produces: discoverability + the `name === dir === symlink` invariant.

- [ ] **Step 1: RED — new symlink absent, stale present.**
```bash
test ! -e .claude/skills/writing-skills && echo "RED: new symlink missing"; \
test -L .claude/skills/writing-great-skills && echo "RED: stale symlink present"
```
- [ ] **Step 2: Create + delete.**
```bash
ln -s ../../skills/authoring/writing-skills .claude/skills/writing-skills && \
rm .claude/skills/writing-great-skills
```
- [ ] **Step 3: GREEN — invariant holds.**
```bash
test -e .claude/skills/writing-skills && echo "resolves ok"; \
test ! -e .claude/skills/writing-great-skills && echo "stale gone"
```
Expected: `resolves ok`, `stale gone`.
- [ ] **Step 4: Commit (proposal).** `git commit -m "chore(writing-skills): add symlink, drop stale writing-great-skills link"`

---

## Task 9: Reconcile 14 `writing-great-skills` references across 7 files

**Files (EDIT):** `.claude/CLAUDE.md` (3), `CLAUDE.md` (2), `.claude/rules/domains/glossary.md` (3), `.claude/rules/domains/framework.md` (1), `.claude/rules/common/scoping-skill-value.md` (3), `.claude/rules/common/agnostic-skill-authoring.md` (1), `.claude/rules/common/skill-routing-sync.md` (1).

**Interfaces:**
- Consumes: the now-real `writing-skills` skill.
- Produces: zero dangling `writing-great-skills` references; claims that called it a "pure reference" reworded to "active authoring skill".

- [ ] **Step 1: RED — count the stale refs.**
```bash
grep -rIc 'writing-great-skills' .claude/ CLAUDE.md skills/ | grep -v ':0$'
```
Expected: the 7 files, 14 total.
- [ ] **Step 2: Edit each occurrence**, re-reading its sentence. Name-only swap where the claim still holds (non-routed, disable-model-invocation); reword where it implied "pure reference / no steps" (e.g. glossary "reference skills (methodology, no triggers) … e.g. writing-great-skills" → keep writing-skills as a `disable-model-invocation` skill but note it is now active create/edit/validate, not pure reference).
- [ ] **Step 3: GREEN — zero stale refs.**
```bash
grep -rIc 'writing-great-skills' .claude/ CLAUDE.md skills/ | grep -v ':0$' || echo "GREEN: no stale refs"
```
Expected: `GREEN: no stale refs`.
- [ ] **Step 4: Commit (proposal).** `git commit -m "docs(rules): repoint writing-great-skills references to writing-skills"`

---

## Task 10: Dogfood validation (Decision 13)

**Files:** none (verification only).

**Interfaces:**
- Consumes: the complete skill + all references + symlink.
- Produces: the GREEN dogfood verdict that closes the build.

- [ ] **Step 1: Run the skill's own validate gate on itself.** Invoke `/writing-skills` in standalone `validate` mode targeting `skills/authoring/writing-skills/` — Layer 1 (static pre-flight) then Layer 2 (dispatch the validation subagent on its own `references/test-cases.md`, NOT the synthesis fallback). Paste the per-case pass/fail + verdict.
- [ ] **Step 2: Cross-check against the root reference.** Invoke `/writing-great-skills` (root) and confirm the new skill's vocabulary/discipline is coherent with it (independent second opinion; mitigates the self-validation circularity risk).
- [ ] **Step 3: Full structural validators + reconciliation proof.**
```bash
grep -rIc 'writing-great-skills' .claude/ CLAUDE.md skills/ | grep -v ':0$' || echo "0 stale"; \
test -e .claude/skills/writing-skills && ! test -e .claude/skills/writing-great-skills && echo "symlinks ok"
```
Expected: `0 stale`, `symlinks ok`.
- [ ] **Step 4: Verdict.** The build is done only when Layer 1 + Layer 2 pass, the root cross-check agrees, and the reconciliation/symlink proofs are clean. Hand to `spec-drift-audit`.
