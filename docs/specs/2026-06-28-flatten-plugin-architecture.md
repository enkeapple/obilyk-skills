# Spec: Flatten & decompose the plugin architecture

> Status: draft for review · Mode: APPLY (the vault is its own consumer repo) · Type: refactor/migration

## Goal

Replace the nested, monolithic `saleizo-core` (31 skills across 5 category subdirs) with **per-concern, flat plugins** — every skill at `plugins/<kit>/skills/<name>/SKILL.md` (no category dir) — so the marketplace publishes 8 narrowly-scoped plugins matching the already-flat `saleizo-learning` / `saleizo-react-native` convention.

## Scope

- Split `saleizo-core` (31 skills) into 4 flat plugins:
  - **saleizo-core** — the 11 `chain/` skills + `handoff` (12 total): `grilling`, `writing-specs`, `writing-plans`, `pre-implementation-protocol`, `resolving-requirements`, `sdd-lifecycle`, `test-driven-development`, `inline-driven-development`, `subagent-driven-development`, `systematic-debugging`, `verifying-implementation`, `handoff`.
  - **saleizo-commands** (NEW) — the 5 aliases: `adr`, `audit`, `grill`, `sdd`, `spec`.
  - **saleizo-authoring** (NEW) — `writing-adrs`, `writing-hooks`, `writing-lessons`, `writing-rules`, `writing-skills` (5).
  - **saleizo-foundation** (NEW) — `adopting-framework`, `auditing-claude-md`, `auditing-glossary`, `auditing-hooks`, `auditing-readme`, `auditing-conflicts`, `bootstrapping-claude-md`, `bootstrapping-glossary`, `bootstrapping-readme`, `reviewing-telemetry` (10) + `skills/shared/placeholder-keys.md`.
- Flatten and split `saleizo-design` (6 skills) into 2 flat plugins:
  - **saleizo-design** — `codebase-design`, `improve-codebase-architecture`, `auditing-code-quality` (3).
  - **saleizo-prose** (NEW) — `humanizing-prose`, `tightening-prose`, `drafting-release-notes` (3) + `skills/shared/` (`scoring-rubric.md`, `phrase-catalog.md`).
- Move every skill dir with `git mv` (preserve history); `shared/` rises to `skills/shared/` in its plugin.
- Rewrite manifests in lockstep: `marketplace.json` (+4 entries), the 2 edited + 4 new `plugin.json`, `.claude/skills-routing.json` (18 `plugin:` field flips).
- Update live cross-references: both CLAUDE.md, `glossary.md`, `skill-routing-sync.md`, root README + 4 new per-plugin READMEs + 2 edited READMEs.
- Version bumps: `saleizo-core` & `saleizo-design` → **major**; 4 new plugins → `1.0.0`.

## Out of scope

- **No skill body/behavior change** — pure relocation + reference rewiring. No SKILL.md prose edits except the path strings that the move invalidates.
- **ADR rewrites** — `docs/adr/0002` cites `…/saleizo-core/skills/authoring/writing-hooks/SKILL.md`; ADRs are immutable point-in-time records (writing-adrs convention). Left as historical record, NOT updated.
- **`lessons-learned.md` stale paths** — already carries pre-rename `craft-kit`/`sdd-kit` paths by the same historical-record precedent. Not updated.
- **`plugins/ai-kit/`** — stale/phantom dir, not in the marketplace. Left untouched.
- **`.claude/settings.local.json`** `enabledPlugins` — gitignored local file; the human re-enables the 4 new plugins locally after publish.
- **The installed plugin cache** (`~/.claude/plugins/cache/saleizo/…`) — re-installed by consumers after publish, not a repo edit.
- **Pre-existing routing/manifest drift not caused by this move** — except two cases corrected for free when the new `plugin.json` files are authored (each must list every skill it owns): `drafting-release-notes` (missing from `saleizo-design`'s current `plugin.json`) → `saleizo-prose`, and `reviewing-telemetry` (missing from `saleizo-core`'s current `plugin.json`, though present on disk and routed) → `saleizo-foundation`.
- Renaming or merging `saleizo-controls`, `saleizo-learning`, `saleizo-react-native` (already flat / hooks-only — untouched).

## Contracts

### New `plugin.json` shape (flat — no category in skill paths)

```json
{
  "name": "saleizo-authoring",
  "description": "Test-first authoring of skills, hooks, rules, lessons, and ADRs.",
  "version": "1.0.0",
  "skills": [
    "./skills/writing-adrs",
    "./skills/writing-hooks",
    "./skills/writing-lessons",
    "./skills/writing-rules",
    "./skills/writing-skills"
  ]
}
```

`saleizo-commands` (5 alias skills), `saleizo-foundation` (10 skills, `shared/` is NOT listed as a skill), and `saleizo-prose` (3 skills) follow the same shape. `saleizo-core` and `saleizo-design` keep their `plugin.json` but with flattened (`./skills/<name>`, no category) and reduced `skills[]` arrays + bumped major `version`.

### `marketplace.json` — add 4 entries (order alongside existing)

```json
{ "name": "saleizo-commands",   "source": "./plugins/saleizo-commands" },
{ "name": "saleizo-authoring",  "source": "./plugins/saleizo-authoring" },
{ "name": "saleizo-foundation", "source": "./plugins/saleizo-foundation" },
{ "name": "saleizo-prose",      "source": "./plugins/saleizo-prose" }
```

### `skills-routing.json` — `plugin:` field flips (18 entries; `kind`/`name`/`triggers` unchanged)

| New `plugin` value | Skill `name` entries (count) |
| --- | --- |
| `saleizo-authoring` | writing-adrs, writing-hooks, writing-lessons, writing-rules, writing-skills (5) |
| `saleizo-foundation` | adopting-framework, auditing-{claude-md,glossary,hooks,readme,conflicts}, bootstrapping-{claude-md,glossary,readme}, reviewing-telemetry (10) |
| `saleizo-prose` | humanizing-prose, tightening-prose, drafting-release-notes (3) |
| *unchanged* `saleizo-core` | the 11 chain skills + handoff (12) |
| *unchanged* `saleizo-design` | codebase-design (1) |
| *unchanged* `saleizo-react-native` | accessibility (1) |

Aliases (`adr`/`audit`/`grill`/`sdd`/`spec`) and `disable-model-invocation` skills (`improve-codebase-architecture`, `auditing-code-quality`) carry **no** routing entry — saleizo-commands gets none; this is correct, not a gap (per `skill-routing-sync.md`). Total entries remain 32.

### Invariant preserved

`name === dir === SKILL.md name:` for every skill; routing key === dir === `name:` for every *routed* skill. Only the `plugin:` field and the on-disk path change.

## Files touched

| File(s) | Change | Why |
| --- | --- | --- |
| `plugins/saleizo-core/skills/{authoring,setup,aliases}/*` | `git mv` (DELETE from core) | move 20 skills out to their new plugins |
| `plugins/saleizo-core/skills/chain/*`, `session/handoff` | `git mv` → `plugins/saleizo-core/skills/<name>` | flatten the 12 that stay |
| `plugins/saleizo-commands/` | NEW | plugin.json + README + 5 alias skill dirs (moved) |
| `plugins/saleizo-authoring/` | NEW | plugin.json + README + 5 writing-* skill dirs (moved) |
| `plugins/saleizo-foundation/` | NEW | plugin.json + README + 10 skill dirs + `skills/shared/placeholder-keys.md` (moved) |
| `plugins/saleizo-prose/` | NEW | plugin.json + README + 3 prose skill dirs + `skills/shared/` (moved) |
| `plugins/saleizo-design/skills/{design,prose,review}/*` | `git mv` → flat; prose dirs → saleizo-prose | flatten + split |
| `plugins/saleizo-core/.claude-plugin/plugin.json` | EDIT | skills[] → 12 flat paths; bump major |
| `plugins/saleizo-design/.claude-plugin/plugin.json` | EDIT | skills[] → 3 flat paths; bump major |
| `.claude-plugin/marketplace.json` | EDIT | +4 plugin entries |
| `.claude/skills-routing.json` | EDIT | 18 `plugin:` flips (gated: read `skill-routing-sync.md` first) |
| `CLAUDE.md` (root) | EDIT | "5 plugins" → 8; plugin descriptions; routing/where-rules tables; paths |
| `.claude/CLAUDE.md` | EDIT | `behavioral-baseline.md` path → saleizo-foundation; plugin-name mentions; hook-location prose |
| `.claude/rules/domains/glossary.md` | EDIT | path convention `…/skills/<name>/`; "five kits" → eight; ownership table; aliases-location note |
| `.claude/rules/common/skill-routing-sync.md` | EDIT | `plugins/saleizo-core/skills/aliases/` → `plugins/saleizo-commands/skills/` |
| `README.md` (root) | EDIT | plugin catalog: +4 plugins, updated descriptions/links |
| `plugins/saleizo-core/README.md`, `plugins/saleizo-design/README.md` | EDIT | reduced skill catalogs + flat paths |
| `plugins/saleizo-{core,design}/skills/**/{catalog-derivation,readme-scaffold,audit-report-example}.md` | REVIEW/EDIT | illustrative example assets that cite category paths — update only where they assert a real current path; keep if illustrative-only |

## Edge cases

- **Empty case** — a new plugin with a `shared/` dir but the loader scanning `skills/*` for SKILL.md: `shared/` has no SKILL.md → must NOT be listed in `plugin.json` `skills[]` and must not be mis-detected as a skill. Verify the validators/loader ignore it (precedent: `setup/shared` already exists undetected today).
- **Link-resolution case** — every `../shared/` and `../../shared/` relative link in moved skills must still resolve after the category dir is gone (it should, since `shared/` rises one level in lockstep). Verify by running the reference-link validator on each moved skill.
- **Cross-plugin invocation** — aliases reference canonical skills by bare name (`sdd-lifecycle`, etc.); the `Skill` tool resolves bare names across plugins. Verify each of the 5 aliases still invokes its target after the move.
- **Partial move (concurrency/abort)** — a half-applied `git mv` leaves a skill in neither/both plugins. The change must reach a consistent end state: every routed skill's `plugin:` matches the plugin its dir actually lives in (the routing-sync invariant).
- **Stale references** — a reference to an old `skills/<category>/` path left anywhere live (not in immutable ADR/lessons) is a defect; the full-repo grep in Verification must come back clean of live category-path refs.

## Verification

No build/test pipeline exists; verification is structural (per framework.md). Run and paste output for each:

1. **Skill validators** (frontmatter ≤1024, name regex, **every reference link resolves**, fences balanced, word count) over all moved/new skills.
2. **Routing ↔ disk parity** — for each routing entry, assert its `plugin` matches the plugin dir its `name` lives in:
   ```
   # every routed skill dir exists under the plugin its entry names
   # and no entry points at saleizo-core for a moved skill
   ```
3. **Manifest ↔ disk parity** — every `plugin.json` `skills[]` path exists on disk; every `marketplace.json` `source` dir exists and has `.claude-plugin/plugin.json`.
4. **No live stale paths** — whole-repo grep (incl. `.claude/`, `docs/` excluding `docs/adr/`, READMEs) for `skills/(chain|authoring|setup|session|aliases|design|prose|review)/` returns only immutable-record hits (ADR, lessons-learned).
5. **Invocation smoke-check** — invoke ≥1 moved skill per new plugin by bare name and confirm it loads (e.g. `writing-adrs`, an alias, a foundation skill, a prose skill).
6. **`auditing-conflicts` / `auditing-readme` / `auditing-glossary`** — run the conflict + drift auditors to confirm no orphan refs, no routing/README/glossary drift introduced.

## Risks

- **Wide blast radius across two CLAUDE.md + glossary + README** — a missed live reference breaks a link silently. *Mitigation:* Verification step 4 (whole-repo grep) is the backstop; run it as a gate, not an afterthought.
- **Routing-sync gate** — editing `skills-routing.json` is denied until `skill-routing-sync.md` is read that turn (`skill-gate.sh`). *Mitigation:* read it first in the routing task.
- **`git mv` of a dir with `shared/`** — moving a category dir that contains both skills and `shared/` to different destinations needs per-subdir moves, not one bulk mv. *Mitigation:* the plan sequences moves per target plugin, `shared/` explicitly.
- **Breaking change for installed consumers** — namespaces change (`saleizo-core:writing-adrs` → `saleizo-authoring:writing-adrs`); anyone who hardcoded a namespaced reference breaks. *Mitigation:* major version bump signals it; verified that this repo stores zero namespaced tokens, so internal breakage is nil.
- **Illustrative example assets** — the readme/catalog example files may cite category paths as illustration; editing them to "fix" an illustration is churn. *Mitigation:* the Files-touched REVIEW row — edit only where a real current path is asserted.
