---
name: accessibility
description: >-
  Use when checking or improving the accessibility (a11y) of a React Native
  screen or component — auditing it against WCAG 2.2 AA and fixing the gaps.
  Triggers on: "accessibility audit", "a11y", "check accessibility", "is this
  screen accessible", "WCAG", "screen reader / VoiceOver / TalkBack support",
  "fix accessibility", "проверь доступность", "аудит доступности",
  "сделай экран доступным".
allowed-tools: Read, Grep, Glob, Edit
---

# Accessibility (React Native)

Audit a named React Native target against **WCAG 2.2 AA**, expressed as concrete RN-checkable rules, produce a **coverage report**, and — only after the user chooses — apply fixes. **Audit first, fix second.** Presenting the report and getting a disposition is the job; editing before that hides from the user the coverage they never saw.

The rule catalog every audit sweeps lives in [references/wcag-rn-checklist.md](./references/wcag-rn-checklist.md): each rule maps a RN accessibility prop/pattern to a WCAG 2.2 success criterion. Project-agnostic — discover the real component files from the repo.

## Inputs

1. **An explicit target — required.** A file, component, screen, or directory the user names. If none is given, **STOP and ask which target**; never audit "the whole app" by guessing or silently pick a file.
2. Optional: a focus area (e.g. "just the forms") to scope the sweep within the target.

## Process

1. **Read the target** source file(s).
2. **Sweep every rule in the catalog (REQUIRED).** For *each* rule in [references/wcag-rn-checklist.md](./references/wcag-rn-checklist.md), inspect the target and assign a status — do not stop at the obvious labels-and-roles gaps. Touch-target size, color/contrast, heading roles, focus order, and font scaling are the rules a freehand pass reliably misses; check each one explicitly.
3. **Record each finding** with its location (`file:line`), the WCAG success criterion, what is missing, and a severity.
4. **Produce the coverage report** (format below). Do not edit yet.

## Report format

Produce, in order:

1. **Coverage** — a table with one row **per catalog rule**: rule → status (`Pass` / `Fail` / `Partial` / `N/A`) → WCAG SC → location. A rule with no relevant element on the target is `N/A`; never omit a rule's row (an omitted rule reads as "checked and fine").
2. **Findings** — for every `Fail` / `Partial`: element + `file:line` + WCAG SC + what is missing + **severity** (`Critical` = blocks an assistive-technology user from completing the task · `Serious` = major barrier · `Minor` = friction) + a one-line recommended fix.
3. **Summary** — counts by status and by severity.

## Disposition gate — STOP before editing

**Even when the task says "fix" (or "audit and fix"), the audit runs first and this gate fires** — "fix" authorizes the work, not skipping the report. After the report, present **one batched choice** and wait for it — do not edit before the user picks:

- **Apply all** → apply every recommended fix.
- **Pick per finding** → walk the findings one at a time.
- **Skip** → report only, change nothing.

(Use the host's option-picker if one exists; otherwise a numbered markdown list and ask for a number.) The audit itself edits nothing — applying fixes is the step the user authorizes here.

## Apply fixes (only after the gate)

For each authorized finding, make the **minimal** edit that satisfies the rule (add the missing prop, mark the decorative node, enlarge the target, remove `allowsFontScaling={false}`, etc.). Re-state each applied edit against its WCAG SC. Where a fix needs human judgment (the *text* of a label, whether an image is decorative), state the assumption rather than inventing copy silently.

## Red Flags — STOP

- Auditing without an explicit target (asking nothing, scanning "the app").
- Editing the code before the report is shown and a disposition is chosen.
- Reporting only the labels/roles you spotted, with no full catalog sweep (touch target, contrast, heading, focus order, font scaling missed).
- Findings with no WCAG success criterion and no `file:line`.
- Omitting a catalog rule's row instead of marking it `N/A`.
- Prose findings instead of the coverage table.

## Rationalizations

| Excuse | Reality |
| --- | --- |
| "I'll just fix what I see while I'm here." | Then show the report first and let the user choose. A silent fix hides the coverage and the decision. |
| "The task said 'fix', so applying everything is implied — skip the gate." | "Fix" authorizes the work, not skipping the report. Run the audit, present the gate, wait for the pick. |
| "The obvious label/role gaps are the whole audit." | A freehand pass reliably misses touch-target size, contrast, heading roles, and font scaling. Sweep every catalog rule. |
| "No target named — I'll audit the main screen." | Guessing the target wastes the run. STOP and ask which target. |
| "Listing problems is enough." | The deliverable is the per-rule coverage table (Pass/Fail/Partial/N/A) — it shows what was checked and found OK, not just what broke. |
| "I know the WCAG number, no need to write it." | Each finding cites its success criterion and `file:line`, or it is not traceable or fixable. |
