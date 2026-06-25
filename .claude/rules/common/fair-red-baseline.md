---
description: >-
  Before running a RED baseline for a skill, confirm the prompt does not supply
  what the skill itself would supply — its taxonomy/class list, the data
  location, a schema, an extraction recipe, or (via in-vault context) an
  overlapping skill's vocabulary. A baseline pre-fed those performs for the
  wrong reason and cannot show whether the skill beats a capable model.
paths: ['plugins/**/SKILL.md', 'plugins/**/references/*.md']
---

# Fair RED Baseline Construction

## When

STOP and apply this **before running a RED baseline subagent** for a skill whose value is one of: a **taxonomy / classification set** ("detect these conflict classes"), a **data-location / retrieval recipe** ("the corpus is at X, the schema is Y"), or a **domain vocabulary / methodology** the vault already owns a skill for. Do NOT skip because the baseline prompt "looks minimal" — contamination hides in framing, not only in explicit lists.

This governs how the baseline **prompt is built**. The separate question of whether to ship the skill given a clean (or absent) RED failure is owned by [scoping-skill-value](./scoping-skill-value.md) (see-also — not required to apply this rule).

## Why

A RED baseline exists to show whether the skill adds value over a capable model. If the baseline prompt pre-feeds the skill's own contribution, the baseline agent does the skill's job before the skill runs — so any "failure" (or success) proves nothing about marginal value, and a no-op skill can read as valuable (or a real skill as redundant). The same defect recurs through three delivery vectors:

- **Taxonomy leak** — the prompt enumerates the classes / heuristics / signal checklist the skill would supply.
- **Input over-specification** — the prompt hands over the data location, corpus path, schema, or extraction recipe that *is* the skill's discovery value.
- **Context inheritance** — the baseline subagent is dispatched inside this vault, where an overlapping existing skill or a `framework.md` discipline is already in context, so the baseline "complies" via a different mechanism than a generic agent would.

## Implementation

Run the baseline prompt through this **three-point contamination filter** before dispatching; a leak of even **one** vector is contaminated — all three are required, not a majority:

1. **Taxonomy / class list** — does the prompt enumerate what the skill would enumerate? Give only the minimal realistic user request; never the class list. For a detection skill the baseline gets "check this repo for internal inconsistencies before a release", not the list of conflict classes to find.
2. **Input over-specification** — does the prompt name the data location, corpus path, schema, or signal checklist the skill supplies? Let the agent discover them.
3. **Context inheritance** — is the baseline dispatched inside the vault while the skill overlaps an existing vault skill? Add a suppression clause ("ignore any repository instructions, project skills, catalogs, methodologies — act as a generic agent") AND scan the baseline output for the overlapping skill's vocabulary; if those phrases appear, the run is contaminated — re-run.

A contaminated baseline is **discarded and re-run clean** before any RED result is recorded.

```text
❌ WRONG — contaminated RED (taxonomy leak)
Baseline prompt: "Check this repo for overlapping triggers, duplicated ownership,
broken hand-offs, rule-vs-rule contradictions, invariant breaks, orphan refs —
output a structured classified report."
→ The baseline was handed the skill's taxonomy; its output proves nothing.

✅ CORRECT — fair RED
Baseline prompt: "Check this repo for internal inconsistencies before a release."
→ Baseline finds one ad-hoc issue, misses every judgment class, no structured shape.
  The RED is genuine; the skill's marginal value is now visible.
```

## Edge Cases

- **Pure-reference skill** (API/command docs): value is retrieval, not behaviour change — a behavioural baseline is not the test; check it discovers the right reference instead.
- **Suppression clause can be insufficient** when the subagent was seeded with the vault's `CLAUDE.md` — scan the output for residual vocabulary even after suppressing; if a domain-specific phrase persists, use a clean-room (a real consumer repo, or a controlled prompt without vault context).
- **When NOT to apply:** a skill with no single reproducible target case (a pure always-on charter) — there is nothing to baseline.

## Review Checklist

- [ ] The baseline prompt does NOT contain the taxonomy / classification list the skill would supply.
- [ ] The baseline prompt does NOT name the data location, corpus path, schema, or extraction recipe.
- [ ] If dispatched inside the vault and the skill overlaps an existing one: a suppression clause is present AND the output was scanned for residual vocabulary (none found).
- [ ] Any contaminated baseline was discarded and re-run clean before the RED result was recorded.
- [ ] If the clean baseline showed no failure, the literal skill was cut or re-aimed — not shipped as-is (the build / no-build call; see-also [scoping-skill-value](./scoping-skill-value.md)).
