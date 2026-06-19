---
name: spec-drift-audit
description: >-
  Use when checking whether shipped or in-progress code still matches an
  approved written spec — after implementation and before a PR, when a
  long-running branch returns from review, or before a refactor built on an
  old spec. Triggers on: "audit the spec", "spec drift", "does the code match
  the spec", "verify spec", "check what we built", "did we build what we agreed".
---

# Spec Drift Audit

A read-only comparison between an approved spec and the current code. It produces a **drift report**, classifies each difference, and ends with decisions for the user. **It does not edit code.**

**The audit is read-only. Reporting drift is the job; fixing it is a separate task the user authorizes after seeing the report.** Offering to "just fix it while I'm here" defeats the audit — the user cannot decide on drift they were never shown. Violating the letter of this (one quick edit) violates the spirit.

This pairs with a spec written via the **writing-specs** skill and assumes its section shape (Goal, Scope, Out of scope, Contracts, Files touched, Edge cases, Verification, Risks). Project-agnostic: discover real commands and paths from the repo.

**Progress:** before your first artifact, reflect this phase in the task list per [phase-task-visualization](../../../.claude/rules/common/phase-task-visualization.md) — under `sdd-lifecycle` update the existing item; run standalone, seed a single item for this phase.

## When to use

- After implementation completes, before opening a PR — confirm what shipped matches what was approved.
- When a long-running branch comes back from review and you need to know what changed vs the spec.
- Before a refactor — confirm the code still reflects the original spec, or document the drift.

## When NOT to use

- Specs explicitly labeled retroactive — those describe the code, not the reverse.
- Specs full of "TBD / we'll decide during implementation" — nothing to compare; fix the spec first.

## Inputs

1. Path to the spec. If it is missing, STOP and ask — do not guess which spec.
2. Optional: a branch / commit range to scope the audit to recent changes.

## Process

1. **Parse the spec.** Extract verbatim: Goal, Scope bullets, Out-of-scope bullets, Contracts, the Files-touched table, the Verification commands.
2. **Verify each file touched.** For every row: open the file; confirm the change kind (NEW / EDIT / DELETE) actually happened; for EDIT, grep for the symbols the spec named.
3. **Compare contracts field by field.** For each type / signature / shape in the spec, find its real definition and diff it. Note every added / removed / renamed / re-typed field.
4. **Sweep out-of-scope (REQUIRED, this is where silent drift hides).** For *every* out-of-scope bullet, actively grep the codebase for evidence it was touched anyway. Do not stop at the first one — agents reliably catch the obvious violation and miss the second. Check each bullet.
5. **Run verification and record real output.** Execute each command from the spec's Verification section; paste the actual result, not "should pass".

## Drift classification

Label every difference:

- **Intentional** — code changed for a documented reason (commit/PR/decision). Acceptable; record the link.
- **Missed scope** — spec required it, code lacks it. Critical.
- **Silent expansion** — code did something not in the spec (often an out-of-scope violation). Critical.
- **Schema drift** — a contract field differs (added/removed/renamed/re-typed). Critical when the field is part of an external interface (public API, shared type, route/param contract); warn-level for purely internal types.

## Report format

Produce a report with these sections, in order (see [references/report-example.md](references/report-example.md) for a filled example):

1. **Verification** — each command → real output.
2. **Files touched** — table: file → spec said → code shows → status (OK / MISSED / SILENT EXPANSION).
3. **Contract drift** — per contract: spec shape → code shape → classification + severity.
4. **Out-of-scope check** — per out-of-scope bullet: touched? where? classification.
5. **Summary** — counts per classification.

## Required decision after the report

End with choices for the user, not edits:

- Each silent expansion → "remove it, or document it in the spec — which?"
- Each missed scope → "implement now, or move to a follow-up spec — which?"
- Each external-interface schema drift → "revert to spec, or bump the spec — which?"

The user picks. The audit does not edit code.

## Red Flags — if you catch yourself here, STOP

Fast trip-wires: the moment you notice one, the audit is about to fail silently. The counter to each is its row in **Rationalizations** below.

- "I read the diff, it looks fine."
- Reaching to fix a mismatch while you are here.
- Checking only the first out-of-scope bullet.
- Marking a verification command passed without running it.
- Reporting in prose instead of the classified format.
- "It mostly matches."

## Rationalizations

Every excuse means the same thing: **report the drift; do not fix it.**

| Excuse | Reality |
| -------- | --------- |
| "I read the diff, it looks fine." | No report written = the audit did not happen. The deliverable is the classified report, not a verdict. |
| "It's a tiny mismatch, I'll just fix it." | Then report it and let the user approve the one-line fix. A silent fix hides the drift and the decision. |
| "The obvious violation is the only one." | Agents reliably miss the second out-of-scope hit. Sweep every bullet, every time. |
| "Verification will pass, I'll skip running it." | "Will pass" is a guess. Run it; paste the output. The rename you missed often fails here. |
| "Prose is clearer than a table." | Prose hides severity and lets items slip. The classified report is the deliverable. |
| "It mostly matches, call it OK." | "Mostly" is not a classification. Every difference gets a label and a severity. |
