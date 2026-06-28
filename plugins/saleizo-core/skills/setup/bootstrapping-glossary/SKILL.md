---
name: bootstrapping-glossary
description: >-
  Use when a project has no foundational rules yet and you need to create the
  base set the agent works from — a domain glossary (what the app's concepts
  mean and who owns them) and a framework charter (how to work in this repo).
  Triggers on: "set up the base rules", "create a domain glossary", "write the
  framework rules", "bootstrap .claude/rules", "how should Claude work here".
allowed-tools: Read, Grep, Glob, Write, Edit
---

# Bootstrapping Glossary

Create the two foundational, always-on rules every other rule hangs off, by default under `.claude/rules/domains/`:

- **Domain glossary** ([assets/domain-glossary-template.md](./assets/domain-glossary-template.md)) — what the app's concepts *mean*, who owns what, and how to disambiguate overlapping terms. The source of truth for domain vocabulary.
- **Framework charter** ([assets/framework-charter-template.md](./assets/framework-charter-template.md)) — how to approach work in this repo regardless of which module you touch: implementation protocol, suspicion/verification discipline, question discipline.

Each template carries the full required anatomy and a filled example; write each doc to its template. This skill owns only the one thing the templates cannot enforce: **that every part is grounded in the real codebase.**

## When to use

- A new or unruled project: there is no `.claude/rules/domains/` glossary or framework yet.
- Recurring confusion about what a term means or who owns a concept → the project needs a glossary.
- Repeated process failures (hallucinated symbols, skipped verification, guessed structure) → the project needs a charter.

**Not** when the docs already exist and only need correcting (that is `auditing-glossary`), nor for a single narrow convention (that is one ordinary area-scoped rule, not a foundational doc).

## Discover first — this is the whole job

**These are built from the real codebase, never from boilerplate.** A glossary that invents entities, or a charter of generic platitudes, is worse than none — it launders guesses into a "source of truth". If you cannot ground a claim in something you read this session, it does not go in the doc. Everything else lives in the templates; this is the one principle they cannot enforce for you.

Before writing a line:

- **For the glossary:** grep the overlapping noun-roots and the domains that share them; open each owning module for the real boundaries, the real route/type/API names, and the actual incident that proves they collide. Capture the conventions the code already uses — never invent them.
- **For the charter:** find the repo's real verification commands (manifest scripts / Makefile / CI), the established patterns to mirror, and the real failure modes this codebase has hit — the charter cites *these*, not generic advice. Resolve the template's stack-specific slots via the keys in [references/placeholder-keys.md](../shared/placeholder-keys.md): auto off disk only when exactly one fact maps with no judgment, else raise an intake question.

## Red Flags — STOP

- Writing either doc before grepping the code, or naming any symbol/path/route/command not verified by a read this session.
- Inventing entities, routes, or naming conventions not in the repo; a charter of platitudes ("write clean code") instead of this repo's concrete protocol and real commands.
- A glossary with no `## When` triggers (it never loads at the moment of confusion), or with definitions but no term→owner disambiguation for the words that actually collide.
