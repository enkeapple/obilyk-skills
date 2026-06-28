---
name: verifying-implementation
description: >-
  Use when checking whether shipped or in-progress code still matches an
  approved written spec — after implementation and before a PR, when a
  long-running branch returns from review, or before a refactor built on an
  old spec. Triggers on: "audit the spec", "spec drift", "does the code match
  the spec", "verify spec", "check what we built", "did we build what we agreed".
allowed-tools: Read, Grep, Glob, Bash
---

# Verifying Implementation

A read-only comparison between an approved spec and the current code. It produces a **drift report**, classifies each difference against a fixed taxonomy, and ends with one decision for the user. Produce the report in the exact shape below **every run** — the value is convergence, not a fresh ad-hoc summary.

**Read-only.** Reporting drift is the job; fixing it is a separate task the user authorizes after seeing the report. Do not "just fix it while I'm here" — the user cannot decide on drift they were never shown. Violating the letter of this (one quick edit) violates the spirit. (`Bash` is in `allowed-tools` only to **run** the spec's verification commands and read-only inspection — never to edit code; the read-only guarantee holds despite it.)

This pairs with a spec written via the **writing-specs** skill and assumes its section shape (an optional **Source** provenance block, then Goal, Scope, Out of scope, Contracts, Files touched, Edge cases, Verification, Risks). Project-agnostic: discover real commands and paths from the repo.

**Progress:** before your first artifact, reflect this phase in the harness task list (one item `in_progress`; an item turns `completed` only on the user's explicit approval of that phase's artifact; a skipped phase stays listed, marked skipped) — under `sdd-lifecycle` update the existing item; run standalone, seed a single item for this phase.

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

1. **Parse the spec.** Extract verbatim: the Source provenance block (if present), Goal, Scope bullets, Out-of-scope bullets, Contracts, the Files-touched table, the Verification commands.
2. **Verify each file touched — both directions.** For every row in the spec's Files-touched table: open the file; confirm the change kind (NEW / EDIT / DELETE) actually happened; for EDIT, grep for the symbols the spec named. Then invert: list any file the diff touched that is **absent** from the spec's table — an untabled touched file is itself a silent expansion, even if no out-of-scope bullet names it.
3. **Compare contracts field by field.** For each type / signature / shape in the spec, find its real definition and diff it. Note every added / removed / renamed / re-typed field.
4. **Sweep out-of-scope.** For *every* out-of-scope bullet, actively grep the codebase for evidence it was touched anyway — check each bullet, not just the first.
5. **Run verification; cite fresh output.** Execute each command from the spec's Verification section and paste the actual result — exit status and the real lines. Never "should pass" / "looks fine"; a claim without fresh output is not a result. If you genuinely cannot run a command (no runtime, sandbox), say so and record the result as **UNVERIFIED** — never infer pass/fail, and never parrot a pre-supplied output as if you ran it.
6. **Trace to source (only if a Source block is present).** Confirm the cited `source`/`revision` is recorded and reachable, then check the shipped behavior against the *original* requirements that bundle carried — not just against the spec. A requirement present in the source but absent from both spec and code is **source drift** (the spec silently narrowed its own ticket); flag it.

## Drift classification

Label every difference:

- **Intentional** — code changed for a documented reason (commit/PR/decision). Acceptable; record the link.
- **Missed scope** — spec required it, code lacks it. Critical.
- **Silent expansion** — code did something not in the spec (often an out-of-scope violation). Critical.
- **Schema drift** — a contract field differs (added/removed/renamed/re-typed). Critical when the field is part of an external interface (public API, shared type, route/param contract); warn-level for purely internal types.
- **Source drift** (only when a Source block is present) — a requirement carried by the cited source bundle that is absent from both the spec and the code. Severity tracks the dropped requirement's importance.

## Report format

Produce a report with these sections, in order (see [assets/report-example.md](./assets/report-example.md) for a filled example):

1. **Verification** — each command → real output.
2. **Files touched** — table: file → spec said → code shows → status (OK / MISSED / SILENT EXPANSION).
3. **Contract drift** — per contract: spec shape → code shape → classification + severity.
4. **Out-of-scope check** — per out-of-scope bullet: touched? where? classification.
5. **Source trace** (only if the spec has a Source block) — the cited `source`/`revision`; per source requirement: present in spec? in code? classification (incl. Source drift).
6. **Summary** — counts per classification. Count one per distinct violation, not per code site (a single out-of-scope change spread over several files is one finding); note the sites under it.
7. **Recommended disposition** — per finding, the audit's recommended action (Fix code / Amend spec / Accept) with a one-line reason.

## Required decision after the report

End with **one** decision, not edits and not a question per finding. Having recorded a recommended disposition per finding (Report item 7), present archetype **C-drift** as one batched picker (markdown-list fallback):

- `Apply recommended` → apply the per-finding recommended dispositions.
- `Adjust per-finding` → walk findings one by one.
- `Stop` → take no action now.

The user picks. The audit itself still does not edit code — applying a disposition is the follow-up task the user authorizes here.

## Integration

- **Upstream:** invoked after the execution phase (`inline-driven-development` / `subagent-driven-development`), or standalone against already-shipped code; pairs with a spec written via `writing-specs` (the section shape it parses).
- **Terminal:** this is the chain's closing **verify** phase — it never feeds another phase. After the disposition is chosen, the human owns the commit.

## Red Flags — if you catch yourself here, STOP

The moment you notice one, the audit is about to fail silently. Each maps to a row in **Rationalizations**.

- "I read the diff, it looks fine." / "It mostly matches." / "Should pass."
- Reaching to fix a mismatch while you are here.
- Checking only the first out-of-scope bullet.
- Marking a verification command passed without running it and pasting its output.
- Reporting in prose instead of the classified format and fixed section order.

## Rationalizations

Every excuse means the same thing: **report the drift in the fixed shape; do not fix it.**

| Excuse | Reality |
| --- | --- |
| "I read the diff, it looks fine." | No report written = the audit did not happen. The deliverable is the classified report, not a verdict. |
| "It's a tiny mismatch, I'll just fix it." | Then report it and let the user approve the one-line fix. A silent fix hides the drift and the decision. |
| "The obvious violation is the only one." | Sweep every out-of-scope bullet — the second hit is the one that slips through. |
| "Verification will pass / should pass." | "Will pass" is a guess. Run it; paste the real output. The rename you missed often fails here. |
| "Prose is clearer than the table." | Prose hides severity and lets items slip, and its shape drifts run to run. The fixed classified report is the deliverable. |
