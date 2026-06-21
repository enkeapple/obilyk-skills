---
description: >-
  Present every SDD-chain gate choice as one canonical interactive picker of
  options-with-descriptions (the harness picker tool; markdown-list fallback when
  absent), not ad-hoc prose. Covers four archetypes — phase approval (A),
  execution-mode fork (B), readiness (C-readiness), drift disposition (C-drift,
  batched). Owns presentation only — the stop and the progress list are owned
  elsewhere. Loaded on demand by the gate work that links it (no path trigger).
  Vault-only; not shipped to consumers.
---

# Interactive Gate Prompts

## When

At any SDD-chain decision point that needs an **explicit, non-derivable user choice**:

- each phase **approval gate**;
- the **execution-mode fork** after plan approval (inline vs subagent);
- the **readiness verdict** before implementation;
- the **post-report disposition** after a drift audit.

Do NOT add a picker where the choice is **agent-derivable** (e.g. routing an input to its entry phase) or **already conversational** (a one-question recommended-answer interview).

## Why

Without one canonical form, gate prompts drift run to run — prose one time, a different option set the next, no clickable choice — and the user re-reads a bespoke sentence at every gate. The value is **convergence**, not "offer a choice": one mechanism plus fixed option templates make every gate recognizable and the approval explicit and one-click. This rule owns only the **presentation** of the gate choice; the **stop** and the **progress-list visual** are separate concerns owned elsewhere, and this rule applies without them.

## Implementation

### Mechanism

Present the choice as a **numbered picker of options-with-descriptions**. In a harness with a dedicated picker tool, use it (typically 1–4 questions; each 2–4 explicit options; a free-text "Other" option is usually added automatically, so never list it). When no picker tool exists, **fall back** to a markdown numbered list with one-line descriptions and ask the user to reply with a number — never silently drop the choice.

### Archetypes and option templates

The archetype letters (A, B, C-readiness, C-drift) are a **stable contract** — other SDD work cites them by letter, so keep them fixed. Each list is the 2–4 explicit options (auto-"Other" omitted):

| Archetype | Fires | Options (label → description) |
| --- | --- | --- |
| **A — approval gate** | after each phase | `Approve` → approve this artifact, advance · `Request changes` → revise this same artifact (user says what) · `Redo a previous phase` → defect upstream, return and rework (user names the phase) |
| **B — execution-mode fork** | after plan approval | `Inline (solo)` → coupled tasks / small plan, execute in-session · `Subagents` → independent tasks, fresh subagent per task + review gates |
| **C-readiness** | readiness check | `Proceed` → readiness confirmed, begin implementation · `Not ready` → gaps remain, list them and return to the plan |
| **C-drift** | after the audit report (ONE picker) | `Apply recommended` → apply the per-finding recommended dispositions · `Adjust per-finding` → walk findings one by one · `Stop` → take no action now |

C-drift is **one batched picker**, never one picker per finding; the audit must therefore record a **recommended disposition per finding** in its report.

### Gate-honesty

The picker **is** the stop: presenting options and waiting for a pick is the gate's "STOP for explicit approval"; "never auto-advance" means "never advance without a pick". An `Approve` pick **is** that explicit approval, so advancing after it honors the gate. A gate-turn awaiting a pick is `Result: IN PROGRESS` (awaiting approval), never `BLOCKED` (reserved for scope decisions / git-boundary actions).

## Edge Cases

- **No picker tool** → markdown numbered-list fallback (above); the choice is never dropped.
- **Consumer repo without this rule** → the gate prompts degrade to plain prose; the picker simply does not appear. The rule being vault-only is intentional, not a leak.
- **Two-step picks** — `Redo a previous phase` (A) and `Adjust per-finding` (C-drift) collect the *branch*; a follow-up free-text prompt collects the detail (which phase / walking findings).
- **Standalone phase invocation** → the phase still presents its own archetype picker at its gate; archetype **B** is only meaningful post-plan.

## Review Checklist

- [ ] Every gate choice in the four covered points is a picker (or its markdown fallback), never bespoke prose.
- [ ] Option sets match the archetype table verbatim; auto-"Other" not listed; each list is 2–4 options.
- [ ] Archetype letters A/B/C-readiness/C-drift are unchanged — other skills cite them.
- [ ] C-drift is one batched picker and the audit produces a per-finding recommended disposition.
- [ ] Does not restate the gate's stop or the progress-list status discipline — only the picker presentation.
- [ ] Gate-turn status is `IN PROGRESS`, not `BLOCKED`.
