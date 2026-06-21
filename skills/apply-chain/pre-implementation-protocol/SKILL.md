---
name: pre-implementation-protocol
description: >-
  Use at the plan-to-implementation boundary, right before the first edit of a
  planned change — when an approved plan or spec is about to be executed, or
  when asked to start coding a change that has no plan yet. Triggers on: "start
  the work", "start coding", "begin implementation", "execute the plan", "kick
  off the task", "ready to implement", "погнали кодить", "приступить к
  реализации", "начать работу по плану".
---

# Pre-Implementation Protocol

The output of this skill is a single **Readiness block**, emitted in the response before the first `Edit`/`Write` of the change, then a hand-off to execution. It exists so the move from a written plan into code has one consistent shape every time — not a different ad-hoc reaction per run.

Reading code, running `grep`, opening files is expected at this step — that is how the slots below get filled with verified facts rather than assumptions.

Project-agnostic: discover the real commands, paths, and test syntax from the target repo. The signatures and commands shown below are **illustrative** — copy the consumer repo's actual ones.

**Progress:** before emitting the Readiness block, reflect this phase in the task list per [phase-task-visualization](../../../.claude/rules/common/phase-task-visualization.md) — under `sdd-lifecycle` update the existing item; run standalone, seed a single item for this phase.

## The observable fork

Fill the block for the path that matches what is on disk:

- **An approved plan or spec for this change exists** → PATH A.
- **No plan and no spec — just a request to build something** → PATH B.

## PATH A — a plan/spec exists (the common case)

Emit the Readiness block with these five slots, in this order:

1. **Plan & spec** — the path(s) to the plan and the spec it consumes; one line confirming the plan is approved.
2. **Contracts** — the exact signatures, types, and data shapes the *first* task consumes and produces, copied from the spec. Tag **every** symbol with exactly one of three: `EXISTS` (located in the repo by a read/grep — cite the path), `NEW` (the plan creates it), or `UNVERIFIED` (the spec references it but you have not located it yet — resolve by a read before coding it). The tag set is exhaustive: an untagged symbol means the slot is unfinished. Example (illustrative): `validateCoupon(c: Coupon, now: Date): Result<void, CouponError>` — `Result` EXISTS (`src/shared/result.ts`), `CouponError` NEW, `Coupon` UNVERIFIED.
3. **Verification** — the exact test / build / lint commands, taken from the repo's own config (not invented), plus one line on the baseline: the suite is green right now, *or* the pre-existing failures are named and isolated so your first RED is attributable to you.
4. **Execution** — name the chosen flow (`inline-driven-development` solo, or `subagent-driven-development` for mostly-independent tasks); task-by-task, test-first, commit after each green.
5. **Go / No-go** — `GO` only if none of these No-go conditions fire; otherwise name the blocker(s): the plan is not approved (slot 1), the baseline is neither green nor isolated (slot 3), the first task *consumes* an `UNVERIFIED` contract (slot 2), or the plan leaves a truncated task / missing type / undefined field. An `UNVERIFIED` contract the first task only *produces* is not a blocker — resolve it at its first read.

Then hand off to execution.

## PATH B — no plan, no spec

The block is a routing decision plus a minimal pre-flight:

1. **Request** — restate it in one line with its success condition. If your restatement is wider than the request, you are about to over-build; if narrower, under-build — flag which.
2. **Route** — apply the small-change predicate: a change stays on PATH B (small) only when it is a single cohesive behavior, touches no shared/public contract, adds no new surface, spans no multiple components/services, and fits one test-first cycle (a source file plus its own test is one cycle, not "multi-file"). If it crosses any of those — a shared contract, a new surface, or multiple components/clients/services — the readiness verdict is "no plan exists; routing to the chain" → go to `grilling` → `writing-specs` → `writing-plans`, and stop here.
3. **Minimal pre-flight** — only if the change is genuinely small and local: a layer map (`file:line` — `NONE`/`PARTIAL`/`FULL`), the contracts written as code, and the real verification commands. Then execute via `test-driven-development` (single-behavior, test-first).

## Output format

A short block in the response, before any code-editing tool call:

```text
Readiness — PATH A:
1. Plan/spec: <plan path> (approved) ← <spec path>
2. Contracts (task 1): <signature> — <EXISTS path | NEW | UNVERIFIED>
3. Verification: <exact commands>; baseline: <green | failures isolated: ...>
4. Execution: <chosen flow: inline-/subagent-driven-development>; task-by-task, test-first, commit per green
5. Go/No-go: <GO, or blocker(s): not-approved | baseline | UNVERIFIED consumed | plan gap>
```

```text
Readiness — PATH B:
1. Request: <restatement + success condition> (<same/wider/narrower> than asked)
2. Route: <chain skill to enter, and stop> | minimal pre-flight below
3. Pre-flight: layers <list>; contracts <code>; verification <commands>
```

After the block, hand off.

## Hand-off

- **Upstream:** the plan comes from `writing-plans` (which produces it from a `writing-specs` spec).
- **Downstream — REQUIRED SUB-SKILL:** execute via the chosen flow — `inline-driven-development` (solo, in-session) or `subagent-driven-development` (fresh subagent per task); a no-plan single-behavior change goes straight to `test-driven-development`. Each writes code test-first, one task at a time, RED → GREEN → REFACTOR per behavior. This skill produces the readiness block; the execution flow writes the code.
- **Gate presentation:** present the readiness verdict as archetype **C-readiness** per [interactive-gates](../../../.claude/rules/common/interactive-gates.md) — `Proceed` (begin implementation) vs `Not ready` (list gaps, return to the plan) — before handing to the execution flow.

## Slot checklist

- [ ] Picked the path from what is actually on disk (plan/spec exists → A, else B).
- [ ] PATH A: all five slots filled; every contract tagged exactly one of `EXISTS` (verified) / `NEW` / `UNVERIFIED` — none left untagged.
- [ ] Verification commands came from the repo's config, not memory; baseline green or pre-existing failures named and isolated.
- [ ] Go/No-go is `GO` only when no No-go condition fires (approved, baseline accounted for, no `UNVERIFIED` contract consumed by task 1, no plan gap).
- [ ] PATH B: non-trivial change routed back to the chain rather than coded ad-hoc.
- [ ] Block emitted before the first code edit; execution handed to the chosen flow (`inline-driven-development` / `subagent-driven-development`, or `test-driven-development` for a no-plan single-behavior change).
