---
name: auditing-code-quality
description: >-
  Use when the user asks for a refactoring audit or code-quality review of a
  given area — "audit this code", "what should I refactor here", "review this
  module for quality", "give me a refactor report" — and wants a prioritized
  written report of findings before any change is made. Produces the report and
  STOPS; execution is handed to the test-first chain. Distinct from
  improve-codebase-architecture, which uses the narrow deep-module / seam lens;
  this one is the broad code-quality lens (duplication, oversized units,
  boundary leaks, complexity, brittle tests, naming, dead code).
disable-model-invocation: true
---

# Auditing Code Quality

Scan a named area of code and produce **one prioritized refactoring report** in a fixed shape, so every run is comparable. The deliverable is the **report only** — you propose directions, you do not change code.

## Boundary — report, then stop

This skill ends at the report. Do **not** edit code, write the fix, or start "while I'm here" cleanups. After the report, hand execution to the test-first chain: `test-driven-development` for a single fix, or `inline-driven-development` / `subagent-driven-development` for the whole set. The report's `Handoff` line names this.

## When to use

- The user asks to audit / review / "what to refactor" in a specific area, and wants findings before committing to changes.
- Not for: the deep-module / seam lens (use `improve-codebase-architecture`); not for executing a refactor (use the chain above); not for checking code against a spec (use `verifying-implementation`).

## Process

1. **Confirm scope.** State exactly what is in scope (the files/area you will read) and what is out. If the target is vague, narrow it before scanning.
2. **Scan for candidates** across these categories — use them as a coverage checklist, not a script: duplicated logic, oversized unit / mixed responsibilities, leaky boundary or layering violation, excess complexity, weak or brittle tests, unclear naming, dead code.
3. **Confirm each candidate with verbatim evidence** (a quoted snippet or location). Then check for an *intentional* reason — a comment, a documented decision, or version-control history that explains the shape. A candidate with a load-bearing intentional reason is **not** a finding: it moves to `Considered & rejected`. Unusual code is not automatically wrong.
4. **Score every surviving finding with the fixed rubric** (below) and sort highest-first. Do not eyeball severity — the rubric is what makes runs comparable.
5. **Emit the report** in the exact contract shape below, then STOP.

## Severity rubric (fixed — do not improvise)

Score each finding `Impact × Reach`, then map to severity. Fixed thresholds keep severity comparable across runs and reviewers.

- **Impact** — 1 = cosmetic; 2 = maintainability drag; 3 = correctness or regression risk.
- **Reach** — 1 = single local site; 2 = one module; 3 = cross-module / many call sites.
- **Severity** — `HIGH` if Impact×Reach ≥ 6; `MEDIUM` if 3–5; `LOW` if ≤ 2.

## Report contract (REQUIRED shape — every section, every run)

````text
# Code Quality Audit — <target area>

## Scope
- Audited: <files / areas actually read>
- Not audited: <what was out of scope, and why>

## Findings — sorted by severity, highest first
| # | Location | Category | Impact×Reach | Severity | Issue (one line) | Proposed direction |
| --- | --- | --- | --- | --- | --- | --- |

## Detail — one block per finding, same shape each
### F<n> — <title>  ·  <SEVERITY>
- Location: <where>
- Evidence: <verbatim quote / reference that proves it>
- Why it matters: <consequence if left>
- Proposed direction: <what to change — direction, NOT the implementation>

## Considered & rejected   (REQUIRED — never omit, even if empty say "none")
| Candidate | Why it is NOT a finding (evidence: comment / history / intentional) |
| --- | --- |

## Recommended order
1. Foundation — boundary fixes, de-duplication, shared extraction
2. Structural — unit splits, decomposition
3. Cleanup — naming, dead code

## Handoff
Report only — no code changed. Execute via `test-driven-development` per fix, or
`inline-driven-development` / `subagent-driven-development` for the set.
````

The `Considered & rejected` section is a **required slot**: a competent audit already notices intentional code, but only a fixed slot makes that visible and consistent every run — it is what stops a reviewer wasting effort re-proposing a documented deviation. Write `none` if nothing was rejected; never drop the heading.

## Red Flags — STOP

- You started editing code or wrote the fix — this skill stops at the report; hand off instead.
- A finding's severity was eyeballed instead of scored `Impact × Reach` against the fixed thresholds.
- The `Considered & rejected` section is missing, or an intentional/documented pattern was filed as a finding.
- A finding has no verbatim evidence — a claim without a quoted location is a guess, not a finding.
- The report's sections or their order differ from the contract — that is the shape drift this skill exists to remove.
