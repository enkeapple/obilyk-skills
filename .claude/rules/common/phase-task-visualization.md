---
description: >-
  Render SDD phases as ONE harness task list (TaskCreate/TaskUpdate): the
  canonical 7-phase label set, exactly one item in_progress, an item turns
  completed ONLY on the user's explicit approval of that phase's artifact (it
  binds to the sdd-lifecycle gate), and a skipped entry phase is shown-and-marked,
  never dropped. sdd-lifecycle seeds all 7; a standalone phase invocation
  seeds/updates only its own item — never a second, competing list.
---

# Phase Task Visualization

## When

You are running any SDD-chain phase skill — either the full gated run via `sdd-lifecycle`, or one phase skill on its own (`resolving-requirements`, `grilling`, `writing-specs`, `writing-plans`, `pre-implementation-protocol`, `inline-driven-development`/`subagent-driven-development`, `spec-drift-audit`). Apply this before producing the phase's first artifact, so the user sees a stable, gate-honest progress list — the active phase highlighted (`in_progress`), the rest pending.

Do NOT apply it to a one-line/cosmetic change made directly (no chain), or to non-SDD work.

## Why

A capable agent already reaches for a task list on a multi-phase run, so the value here is NOT "make a list" (that is a no-op) — it is **convergence**: without a fixed shape the list drifts every run (6 items one run dropping `resolving-requirements`, 7 another; ad-hoc labels; `completed` flipped on "phase done" instead of on approval). Standalone phase invocations show the opposite failure — no item at all. One canonical shape + one create-or-update rule fixes both and keeps the visual honest about the approval gate.

## Implementation

### The canonical 7-phase label set

Use these exact item labels, in this order — every run, so the list is recognizable across sessions:

```text
1. Resolve requirements (resolving-requirements)
2. Grill into a design (grilling)
3. Write the spec (writing-specs)
4. Write the plan (writing-plans)
5. Readiness check (pre-implementation-protocol)
6. Implement test-first (inline-/subagent-driven-development)
7. Audit against the spec (spec-drift-audit)
```

### Status semantics — bind completed to the approval gate

- **Exactly one `in_progress`** at any time — the phase you are actively in (the highlighted/orange item).
- **`completed` ONLY on the user's explicit approval of that phase's artifact** — never on "the artifact is produced" or "the phase ran". Producing the spec is not completing the spec item; the user approving it is. This makes the list a faithful mirror of the `sdd-lifecycle` gate, not a progress counter that runs ahead of it.
- **A skipped entry phase stays in the list, marked skipped** (e.g. `resolving-requirements` when the input is a free-text idea, or a `skip <phase>` control). Resolve its item as skipped with a one-word note — your runtime's `cancelled`/closed status, or `completed` annotated `(skipped: no ticket)`. **Never silently omit a row** — a 6-item list hides which phase was bypassed.
- On a `redo <phase>`, flip that item back to `in_progress` and the later items to `pending`.

### Create-or-update — one list, never two

Before touching the list, check whether a phase task list **already exists this session**:

- **It exists** → `sdd-lifecycle` is driving. Do NOT create another. Set your phase's existing item to `in_progress`; on approval, `completed`.
- **It does not exist** → create one:
  - `sdd-lifecycle` seeds **all 7** items (entry phases ahead of the classified start are marked skipped).
  - A **standalone** phase skill seeds **only its own one item** — it is not orchestrating the chain, so it must not fabricate the other six.

```text
❌ WRONG — writing-specs runs under sdd-lifecycle and calls TaskCreate fresh.
   Now two lists compete; one says "Write the spec [in_progress]", the other
   re-lists all 7. Or: the lifecycle list drops `resolving-requirements` (6 items),
   and the spec item flips to `completed` the moment the draft is written.

✅ CORRECT — sdd-lifecycle seeded the canonical 7 (resolving-requirements marked
   skipped, no ticket). writing-specs finds the list, sets item 3 `in_progress`,
   produces the spec, STOPS; item 3 → `completed` only after the user approves it.
   Run standalone instead, writing-specs seeds ONE item ("Write the spec
   (writing-specs)") and updates that.
```

## Edge Cases

- **No task tooling in the runtime** → skip silently; this rule shapes the list when one is rendered, it does not mandate a tool that is absent.
- **Single-behavior `test-driven-development`** outside the chain is not a phase — no list (one RED→GREEN loop is not a pipeline).
- **The execution phase (`inline-`/`subagent-driven-development`) keeps its own per-task ledger** — a separate, finer-grained concern from this phase list. When a phase list already occupies the harness task list, keep that per-task ledger in plan-file markers so the two never collide; the execution phase's single item (`Implement test-first`) is driven like any other.
- This rule owns only the **visual + its status-to-approval binding**. The approval gate itself is owned by `sdd-lifecycle`; the per-phase work is owned by each phase skill. Do not restate either here.

## Review Checklist

- [ ] Item labels match the canonical 7 set verbatim and in order (or, standalone, the one matching item).
- [ ] Exactly one item `in_progress`; no item `completed` without the user's explicit approval of its artifact.
- [ ] A bypassed entry phase is present and marked skipped — the list is never silently shortened.
- [ ] Exactly one list exists — a phase under `sdd-lifecycle` updated the existing list rather than creating a second.
- [ ] A standalone phase seeded only its own item, not the whole chain.
