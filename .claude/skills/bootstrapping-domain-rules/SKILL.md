---
name: bootstrapping-domain-rules
description: >-
  Use when a project has no foundational rules yet and you need to create the
  base set the agent works from — a domain glossary (what the app's concepts
  mean and who owns them) and a framework charter (how to work in this repo).
  Triggers on: "set up the base rules", "create a domain glossary", "write the
  framework rules", "bootstrap .claude/rules", "how should Claude work here".
---

# Bootstrapping Domain Rules

Create the two foundational, always-on rules every other rule hangs off, by default under `.claude/rules/common/`:

- **Domain glossary** — what the app's concepts *mean*, who owns what, and how to disambiguate overlapping terms. The source of truth for domain vocabulary.
- **Framework charter** — how to approach work in this repo regardless of which module you touch: the implementation protocol, the suspicion/verification discipline, the question discipline.

**Core principle: these are built from the real codebase, not from boilerplate.** A glossary that invents entities, or a charter of generic platitudes, is worse than none — it launders guesses into a "source of truth". Discover first; write only what the code confirms.

These are foundational, always-on rules. This skill owns the two specific docs and exactly what each must contain — their full anatomy and filled examples are self-contained in the templates referenced below.

## When to use

- A new or unruled project: there is no `.claude/rules/common/` glossary or framework yet.
- Recurring confusion about what a term means or who owns a concept → the project needs a glossary.
- Repeated process failures (hallucinated symbols, skipped verification, guessed structure) → the project needs a framework charter.

## When NOT to use

- The docs already exist and just need correcting — that is `auditing-domain-rules`.
- A single narrow convention — that is one ordinary, area-scoped rule, not a foundational doc.

## Discover first (non-negotiable)

Before writing a line, explore the actual repo:

- **For the glossary:** grep the overlapping noun-roots and the domains that share them; open each owning module to learn the real boundaries, the real route/type/API names, and the actual incident that proves they collide. Do not invent entities or naming conventions — capture the ones the code already uses.
- **For the charter:** find the repo's real verification commands (package.json / Makefile / CI), the established patterns to mirror, and the real failure modes this codebase has hit. The charter cites *these*, not generic advice.

If you cannot ground a claim in something you read this session, it does not go in the doc.

## The two artifacts

Write each to its anatomy; full templates + filled examples are in references.

**Domain glossary** ([references/domain-glossary-template.md](references/domain-glossary-template.md)) — required parts:

- `## When` — every trigger that must make the agent STOP and read this: each ambiguous term (in every language the team uses) and each owning path.
- `## Why` — the confusion it prevents, ideally the concrete incident that motivated it.
- `## Implementation` — the canonical **ownership table** (concept → owning module/route/type → what it represents) AND the **term-disambiguation rules** (what each word maps to, and how to resolve the genuinely ambiguous ones by context).
- `## Edge Cases` + `## Review Checklist`.
- State the **source-of-truth principle**: when code and glossary disagree, fix the glossary first, then the code — never silently diverge.

**Framework charter** ([references/framework-charter-template.md](references/framework-charter-template.md)) — required parts:

- **Implementation protocol** — read the request, scan every layer the change touches (classify none/partial/full), write contracts as code (not prose), think through happy + edge cases, then code in dependency order.
- **Suspicion protocol** — the concrete failure modes this repo hits (missed duplicate code, shortcut/silent cut, hallucinated symbol, test-passes-for-wrong-reason, unverified structure claim), each with a detection check.
- **Evidence-based verification** — the repo's real commands, output shown (not "should pass").
- **Question discipline** — don't ask what the repo/rules already answer; pick the smallest-diff default and state it; reserve questions for genuine product/business decisions.

## Red Flags — STOP

- Writing the glossary/charter before grepping the actual code.
- A glossary with no `## When` triggers — it will never load at the moment of confusion.
- A glossary that lists definitions but no term→owner disambiguation for the words that actually collide.
- Inventing entities, routes, or naming conventions not found in the repo.
- A framework charter of generic platitudes ("write clean code") instead of this repo's concrete protocol, failure modes, and real commands.
- Any structural claim (symbol, path, route, command) not verified by a read this session.
