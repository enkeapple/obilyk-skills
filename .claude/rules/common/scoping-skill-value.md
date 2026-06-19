---
description: >-
  When authoring a skill or adding a phase to one, scope its value to a
  reproduced failure, not its stated purpose. RED the literal version against a
  cold baseline first; a strong model often already obeys a principle / catches
  a correctness defect / keeps a discipline, so the literal skill is a no-op.
  Re-aim GREEN at the failure that actually reproduces (shaping / efficacy /
  skipped process). Caveat: an in-vault subagent control inherits framework.md,
  so a discipline-RED can read as a false "no failure".
paths: ['skills/**/SKILL.md']
---

# Scoping Skill Value to a Reproduced Failure

## When

You are authoring a new skill, or adding a phase / section to an existing one, whose remit is one of: a **principle** ("think about deep modules", "consider edge cases"), a **"review / verify / validate" pass**, or a **discipline gate** ("don't dive into code before X"). This is the moment to check the value is real before writing — it is the recurring `skill-value-vs-noop` failure (3 instances in [lessons-learned.md](../../lessons-learned.md)).

The RED→GREEN methodology this rule applies is owned by `writing-great-skills` (the inversion test and the No-op failure mode); this rule is the always-on distillate of the *scoping decision*, not a substitute for that skill.

## Implementation

**Before writing the skill/phase, RED the literal version against a cold baseline.** Hand a cold subagent the governed task with NO skill in context. A strong model frequently already obeys the principle, catches the correctness defect, or keeps the discipline — that is the inversion test failing, and the literal skill would be a no-op that only costs load.

When the baseline absorbs the literal version, **do not ship it.** Re-aim GREEN at the failure that *does* reproduce, and calibrate the skill to that:

- **Shaping failure** (behaviour happens, output has the wrong/inconsistent shape — lexicon drift, variance across reps) → a fixed positive recipe, not a prohibition.
- **Efficacy gap** (does the rule/phase steer behaviour at all?) → an efficacy test, not another correctness pass.
- **Skipped process steps** (the explore→present→grill the model shortcuts) → make the step structural.

```text
❌ WRONG — scoped to the stated purpose; cold baseline already complies → no-op.
Asked to add a "pre-implementation gate", write a prohibition: "Don't start coding
before verifying the plan." Ship it. (Cold agents recon-before-code anyway; the
gate guards nothing — it is theatre.)

✅ CORRECT — RED the literal version, find the failure that reproduces, scope to it.
RED shows cold agents already verify the plan (no discipline failure), but produce
the readiness check in 4 different shapes (a shaping failure). Ship a positive
recipe for one fixed readiness-block shape; GREEN = the shape converges across reps.
```

**Two-layer review variant — a cold pass is a no-op unless it is *differently informed*.** When a review has an author self-review *and* an independent cold reviewer, the cold layer earns its load only if its remit is disjoint — not a fresh agent re-running the same checklist. Two structural requirements:

- **Feed the cold reviewer the source, not just the artifact.** Its unique value is re-deriving intent from the *source the artifact came from* (the request/design for a spec, the spec for a plan, the existing-rules set for a rule) and flagging divergence — the misread the author is blind to. Given only the produced artifact, it collapses into a second internal-completeness pass.
- **Split the checklists by reachability:** self = checks the author can make against the artifact itself (placeholders, internal consistency, naming); cold = the author-blind class (conformance to source, ambiguity two readers would split on). Overlapping checklists are the redundancy that reads as theatre.

RED it with a **clean misread** — an artifact internally consistent but wrong against its source. If the cold reviewer, given only the artifact, approves it, the layer is a no-op: wire the source in, make the remits disjoint, and re-RED.

**Caveat — a contaminated discipline control reads as a false "no failure."** A subagent spawned in this repo inherits the vault's operating manual ([framework.md](../domains/framework.md): the Iron Law, read-before-assert, the chain), so a discipline-RED run that "complies" may be obeying the force-injected manual, not your skill — agents will even cite "the vault's discipline" verbatim. To measure a true discipline baseline, use an environment WITHOUT that injection (a controlled system prompt, or a real consumer repo). Shaping failures (output-shape variance) stay cleanly measurable in-repo regardless. If you cannot reproduce the discipline failure at all, do not build the gate — find the shaping / efficacy failure that is reproducible, or write nothing.

## Edge Cases

- **When NOT to apply:** a pure-reference skill (API/command docs) — its value is retrieval, not behaviour change, so the no-op test does not apply. Test retrieval instead.
- A skill that bundles principle-prose *plus* a reproduced shaping/process failure is fine — keep the load-bearing part scoped to the failure and treat the principle as light scaffolding, not the justification.
- This rule governs the *scoping decision*. The full RED→GREEN→REFACTOR loop, the rationalization table, and "Match the Form to the Failure" live in `writing-great-skills` — cross-link, don't restate.

## Review Checklist

- [ ] Named the target failure class (discipline / shaping / efficacy / process) before writing the skill or phase.
- [ ] RED-ran the literal version against a cold baseline; if the baseline complied, the literal version was cut or re-aimed — not shipped.
- [ ] GREEN is calibrated to the reproduced failure (shape convergence / efficacy / step taken), not to the skill's stated purpose.
- [ ] For a discipline target, did not trust an in-vault Agent-tool "compliance" as the baseline (it may be inherited `framework.md`) — got a clean baseline or pivoted.
- [ ] Did not duplicate `writing-great-skills`' methodology content; cross-linked it instead.
- [ ] For a two-layer review (self + cold reviewer): the cold layer is fed the SOURCE the artifact derives from (not just the artifact), its checklist is disjoint from the self-review's (author-reachable vs author-blind), and a clean-misread RED confirms it catches a consistent-but-wrong artifact.
