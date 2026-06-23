---
name: adopting-framework
description: >-
  Use right after the sdd-kit plugin is installed into a fresh consumer
  repo, to do the per-consumer bootstrap the plugin itself cannot ship — generate
  the domain rules and the two CLAUDE.md files, then verify. The plugin delivers
  skills/hooks/agnostic-rules; this skill is the user-invoked post-install setup.
  Triggers on: "adopt the framework", "bootstrap this repo for sdd", "post-install
  setup", "set up sdd in this repo", "onboard this repo to sdd".
---

# Adopting the Framework (post-install bootstrap)

The `sdd-kit` plugin ships the skills, the enforcement hooks, and the agnostic rules — those arrive with the install, not by copying. What the plugin **cannot** ship is the per-consumer material: the domain glossary and framework charter that describe *this* repo, and the two CLAUDE.md files that wire the agent to it. This skill is that user-invoked bootstrap: an ordered recipe ending in a verified result, not "the plugin is installed".

**Progress:** before your first artifact, reflect this phase in the harness task list (one item `in_progress`; `completed` only on the user's explicit approval of that phase's artifact; a skipped phase stays listed, marked skipped) — run standalone, seed a single item for this adoption.

## When to use

- A fresh consumer repo where the `sdd-kit` plugin is installed but no domain rules / CLAUDE.md exist yet.
- Re-verifying a partial bootstrap (some docs present, others missing).

## When NOT to use

- The plugin is not installed yet — install it first via the marketplace (`/plugin marketplace add <repo>` → install `sdd-kit`), then return here.
- You are only refreshing one bootstrapped doc — use that `bootstrapping-*` skill directly.

## The ordered procedure

Run these in order; each step verifies before the next begins.

1. **Verify install.** Confirm the plugin is reachable: `${CLAUDE_PLUGIN_ROOT}/skills-routing.json` resolves (the bundled marker). If it does not, the plugin is not installed — instruct the user to `/plugin marketplace add <repo>` and install `sdd-kit`, then stop. Also capture the consumer specifics the bootstraps need: confirm it is a git repo and note its real stack (build tool, test runner, where it keeps design docs).
2. **Bootstrap the domain rules.** Invoke `bootstrapping-glossary` to generate the consumer's `.claude/rules/domains/glossary.md` (the repo's vocabulary) and `framework.md` (how to work here). This establishes the vocabulary the next step references.
3. **Bootstrap the CLAUDE.md files.** Invoke `bootstrapping-claude-md` to generate the root entry point and `.claude/CLAUDE.md` operating manual, pointing at the rules step 2 just created.
4. **Verify (the gate — not "the plugin is installed").** Confirm the domain rules and both CLAUDE.md files exist and their internal links resolve. Then the real proof: type a registered trigger phrase and confirm the right plugin skill actually fires in the consumer repo.

## Hand off

Bootstrap complete → the repo is ready to run the SDD chain. Enter at `resolving-requirements` (a ticket) or `grilling` (a free-text idea); `sdd-lifecycle` orchestrates the full gated run.

## Red Flags — STOP

- Declaring adopted because the plugin is installed — domain rules and CLAUDE.md still missing, no trigger fired. "Installed" is not "bootstrapped".
- Running `bootstrapping-claude-md` before `bootstrapping-glossary` (the CLAUDE.md points at rules the glossary creates).
- Skipping the verify step — a bootstrap that produced no resolving docs is not done.
- Trying to copy skills/hooks into the repo — the plugin already provides them; copying is the old pre-plugin procedure.
