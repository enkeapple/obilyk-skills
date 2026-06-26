---
name: sdd-lifecycle
description: >-
  Use when the user wants the full spec-driven pipeline run end-to-end on a
  feature or change — an explicit "run the lifecycle / the whole workflow",
  "kick off the pipeline", "do the full SDD flow for X". The active front door
  that classifies where the work enters the chain and drives it phase by phase.
  Triggers on: "lifecycle", "run the workflow", "start the sdd flow", "kick off
  the pipeline", "full pipeline", "the whole flow", "запусти воркфлоу", "прогон по
  циклу", "весь цикл", "начать цикл".
---

# SDD Lifecycle

The active front door for the spec-driven pipeline. On a build request, classify where it enters the chain, then drive the chain **one phase at a time, stopping for the user's explicit approval after every phase**.

This skill owns the **cross-phase gate, the entry classification, and the controls**. It routes into the phase skills and never restates their work; it names no stack, path, or command.

**What it adds is the gate, not the order.** The phase order is already forced by each skill's own hand-offs. What this skill adds is the **stop between phases: advance only on the user's explicit approval of the phase you just finished.** A design sign-off is NOT blanket approval for the spec, the plan, or "start coding" — each artifact is approved on its own.

## When to use / when not

- Use when the user wants the whole gated pipeline run on a non-trivial change.
- A bare "build X" with no lifecycle request enters the chain at `grilling` directly — invoke this skill only when the user wants the full orchestrated, gated run.
- **Do NOT run the pipeline for a one-line or cosmetic change** — the overhead is wrong-sized; make the change directly (still test-first).

## Entry classification (where the chain starts)

Route the input to its entry phase, then gate from there:

| Input on the table | Enters at |
| --- | --- |
| A ticket ID or URL | `resolving-requirements` |
| A fuzzy idea / "I want to add X" | `grilling` |
| An approved design, no spec yet | `writing-specs` |
| A half-done feature (code, no current spec) | `writing-specs` (reverse-engineer the spec) |
| A spec exists, no plan | `writing-plans` |
| An approved plan | `pre-implementation-protocol` |

(`spec-drift-audit` is not an entry — it is the terminal verify phase (see The phases). A standalone audit of already-shipped code *outside* a full run invokes `spec-drift-audit` directly.)

## The phases

`resolving-requirements → grilling → writing-specs → writing-plans → pre-implementation-protocol → (inline-driven-development \| subagent-driven-development) → writing-adrs (optional) → spec-drift-audit`. Each phase produces one artifact and hands to the next; invoke the phase skill — do not re-derive its work here. Two phases are special:

- **`writing-adrs` is an optional gate** (item 7), not a core artifact — after implementation, before verify, it asks whether the build made an architectural decision worth recording. Frequently skipped, never blocks the chain. See "Optional ADR gate".
- **`spec-drift-audit` closes the chain** — the verify phase: after implementation (and the optional ADR gate) and before the commit, it checks shipped code against the approved spec. Terminal, never an entry into a build; the human owns the commit.

## Progress list

Before the first phase, seed a single harness task list with these **canonical phase items**, in order — entry phases ahead of the classified start marked skipped, never dropped. Item 7 is the optional ADR gate (skipped when no decision qualifies):

```text
1. Resolve requirements (resolving-requirements)
2. Grill into a design (grilling)
3. Write the spec (writing-specs)
4. Write the plan (writing-plans)
5. Readiness check (pre-implementation-protocol)
6. Implement test-first (inline-/subagent-driven-development)
7. Record architectural decisions — optional (writing-adrs)
8. Audit against the spec (spec-drift-audit)
```

Then drive its statuses as you advance. The status discipline — exactly one `in_progress`, the create-or-update logic, and the binding of `completed` to the user's explicit approval — holds here: keep one shared create-or-update list, never a second competing one. An item turns `completed` only when the user approves that phase's artifact, so the list mirrors the gate below rather than running ahead of it.

## The gate — the load-bearing rule

After each phase: **present its artifact, then STOP.** Advance to the next phase only on the user's explicit approval of *that* artifact. Never auto-advance — not when confident, not because the previous phase was approved, not because the next phase is "just an elaboration". One approval unlocks exactly one phase. Present that approval choice as archetype A — a picker of labeled options-with-descriptions (numbered markdown-list fallback when no picker tool exists): `Approve` (advance to the next phase), `Request changes` (revise this same artifact — the user says what), `Redo a previous phase` (a defect upstream — name the phase and return to rework it).

If a later phase reveals an earlier artifact is wrong, **loop back**: return to that phase, fix it, and re-advance with fresh approval — do not patch forward.

## Controls

- **`skip <phase>`** — its artifact already exists on disk; verify it is current, then start at the next phase.
- **`from <phase>`** — begin mid-chain (e.g. a plan is ready → `from pre-implementation-protocol`).
- **`redo <phase>`** — a later phase exposed a defect upstream; return, fix, re-advance from there.

## Execution-mode fork

After the plan is approved and before execution, present the inline-vs-subagent choice as archetype **B** (a picker of labeled options; markdown-list fallback): `inline-driven-development` (coupled tasks / small plan) vs `subagent-driven-development` (independent tasks). This is a presentation point only — the chosen flow owns the execution.

## Optional ADR gate (before verify)

After implementation is approved and **before** `spec-drift-audit`, check whether the build made an **architectural decision worth recording**. Invoke `writing-adrs`; it applies its own Gate (hard to reverse + surprising without context + a genuine trade-off).

Present the call as a picker (numbered-list fallback when no picker tool) and **argue the recommendation explicitly, either way**: `Record ADR` — *"this decision qualifies because it is hard to reverse / surprising without context / a real trade-off"* (name the tests it passes) — vs `Skip` — *"nothing here qualifies: reversible, unsurprising, no weighed alternative"*. The user owns the choice: **never record silently and never skip silently** — state the argument before the pick. A skipped gate stays listed, marked skipped; recording hands off to `writing-adrs` for the ADR(s) + index. Either way, advance to verify.

## Rationalizations

| Excuse | Reality |
| --- | --- |
| "The design was approved — that covers the spec and plan too." | Each artifact is approved on its own. Design sign-off is not blanket consent. |
| "I'm confident; advancing saves a round-trip." | The user owns each artifact. Confidence is not consent. |
| "The spec/plan are just elaborations of the approved design." | Elaboration is exactly where scope silently drifts — that is what the gate catches. |
| "It's faster to run the chain end-to-end." | A wrong spec caught at its gate is cheap; caught after code it is a rewrite. |
| "The order is obvious, so I don't need to stop." | The order being obvious is *why* this skill isn't about order — it's about the stop. |

## Red Flags — STOP

- Advancing to the next phase without an explicit approval of the current artifact.
- Treating the design sign-off as approval for the spec, the plan, or starting code.
- Running the full pipeline for a one-line / cosmetic change.
- Restating a phase skill's internals instead of invoking it.
- Auto-advancing "because the chain order is obvious".
- Reaching `spec-drift-audit` without the optional ADR gate — recording an ADR silently, or skipping it without arguing the call.
