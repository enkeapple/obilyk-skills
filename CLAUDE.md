# SDD Workflow — marketplace & Claude entry point

A **Claude Code skill marketplace** and the in-place dev vault that develops it. The repo publishes 4 plugins via `.claude-plugin/marketplace.json` — **sdd-kit** (the gated Spec-Driven-Development chain plus skill/hook/rule authoring and foundation bootstrapping), **learning-kit** (user-invoked learning skills), **craft-kit** (deep-module design, architecture review, prose), and **guardrails-kit** (the routing-bypass detection, telemetry, session, and quality hooks that the harness reads from `.claude/skills-routing.json`). The product is not an app — it is the skills themselves and *how they interact*. The goal is a flexible system that surfaces its own bottlenecks (a misfiring skill, a leaky hand-off, an over-rigid step), which become lessons → rules → skill edits.

## How to work here (read first)

Authoring or changing a skill runs through **RED → GREEN → REFACTOR → VALIDATE** (the `writing-skills` TDD methodology). Applying the framework to a consumer repo runs the chain `grilling → writing-specs → writing-plans → pre-implementation-protocol → inline-driven-development | subagent-driven-development → spec-drift-audit` (each task test-first via `test-driven-development`). Full operating manual: [.claude/CLAUDE.md](./.claude/CLAUDE.md).

**Hard rules:**

- **No skill (or skill edit) without a failing test first.** Run the baseline subagent scenarios and watch them fail (RED) before writing. Wrote it first? Delete it, start over.
- **Agnostic by default.** A skill never hard-depends on one project's stack, paths, or commands — the consumer repo fills specifics.
- **Capture a qualifying lesson the same turn.** Only when it passes the (A)+(B) bar — a concrete reusable check AND a recurring/non-obvious class (most turns produce none); `writing-lessons` owns the bar. Recurring (3×) → `writing-rules`.
- **Verify before "done".** Validators pass AND a GREEN subagent run confirms the behavior — code/markdown existing is not "done".
- **Skill names are structural claims.** A reference to a skill must match its real dir/`name` under `plugins/*/skills/**` and its routing key in `.claude/skills-routing.json` — verify, don't recall.

## What this project is

Agnostic skills authored under `plugins/<kit>/skills/<category>/<name>/` across the four kits (`sdd-kit`, `learning-kit`, `craft-kit`, `guardrails-kit`, each with its own `.claude-plugin/plugin.json`) and discovered by Claude Code via the installed marketplace plugins, plus the harness around them: the marketplace manifest `.claude-plugin/marketplace.json`, guard hooks in `hooks/guards/` surfaced via `.claude/hooks/` symlinks (wired by root `settings.json`), routing/metric/session/quality hooks in `plugins/guardrails-kit/hooks/` (wired by its `hooks.json`), `.claude/rules/domains/` (framework + domain glossary) and `.claude/rules/common/` (cross-cutting rules), `.claude/skills-routing.json`, `.claude/state/`. No application code, no `package.json`, no build.

The vault's own design docs follow a single convention: **specs live in `docs/specs/YYYY-MM-DD-<topic>.md`, plans in `docs/plans/YYYY-MM-DD-<topic>.md`** — never bare `specs/` or `plans/` at the root. This is the convention `writing-specs`/`writing-plans` detect via "where the project keeps design docs"; keeping it single-valued is what makes the output path deterministic.

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
| Adopt / install the framework into a fresh consumer repo (ordered: copy → symlinks → bootstraps → routing → verify) | `adopting-framework` |
| Create / audit the two CLAUDE.md files | `bootstrapping-claude-md` / `auditing-claude-md` |
| Create / audit the base domain rules (glossary, framework) | `bootstrapping-glossary` / `auditing-glossary` |
| Create / audit the README skills catalog | `bootstrapping-readme` / `auditing-readme` |
| Capture a lesson; promote a recurring one to a rule | `writing-lessons` → `writing-rules` |
| Author or change any skill (test-first) | `writing-skills` |
| Author or change a Claude Code hook (test-first) | `writing-hooks` |
| Record an architectural decision as an immutable ADR (gate it, maintain the index, supersede — never edit) | `writing-adrs` |
| Design a deep module / find a seam (shared deep-module vocabulary) | `codebase-design` |
| Architecture review — surface deepening opportunities (user-invoked, not trigger-routed) | `improve-codebase-architecture` |
| De-slop an existing chunk of prose (remove the AI tells) | `tightening-prose` |
| Rewrite a draft into publication-ready prose (article / blog / post register) | `humanizing-prose` |
| Approaching the context limit / ending with unfinished work | `handoff` |
| Short user-typed aliases (deterministic entry; same skills) | `/sdd`→`sdd-lifecycle`, `/grill`→`grilling`, `/spec`→`writing-specs`, `/audit`→`spec-drift-audit`, `/adr`→`writing-adrs` |

When a user prompt contains a registered trigger and the corresponding skill is not invoked within a few tool calls, `detect-bypass.sh` (from `guardrails-kit`) warns and logs the event to `.claude/state/_metrics.jsonl` (gitignored). Triggers are listed in [.claude/skills-routing.json](./.claude/skills-routing.json).

## Where rules live

| Layer | Folder |
| --- | --- |
| Domain rules (glossary, framework charter) | [.claude/rules/domains/](./.claude/rules/domains/) |
| Cross-cutting process & policy (markdown style, skill-routing sync, git conventions, …) | [.claude/rules/common/](./.claude/rules/common/) |

Rules load on demand, not auto-injected. Bootstrap them in a consumer repo with `bootstrapping-glossary`; keep them true with `auditing-glossary`.

## Engineering system

Full operating manual (system prompt for HOW to work): [.claude/CLAUDE.md](./.claude/CLAUDE.md). Covers the **Role** (Principal AI/Workflow Engineer), the **Non-negotiables** (Iron Law, agnostic-by-default, read-before-assert, validate-before-done, capture-bottlenecks), the **operating modes** (AUTHOR / AUDIT / APPLY), the **RED → GREEN → REFACTOR → VALIDATE** authoring workflow, the **Completeness Checklist** for a skill change, the **session-handoff** flow, search-before-ask, the git boundary, and the status-block format.

Process basics (Implementation Protocol, Suspicion Protocol, evidence-based verification, question discipline): [.claude/rules/domains/framework.md](./.claude/rules/domains/framework.md). Domain glossary: [.claude/rules/domains/glossary.md](./.claude/rules/domains/glossary.md).
