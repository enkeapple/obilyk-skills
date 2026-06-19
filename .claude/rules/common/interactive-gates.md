---
description: >-
  Present every SDD-chain gate choice as one canonical interactive picker of
  options-with-descriptions (the AskUserQuestion tool; markdown-list fallback
  when absent), not ad-hoc prose. Covers four archetypes — phase approval (A),
  execution-mode fork (B), readiness (C-readiness), drift disposition (C-drift,
  batched). Owns presentation only: the stop is sdd-lifecycle's gate, the
  progress list is phase-task-visualization. Vault-only; not shipped to consumers.
---

# Interactive Gate Prompts

## When

At any SDD-chain decision point that needs an **explicit, non-derivable user choice**:

- each phase **approval gate** (owned by `sdd-lifecycle`);
- the **execution-mode fork** after plan approval (inline vs subagent, owned by `sdd-lifecycle`);
- the **readiness verdict** (`pre-implementation-protocol`);
- the **post-report disposition** (`spec-drift-audit`).

Do NOT add a picker where the choice is **agent-derivable** (entry classification in `sdd-lifecycle`) or **already conversational** (`grilling`'s one-question recommended-answer interview).

## Why

Without one canonical form, gate prompts drift run to run — prose one time, a different option set the next, no clickable choice — and the user re-reads a bespoke sentence at every gate. The value is **convergence** (as in [phase-task-visualization](./phase-task-visualization.md)), not "offer a choice": one mechanism + fixed option templates make every gate recognizable and the approval explicit and one-click. This rule owns only the **presentation** of the gate choice — the **stop** is owned by `sdd-lifecycle`'s gate, the **progress-list visual** by `phase-task-visualization`. Cross-link, do not restate.

## Implementation

### Mechanism

Present the choice as a **numbered picker of options-with-descriptions**. In this harness that is the `AskUserQuestion` tool (1–4 questions; each 2–4 explicit options; an "Other" free-text option is added automatically, so never list it). When no picker tool exists (e.g. a consumer repo's harness), **fall back** to a markdown numbered list with one-line descriptions and ask the user to reply with a number — never silently drop the choice.

### Archetypes and option templates

Each list is the 2–4 explicit options (auto-"Other" omitted):

| Archetype | Fires | Options (label → description) |
| --- | --- | --- |
| **A — approval gate** | after each phase | `Approve` → approve this artifact, advance · `Request changes` → revise this same artifact (user says what) · `Redo a previous phase` → defect upstream, return and rework (user names the phase) |
| **B — execution-mode fork** | after plan approval | `Inline (solo)` → coupled tasks / small plan, execute in-session · `Subagents` → independent tasks, fresh subagent per task + review gates |
| **C-readiness** | readiness check | `Proceed` → readiness confirmed, begin implementation · `Not ready` → gaps remain, list them and return to the plan |
| **C-drift** | after the audit report (ONE picker) | `Apply recommended` → apply the per-finding recommended dispositions · `Adjust per-finding` → walk findings one by one · `Stop` → take no action now |

C-drift is **one batched picker**, never one picker per finding; the audit must therefore record a **recommended disposition per finding** in its report.

### Gate-honesty

The picker **is** the stop: presenting options and waiting for a pick is the gate's "STOP for explicit approval"; "never auto-advance" means "never advance without a pick". An `Approve` pick **is** that explicit approval, so advancing after it honors the gate — `sdd-lifecycle`'s prohibition is unchanged in meaning. A gate-turn awaiting a pick is `Result: IN PROGRESS` (awaiting approval), never `BLOCKED` (reserved for scope decisions / git-boundary actions).

## Edge Cases

- **No picker tool** → markdown numbered-list fallback (above); the choice is never dropped.
- **Consumer repo without this rule** → the chain skills' pointers degrade to their prior prose; the picker simply does not appear. The rule being vault-only is intentional, not a leak.
- **Two-step picks** — `Redo a previous phase` (A) and `Adjust per-finding` (C-drift) collect the *branch*; a follow-up free-text prompt collects the detail (which phase / walking findings).
- **Standalone phase invocation** (not under `sdd-lifecycle`) → the phase skill still presents its own archetype picker at its gate; archetype **B** is only meaningful post-plan and stays owned by `sdd-lifecycle`.

## Review Checklist

- [ ] Every gate choice in the four covered points is a picker (or its markdown fallback), never bespoke prose.
- [ ] Option sets match the archetype table verbatim; auto-"Other" not listed; each list is 2–4 options.
- [ ] C-drift is one batched picker and the audit produces a per-finding recommended disposition.
- [ ] No restatement of `sdd-lifecycle`'s stop or `phase-task-visualization`'s list — only cross-links.
- [ ] Gate-turn status is `IN PROGRESS`, not `BLOCKED`.
