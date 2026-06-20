---
name: subagent-driven-development
description: >-
  Use when an approved multi-task implementation plan exists and you want to
  execute it in the current session with isolated context and review gates per
  task — tasks are mostly independent and you would otherwise hold the whole
  plan in one context. Triggers on: "subagent-driven", "dispatch a subagent per
  task", "execute the plan with subagents", "fan out the tasks", "run the plan in
  parallel", "сабагент на задачу", "исполнить план сабагентами", "раскидать задачи
  по агентам".
---

# Subagent-Driven Development

Execute an approved plan by dispatching a **fresh subagent per task**, with a two-stage review after each: spec-compliance review first, then code-quality review.

**Why subagents:** you delegate each task to an agent with isolated context. You craft exactly the instructions and context it needs — it never inherits your session history — so it stays focused, and your own context stays free for coordination.

**Core principle:** fresh subagent per task + two-stage review (spec, then quality) = high quality, fast iteration.

**Continuous execution:** do not pause to check in between tasks. Execute every task in the plan without stopping. The only reasons to stop are a `BLOCKED` status you cannot resolve, an ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts waste the owner's time — they asked you to execute the plan, so execute it.

**Project-agnostic:** discover the repo's real test/build/commit commands, paths, and layout from the target repo — this skill names none. Each subagent writes code test-first via `test-driven-development`; this skill orchestrates, it does not replace the test discipline.

**Progress:** this is the chain's *implement* phase; its single task-list item is driven per [phase-task-visualization](../../../.claude/rules/common/phase-task-visualization.md). That phase item is distinct from the per-task ledger below — when a phase list already renders, keep the ledger in plan-file markers so the two don't collide.

## When to use

```dot
digraph when_to_use {
    "Approved multi-task plan exists?" [shape=diamond];
    "Tasks mostly independent?" [shape=diamond];
    "subagent-driven-development" [shape=box];
    "inline-driven-development (solo, sequential)" [shape=box];
    "writing-plans / test-driven-development" [shape=box];

    "Approved multi-task plan exists?" -> "Tasks mostly independent?" [label="yes"];
    "Approved multi-task plan exists?" -> "writing-plans / test-driven-development" [label="no"];
    "Tasks mostly independent?" -> "subagent-driven-development" [label="yes"];
    "Tasks mostly independent?" -> "inline-driven-development (solo, sequential)" [label="no — tightly coupled"];
}
```

- **Use** when the plan's tasks are mostly independent and each carries its own test cycle.
- **Prefer `inline-driven-development`** when tasks are tightly coupled (parallel-style dispatch would fight itself) or the change is small enough to hold solo.
- **Go back to `writing-plans`** (or `test-driven-development` for a single-behavior change) when there is no multi-task plan yet.

## The process

```dot
digraph process {
    rankdir=TB;

    "Read plan once; extract every task's full text + context; build a durable ledger" [shape=box];
    "More tasks remain?" [shape=diamond];
    "Dispatch implementer subagent (./assets/implementer-prompt.md)" [shape=box];
    "Implementer asks questions?" [shape=diamond];
    "Answer; provide context" [shape=box];
    "Implementer implements test-first, verifies, commits, self-reviews" [shape=box];
    "Dispatch spec reviewer (./assets/spec-reviewer-prompt.md)" [shape=box];
    "Spec compliant?" [shape=diamond];
    "Implementer fixes spec gaps" [shape=box];
    "Dispatch code-quality reviewer (./assets/code-quality-reviewer-prompt.md)" [shape=box];
    "Quality approved?" [shape=diamond];
    "Implementer fixes quality issues" [shape=box];
    "Mark task complete in the ledger" [shape=box];
    "Dispatch final reviewer over the whole change" [shape=box];
    "Hand off: spec-drift-audit, then propose the commit to the owner" [shape=box style=filled fillcolor=lightgreen];

    "Read plan once; extract every task's full text + context; build a durable ledger" -> "More tasks remain?";
    "More tasks remain?" -> "Dispatch implementer subagent (./assets/implementer-prompt.md)" [label="yes"];
    "Dispatch implementer subagent (./assets/implementer-prompt.md)" -> "Implementer asks questions?";
    "Implementer asks questions?" -> "Answer; provide context" [label="yes"];
    "Answer; provide context" -> "Dispatch implementer subagent (./assets/implementer-prompt.md)";
    "Implementer asks questions?" -> "Implementer implements test-first, verifies, commits, self-reviews" [label="no"];
    "Implementer implements test-first, verifies, commits, self-reviews" -> "Dispatch spec reviewer (./assets/spec-reviewer-prompt.md)";
    "Dispatch spec reviewer (./assets/spec-reviewer-prompt.md)" -> "Spec compliant?";
    "Spec compliant?" -> "Implementer fixes spec gaps" [label="no"];
    "Implementer fixes spec gaps" -> "Dispatch spec reviewer (./assets/spec-reviewer-prompt.md)" [label="re-review"];
    "Spec compliant?" -> "Dispatch code-quality reviewer (./assets/code-quality-reviewer-prompt.md)" [label="yes"];
    "Dispatch code-quality reviewer (./assets/code-quality-reviewer-prompt.md)" -> "Quality approved?";
    "Quality approved?" -> "Implementer fixes quality issues" [label="no"];
    "Implementer fixes quality issues" -> "Dispatch code-quality reviewer (./assets/code-quality-reviewer-prompt.md)" [label="re-review"];
    "Quality approved?" -> "Mark task complete in the ledger" [label="yes"];
    "Mark task complete in the ledger" -> "More tasks remain?";
    "More tasks remain?" -> "Dispatch final reviewer over the whole change" [label="no"];
    "Dispatch final reviewer over the whole change" -> "Hand off: spec-drift-audit, then propose the commit to the owner";
}
```

## The durable ledger

A plan has more tasks than survive one context window. Before dispatching anything, write a **ledger** that outlives a context reset: the task list with a status per task (`pending` / `in_progress` / `done`), plus the one fact each later task needs from an earlier one (a signature, a path). Use your runtime's todo mechanism and/or progress markers in the plan file — never a per-user memory store. After a reset, trust the ledger over memory: re-read it, re-establish the baseline (re-run the suite), and resume at the first non-`done` task.

## Model selection

Use the least powerful model that can do each role — turn count matters more than per-token price, so a model that needs 2–3× the turns can cost more overall.

- **Mechanical task** (1–2 files, complete spec) → a fast, cheap model. Most well-specified tasks are mechanical.
- **Integration / judgment task** (multi-file, pattern-matching, debugging) → a standard model.
- **Architecture / design / any review** → the most capable model. The final whole-change review always uses maximum capability.

Signal: touches 1–2 files with a full spec → cheap; multiple files with integration concern → standard; needs design judgment or broad understanding → most capable.

## Handling implementer status

Implementers report one of four statuses:

- **DONE** → proceed to spec-compliance review.
- **DONE_WITH_CONCERNS** → read the concerns first. Correctness/scope doubts: resolve before review. Mere observations ("this file is getting large"): note and proceed.
- **NEEDS_CONTEXT** → provide the missing context, re-dispatch.
- **BLOCKED** → assess: context problem → add context, re-dispatch same model; needs more reasoning → re-dispatch a more capable model; task too large → split it; plan itself is wrong → escalate to the owner.

**Never** ignore an escalation or force the same model to retry unchanged. If the implementer is stuck, something must change.

## Prompt templates

- [./assets/implementer-prompt.md](./assets/implementer-prompt.md) — dispatch the implementer subagent.
- [./assets/spec-reviewer-prompt.md](./assets/spec-reviewer-prompt.md) — dispatch the spec-compliance reviewer.
- [./assets/code-quality-reviewer-prompt.md](./assets/code-quality-reviewer-prompt.md) — dispatch the code-quality reviewer.

Hand subagents large artifacts as **files**, not pasted blobs: give the task's full text in the prompt (don't make the subagent re-read the plan), and pass diffs to reviewers as file references.

## Red flags — STOP

- Start implementation on the main/default branch without explicit owner consent.
- Skip a review (spec compliance OR code quality), or run code-quality review before spec compliance is clean (wrong order).
- Move to the next task while either review has an open issue.
- Dispatch multiple implementer subagents in parallel for the same workspace (they collide — isolate per task if you must, e.g. a worktree).
- Make a subagent read the plan file instead of giving it the task's full text.
- Accept "close enough" on spec compliance, or let an implementer's self-review replace an actual reviewer.
- Skip the re-review after a fix, or fix a subagent's work yourself (context pollution — dispatch a fix subagent instead).

## Integration

- **Upstream:** `writing-plans` produces the plan this skill executes; `pre-implementation-protocol` runs the readiness check and routes here when the owner picks subagent-driven execution.
- **Inside each task:** subagents write code via `test-driven-development` (RED → GREEN → REFACTOR per behavior).
- **Downstream:** after the final review, run `spec-drift-audit` over the whole change, then propose the commit to the owner (the human owns the commit).
- **Alternative:** `inline-driven-development` for solo, sequential, in-session execution when tasks are coupled or the change is small.
