---
name: adopting-framework
description: >-
  Use right after the needed marketplace plugins are installed into a fresh
  consumer repo, to do the per-consumer bootstrap the plugins themselves cannot
  ship — set up consumer routing, generate domain rules and the two CLAUDE.md
  files, then verify. Triggers on: "adopt the framework", "bootstrap this repo
  for sdd", "post-install setup", "set up sdd in this repo", "onboard this repo
  to sdd".
---

# Adopting the Framework (post-install bootstrap)

The marketplace plugins ship the skills, the enforcement hooks, and the agnostic rules — those arrive with the install. What the plugins **cannot** ship is the per-consumer material: the consumer's own `skills-routing.json`, the domain glossary and framework charter that describe *this* repo, and the two CLAUDE.md files that wire the agent to it. This skill is the user-invoked bootstrap: an ordered recipe ending in a verified result, not "the plugins are installed".

**Progress:** before your first artifact, reflect this phase in the harness task list (one item `in_progress`; `completed` only on the user's explicit approval of that phase's artifact; a skipped phase stays listed, marked skipped) — run standalone, seed a single item for this adoption.

## When to use

- A fresh consumer repo where the needed plugins are installed but consumer routing / domain rules / CLAUDE.md do not exist yet.
- Re-verifying a partial bootstrap (some docs present, others missing).

## When NOT to use

- The plugins are not installed yet — install them first via the marketplace (`/plugin marketplace add <repo>`), then return here.
- You are only refreshing one bootstrapped doc — use that `bootstrapping-*` skill directly.

## Required plugins

At minimum two plugins must be installed **and enabled** before bootstrapping:

- **`sdd-kit`** — the SDD chain, skill-authoring, and setup skills (including this one).
- **`guardrails-kit`** — the routing-bypass detection, telemetry, token-budget, and quality hooks. Without `guardrails-kit` installed and enabled, **no routing telemetry or enforcement gates fire** — the `skills-routing.json` you create in step 3 exists but nothing reads it.

Install via the marketplace if either is absent:

```bash
/plugin marketplace add <sdd-kit-repo>
/plugin marketplace add <guardrails-kit-repo>
```

Then enable both in the consumer repo's plugin settings before proceeding.

## Skill discovery — no symlinks

Skills are discovered through the installed plugins, not through per-skill symlinks. **Do not create** `.claude/skills/<name>` entries for plugin-provided skills. The consumer's `.claude/skills/` directory is reserved for skills the consumer authors locally (`kind:"local"` entries — see step 3).

## The ordered procedure

Run these in order; each step verifies before the next begins.

### Step 1 — Verify installs

Confirm both `sdd-kit` and `guardrails-kit` are installed and enabled in the consumer repo. If either is missing, instruct the user to install and enable it via the marketplace, then stop.

Also capture the consumer specifics the bootstraps need: confirm it is a git repo and note its real stack (build tool, test runner, where it keeps design docs).

### Step 2 — Bootstrap the domain rules

Invoke `bootstrapping-glossary` to generate the consumer's `.claude/rules/domains/glossary.md` (the repo's vocabulary) and `framework.md` (how to work here). This establishes the vocabulary the next steps reference.

### Step 3 — Create the consumer's `skills-routing.json`

Create `.claude/skills-routing.json` at the consumer repo root. Use schema version 2, which supports two entry kinds:

- **`kind:"ref"`** — routes a plugin-provided skill. Fields: `kind`, `plugin` (the plugin name, e.g. `"sdd-kit"`), `name` (the skill's canonical name), `triggers` (the prompt phrases that invoke it). No `files` field — the installed plugin provides the skill.
- **`kind:"local"`** — routes a skill the consumer authors in its own `.claude/skills/<name>/`. Fields: `kind`, `name`, `triggers`, `files` (pointing at the skill's `SKILL.md` inside `.claude/skills/`). Only needed for locally-authored skills.

At minimum, register the `sdd-kit` skills the consumer wants routed and metered. Example skeleton (illustrative — adjust triggers and plugin name to match your actual install):

```json
{
  "version": 2,
  "skills": {
    "grilling": {
      "kind": "ref",
      "plugin": "sdd-kit",
      "name": "grilling",
      "triggers": ["help me think this through", "brainstorm", "grill me", "I want to build"]
    },
    "writing-specs": {
      "kind": "ref",
      "plugin": "sdd-kit",
      "name": "writing-specs",
      "triggers": ["write a spec", "spec this out"]
    }
  }
}
```

The `guardrails-kit` hooks read this file from `${CLAUDE_PROJECT_DIR}/.claude/skills-routing.json` and write telemetry to `.claude/state/`.

### Step 4 — Bootstrap the CLAUDE.md files

Invoke `bootstrapping-claude-md` to generate the root entry point and `.claude/CLAUDE.md` operating manual, pointing at the rules step 2 just created and the routing file from step 3.

### Step 5 — Verify (the gate)

Confirm the domain rules, both CLAUDE.md files, and `.claude/skills-routing.json` exist and their internal links resolve. Then the real proof: type a registered trigger phrase and confirm:

1. The right plugin skill fires in the consumer repo.
2. A new line appears in `.claude/state/_metrics.jsonl` — this confirms `guardrails-kit` is active and reading the routing file.

If no `_metrics.jsonl` line appears, `guardrails-kit` is not wired correctly — re-check that it is both installed and enabled.

## Dev loop — editing a plugin skill

Because discovery flows through the installed plugin (a cached copy), editing a skill in the plugin's source directory does **not** automatically update what the consumer repo sees. To pick up a WIP edit:

1. Make the edit in the plugin source.
2. Re-install or update the plugin in the consumer repo (`/plugin update <plugin-name>` or the equivalent marketplace update command) to sync the cached copy.
3. Re-run the trigger to confirm the updated skill fires.

There is no `.claude/skills/` symlink bridging WIP edits — the update-the-installed-plugin step is the only path.

## Hand off

Bootstrap complete → the repo is ready to run the SDD chain. Enter at `resolving-requirements` (a ticket) or `grilling` (a free-text idea); `sdd-lifecycle` orchestrates the full gated run.

## Red flags — STOP

- Declaring adopted because the plugins are installed — consumer routing, domain rules, and CLAUDE.md still missing, no trigger fired. "Installed" is not "bootstrapped".
- Missing `guardrails-kit` — routing rules exist but nothing enforces or meters them; `.claude/state/_metrics.jsonl` never appears.
- Creating `.claude/skills/<name>` entries for plugin-provided skills — plugin skills are discovered through the installed plugin, not via per-skill symlinks.
- Running `bootstrapping-claude-md` before `bootstrapping-glossary` (the CLAUDE.md points at rules the glossary creates).
- Skipping the verify step — a bootstrap that produced no firing trigger and no metrics entry is not done.
