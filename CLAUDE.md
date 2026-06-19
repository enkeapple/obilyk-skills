# SDD Workflow Vault — Claude entry point

A **vault for developing an agnostic Spec-Driven-Development (SDD) skill framework**. The product is not an app — it is the skills themselves and *how they interact*. The goal is a flexible system that surfaces its own bottlenecks (a misfiring skill, a leaky hand-off, an over-rigid step), which become lessons → rules → skill edits.

## How to work here (read first)

Authoring or changing a skill runs through **RED → GREEN → REFACTOR → VALIDATE** (the `writing-great-skills` TDD methodology). Applying the framework to a consumer repo runs the chain `grilling → writing-specs → writing-plans → tdd → spec-drift-audit`. Full operating manual: [.claude/CLAUDE.md](./.claude/CLAUDE.md).

**Hard rules:**

- **No skill (or skill edit) without a failing test first.** Run the baseline subagent scenarios and watch them fail (RED) before writing. Wrote it first? Delete it, start over.
- **Agnostic by default.** A skill never hard-depends on one project's stack, paths, or commands — the consumer repo fills specifics.
- **Capture bottlenecks the same turn.** Friction in a skill or a hand-off → a `lessons-learned-protocol` entry now; recurring (3×) → `writing-rules`.
- **Verify before "done".** Validators pass AND a GREEN subagent run confirms the behavior — code/markdown existing is not "done".
- **Skill names are structural claims.** A reference to a skill must match its real dir/`name` in `.claude/skills/*` — verify, don't recall.

## What this project is

Agnostic skills authored under `skills/` (grouped into category folders) and discovered by Claude Code through flat symlinks in `.claude/skills/`, plus the harness around them: hooks authored under `hooks/` and surfaced via flat symlinks in `.claude/hooks/` (gates + logging), `.claude/rules/common/` (framework + domain glossary), `.claude/skills-routing.json`, `.claude/state/`. No application code, no `package.json`, no build.

## Common commands

No build / dev / test pipeline — this is a skills vault, not an app. Verification is **(a)** the skill validators (frontmatter ≤1024, name regex, reference links resolve, fence balance, word count) and **(b)** subagent RED/GREEN pressure runs. Both are defined in the operating manual → "Workflow" / "Completeness Checklist", not run as project scripts. Read-only `git` inspection is the only routine shell use.

## Skill routing

| Task | Skill |
| --- | --- |
| Resolve a ticket ID / URL into a faithful requirements bundle before design | `resolving-requirements` |
| Turn a fuzzy idea into a shared, concrete design | `grilling` |
| Turn an approved design into a concrete spec | `writing-specs` |
| Turn a spec into a task-by-task implementation plan | `writing-plans` |
| Implement test-first (RED→GREEN→REFACTOR) | `tdd` |
| Check shipped code against an approved spec | `spec-drift-audit` |
| Create / audit the two CLAUDE.md files | `bootstrapping-claude-md` / `auditing-claude-md` |
| Create / audit the base domain rules (glossary, framework) | `bootstrapping-domain-rules` / `auditing-domain-rules` |
| Capture a lesson; promote a recurring one to a rule | `lessons-learned-protocol` → `writing-rules` |
| Author or change any skill (test-first) | `writing-great-skills` |
| Approaching the context limit / ending with unfinished work | `handoff` |

When a user prompt contains a registered trigger and the corresponding skill is not invoked within a few tool calls, [.claude/hooks/detect-bypass.sh](./.claude/hooks/detect-bypass.sh) warns and logs the event to `.claude/skills/_metrics.jsonl` (gitignored). Triggers are listed in [.claude/skills-routing.json](./.claude/skills-routing.json).

## Where rules live

| Layer | Folder |
| --- | --- |
| Cross-cutting process & policy (framework, domain glossary) | [.claude/rules/common/](./.claude/rules/common/) |

Rules load on demand, not auto-injected. Bootstrap them in a consumer repo with `bootstrapping-domain-rules`; keep them true with `auditing-domain-rules`.

## Engineering system

Full operating manual (system prompt for HOW to work): [.claude/CLAUDE.md](./.claude/CLAUDE.md). Covers the **Role** (Principal AI/Workflow Engineer), the **Non-negotiables** (Iron Law, agnostic-by-default, read-before-assert, validate-before-done, capture-bottlenecks), the **operating modes** (AUTHOR / AUDIT / APPLY), the **RED → GREEN → REFACTOR → VALIDATE** authoring workflow, the **Completeness Checklist** for a skill change, the **session-handoff** flow, search-before-ask, the git boundary, and the status-block format.

Process basics (Implementation Protocol, Suspicion Protocol, evidence-based verification, question discipline): [.claude/rules/common/framework.md](./.claude/rules/common/framework.md). Domain glossary: [.claude/rules/common/domains-glossary.md](./.claude/rules/common/domains-glossary.md).
