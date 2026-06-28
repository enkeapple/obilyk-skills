---
description: 'When a routed skill is added, renamed, deleted, or has its triggers changed, update the consumer repo root .claude/skills-routing.json in the same change so the routing hooks stay in sync. Loads only when the routing file or skill source is touched.'
paths:
  - '.claude/skills-routing.json'
  - 'plugins/**/skills/**/*.md'
  - '.claude/skills/**/*.md'
---

# Skill Routing Sync

How to work in this repo when you touch the routed skill set. Keeps the consumer repo's root [.claude/skills-routing.json](../../.claude/skills-routing.json) — the registry the routing hooks read — in lockstep with the skills in use. This is judgment work (choosing trigger phrases), not a mechanical sync, which is why it is a rule and not a linter.

## When

STOP and update routing whenever you change the **shape** of the routed skill set:

- You **add** a plugin-provided skill to routing (a new `ref` entry — you want it detected and metered).
- You **author** a new consumer-local skill (a new `local` entry under `.claude/skills/<name>/`).
- You **rename** or **remove** a routed skill — update or delete its entry.
- You **change a skill's triggers** — the phrases/keywords a user prompt would use to invoke it (usually mirrored in the skill's `description` / "Triggers on:" line).

Editing only a skill's *body* or its `references/*.md` / `assets/*.md` — without changing its name or trigger phrases — does NOT require a routing change.

## Why

The hooks `detect-bypass.sh`, `skill-gate.sh`, and `log-skill-usage.sh` read the consumer repo's root `.claude/skills-routing.json` as the **single source of truth** (accessed via `${CLAUDE_PROJECT_DIR}`): `detect-bypass.sh` iterates `.skills | to_entries[]` and matches each entry's `.triggers` against the prompt. A skill that is not registered there is invisible to routing — its triggers never fire, bypass is never detected, usage is never logged. A stale entry key or wrong `plugin`/`files` value silently breaks the same machinery.

There is **no per-plugin routing file** — the consumer root file governs everything. Skills provided by a marketplace plugin are discovered through the installed plugin, not through local file paths; their routing entries carry `kind: "ref"` with no `files`. Consumer-authored skills live under `.claude/skills/<name>/` and carry `kind: "local"` with a `files` path.

## Implementation

The `skills` map uses **schema v2**: every entry has a `kind` field that determines its remaining fields.

### Entry kinds

| Kind | When | Required fields | `files`? |
| --- | --- | --- | --- |
| `ref` | Skill is provided by a marketplace plugin | `kind`, `plugin`, `name`, `triggers` | No |
| `local` | Skill is authored in this consumer repo | `kind`, `triggers`, `files` | Yes — real path under `.claude/skills/…` |

The **entry key** is always the skill's canonical name (bare — no plugin prefix). For a `ref` entry, `name` repeats that canonical name and `plugin` gives provenance.

### Canonical example

```jsonc
// ❌ WRONG — a ref entry has no `files`; a new local skill was added without an entry;
// detect-bypass never matches its triggers; the routed plugin skill is unroutable.
{
  "skills": {
    "grilling": { "kind": "ref", "plugin": "saleizo-core", "name": "grilling",
                  "triggers": ["grill me", "brainstorm"],
                  "files": [".claude/skills/grilling/SKILL.md"] }
  }
}

// ✅ CORRECT — ref has no files; local has a files path; key === canonical name.
{
  "skills": {
    "grilling":      { "kind": "ref",   "plugin": "saleizo-core",  "name": "grilling",
                       "triggers": ["grill me", "brainstorm", "help me think this through"] },
    "my-own-skill":  { "kind": "local", "triggers": ["my trigger phrase"],
                       "files": [".claude/skills/my-own-skill/SKILL.md"] }
  }
}
```

### Per-operation steps

- **Add a plugin skill to routing** → add a `ref` entry. Key = canonical name; `plugin` = providing plugin name; `name` = same canonical name; `triggers` = phrases from the skill's stated trigger list. No `files`.
- **Author a new local skill** → add a `local` entry. Key = skill directory name; `triggers` from the skill's "Triggers on:" line; `files` = the real path to its `SKILL.md` under `.claude/skills/<name>/SKILL.md`.
- **Rename or remove** → rename the key (and fix `name` for a `ref`) or remove the entry in the same change.
- **Trigger change** → update the `triggers` array to match the skill's stated triggers.
- **Rename a canonical skill an alias delegates to** → fix the alias body that names it (the alias body is a structural skill-name reference). The alias has no routing key to update, but its prose target must still resolve.
- After editing, confirm the file is still valid JSON and, for any `local` entry, that its `files` path resolves before calling the change done.

## Edge Cases

- When NOT to apply: editing a skill's prose, examples, or `references/*.md` / `assets/*.md` without touching its name or trigger phrases — internal reference files are not listed and need no change.
- **Any skill with `disable-model-invocation: true` is not trigger-routed — do NOT add an entry for it.** This covers two sub-kinds: a **reference/methodology** skill (e.g. `improve-codebase-architecture`) and an **alias-facade** skill under `plugins/saleizo-core/skills/aliases/` (`/sdd`, `/grill`, …) that delegates to a canonical skill. Absence from `skills-routing.json` is correct for both, not a gap.
- This rule governs only the `skills` map. Leave `version` and `ruleGates` alone unless a separate task requires them.
- Trigger phrases are bilingual where the skill declares them — include Russian triggers if the skill lists them (e.g. `handoff` lists «передать сессию»).
- A `_`-prefixed path under `.claude/state/` or the project root (e.g. `_metrics.jsonl`) is runtime state, not a skill — do not add routing entries for it.

## Review Checklist

- [ ] File is valid JSON (`jq . .claude/skills-routing.json`).
- [ ] Every entry has a `kind` field (`jq '[.skills[] | has("kind")] | all' .claude/skills-routing.json` → `true`).
- [ ] Every `ref` entry has `plugin` and `name` and does NOT have `files` (`jq '.skills | to_entries[] | select(.value.kind=="ref") | .value | {has_plugin: has("plugin"), has_name: has("name"), no_files: (has("files") | not)}' .claude/skills-routing.json`).
- [ ] Every `local` entry's `files` path resolves on disk.
- [ ] For every `ref`, the entry key equals `name` (`jq '.skills | to_entries[] | select(.value.kind=="ref") | select(.key != .value.name)' .claude/skills-routing.json` → empty).
- [ ] `triggers` is non-empty for every entry and reflects the skill's stated trigger phrases (incl. RU where declared).
- [ ] No entry exists for a deleted/removed skill, and no entry carries `disable-model-invocation: true`.
