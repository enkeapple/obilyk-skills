---
name: inline-driven-development
description: >-
  Use when executing an approved implementation plan yourself, solo, in the
  current session — no subagent dispatch — because the tasks are tightly coupled
  or the plan is small enough to hold in one context. Triggers on: "inline
  execution", "execute the plan myself", "run the plan solo", "execute it in this
  session", "no subagents", "исполнить план соло", "выполнить план сам", "без
  сабагентов", "пройти план по шагам".
---

# Inline-Driven Development

Execute an approved plan **yourself, task by task, in this session**: review the plan critically first, then for each task verify and commit before moving on, and stop the moment something fails or is unclear.

**Core principle:** your default pull is forward momentum — and every failure mode here comes from it. Batching tasks, testing at the end, guessing past a failure, and keeping progress in your head all feel faster and all cost more. This skill holds the line against momentum.

**Project-agnostic:** discover the repo's real test/build/commit commands and paths from the target repo — this skill names none. Each task's code is written test-first via `test-driven-development`; this skill governs *order and cadence*, not the test discipline itself.

**Progress:** this is the chain's *implement* phase; its single task-list item is driven per [phase-task-visualization](../../../.claude/rules/common/phase-task-visualization.md), which also owns how that phase item and the per-task ledger below coexist without colliding.

## When to use

- An approved plan exists and you are executing it solo in this session.
- Tasks are tightly coupled (parallel dispatch would fight itself), or the plan is small enough to hold in one context.
- **Prefer `subagent-driven-development`** instead when tasks are mostly independent and you want isolated context + review gates per task.
- **No plan yet?** A single-behavior change → `test-driven-development`. A multi-step feature → `writing-plans` first.

## The process

### 1. Load and review the plan — critically

Read the whole plan before touching anything, as an adversary, not for comprehension. "Approved" is not "correct": validate that the file paths exist, that no step contradicts another, and that the task order has no hidden dependency. Surface any gap to the owner **before** starting task 1 — a plan bug found now is cheap; found mid-execution it is a tangle.

### 2. Execute one task at a time

For each task, in order:

1. Mark it `in_progress` in the ledger (below).
2. Follow its steps exactly, test-first (`test-driven-development`): failing test → watch it fail → minimal code → green.
3. **Verify before moving on:** run the repo's real test/build command and read the actual output. Pristine green, not "should pass". One task's failure stays localized to that task — that is the whole point of per-task cadence.
4. **Commit this task** using the repo's conventions, then mark it `done`. Per-task commits give you clean history and a resume point.

Do not batch: do not write task 2 before task 1 is verified and committed.

### 3. Complete

After the last task: full suite green, then run `spec-drift-audit` over the whole change, and propose the commit(s) to the owner — the human owns the commit.

## The durable ledger

Progress kept in your head does not survive a context reset. Maintain an on-disk ledger as you go — your runtime's todo mechanism and/or status markers in the plan file (`pending` / `in_progress` / `done` per task), plus per-task commits as natural resume points. Never a per-user memory store. After a reset: re-read the ledger, re-run the suite to re-establish the baseline, resume at the first non-`done` task.

## When to STOP (do not push through)

Stop the instant any of these happen — diagnose the root cause, ask if it is genuinely ambiguous, do **not** guess forward:

- A step's command fails or a test won't go green.
- An instruction is unclear or a path/name in the plan doesn't exist.
- A step contradicts what you found in the code.
- Verification fails repeatedly.

A failing test tempts you to tweak until green — that is guessing, not fixing. Understand *why* it failed first. If the plan itself is wrong, return to the plan with the owner; don't patch around it.

## Momentum traps

| Your pull | What it costs | Do instead |
| --- | --- | --- |
| "Read the plan, looks fine, start." | Plan bugs surface mid-execution as a tangle. | Review the plan adversarially first; validate paths/order. |
| "I'm in flow — write 2, 3, 4, test at the end." | A failure at the end spans five tasks; you debug a knot. | Verify after each task; localize failures. |
| "It compiles / the file exists — done." | Weak evidence hides real breakage. | Run the suite per task; read the actual output. |
| "I'll commit once at the end." | No clean history, no resume point. | Commit per task. |
| "This is probably what they meant — keep going." | Compounding guesses drift far from intent. | Stop; ask when genuinely ambiguous. |
| "I'll remember where I am." | A context reset loses all state. | Durable on-disk ledger + per-task commits. |

## Red flags — STOP

- You've written more than one task without running the suite.
- You're tweaking code to make a test pass without knowing why it failed.
- You're picking the interpretation that "keeps you moving" past an ambiguity.
- You started on the main/default branch without explicit owner consent.
- Nothing on disk would tell a fresh session how far you've gotten.

## Integration

- **Upstream:** `writing-plans` produces the plan; `pre-implementation-protocol` runs the readiness check and routes here when the owner picks solo, in-session execution.
- **Inside each task:** `test-driven-development` (RED → GREEN → REFACTOR per behavior).
- **Downstream:** `spec-drift-audit` over the whole change, then propose the commit to the owner.
- **Alternative:** `subagent-driven-development` for fresh-subagent-per-task execution with review gates when tasks are independent.
