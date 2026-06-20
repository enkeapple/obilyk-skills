# writing-skills authoring skill

## Goal

Create a new vault skill `writing-skills` at `skills/authoring/writing-skills/` that synthesizes the leading-words vocabulary of the root `~/.claude/skills/writing-great-skills` with the TDD-for-skills process of obra/superpowers `writing-skills`. It is an active, user-invoked skill with two authoring branches (`create`, `edit`) converging on one self-contained `validate` gate, and it replaces the now-defunct `writing-great-skills` skill the vault still references.

## Scope

- New skill dir `skills/authoring/writing-skills/` with `SKILL.md` + `references/`.
- `SKILL.md` body: mode-classification step → `create` branch → `edit` branch → shared `validate` gate; discipline content inline (Iron Law, rationalization table, red flags, "Match the Form to the Failure").
- Five reference files (below) + a persisted `references/test-cases.md` contract.
- `validate` gate = subagent-driven test-case run, self-contained (no dependency on `hooks/quality/quality.sh`), with a cheap static pre-flight whose checks are defined inside the skill folder.
- The skill teaches and validates the optional `allowed-tools` and `model` frontmatter fields in authored skills; it declares `allowed-tools` on itself.
- Flat symlink: create `.claude/skills/writing-skills`; delete stale `.claude/skills/writing-great-skills`.
- Reconciliation: repoint all 14 `writing-great-skills` references across 7 files to `writing-skills`.

## Out of scope

- A `scripts/` runner (`scripts/validate.sh`) — cut; one validation path (subagent + checklist).
- A `skills-routing.json` entry / triggers — `disable-model-invocation: true` skills are correctly unrouted.
- Changing any other skill's behavior beyond the name-reference repoint.
- Porting superpowers' `render-graphs.js`, `graphviz-conventions.dot`, `persuasion-principles.md` verbatim — vocabulary and method are adapted, not copied (agnostic bar).
- Removing/altering the advisory `hooks/quality/quality.sh` hook — it keeps firing independently; the skill simply does not depend on it.
- Editing the root `~/.claude/skills/writing-great-skills` — it stays as an external reference.

## Contracts

### Frontmatter of the new skill (`skills/authoring/writing-skills/SKILL.md`)

```yaml
---
name: writing-skills
description: <human-facing one line; disable-model-invocation makes this human-only — no trigger list>
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Task, Skill
---
```

- `disable-model-invocation: true` ⇒ NO `skills-routing.json` key, NO triggers, `name === dir === symlink name`.

### Authoritative SKILL.md frontmatter field set (verified vs Claude Code docs) — input for `frontmatter-reference.md` + the validator

```text
name, description, when_to_use, argument-hint, arguments, disable-model-invocation,
user-invocable, allowed-tools, disallowed-tools, model, effort, context, agent, hooks,
paths, shell
```

- `allowed-tools` — VERIFIED. Space/comma string or YAML list. Auto-grants the listed tools (does NOT restrict the rest).
- `model` — VERIFIED. Value: full model ID | alias (`opus`/`sonnet`/`haiku`) | `inherit`. Overrides session model while the skill is active.

### `validate` gate contract (two layers, self-contained)

```text
Layer 1 — static pre-flight (defined in references/validation-checklist.md; runs first, fails fast):
  frontmatter <=1024 bytes; name matches ^[a-z0-9-]+$; name == dir == symlink name;
  code fences balanced; every references/*.md link resolves; word count sane;
  allowed-tools/model (and any frontmatter key) is in the authoritative field set above
  and well-formed; routing invariant: disable-model-invocation ⇒ absent from
  skills-routing.json, else present.

Layer 2 — subagent test-case run (the real gate; references/validation-subagent-prompt.md):
  INPUT  = path to target skill + its test cases.
  test cases SOURCE (Decision 7):
    - if <skill>/references/test-cases.md exists -> load and run it;
    - else (foreign skill) -> subagent SYNTHESIZES cases from the skill's contract
      (description + completion criteria + rationalization table) and marks them `synthesized`.
  BEHAVIOR = run each case WITH the skill enabled; confirm GREEN (intended behavior) +
             requirement compliance vs the skill's stated contract.
  OUTPUT = pass/fail per case with VERBATIM evidence of what the agent did; overall verdict.
```

### `references/test-cases.md` (persisted artifact written by create/edit)

```text
One block per pressure scenario / test case:
  - id / title
  - setup: the realistic context + the task that tempts the failure
  - baseline expectation (RED): what a cold agent does WITHOUT the skill
  - with-skill expectation (GREEN): the compliant behavior
  - which Review-Checklist / contract item it exercises
```

## Files touched

| File | Change | Why |
| --- | --- | --- |
| `skills/authoring/writing-skills/SKILL.md` | NEW | process spine + inline discipline |
| `skills/authoring/writing-skills/references/vocabulary.md` | NEW | leading-words glossary (from root writing-great-skills) |
| `skills/authoring/writing-skills/references/testing-with-subagents.md` | NEW | RED/GREEN pressure-scenario + micro-test method (from superpowers) |
| `skills/authoring/writing-skills/references/frontmatter-reference.md` | NEW | full field set incl. allowed-tools/model, formats + trade-offs |
| `skills/authoring/writing-skills/references/validation-subagent-prompt.md` | NEW | dispatched validation-subagent prompt (Layer 2) |
| `skills/authoring/writing-skills/references/validation-checklist.md` | NEW | Layer-1 static checks, defined inside the skill |
| `skills/authoring/writing-skills/references/test-cases.md` | NEW | this skill's own persisted test cases |
| `.claude/skills/writing-skills` | NEW (symlink → `../../skills/authoring/writing-skills`) | discovery |
| `.claude/skills/writing-great-skills` | DELETE (stale broken symlink) | name no longer exists |
| `.claude/CLAUDE.md` | EDIT | 3 refs → `writing-skills` |
| `CLAUDE.md` | EDIT | 2 refs → `writing-skills` |
| `.claude/rules/domains/glossary.md` | EDIT | 3 refs → `writing-skills` |
| `.claude/rules/domains/framework.md` | EDIT | 1 ref → `writing-skills` |
| `.claude/rules/common/scoping-skill-value.md` | EDIT | 3 refs → `writing-skills` |
| `.claude/rules/common/agnostic-skill-authoring.md` | EDIT | 1 ref → `writing-skills` |
| `.claude/rules/common/skill-routing-sync.md` | EDIT | 1 ref → `writing-skills` |

Reconciliation total: 14 occurrences across 7 doc files (verified by `grep -rIc 'writing-great-skills'`). Each edit must re-read the surrounding claim: refs that called it a "reference/methodology, non-routed" skill stay true (writing-skills is also `disable-model-invocation`); a ref implying "pure reference, no steps" must be reworded since writing-skills is now active.

## Edge cases

- **Empty / new skill (create):** target dir does not exist → `create` branch; RED must be observed before any file is written (Iron Law).
- **Foreign skill, no test-cases.md (standalone validate):** Layer 2 synthesizes cases and marks them `synthesized`; verdict notes lower confidence.
- **Skill under validation is itself `disable-model-invocation`:** Layer-1 routing invariant expects ABSENCE from routing — not a failure.
- **A repoint ref describes the old skill as a pure reference:** reword, don't blind-replace (claim drift).
- **`allowed-tools`/`model` absent in an authored skill:** legal (both optional) — pre-flight only validates them WHEN present.
- **`validate` run yields a fail:** gate returns fail with verbatim evidence; create/edit loops back (REFACTOR), never ships on a fail.
- **Symlink: `ln -sf` onto the old name:** forbidden — must delete `writing-great-skills` symlink and create `writing-skills` (invariant `name === dir === symlink`).

## Verification

- **Static pre-flight** on the new skill: `bash hooks/quality/quality.sh`-equivalent checks (the skill's own Layer-1 set) — frontmatter ≤1024, `name` regex, `name == dir`, fences balanced, refs resolve. Run the vault's `quality.sh` too as an independent cross-check (it fires on the SKILL.md edit anyway).
- **RED → GREEN** (Iron Law): a cold subagent fails the authoring pressure scenarios WITHOUT the skill; complies WITH it. Paste verbatim both runs.
- **Reconciliation proof:** `grep -rIc 'writing-great-skills' .claude/ CLAUDE.md skills/` returns 0; `test -L .claude/skills/writing-skills && ! test -e .claude/skills/writing-great-skills`.
- **Dogfood (Decision 13):** invoke `/writing-skills` in `validate` standalone mode ON `skills/authoring/writing-skills/` itself (runs its own `references/test-cases.md` through Layer 1 + Layer 2). Then cross-check the result against the root `/writing-great-skills` reference (vocabulary/discipline coherence). Both must agree the skill is sound.
- **Chain coherence:** every `references/*.md` link resolves; hand-offs to/from neighbor authoring skills (`writing-lessons`, `writing-rules`) named consistently.

## Risks

- **Self-validation circularity** — the skill validates itself via its own gate; a bug in the gate hides itself. Mitigation: the root `/writing-great-skills` cross-check (Decision 13) is an independent second opinion; the cold RED/GREEN runs use fresh subagents, not the skill's own logic.
- **Reconciliation claim drift** — blind find/replace of 14 refs could leave a sentence calling an active skill a "pure reference". Mitigation: re-read each occurrence's surrounding claim (edge case above), not a global sed.
- **Agnostic leak** — the skill lives in the vault but must read the same in any repo; the self-contained validate gate must not hardcode vault paths/commands. Mitigation: parameterize per `agnostic-skill-authoring.md`; reconciliation edits to CLAUDE.md/rules are vault-internal harness (exempt).
- **superpowers reference files not yet fetched** — `testing-skills-with-subagents.md` etc. were listed, not read. Mitigation: fetch them during implementation before writing `testing-with-subagents.md`; adapt (don't copy) to stay agnostic.
- **Sprawl** — combining two skills risks an over-long SKILL.md. Mitigation: discipline inline, everything else behind reference pointers (progressive disclosure); keep SKILL.md within the vault's word-count norm.
