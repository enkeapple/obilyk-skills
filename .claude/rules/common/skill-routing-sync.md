---
description: 'When a skill under .claude/skills/** is created, renamed, deleted, or has its triggers changed, update skills-routing.json in the same change so the routing hooks stay in sync. Global rule — applies whenever the skill set changes.'
---

# Skill Routing Sync

How to work in this repo when you touch the skill set. Keeps [skills-routing.json](../../skills-routing.json) — the registry the routing hooks read — in lockstep with the skills on disk. This is judgment work (choosing trigger phrases), not a mechanical sync, which is why it is a rule and not a linter.

## When

STOP and update routing whenever you change the **shape** of a skill under `.claude/skills/**`:

- You **create** a new skill directory (new `.claude/skills/<name>/SKILL.md`).
- You **rename** or **move** a skill directory, or relocate its `SKILL.md`.
- You **delete** a skill.
- You **change a skill's triggers** — the phrases/keywords a user prompt would use to invoke it (usually mirrored in the skill's `description` / "Triggers on:" line).

Editing only a skill's *body* or its `references/*.md` — without changing its name, location, or trigger phrases — does NOT require a routing change.

## Why

The hooks [detect-bypass.sh](../../hooks/detect-bypass.sh), [skill-gate.sh](../../hooks/skill-gate.sh), and [log-skill-usage.sh](../../hooks/log-skill-usage.sh) read `skills-routing.json` as the single source of truth: `detect-bypass.sh` iterates `.skills | to_entries[]` and matches each entry's `.triggers` against the prompt, pointing at `.files`. A skill that is not registered there is invisible to routing — its triggers never fire, bypass is never detected, usage is never logged. A stale `files` path or wrong key silently breaks the same machinery.

## Implementation

In the same change that creates/renames/deletes a skill or edits its triggers, update the `skills` map in `skills-routing.json` so it matches disk. Each skill is **one entry**: the key is the skill's directory name (which MUST equal the `name:` in its `SKILL.md` frontmatter), with a `triggers` array and a `files` array pointing at its `SKILL.md`.

```jsonc
// ❌ WRONG — new skill .claude/skills/writing-specs/ added, routing left untouched.
// detect-bypass never matches its triggers; the skill is unroutable.
{
  "skills": {
    "handoff": { "triggers": ["handoff", "..."], "files": [".claude/skills/handoff/SKILL.md"] }
  }
}

// ✅ CORRECT — every skill on disk has a matching entry; key === dir name === SKILL.md `name`.
{
  "skills": {
    "handoff":       { "triggers": ["handoff", "save the plan", "..."], "files": [".claude/skills/handoff/SKILL.md"] },
    "writing-specs": { "triggers": ["write a spec", "spec this out", "..."], "files": [".claude/skills/writing-specs/SKILL.md"] }
  }
}
```

- **Create** → add an entry. Derive `triggers` from the skill's `description` / "Triggers on:" line — the phrases a user would actually type, not a paraphrase. Set `files` to the real `SKILL.md` path.
- **Rename/move** → rename the key AND fix the `files` path in the same edit; the key must still equal the new dir name and the `SKILL.md` `name:`.
- **Delete** → remove the entry.
- **Trigger change** → update the `triggers` array to match the skill's stated triggers.
- After editing, confirm the file is still valid JSON and the `files` path resolves before calling the change done.

## Edge Cases

- When NOT to apply: editing a skill's prose, examples, or `references/*.md` without touching its name, location, or trigger phrases — `files` points at `SKILL.md`, so internal reference files are not listed and need no change.
- Entries under `.claude/skills/` that are not skill directories (e.g. `_metrics.jsonl`, any `_`-prefixed path) are not skills — do not add entries for them.
- A reference/methodology skill that opts out of routing with `disable-model-invocation: true` in its `SKILL.md` frontmatter and declares no trigger phrases (e.g. `writing-great-skills`) is not trigger-routed — do NOT add a `triggers` entry for it. The "every skill has a key" check below applies only to invocable skills.
- This rule governs only the `skills` map. Leave `version` and `ruleGates` alone unless a separate task requires them.
- Trigger phrases are bilingual where the skill is — include the Russian triggers too if the skill declares them (e.g. `handoff` lists «передать сесси»).

## Review Checklist

- [ ] Every invocable skill directory under `.claude/skills/` (excluding `_`-prefixed entries and `disable-model-invocation` reference skills) has exactly one matching key in `skills-routing.json` (`ls .claude/skills/` vs `jq '.skills | keys' .claude/skills-routing.json`).
- [ ] Each entry's key equals the directory name AND the `name:` in that skill's `SKILL.md`.
- [ ] Each entry's `files` path exists and points at the skill's `SKILL.md`.
- [ ] `triggers` is non-empty and reflects the skill's stated trigger phrases (incl. RU where declared).
- [ ] No entry exists for a deleted/renamed skill.
- [ ] File is valid JSON (`jq . .claude/skills-routing.json`).
