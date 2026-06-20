---
name: writing-skills
description: Test-first methodology for authoring, editing, and validating skills (RED→GREEN). User-invoked.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Task, Skill
---

# Writing Skills

A skill exists to wrangle determinism out of a stochastic system. **Predictability** — the agent
taking the same *process* every run — is the root virtue. This skill builds and changes skills
**test-first**: you watch an agent fail without the skill, then comply with it. **Bold terms** are
defined in [`vocabulary.md`](./references/vocabulary.md).

## The Iron Law

**No skill, and no skill edit, without a failing test first.** The "test" is a subagent pressure
run, not a unit test (see [`testing-with-subagents.md`](./references/testing-with-subagents.md)): run
the scenario WITHOUT the skill and watch it fail (**RED**) before you write. Wrote it first? Delete
it. Start over. No exception for "simple additions", "just a section", or "it's only docs" —
**editing a skill doc IS editing code.** Violating the letter is violating the spirit.

## Step 0 — classify the mode

- **create** — the skill does not exist on disk yet → write it test-first.
- **edit** — the skill exists; you are changing it → the Iron Law applies to the change.
- **validate** — you only want to check an existing skill → go straight to the gate.

## create

1. **RED.** Run the baseline pressure scenario(s) WITHOUT the skill; record the agent's
   rationalizations verbatim. Suppress any injected operating manual for a *discipline* skill, or
   the baseline is contaminated and "complies" for the wrong reason. No failure reproduces → there
   is nothing to fix; stop.
2. **Match the form to the failure** (table below) before writing.
3. **GREEN.** Write the minimal skill addressing those exact failures — in the form the failure
   calls for. Re-run the scenarios WITH the skill; confirm compliance.
4. **Offer the optional levers.** Decide whether the skill wants `allowed-tools` or `model`
   ([`frontmatter-reference.md`](./references/frontmatter-reference.md)) — offer them with their
   trade-offs; do not bake them in by reflex.
5. **REFACTOR.** Close each new loophole the agent invents (rationalization-table row + red flag).
6. **validate** (the gate).

## edit

The Iron Law holds for edits. Establish a diff-scoped **RED** on the behaviour you are changing
(a scenario the current skill fails or under-specifies), make the minimal change, re-run for
**GREEN**, then run the gate. Do not edit the markdown and call it done.

## validate (the gate — self-contained, runs after create/edit and standalone)

Two layers, both defined inside this skill — no dependency on any repo hook:

1. **Layer 1 — static pre-flight.** Run the checks in
   [`validation-checklist.md`](./references/validation-checklist.md): frontmatter size, `name`
   regex, `name === dir === symlink`, balanced fences, links resolve, legal frontmatter keys,
   routing invariant, word count. Fail fast here before spending a subagent.
2. **Layer 2 — dynamic run.** Dispatch the validation subagent
   ([`validation-subagent-prompt.md`](./references/validation-subagent-prompt.md)) to RUN the
   skill's test cases (from [`test-cases.md`](./references/test-cases.md), or synthesized for a
   foreign skill) WITH the skill enabled, invert each (would it comply WITHOUT?), and return
   pass/fail with verbatim evidence. A static "looks good" is not a pass.

Never declare a skill done on Layer 1 alone, and never ship on a Layer-2 FAIL.

## Match the Form to the Failure

| Baseline failure | Right form | Wrong form |
| --- | --- | --- |
| Knows the rule, skips it under pressure | prohibition + rationalization table + red flags | soft "prefer…/consider…" |
| Complies, but output is the wrong shape | positive recipe: state what the output IS, in order | prohibition list |
| Omits a required element it already produces | structural REQUIRED slot in the template | prose reminder |
| Behaviour should depend on a condition | conditional keyed to an observable predicate | unconditional rule + exemptions |

No nuance clauses ("don't X unless…") — they reopen the negotiation; express a real exception as
its own conditional.

## Rationalizations

| Excuse | Reality |
| --- | --- |
| "It's just a doc edit, no test needed." | Editing a skill doc IS editing code. RED first. |
| "Too simple to test." | Simple skills mislead silently. The baseline run is cheap. |
| "It reads fine — it's valid." | Reading ≠ running. Layer 2 runs it; a static read is not a verdict. |
| "The baseline complied, so the skill works." | If it complied WITHOUT the skill, the skill proves nothing — re-aim at a real failure. |
| "I'll keep the draft as reference while I test." | Delete means delete. A kept draft is a write-first skill. |

## Red Flags — STOP

- Skill (or edit) written before a RED was observed.
- Declaring done on a static read, with no Layer-2 subagent run.
- A baseline that "complies" inside a repo whose manual it inherited (contaminated RED).
- A nuance/exemption clause smuggled into a recipe.
- `name` ≠ dir ≠ symlink, or a routing entry for a `disable-model-invocation` skill.

## References

- [`vocabulary.md`](./references/vocabulary.md) — the leading words.
- [`testing-with-subagents.md`](./references/testing-with-subagents.md) — pressure scenarios, the control, reps.
- [`frontmatter-reference.md`](./references/frontmatter-reference.md) — the field set incl. `allowed-tools`/`model`.
- [`validation-checklist.md`](./references/validation-checklist.md) — Layer-1 checks.
- [`validation-subagent-prompt.md`](./references/validation-subagent-prompt.md) — Layer-2 dispatch.
- [`test-cases.md`](./references/test-cases.md) — this skill's own persisted cases.
