# Root `CLAUDE.md` Template

The entry point. Mirror this section order exactly — it is the structure proven in real repos. Scannable, link-heavy: the root routes, the operating manual governs. Every command, path, and skill name is the real one, verified by reading the repo.

## Section order (fixed)

1. `# <Project> — Claude entry point`
2. `## How to work here (read first)` — the pipeline one-liner + pointer to `.claude/CLAUDE.md`, then a distinct **Hard rules** block.
3. `## What this project is` — product + stack, grounded; plus, for an SDD-chain repo, the single design-docs location convention.
4. `## Common commands` — the real dev commands table.
5. `## Skill routing` — task → skill table.
6. `## Slash commands` — (only if the repo has `.claude/commands/`).
7. `## Where rules live` — layer → folder table.
8. `## Engineering system` — pointer to the operating manual.

## Template

```markdown
# <Project> — Claude entry point

## How to work here (read first)

Every non-trivial task runs through **<PIPELINE>** and ends with the Completeness Checklist walked in the status block. Full operating manual: [.claude/CLAUDE.md](./.claude/CLAUDE.md).

**Hard rules:**

- **Temp-file / plan creation goes through `handoff` — never a hand-written `/tmp` file.** Invoke it (a) when the task crosses the plan-file threshold (<shared contracts / data shapes / routes / >2 features — link the repo's framework rule>) to persist the plan, and (b) when a turn ends incomplete or the context window nears its limit to write the handoff doc — independent of the threshold, for any task. For batches of small fixes, use a todo list — no plan file.
- **Batch of fixes = one process pass.** When the user sends N independent fixes in one message, do ALL of them in the same turn: one todo list, one Completeness Checklist at the end, one status block. Do not stop after item 1 to confirm — finish the list.
- **Search before asking. Always.** Before any clarifying question, run the search order in [.claude/CLAUDE.md](./.claude/CLAUDE.md) → "Search-before-ask". Only escalate when sources conflict, are demonstrably wrong, or are silent on a genuine business decision.
- **A task is "done" only when every Completeness Checklist row is `[x]` or `[N/A]`-with-reason.** Any `[ ]` item → no `Suggested commit:` line.

## What this project is

<One or two sentences: product + platforms.> <Then the stack as the repo actually uses it.> Stack pins live in [`<stack-manifest>`](./<stack-manifest>) and [.claude/rules/](./.claude/rules/) — read them, do not infer.

Design docs follow one convention: specs in `docs/specs/YYYY-MM-DD-<topic>.md`, plans in `docs/plans/YYYY-MM-DD-<topic>.md` (the `writing-specs`/`writing-plans` defaults) — a single declared location so the output path stays deterministic.
<!-- Include the design-docs line ONLY if the repo applies the writing-specs/writing-plans chain; drop it otherwise. If the repo already keeps design docs elsewhere, name that ONE location instead of the defaults — but never leave it multi-valued: two competing dirs (e.g. both `specs/` and `docs/specs/`) make the output path a coin-flip from session to session. -->

## Common commands

| Task | Command |
|---|---|
| run / dev | `<run-cmd>` |
| typecheck | `<typecheck-cmd>` |
| lint | `<lint-cmd>` |
| lint autofix / format | `<format-cmd>` |
| test | `<test-cmd>` |
| native install / build / deploy | `<build-deploy-cmd>` |

<List every command the team actually runs — not just the basics. If there is no test pipeline, state it in one line here: e.g. "There is no `<test>` script; verification is `<typecheck>` + `<lint>` + manual, judged against the feature's spec.">

## Skill routing

| Task triggers a skill | Skill |
|---|---|
| <concrete task / file pattern> | `<skill-name>` |
| Approaching the context limit / ending a session with unfinished work | `handoff` |

When a user prompt contains a registered trigger and the corresponding skill is not invoked within a few tool calls, `<.claude/hooks/detect-bypass.sh or the repo's bypass hook>` warns and logs the event to `<.claude/skills/_metrics.jsonl>`. Triggers are listed in [.claude/skills-routing.json](./.claude/skills-routing.json).
<!-- Include the sentence above ONLY if the repo actually has a bypass-detection hook + routing registry; otherwise drop it. -->

## Slash commands

Process commands under `.claude/commands/`, each a multi-phase flow with user-approval gates:

| Command | When to use |
|---|---|
| `/<command>` | <one line — list every command the repo has> |

For trivial one-line fixes, skip the commands and edit directly.

## Where rules live

One row per rule folder the repo actually has:

| Layer | Folder |
|---|---|
| Domain rules (glossary, framework charter) | [.claude/rules/domains/](./.claude/rules/domains/) |
| Cross-cutting process & policy (code style, file org, security, error handling) | [.claude/rules/common/](./.claude/rules/common/) |
| <framework/runtime patterns> | [.claude/rules/<area>/](./.claude/rules/<area>/) |
| <language idioms> | [.claude/rules/<area>/](./.claude/rules/<area>/) |
| <data / API layer> | [.claude/rules/<area>/](./.claude/rules/<area>/) |

## Engineering system

Full operating manual (system prompt for HOW to work): [.claude/CLAUDE.md](./.claude/CLAUDE.md). Covers <the manual's actual sections — e.g. the Role/persona, Non-negotiables, operating modes, the <PIPELINE> workflow, the Completeness Checklist, plan persistence & session-handoff, search-before-ask, git boundary, status-block format>.

Process basics (<Implementation Protocol, Suspicion Protocol, evidence-based verification, question discipline>): [.claude/rules/domains/framework.md](./.claude/rules/domains/framework.md).
```

## Notes

- **Hard rules** (here) ≠ **Non-negotiables** (in the operating manual). Hard rules are the 3-5 entry-point reminders a fresh session needs immediately; Non-negotiables are the discipline set that must survive context summarization. Overlap is fine; the root version is shorter.
- **Common commands** is the real dev/verification commands the human actually runs (run / typecheck / lint / build / test). Do not pad it with internal validator one-liners or invent a `test` script — if there is no test pipeline, say so in one line. A wrong command here wastes every session.
- **Skill routing** is first-class: a task→skill table so the agent loads the right skill before editing. Omit a row only if the skill genuinely doesn't exist.
- **Design-docs convention** is for repos that apply the `writing-specs`/`writing-plans` chain: declare ONE location (the `docs/specs/` + `docs/plans/` defaults, or the repo's existing single home) so the skills' "where the project keeps design docs" detection resolves deterministically. Two competing dirs are exactly what makes the output path drift; omit the line entirely for a repo that doesn't run the chain.
- Keep the root an index. Anything about *how* to work goes in `.claude/CLAUDE.md`.
