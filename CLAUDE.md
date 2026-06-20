# SDD Workflow Vault — Claude entry point

A **vault for developing an agnostic Spec-Driven-Development (SDD) skill framework**. The product is not an app — it is the skills themselves and *how they interact*. The goal is a flexible system that surfaces its own bottlenecks (a misfiring skill, a leaky hand-off, an over-rigid step), which become lessons → rules → skill edits.

## How to work here (read first)

Authoring or changing a skill runs through **RED → GREEN → REFACTOR → VALIDATE** (the `writing-skills` TDD methodology). Applying the framework to a consumer repo runs the chain `grilling → writing-specs → writing-plans → pre-implementation-protocol → inline-driven-development | subagent-driven-development → spec-drift-audit` (each task test-first via `test-driven-development`). Full operating manual: [.claude/CLAUDE.md](./.claude/CLAUDE.md).

**Hard rules:**

- **No skill (or skill edit) without a failing test first.** Run the baseline subagent scenarios and watch them fail (RED) before writing. Wrote it first? Delete it, start over.
- **Agnostic by default.** A skill never hard-depends on one project's stack, paths, or commands — the consumer repo fills specifics.
- **Capture a qualifying lesson the same turn.** Only when it passes the (A)+(B) bar — a concrete reusable check AND a recurring/non-obvious class (most turns produce none); `writing-lessons` owns the bar. Recurring (3×) → `writing-rules`.
- **Verify before "done".** Validators pass AND a GREEN subagent run confirms the behavior — code/markdown existing is not "done".
- **Skill names are structural claims.** A reference to a skill must match its real dir/`name` in `.claude/skills/*` — verify, don't recall.

## What this project is

Agnostic skills authored under `skills/` (grouped into category folders) and discovered by Claude Code through flat symlinks in `.claude/skills/`, plus the harness around them: hooks authored under `hooks/` and surfaced via flat symlinks in `.claude/hooks/` (gates + logging), `.claude/rules/domains/` (framework + domain glossary) and `.claude/rules/common/` (cross-cutting rules), `.claude/skills-routing.json`, `.claude/state/`. No application code, no `package.json`, no build.

## Common commands

No build / dev / test pipeline — this is a skills vault, not an app. Verification is **(a)** the skill validators (frontmatter ≤1024, name regex, reference links resolve, fence balance, word count) and **(b)** subagent RED/GREEN pressure runs. Both are defined in the operating manual → "Workflow" / "Completeness Checklist", not run as project scripts. Read-only `git` inspection is the only routine shell use.

## Skill routing

| Task | Skill |
| --- | --- |
| Run the full gated SDD pipeline end-to-end on a change (front door) | `sdd-lifecycle` |
| Resolve a ticket ID / URL into a faithful requirements bundle before design | `resolving-requirements` |
| Turn a fuzzy idea into a shared, concrete design | `grilling` |
| Turn an approved design into a concrete spec | `writing-specs` |
| Turn a spec into a task-by-task implementation plan | `writing-plans` |
| Run the readiness check before executing a plan (or before coding with no plan) | `pre-implementation-protocol` |
| Implement test-first (RED→GREEN→REFACTOR) | `test-driven-development` |
| Execute an approved plan solo, in-session (coupled tasks or a small plan) | `inline-driven-development` |
| Execute an approved plan via a fresh subagent per task (independent tasks) | `subagent-driven-development` |
| Check shipped code against an approved spec | `spec-drift-audit` |
| Create / audit the two CLAUDE.md files | `bootstrapping-claude-md` / `auditing-claude-md` |
| Create / audit the base domain rules (glossary, framework) | `bootstrapping-glossary` / `auditing-glossary` |
| Capture a lesson; promote a recurring one to a rule | `writing-lessons` → `writing-rules` |
| Author or change any skill (test-first) | `writing-skills` |
| Design a deep module / find a seam (shared deep-module vocabulary) | `codebase-design` |
| Architecture review — surface deepening opportunities (user-invoked, not trigger-routed) | `improve-codebase-architecture` |
| Approaching the context limit / ending with unfinished work | `handoff` |
| Short user-typed aliases (deterministic entry; same skills) | `/sdd`→`sdd-lifecycle`, `/grill`→`grilling`, `/spec`→`writing-specs`, `/audit`→`spec-drift-audit` |

When a user prompt contains a registered trigger and the corresponding skill is not invoked within a few tool calls, [.claude/hooks/detect-bypass.sh](./.claude/hooks/detect-bypass.sh) warns and logs the event to `.claude/skills/_metrics.jsonl` (gitignored). Triggers are listed in [.claude/skills-routing.json](./.claude/skills-routing.json).

## Where rules live

| Layer | Folder |
| --- | --- |
| Domain rules (glossary, framework charter) | [.claude/rules/domains/](./.claude/rules/domains/) |
| Cross-cutting process & policy (markdown style, skill-routing sync, git conventions, …) | [.claude/rules/common/](./.claude/rules/common/) |

Rules load on demand, not auto-injected. Bootstrap them in a consumer repo with `bootstrapping-glossary`; keep them true with `auditing-glossary`.

## Engineering system

Full operating manual (system prompt for HOW to work): [.claude/CLAUDE.md](./.claude/CLAUDE.md). Covers the **Role** (Principal AI/Workflow Engineer), the **Non-negotiables** (Iron Law, agnostic-by-default, read-before-assert, validate-before-done, capture-bottlenecks), the **operating modes** (AUTHOR / AUDIT / APPLY), the **RED → GREEN → REFACTOR → VALIDATE** authoring workflow, the **Completeness Checklist** for a skill change, the **session-handoff** flow, search-before-ask, the git boundary, and the status-block format.

Process basics (Implementation Protocol, Suspicion Protocol, evidence-based verification, question discipline): [.claude/rules/domains/framework.md](./.claude/rules/domains/framework.md). Domain glossary: [.claude/rules/domains/glossary.md](./.claude/rules/domains/glossary.md).
