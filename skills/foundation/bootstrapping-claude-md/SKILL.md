---
name: bootstrapping-claude-md
description: >-
  Use when a project has no CLAUDE.md yet (or only a stub) and you need to set
  up the agent's entry point and operating manual for the repo. Triggers on:
  "set up CLAUDE.md", "initialize CLAUDE.md", "create the project's Claude
  config", "bootstrap the engineering system", "give Claude a persona/pipeline
  for this repo".
---

# Bootstrapping CLAUDE.md

Set up the two-file CLAUDE.md system every other instruction hangs off:

- **`CLAUDE.md` (repo root)** — the entry point: what the project is, the real commands, where rules/skills live, and the one-paragraph "how to work here".
- **`.claude/CLAUDE.md`** — the operating manual: the engineer persona, the non-negotiables, the task pipeline, the verification checklist, and the session-handoff flow.

**Core principle: interview the human for the initial facts, then ground everything else in the actual repo — never invent.** A CLAUDE.md that guesses the stack, the commands, or the test setup makes the agent work *worse*. Ask what only the human knows; discover the rest by reading.

This mirrors `bootstrapping-glossary` (which builds `.claude/rules/`); the CLAUDE.md files point at those rules. For the intake interview style (one question at a time, with a recommended answer), borrow from `grilling`. For the session-handoff mechanics, wire to the `handoff` skill.

## When to use

- A repo with no `CLAUDE.md`, or a thin stub that doesn't define how the agent should work.
- Standing up the engineering system for a new project.

## When NOT to use

- The files exist and just need correcting → `auditing-claude-md`.
- A single convention or domain rule → `writing-rules` / `bootstrapping-glossary`.

## Step 1 — Intake interview (ask, don't invent)

Before writing, collect what only the human can tell you — one question at a time, with a recommended default. The full question set is in [references/intake-questions.md](references/intake-questions.md). At minimum:

- **What the app is** — product, platforms, the domain in one or two sentences.
- **The managing engineer's position** — e.g. *Principal Mobile Dev*, *Staff Backend*, *Senior Frontend*. This sets the **Role/persona** the agent acts as and the bar it holds. Do not default to a generic "senior engineer" — use the position given.
- **Stack & real commands** — confirm against `package.json`/Makefile/CI; ask for anything not discoverable. Crucially, whether there IS a test pipeline — never assume one.
- **Where rules/skills/commands live** and any **session-handoff** preference.

Discover the rest (stack pins, folder layout, existing rules) by reading the repo.

## Step 2 — Write the two files

Each template carries the fixed section order, a filled example, and per-section notes — follow it, don't re-derive the structure here.

- **Root `CLAUDE.md`** ([references/root-claude-md-template.md](references/root-claude-md-template.md)) — the scannable entry point: "How to work here" with a distinct **Hard rules** block, What this project is, **Common commands** (the *real* ones — never validator one-liners; if there's no test pipeline, say so), **Skill routing**, Slash commands / Where rules live, and a substantial **Engineering system** pointer.
- **`.claude/CLAUDE.md`** ([references/operating-manual-template.md](references/operating-manual-template.md)) — the operating manual: Rule precedence; **Non-negotiables** (the discipline set that survives summarization, each with WHY + enforcement); **Role** (the intake position, not a generic "senior engineer"); Operating modes; **Workflow pipeline** + **Completeness Checklist** (real commands); Plan persistence; Search-before-ask; Git boundary; Status block; **Skill discipline**, **Lessons promotion path**, **Pointers**.

**Three rules that override the templates' defaults:**

- **Ground every command, path, skill, and hook in the repo this session** — a cited command/hook/path that doesn't exist is a hallucination.
- **Hook-tied clauses are conditional** — keep skill-gate / bypass / token-guard / lessons-nudge references ONLY for hooks the repo actually has.
- **Skill-owned workflows route through the `Skill` tool, not a direct file edit.** When the manual documents a workflow a skill owns — lesson capture, handoff/plan persistence, spec authoring — instruct invoking that skill, never an `Edit`/`Write` to the artifact the skill manages (`lessons-learned.md`, a `/tmp` plan): a direct edit bypasses the skill's discipline, routing, and metrics. Keep it conditional — route through the skill only where the repo HAS one; else document the direct fallback. (The templates already do this for `handoff`; match that pattern for lessons.)

## Step 3 — Session-jumping / handoff flow (required)

Document how work survives the context limit, because long tasks will hit it. The operating manual must state: when the turn ends incomplete OR context nears the limit, persist a handoff doc (goal, done, remaining, exact next step, files touched, open decisions, working-tree state), end the turn cleanly, and resume from that doc next session. Wire the mechanics to the `handoff` skill rather than re-describing them. The status block's `Next:` line points at the handoff doc.

## Red Flags — STOP

- Writing either file before the intake interview — guessing the app, stack, or commands.
- A generic persona ("senior engineer") instead of the position the human gave.
- Assuming a test pipeline / TDD when the repo has none — verify, don't assume.
- One mega-file instead of the entry-point + operating-manual split.
- A non-negotiable or pointer that tells the agent to `append`/`Edit` a skill-owned artifact (e.g. the lessons log) directly when the repo has the skill that owns it — that bypasses the skill; route through the `Skill` tool instead.
- A pipeline with no Completeness Checklist, or verification rows with invented commands.
- A flat single-line status block (fields joined by `·`/`,`) instead of the structured, verdict-first markdown form in the template — or reaching for emoji to make it scannable, which breaks the manual's own "no emoji" rule.
- No session-handoff flow — long tasks will silently lose state at the context limit.
- Any stack/command/path claim not verified by a read this session.
