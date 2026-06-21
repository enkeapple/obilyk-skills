---
description: >-
  Render the SDD phases as ONE harness task list (the runtime's task create/update
  tooling): exactly one item in_progress, an item turns completed ONLY on the user's
  explicit approval of that phase's artifact (it mirrors the chain's approval gate),
  and a skipped phase is shown-and-marked, never dropped. A full gated run seeds the
  whole canonical phase set; a standalone phase seeds/updates only its own item —
  never a second, competing list. Owns the list's status discipline only, not the
  phase set itself. Loaded on demand by the SDD phase work that links it (no path
  trigger). Vault-only; not shipped to consumers.
---

# Phase Task Visualization

## When

You are running any SDD-chain phase — either the full gated run driven by the chain orchestrator, or a single phase on its own. Apply this before producing the phase's first artifact, so the user sees a stable, gate-honest progress list — the active phase highlighted (`in_progress`), the rest pending.

Do NOT apply it to a one-line/cosmetic change made directly (no chain), or to non-SDD work.

## Why

A capable agent already reaches for a task list on a multi-phase run, so making the list is a no-op. The value is **convergence**: without a fixed shape the list drifts every run (a different item count from one run to the next; ad-hoc labels; `completed` flipped on "phase done" instead of on approval). Standalone phase invocations show the opposite failure — no item at all. One create-or-update rule plus one status-to-approval binding fixes both and keeps the visual honest about the approval gate.

This rule owns the **status discipline of the list**, not the phase set: which phases exist and how they are labelled is defined by whatever drives the run (the orchestrator for a full run, the single phase for a standalone). Delete every reference to a specific phase and this rule still applies unchanged — that is the point.

## Implementation

### Status semantics — bind completed to the approval gate

- **Exactly one `in_progress`** at any time — the phase you are actively in (the highlighted item).
- **`completed` ONLY on the user's explicit approval of that phase's artifact** — never on "the artifact is produced" or "the phase ran". Producing an artifact is not completing its item; the user approving it is. This makes the list a faithful mirror of the approval gate, not a progress counter that runs ahead of it.
- **A skipped phase stays in the list, marked skipped** (e.g. an entry phase whose input is absent, or an explicit `skip <phase>` control). Resolve its item as skipped with a one-word note — your runtime's `cancelled`/closed status, or `completed` annotated `(skipped: <reason>)`. **Never silently omit a row** — a shortened list hides which phase was bypassed.
- On a `redo <phase>`, flip that item back to `in_progress` and the later items to `pending`.

### Create-or-update — one list, never two

Before touching the list, check whether a phase task list **already exists this session**:

- **It exists** → the orchestrator is driving. Do NOT create another. Set your phase's existing item to `in_progress`; on approval, `completed`.
- **It does not exist** → create one:
  - A **full gated run** seeds the **whole canonical phase set** (entry phases ahead of the classified start marked skipped).
  - A **standalone** phase seeds **only its own one item** — it is not orchestrating the chain, so it must not fabricate the others.

```text
❌ WRONG — a phase running under the orchestrator calls task-create fresh.
   Now two lists compete; one shows a single in_progress item, the other re-lists
   the whole chain. Or: the orchestrator's list drops an entry phase (a shorter list),
   and an item flips to `completed` the moment the draft is written.

✅ CORRECT — the orchestrator seeded the canonical set (a bypassed entry phase marked
   skipped). A phase under it finds the list, sets its item `in_progress`, produces the
   artifact, STOPS; the item → `completed` only after the user approves it. Run standalone
   instead, the phase seeds ONE item and updates that.
```

## Edge Cases

- **No task tooling in the runtime** → skip silently; this rule shapes the list when one is rendered, it does not mandate a tool that is absent.
- **A single-behavior test-first change outside the chain** is not a phase — no list (one RED→GREEN loop is not a pipeline).
- **The execution phase keeps its own per-task ledger** — a separate, finer-grained concern from this phase list. When a phase list already occupies the harness task list, keep that per-task ledger in plan-file markers so the two never collide; the execution phase's single item is driven like any other.
- This rule owns only the **visual + its status-to-approval binding**. The approval gate itself and the concrete phase set are owned elsewhere (the chain orchestrator); this rule is fully applicable without them — do not restate either here.

## Review Checklist

- [ ] Exactly one item `in_progress`; no item `completed` without the user's explicit approval of its artifact.
- [ ] A bypassed entry phase is present and marked skipped — the list is never silently shortened.
- [ ] Exactly one list exists — a phase under the orchestrator updated the existing list rather than creating a second.
- [ ] A standalone phase seeded only its own item, not the whole chain.
- [ ] No specific phase/skill name is load-bearing: deleting it leaves the rule applicable.
