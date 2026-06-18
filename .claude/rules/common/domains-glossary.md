# Vault Glossary — what the SDD-framework words mean here (and what "test" is NOT)

## When

STOP and read this before acting whenever a prompt or your own draft uses any of these:

- **"test" / "tests" / "тест" / "run the tests"** — in this repo this is almost never a unit test. Disambiguate before you act.
- **"RED" / "GREEN" / "REFACTOR" / "red-green"** — used by two different workflows here; name which.
- **"skill" / "rule" / "hook" / "trigger" / "routing" / "скилл" / "правило"**.
- **"design" / "spec" / "plan"** — three distinct artifacts in the chain, not synonyms.
- **"the vault" / "this repo" vs "consumer repo" / "target repo" / "the app"**.
- **"validator" / "validators" / "checks"**, **"bootstrap" vs "audit"**, **"lesson" vs "rule"**, **"AUTHOR / AUDIT / APPLY"**.
- Anytime you read or edit `.claude/skills/**`, `.claude/rules/**`, `.claude/hooks/**`, or `.claude/skills-routing.json`.

## Why

This vault has no application code — its "domain" is the SDD skill framework itself, and several of its core words collide with their ordinary software meaning. The dangerous one is **"test"**: a reader who hears "write a failing test first" (Iron Law) and reaches for a unit-test runner is lost — there is no `pnpm`, no Vitest, no suite here. The RED/GREEN test is a *subagent pressure run*. Getting this wrong turns the whole discipline into theatre.

**Source-of-truth principle:** if code/skills on disk disagree with this file, fix THIS file first, then reconcile the code — never let the two silently diverge. A glossary cell that greps to nothing is a defect (`auditing-domain-rules` catches it).

## Implementation

Ownership table — do not infer from a filename:

| # | Concept | Lives in | Surface / artifact | What it represents |
| --- | --- | --- | --- | --- |
| 1 | **skill** | `.claude/skills/<name>/SKILL.md` (+ `references/*.md`) | invoked via the `Skill` tool | a routable capability; `name:` MUST equal the directory name |
| 2 | **rule** | `.claude/rules/common/*.md` | loaded on demand, never auto-injected | a convention/process doc the agent reads when relevant |
| 3 | **hook** | `.claude/hooks/*.sh` | runs on tool events | a gate/logger (`detect-bypass`, `skill-gate`, `token-guard`, `lessons-nudge`, …) |
| 4 | **routing** | `.claude/skills-routing.json` | read by the hooks | trigger-phrase → skill map; `skill-routing-sync.md` keeps it true |
| 5 | **the SDD chain** | skills #1 | `grilling → writing-specs → writing-plans → tdd → spec-drift-audit` | the APPLY-mode pipeline run on a consumer repo |
| 6 | **validators** | root [CLAUDE.md](../../../CLAUDE.md) → "Common commands" | frontmatter ≤1024, name regex, reference links resolve, fence balance, word count | structural checks on a skill change — **not** a test suite |
| 7 | **lessons** | [lessons-learned.md](../../lessons-learned.md) | append-only log | captured bottleneck; 3× same cause-tag → promoted to a rule |

Term-disambiguation rules — what each word maps to, and how to resolve the ambiguous ones:

- **"test"** — resolve by mode. In **AUTHOR/AUDIT** (working on the vault's own skills) → a **subagent pressure scenario**: RED = run the scenario WITHOUT the skill and watch it fail; GREEN = re-run WITH the skill and confirm compliance. In **APPLY** (the `tdd` skill on a consumer repo) → a real automated unit test on that repo's stack. Never a unit test *of the vault* — there is none.
- **"RED / GREEN / REFACTOR"** — in **AUTHOR** it is the skill-authoring loop (`writing-great-skills`: RED→GREEN→REFACTOR→VALIDATE, object = a `SKILL.md`). In **APPLY** it is the `tdd` skill's code loop (object = implementation code). Same words, different workpiece — always name which.
- **"the vault" / "this repo"** — always this repo: the skills are the *product*. **"consumer / target repo" / "the app"** — a separate codebase the chain is APPLIED to; it supplies the stack, paths, and commands the agnostic skills never bake in.
- **"design" → "spec" → "plan"** — ordered, distinct artifacts: `grilling` produces a **design**; `writing-specs` turns it into a **spec**; `writing-plans` turns that into a task-by-task **plan**. Do not use them interchangeably.
- **"bootstrap" vs "audit"** — `bootstrapping-*` creates a doc from scratch; `auditing-*` checks an existing doc for drift. Two skills per target (CLAUDE.md, domain-rules).
- **"lesson" vs "rule"** — a **lesson** is one entry in `lessons-learned.md`; it becomes a **rule** only after the same cause-tag recurs 3× and is promoted via `writing-rules`.

What is NOT in this domain (must not be conflated): there is **no** `package.json` / build / dev / unit-test pipeline, **no** `src/`, **no** simulator. Verification here = validators + subagent runs only. `writing-great-skills` is a reference skill (`disable-model-invocation: true`) — it is NOT trigger-routed and has no entry in `skills-routing.json`.

## Edge Cases

- The deleted `framework.md` once described a TypeScript/React-Native + `pnpm` app — that was a **project leak**, not this vault. Never reintroduce stack-specific verification (`pnpm test`, Vitest) as if it were the vault's.
- `RED/GREEN` in a quoted `tdd` example refers to the consumer repo's tests — do not "fix" it to mean subagent runs.
- A `_`-prefixed path under `.claude/skills/` (e.g. `_metrics.jsonl`) is runtime state, not a skill — it owns no glossary row.

## Review Checklist

- Named the operating mode (AUTHOR / AUDIT / APPLY) before interpreting "test", "RED", or "GREEN".
- Used **design / spec / plan** as distinct artifacts, not synonyms.
- Did not attribute any `pnpm` / build / unit-test command to the vault itself.
- Every skill/rule/hook/path cited matches disk (key === dir === `SKILL.md name:`).
- Did not add a glossary row for a `_`-prefixed runtime path or for `writing-great-skills`'s triggers.
