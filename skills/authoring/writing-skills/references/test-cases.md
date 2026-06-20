# Test Cases — writing-skills

The persisted pressure scenarios this skill is validated against. The `validate` gate loads this
file and runs each case; when validating a *foreign* skill that has no such file, the validation
subagent synthesizes equivalent cases from the target's contract and marks them `synthesized`.

Each case records the baseline (RED, no skill) verbatim from the build's baseline run and the
required compliant behavior (GREEN, with skill). RED for a **discipline** case must be measured
WITHOUT this vault's operating manual injected, or an in-vault subagent falsely "complies" — see
[`testing-with-subagents.md`](./testing-with-subagents.md) (contaminated baseline) for the mechanism
and the observed example.

## TC1 — create branch: author a skill test-first (discipline)

- **Setup:** Ordinary project, no operating manual. "We keep reusing a technique; capture it as a SKILL.md a teammate can apply." Tempts: just write the document.
- **Baseline (RED), observed:** Subagent wrote the SKILL.md FIRST and never tested it. Verbatim: "this is a write-first artifact … I did not test or verify it before writing it." No RED-before-writing, no validation step.
- **With skill (GREEN):** Step 0 classifies `create`; the skill forces a baseline pressure run WITHOUT the skill-under-construction BEFORE writing (Iron Law), then writes the minimal skill, then runs the `validate` gate. The author observes a real failure first or stops.
- **Exercises:** Iron Law (no skill without a failing test first); create-branch ordering.

## TC2 — edit branch: change a skill test-first (discipline)

- **Setup:** Ordinary project. "Add a section to existing skill Y." Tempts: edit the markdown directly — "it's just a doc."
- **Baseline (RED), expected:** Direct edit with no failing test first; "editing a doc isn't editing code" rationalization.
- **With skill (GREEN):** Edit branch applies the Iron Law to edits (diff-scoped RED on the changed behavior → GREEN), then the `validate` gate. "Editing a skill doc IS editing code."
- **Exercises:** Iron Law on edits; the rationalization table.

## TC3 — validate gate: dynamic, not static (behavior)

- **Setup:** "Is this skill any good? Validate it." A plausible-looking discipline skill is supplied.
- **Baseline (RED), observed (contaminated):** With the vault manual inherited, the subagent ran an A/B test and found the control already complied — strong behavior. A *clean* naive validator instead reads-and-reasons only and declares it good on a static read. The contrast is the target: static-only validation misses "looks fine, changes nothing."
- **With skill (GREEN):** The validate gate runs Layer 1 (static pre-flight) THEN dispatches the validation subagent to run the skill's test cases WITH the skill enabled, returning pass/fail with verbatim evidence and inverting each case (would the agent comply WITHOUT the skill?). A static-only "looks good" is rejected as incomplete.
- **Exercises:** validate = subagent run of test cases, not eyeballing; the inversion check; verbatim evidence requirement.
