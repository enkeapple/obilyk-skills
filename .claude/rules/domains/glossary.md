# Vault Glossary — what the SDD-framework words mean here (and what "test" is NOT)

## When

STOP and read this before acting whenever a prompt or your own draft uses any of these:

- **"test" / "tests" / "тест" / "run the tests"** — in this repo this is almost never a unit test. Disambiguate before you act.
- **"RED" / "GREEN" / "REFACTOR" / "red-green"** — used by two different workflows here; name which.
- **"skill" / "rule" / "hook" / "trigger" / "routing" / "скилл" / "правило"**.
- **"design" / "spec" / "plan"** — three distinct artifacts in the chain, not synonyms.
- **"the vault" / "this repo" vs "consumer repo" / "target repo" / "the app"**.
- **"validator" / "validators" / "checks"**, **"bootstrap" vs "audit"**, **"lesson" vs "rule"**, **"AUTHOR / AUDIT / APPLY"**.
- Anytime you read or edit skill source under `plugins/*/skills/**`, `.claude/rules/**`, `hooks/**` (guard hooks surfaced via `.claude/hooks/**`; routing/metric/session/quality hooks in `plugins/guardrails-kit/hooks/`), or `.claude/skills-routing.json`.

## Why

This vault has no application code — its "domain" is the SDD skill framework itself, and several of its core words collide with their ordinary software meaning. The dangerous one is **"test"**: a reader who hears "write a failing test first" (Iron Law) and reaches for a unit-test runner is lost — there is no `pnpm`, no Vitest, no suite here. The RED/GREEN test is a *subagent pressure run*. Getting this wrong turns the whole discipline into theatre.

**Source-of-truth principle:** if code/skills on disk disagree with this file, fix THIS file first, then reconcile the code — never let the two silently diverge. A glossary cell that greps to nothing is a defect (`auditing-glossary` catches it).

## Implementation

Ownership table — do not infer from a filename:

| # | Concept | Lives in | Surface / artifact | What it represents |
| --- | --- | --- | --- | --- |
| 1 | **skill** | source `plugins/<kit>/skills/<cat>/<name>/SKILL.md` (+ `references/*.md`, `assets/*.md`); discovered via the installed marketplace plugin | invoked via the `Skill` tool | a routable capability; `name:` MUST equal the directory name and the routing key |
| 2 | **rule** | `.claude/rules/<area>/*.md` (`common/` = cross-cutting; `domains/` = glossary + framework) | loaded on demand, never auto-injected | a convention/process doc the agent reads when relevant |
| 3 | **hook** | routing/metric/session/quality hooks ship in the `guardrails-kit` plugin (`plugins/guardrails-kit/hooks/`), wired by its `hooks.json`; guard hooks remain vault-local in `hooks/guards/`, surfaced via `.claude/hooks/` symlinks, wired by root `settings.json` | runs on tool events | a gate/logger: routing (`detect-bypass`, `skill-gate`, `log-skill-usage`), guards (`security-guard`, `bash-read-guard`, `read-guard`, `edit-write-guard`), quality (`quality`), session (`reset-turn-budget`, `token-guard`, `lessons-nudge`); authored/edited test-first via `writing-hooks` (fixture-execution is its RED/GREEN) |
| 4 | **routing** | root `.claude/skills-routing.json` (consumer single source of truth, schema v2) | read by the hooks | entries are `kind:"ref"` (plugin-provided skill: kind + plugin + name + triggers, no files) or `kind:"local"` (consumer-authored skill: kind + triggers + files); `skill-routing-sync.md` keeps it true |
| 5 | **the SDD chain** | skills #1 | `resolving-requirements → grilling → writing-specs → writing-plans → pre-implementation-protocol → (inline-driven-development \| subagent-driven-development) → spec-drift-audit` | the APPLY-mode pipeline run on a consumer repo (`resolving-requirements` is the front door: it resolves a ticket-ID/URL input into a faithful requirements bundle; a ready free-text idea enters at `grilling`; `pre-implementation-protocol` is the readiness gate between a written plan and execution; execution runs via `inline-driven-development` (solo, in-session) or `subagent-driven-development` (fresh subagent per task), each writing code test-first via `test-driven-development`; a no-plan single-behavior change enters execution directly at `test-driven-development`) |
| 6 | **validators** | root [CLAUDE.md](../../../CLAUDE.md) → "Common commands" | frontmatter ≤1024, name regex, reference links resolve, fence balance, word count | structural checks on a skill change — **not** a test suite |
| 7 | **lessons** | [lessons-learned.md](../../lessons-learned.md) | transient candidate-rules backlog (un-promoted only); git = archive | captured bottleneck; on promotion (3×) its entries are deleted and the tag recorded in `## Promoted clusters` |

Term-disambiguation rules — what each word maps to, and how to resolve the ambiguous ones:

- **"test"** — resolve by mode. In **AUTHOR/AUDIT** (working on the vault's own skills) → a **subagent pressure scenario**: RED = run the scenario WITHOUT the skill and watch it fail; GREEN = re-run WITH the skill and confirm compliance. In **APPLY** (the `test-driven-development` skill on a consumer repo) → a real automated unit test on that repo's stack. Never a unit test *of the vault* — there is none.
- **"RED / GREEN / REFACTOR"** — in **AUTHOR** it is the skill-authoring loop (`writing-skills`: RED→GREEN→REFACTOR→VALIDATE, object = a `SKILL.md`). In **APPLY** it is the `test-driven-development` skill's code loop (object = implementation code). Same words, different workpiece — always name which.
- **"the vault" / "this repo"** — always this repo: the skills are the *product*. **"consumer / target repo" / "the app"** — a separate codebase the chain is APPLIED to; it supplies the stack, paths, and commands the agnostic skills never bake in.
- **"design" → "spec" → "plan"** — ordered, distinct artifacts: `grilling` produces a **design**; `writing-specs` turns it into a **spec**; `writing-plans` turns that into a task-by-task **plan**. Do not use them interchangeably.
- **"bootstrap" vs "audit"** — `bootstrapping-*` creates a doc from scratch; `auditing-*` checks an existing doc for drift. Two skills per target (CLAUDE.md, domain-rules).
- **"lesson" vs "rule"** — a **lesson** is one entry in `lessons-learned.md`; it becomes a **rule** only after the same cause-tag recurs 3× and is promoted via `writing-rules`, at which point its lesson entries are deleted from the backlog (git keeps them).

What is NOT in this domain (must not be conflated): there is **no** `package.json` / build / dev / unit-test pipeline, **no** `src/`, **no** simulator. Verification here = validators + subagent runs; a **hook** change additionally verifies by **fixture-execution** (crafted stdin → run the script → assert the decision), since a hook is deterministic executable code (`writing-hooks` owns this). Still no `pnpm`/Vitest/build/suite/simulator. `writing-skills` is the skill-authoring methodology and is **trigger-routed** — it is model-invocable and has a `skills-routing.json` entry (despite being a large reference skill, by owner decision; its body budget is the ≤1500-word methodology tier). `improve-codebase-architecture` is the remaining **reference skill** (`disable-model-invocation: true`) — NOT trigger-routed, no entry in `skills-routing.json`. The general rule: `disable-model-invocation: true` ⇒ no `skills-routing.json` entry, and it has two sub-kinds — **reference skills** (methodology with the flag, no triggers) and **alias skills** (see Edge Cases below).

## Edge Cases

- An earlier version of `framework.md` (before it was de-leaked and moved from `common/` into `domains/`) described a TypeScript/React-Native + `pnpm` app — that was a **project leak**, not this vault. The current `framework.md` is the agnostic Charter; never reintroduce stack-specific verification (`pnpm test`, Vitest) as if it were the vault's.
- `RED/GREEN` in a quoted `test-driven-development` example refers to the consumer repo's tests — do not "fix" it to mean subagent runs.
- Per-turn metric/state files (e.g. `_metrics.jsonl`) are written under `.claude/state/`, not `.claude/skills/` — they are runtime state and own no glossary row. (Historical note: an earlier model placed them under `.claude/skills/`; that model no longer applies.)
- An **alias skill** is a thin `disable-model-invocation` facade under `plugins/sdd-kit/skills/aliases/` (`sdd`, `grill`, `spec`, `audit`) whose body delegates to exactly one canonical skill and forwards `$ARGUMENTS` — it holds no logic of its own and is correctly absent from `skills-routing.json`. The invariant `name === dir === SKILL.md name:` still holds; only the routing-key expectation differs (it has none). (Historical note: an earlier model required the name to also equal a flat `.claude/skills/<name>` symlink; skills are now discovered via the installed marketplace plugin, not flat symlinks.)

## Review Checklist

- Named the operating mode (AUTHOR / AUDIT / APPLY) before interpreting "test", "RED", or "GREEN".
- Used **design / spec / plan** as distinct artifacts, not synonyms.
- Did not attribute any `pnpm` / build / unit-test command to the vault itself.
- Every skill/rule/hook/path cited matches disk (key === dir === `SKILL.md name:`).
- Did not add a glossary row for a `_`-prefixed runtime path, nor claim a `disable-model-invocation` reference skill (e.g. `improve-codebase-architecture`) carries routing triggers.
