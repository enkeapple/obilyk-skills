---
name: adopting-framework
description: >-
  Use when installing or adopting this agnostic SDD skills framework into a
  fresh consumer repository for the first time — the one ordered procedure that
  sequences copy → symlinks → hook wiring → the three bootstraps → routing sync
  → verification, so adoption does not depend on inferring the order. Triggers
  on: "adopt the framework", "install the SDD vault", "set up the skills in this
  repo", "onboard this repo to the framework", "bootstrap a new repo".
---

# Adopting the Framework

Adopting this framework into a fresh repo is **not** a single bootstrap — it is an ordered procedure, and no single bootstrapping skill owns the sequence. Run them out of order, or skip the symlink/verify steps, and the skills exist on disk but never fire. This skill is that sequence: a positive, ordered recipe ending in a verified GREEN run, not "the files are present".

**Progress:** before your first artifact, reflect this phase in the task list per [phase-task-visualization](../../../.claude/rules/common/phase-task-visualization.md) — run standalone, seed a single item for this adoption.

## When to use

- A fresh consumer repo that does not yet carry the framework's `skills/`, `.claude/`, or rules.
- Re-verifying a partial adoption (some skills present, routing or symlinks unknown).

## When NOT to use

- The repo already has the framework wired and you are changing one skill — use `writing-skills`.
- You are only generating/refreshing one bootstrapped doc — use that `bootstrapping-*` skill directly.

## The ordered procedure

Run these in order; each step verifies before the next begins.

1. **Pre-flight — capture the consumer specifics.** Confirm the target is a git repo. Inspect and note its real stack: build tool, test runner, where it keeps design docs. These are what the agnostic bootstraps fill in — gather them now, do not guess later.
2. **Copy the source trees.** Place `skills/` and `hooks/` (the product) into the repo, plus `.claude/skills-routing.json` and `.claude/settings.json`. The symlinks and catalogs are *derived* from these — source first.
3. **Create the flat symlinks (the discovery layer).** For every `skills/<category>/<name>/SKILL.md`, create `.claude/skills/<name>` → its source dir; for every `hooks/<area>/<name>.sh`, create `.claude/hooks/<name>.sh`. **Verify:** reconcile `find skills -name SKILL.md` against `ls .claude/skills/` — every skill has exactly one live symlink, none dangling. A skill with no symlink is invisible to the harness even though its source exists.
4. **Wire and verify hooks.** Confirm `.claude/settings.json` references each hook by its `.claude/hooks/<name>.sh` path and every path resolves. **If a guard hook blocks edits to `.claude/hooks`/`settings`, that step needs a human-run command — surface it, do not work around the block.**
5. **Bootstrap the docs, in this order** (each later one depends on the earlier's output):
   1. `bootstrapping-glossary` — the domain glossary + framework charter (establishes the repo's vocabulary the next step references).
   2. `bootstrapping-claude-md` — the root entry point + `.claude/CLAUDE.md` operating manual (points at the rules the glossary just created).
   3. `bootstrapping-readme` — the human-facing skills catalog, derived from frontmatter on disk; run **last**, after every skill is present, so the catalog is complete.
6. **Sync routing.** Reconcile `.claude/skills-routing.json` against disk per [skill-routing-sync](../../../.claude/rules/common/skill-routing-sync.md): every trigger-routed skill (every skill *without* `disable-model-invocation: true`) has one key === dir === `SKILL.md name:`, a resolving `files` path, and non-empty `triggers`; reference/alias skills correctly have no entry. Confirm `jq . .claude/skills-routing.json` is valid JSON.
7. **Verify adoption (the gate — not "files exist").** Run the validators on the bootstrapped docs (frontmatter ≤1024, name regex, reference links resolve, fences balanced, word count). Then the real proof: a **GREEN run** — type a registered trigger phrase and confirm the right skill actually fires in the consumer repo. If no validator script exists in the consumer's toolchain, say so explicitly rather than claim a check that cannot run.

## Hand off

Adoption complete → the repo is ready to run the SDD chain. Enter at `resolving-requirements` (a ticket) or `grilling` (a free-text idea); `sdd-lifecycle` orchestrates the full gated run.

## Red Flags — STOP

- Declaring adopted because `skills/` source is present — symlinks unverified, no trigger fired. "Files exist" is not "adopted".
- Running a bootstrap before its prerequisite (glossary before claude-md; readme before all skills are on disk).
- Inventing the bootstrap order instead of following step 5.
- Creating symlinks without reconciling them against `find skills -name SKILL.md` (dangling or missing links pass silently).
- Working around a guard-hook block on `.claude/hooks`/`settings` instead of surfacing it for a human-run command.
- Claiming "validators pass" when no validator can actually run in the consumer's toolchain.
