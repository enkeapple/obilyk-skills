# ADR-0003 — Flat, per-concern plugins instead of a nested monolith

- **Status:** Accepted
- **Date:** 2026-06-28
- **Related:** [spec](../specs/2026-06-28-flatten-plugin-architecture.md), [plan](../plans/2026-06-28-flatten-plugin-architecture.md)

## Context

The marketplace published 5 plugins, of which `saleizo-core` was a monolith: 31 skills under five category subdirs (`chain/`, `authoring/`, `setup/`, `aliases/`, `session/`), and `saleizo-design` nested its 6 skills under `design/`/`prose/`/`review/`. `saleizo-learning` and `saleizo-react-native` were already flat (`skills/<name>/`), so the repo carried two conflicting layout conventions. Category dirs add a navigation level, force a per-category README section, and bundle unrelated concerns (alias facades, framework bootstrap, the SDD chain) behind one install and one version. The owner wanted a maximally flat layout where one plugin equals one concern.

## Decision

Adopt **one flat plugin per concern**: skills live directly at `plugins/<kit>/skills/<name>/SKILL.md` with no category dir, and each former category became its own plugin. `saleizo-core` split into `saleizo-core` (the SDD chain + `systematic-debugging` + `handoff`), `saleizo-commands` (aliases), `saleizo-authoring` (`writing-*`), and `saleizo-foundation` (adopt/bootstrap/audit + `reviewing-telemetry`); `saleizo-design` split into `saleizo-design` and `saleizo-prose` — **9 plugins** total. Non-skill shared assets sit at `skills/shared/` per plugin, so `../shared/` links survive the flatten. The decomposition and the flat path convention are recorded in both `CLAUDE.md` files and `glossary.md`.

## Options considered

- **Option A (chosen) — per-category plugins, flat skills.** One plugin per concern; flattens the directory nesting and breaks the monolith in one move; matches the already-flat learning/react-native plugins. Cost: more plugins to install/route and two major version bumps.
- **Option B — coarser 3-plugin split** (core+session+authoring, commands, foundation). Fewer plugins, less namespace churn, but `saleizo-core` stays large and still mixes the chain with authoring — the concern boundary the owner wanted is blurred.
- **Option C — per-skill micro-plugins.** Maximally flat, but ~38 plugins to maintain, install, and route — a maintenance and routing-surface blowup for no concern-level benefit.

## Consequences

- **Cost / negative:** breaking change for consumers — skill namespaces move (`saleizo-core:writing-adrs` → `saleizo-authoring:writing-adrs`), so `saleizo-core` and `saleizo-design` take **major** version bumps and consumers must reinstall; the marketplace and routing now span 9 plugins, a wider surface to keep in sync.
- **Follow-ups:** re-publish the marketplace and reinstall before the new structure is live (skills run from the installed cache, not the working tree); the `bootstrapping-readme`/`auditing-readme` skills still teach category derivation for consumer repos that choose to nest — that capability is retained, not removed.
- **Enabled:** each concern installs and versions independently; the flat layout is now single-valued across all skill-bearing plugins.

## Related files

- `.claude-plugin/marketplace.json` — the 9-plugin manifest
- `.claude/skills-routing.json` — routing `plugin:` field per skill
- `.claude/rules/domains/glossary.md` → skill row — the `plugins/<kit>/skills/<name>/` convention
