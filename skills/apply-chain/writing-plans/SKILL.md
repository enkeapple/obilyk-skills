---
name: writing-plans
description: >-
  Use when you have an approved spec or written requirements for a multi-step
  task and are about to implement, or when handing work to another engineer or
  a subagent to execute task-by-task. Triggers on: "write a plan", "break this
  into tasks", "implementation plan", "plan this out".
---

# Writing Plans

Write a comprehensive implementation plan assuming the engineer executing it has zero context for this codebase and questionable taste. They are a skilled developer but know almost nothing about your toolset or domain, and they may read tasks out of order. Document everything they need: which files to touch, the actual code, the exact commands, how to test it.

**Core contract: every code step shows the actual code, every task is test-first, and the plan commits after each passing test.** A step that describes what to do without showing how is not a plan step — it is a wish. If a step changes code, the code is in the step.

This consumes a spec written via the **writing-specs** skill. Project-agnostic: discover real commands, paths, and test syntax from the repo; copy the spec's contracts and constraints verbatim.

**Progress:** before your first artifact, reflect this phase in the task list per [phase-task-visualization](../../../.claude/rules/common/phase-task-visualization.md) — under `sdd-lifecycle` update the existing item; run standalone, seed a single item for this phase.

## When to use

- You have an approved spec/requirements and are about to write implementation code.
- You are handing work to another engineer or a subagent to execute without you present.

## When NOT to use

- A one-step change with no decomposition (just do it).
- There is no spec yet — write the spec first (writing-specs), then plan.

## Plan location

Default to `docs/plans/YYYY-MM-DD-<feature>.md` if the project has no convention. User preference overrides.

## Process

1. **Scope check.** If the spec spans multiple independent subsystems, split into one plan per subsystem — each must produce working, testable software on its own.
2. **Map files first.** Before defining tasks, list every file to create/modify and its single responsibility. Files that change together live together; prefer small, focused files. In an existing codebase, follow established patterns — don't unilaterally restructure.
3. **Right-size tasks.** A task is the smallest unit that carries its own test cycle and is worth a fresh reviewer's gate. Fold setup/config/scaffolding/docs into the task whose deliverable needs them; split only where a reviewer could reject one task while approving its neighbor. Each task ends with an independently testable deliverable.
4. **Write each task** to the recipe below.
5. **Self-review** (checklist below), fix inline, save.

## Plan header (start every plan with this)

```markdown
# <Feature> Implementation Plan

**Goal:** <one sentence>
**Architecture:** <2-3 sentences on the approach>
**Tech stack:** <key technologies>

## Global constraints
<Project-wide requirements copied verbatim from the spec — version floors,
dependency limits, naming/copy rules, platform requirements. One line each.
Every task implicitly includes these.>
```

## Task recipe (the contract for every task)

Each task has, in order: **Files**, **Interfaces**, then **checkbox steps** where every code step contains real code and every command step shows the exact command + expected output. The full template and a filled example are in [references/plan-template.md](references/plan-template.md).

A task's steps follow the test-first cycle, each step one action (2–5 min):

1. Write the failing test (real test code).
2. Run it, confirm it fails (exact command + expected failure).
3. Write the minimal implementation (real code).
4. Run the test, confirm it passes (exact command + expected output).
5. Commit (exact `git` command).

The **Interfaces** block is how out-of-order readers learn neighboring tasks' names and types:

- **Consumes:** exact signatures this task uses from earlier tasks.
- **Produces:** exact function names, parameter and return types later tasks rely on.

## These are plan failures (the recipe above prevents them)

The baseline failure is not lazy "TODO" markers — it is *describing instead of showing*. Each of these means the step is not done:

- A code step with prose instead of a code block ("pass the cursor to the data source", "add validation", "handle edge cases").
- A test referenced but not written out ("write tests for the above").
- "Similar to Task N" — repeat the code; the reader may not have seen Task N.
- A type / function / command named but never defined or shown in any task.
- "Find the command in package.json" — look it up now and write the exact command.

## Two-layer review — self first, then an independent cold pass

The two layers catch **different** defect classes; keep their remits disjoint per [scoping-skill-value](../../../.claude/rules/common/scoping-skill-value.md) (Two-layer review variant).

### Self-review (author pass — cheap, every time)

Mechanical checks against the plan **text itself**, with the context you already hold:

1. **Show-don't-describe scan:** every code step has a code block; every command step has the exact command + expected output; every task has a commit step.
2. **Type consistency:** the names/signatures used in later tasks match what earlier tasks produced (a `clearLayers()` in Task 3 vs `clearFullLayers()` in Task 7 is a bug).

### Independent cold reviewer (the author-blind pass)

For anything beyond a small plan, dispatch an **independent reviewer — a fresh subagent with zero shared context, handed the spec** — using [references/plan-reviewer-prompt.md](references/plan-reviewer-prompt.md). Its remit is what you cannot judge from inside your own context, so it is **not** a re-run of the scan above:

- **Spec coverage, re-derived:** it reads the spec independently and checks each requirement maps to a task — you *believe* you covered it; it verifies you did. A gap you can't see is one you didn't know you left.
- **Zero-context buildability:** could an engineer with no context follow this task-by-task, possibly out of order, without getting stuck or guessing? You hold the context, so you cannot feel its absence — only a cold reader can.

Fix issues and re-review.

## Execution handoff

After saving, the plan is ready to execute. Before the first code edit, run the `pre-implementation-protocol` readiness check on the plan (it confirms the contracts, real verification commands, and a green baseline, then routes to the chosen execution flow). Offer the owner an execution choice, keyed to whether the tasks are independent:

- **`subagent-driven-development` (recommended for mostly-independent tasks):** a fresh subagent per task, with two-stage review between tasks.
- **`inline-driven-development` (tightly-coupled tasks, or a small plan you hold solo):** execute task-by-task yourself in this session, verifying and committing per task.

> REQUIRED SUB-SKILL: whichever flow, each task's code is written test-first via `test-driven-development` — the choice decides *who* runs the tasks and *how*, not *whether* they are test-first. One task at a time; commit after each passing test.

## Red Flags — if you catch yourself here, STOP

Fast trip-wires; the fix for each is in **plan failures** above (coarse tasks → right-size, Process step 3).

- A step that shows no code block.
- A test referenced but not written out.
- A name used in a later task that no earlier task defined.
- Coarse-bucket tasks ("build the API") with no test-first steps.
- "I'll fill in the code during implementation."
