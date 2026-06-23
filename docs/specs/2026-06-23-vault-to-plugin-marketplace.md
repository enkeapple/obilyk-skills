# Vault → Claude Code plugin marketplace (3 plugins)

## Goal

Restructure the SDD-workflow repo so it IS a Claude Code plugin marketplace publishing three independent plugins (`sdd-framework`, `learning-skills`, `dev-utilities`), while the repo keeps working as the in-place dev environment for authoring those skills. Replaces the manual `adopting-framework` copy procedure with marketplace install + a user-invoked per-consumer bootstrap.

## Scope

- Root `.claude-plugin/marketplace.json` listing the 3 plugins (`metadata.pluginRoot: "./plugins"`).
- `plugins/<name>/.claude-plugin/plugin.json` for each plugin.
- Physical `git mv` of skill dirs from `skills/<category>/` into `plugins/<plugin>/skills/<category>/` (category nesting preserved, NOT flattened).
- Bundle the 3 consumer-facing agnostic rules into `plugins/sdd-framework/rules/common/` and rewrite the 17 skill links (11 files) from `../../../.claude/rules/...` to the plugin-root form.
- Ship the curated enforcement hook subset in `plugins/sdd-framework/hooks/` + `hooks/hooks.json`, modified to read routing from `${CLAUDE_PLUGIN_ROOT}` and write state to `${CLAUDE_PROJECT_DIR}`.
- A bundled `plugins/sdd-framework/skills-routing.json` listing only sdd-framework's 22 trigger-routed skills.
- Rewrite `adopting-framework` from a copy procedure into a user-invoked post-install bootstrap orchestrator.
- Repoint `scripts/link-skills.sh` and `scripts/link-hooks.sh` so the vault's `.claude/skills/` and `.claude/hooks/` dev symlinks resolve into the new `plugins/*` tree.

## Out of scope

- Publishing the marketplace to a public registry / changing remote/marketplace discovery for end users (the repo IS the source; install is local-git `/plugin marketplace add .`).
- Versioning policy, changesets, or CI release automation for the plugins.
- Any change to skill BODIES beyond the mechanical rule-link rewrite and the `adopting-framework` rewrite (no methodology edits).
- A 4th `sdd-authoring` plugin — authoring skills ship inside `sdd-framework` (decision 6).
- Bundling domain rules (`glossary`, `framework`) or vault-only authoring rules into any plugin — they stay vault-only / per-consumer-generated.
- `dev-utilities` and `learning-skills` getting hooks or a bundled routing.json (skills-only).
- Editing the vault's own root `CLAUDE.md` / `.claude/CLAUDE.md` operating manuals (they govern the dev env, not a plugin).

## Contracts

### `.claude-plugin/marketplace.json` (NEW)

```json
{
  "name": "sdd-workflow",
  "metadata": { "pluginRoot": "./plugins" },
  "plugins": [
    { "name": "sdd-framework",  "source": "sdd-framework" },
    { "name": "learning-skills", "source": "learning-skills" },
    { "name": "dev-utilities",   "source": "dev-utilities" }
  ]
}
```

### `plugins/<name>/.claude-plugin/plugin.json` (NEW ×3)

Skills auto-discover from each plugin's `skills/` dir (listing optional). `sdd-framework` additionally wires hooks via the auto-loaded `hooks/hooks.json` convention; the others are skills-only.

```json
// plugins/sdd-framework/.claude-plugin/plugin.json
{ "name": "sdd-framework", "description": "Gated spec-driven-development chain + authoring + foundation.", "version": "0.1.0" }
// plugins/learning-skills/.claude-plugin/plugin.json
{ "name": "learning-skills", "description": "User-invoked learning skills.", "version": "0.1.0" }
// plugins/dev-utilities/.claude-plugin/plugin.json
{ "name": "dev-utilities", "description": "Deep-module design vocabulary + prose tightening/humanizing.", "version": "0.1.0" }
```

### Hook routing/state path change (the 5 shipped hooks are independent COPIES, not the vault originals)

The vault's `hooks/*.sh` stay unchanged (project-dir routing); the plugin gets edited copies. Both forms work because the copy uses a graceful fallback (no `:?` hard-fail), so even if a shipped copy ever runs without `CLAUDE_PLUGIN_ROOT` it degrades instead of crashing.

```bash
# Vault original (unchanged) — routing read from the project dir
ROUTING="${CLAUDE_PROJECT_DIR:-.}/.claude/skills-routing.json"
# Shipped copy (plugins/sdd-framework/hooks/) — prefer the bundled plugin routing, fall back gracefully
ROUTING="${CLAUDE_PLUGIN_ROOT:-${CLAUDE_PROJECT_DIR:-.}/.claude}/skills-routing.json"
STATE_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/state/$SID"           # state stays project-local
METRICS="${CLAUDE_PROJECT_DIR:-.}/.claude/state/_metrics.jsonl"   # moved out of .claude/skills/ (see Risks)
```

### `plugins/sdd-framework/hooks/hooks.json` (NEW)

Event→hook wiring for the 5 shipped hooks, using `${CLAUDE_PLUGIN_ROOT}` for the command paths. Mirrors the matchers in the vault's `.claude/settings.json` for: UserPromptSubmit→reset-turn-budget; PostToolUse(`.*`)→token-guard; PostToolUse(`Read|Skill|Edit|Write|MultiEdit`)→detect-bypass; Stop→log-skill-usage; PreToolUse(`Edit|Write|MultiEdit`)→skill-gate.

### Rule-link rewrite (EDIT, 17 occurrences / 11 files)

```text
# BEFORE (in a SKILL.md under plugins/sdd-framework/skills/<cat>/<name>/)
](../../../.claude/rules/common/phase-task-visualization.md)
# AFTER — resolves to the bundled shared rule via plugin root
](${CLAUDE_PLUGIN_ROOT}/rules/common/phase-task-visualization.md)
```

Applies to the 3 agnostic rules only: `phase-task-visualization` (10), `interactive-gates` (4), `scoping-skill-value` (3).

### `adopting-framework` rewritten procedure (EDIT — body + frontmatter)

```text
New ordered steps (user-invoked; replaces the old copy/symlink/wiring/routing-sync procedure):
1. Verify install — confirm the plugin is reachable: ${CLAUDE_PLUGIN_ROOT}/skills-routing.json
   resolves (the bundled marker). If unreachable, instruct the user to run
   `/plugin marketplace add <repo>` + install sdd-framework, then stop.
2. Bootstrap domain rules — invoke `bootstrapping-glossary` (generates the consumer's
   .claude/rules/domains/{glossary,framework}.md).
3. Bootstrap CLAUDE.md — invoke `bootstrapping-claude-md` (consumer root + .claude/CLAUDE.md).
4. Verify — domain rules + both CLAUDE.md files exist and resolve.

- `bootstrapping-readme` is NOT part of this orchestrator (a consumer cataloging its OWN
  skills invokes it separately; the framework's skills are provided by the plugin). Out of scope here.
- Frontmatter: `description` and `triggers` rewritten from copy-procedure language
  ("install the SDD vault", "set up the skills in this repo") to post-install bootstrap
  language; the trigger change propagates to BOTH the vault `.claude/skills-routing.json`
  entry and the bundled `plugins/sdd-framework/skills-routing.json` entry.
```

### Bundled `plugins/sdd-framework/skills-routing.json` content

Derivation rule: the vault's 25 trigger-routed skills MINUS the 3 that belong to other plugins (`codebase-design`, `tightening-prose`, `humanizing-prose`) = the 22 sdd-framework keys. Each entry's `files` path is rewritten to the plugin-relative `skills/<category>/<name>/SKILL.md` location.

## Files touched

| File(s) | Change | Why |
|------|--------|-----|
| `.claude-plugin/marketplace.json` | NEW | declare the 3-plugin marketplace |
| `plugins/sdd-framework/.claude-plugin/plugin.json` | NEW | manifest |
| `plugins/learning-skills/.claude-plugin/plugin.json` | NEW | manifest |
| `plugins/dev-utilities/.claude-plugin/plugin.json` | NEW | manifest |
| `skills/{apply-chain,authoring,foundation,process,entrypoints}/*` → `plugins/sdd-framework/skills/...` | MOVE | 26 skill dirs into the plugin (git mv) |
| `skills/personal/*` → `plugins/learning-skills/skills/personal/...` | MOVE | 7 skill dirs |
| `skills/{design,prose}/*` → `plugins/dev-utilities/skills/...` | MOVE | 4 skill dirs |
| `.claude/rules/common/{phase-task-visualization,interactive-gates,scoping-skill-value}.md` → `plugins/sdd-framework/rules/common/` | MOVE | bundle the 3 agnostic rules (shared, single copy) |
| 11 `SKILL.md` (see Contracts) | EDIT | rewrite 17 rule links to `${CLAUDE_PLUGIN_ROOT}` form |
| `plugins/sdd-framework/skills-routing.json` | NEW | bundled routing: the 22 sdd-framework trigger-routed skills only |
| `plugins/sdd-framework/hooks/{detect-bypass,skill-gate,log-skill-usage,token-guard,reset-turn-budget}.sh` | NEW (copied + edited from `hooks/`) | shipped enforcement subset, ROUTING via `${CLAUDE_PLUGIN_ROOT}` |
| `plugins/sdd-framework/hooks/hooks.json` | NEW | event→hook wiring |
| `plugins/sdd-framework/skills/foundation/adopting-framework/SKILL.md` | EDIT | rewrite body to the 4-step post-install bootstrap + new frontmatter description/triggers (drop copy/symlink/wiring/routing-sync + its skill-routing-sync link) |
| `.claude/skills-routing.json` | EDIT | update the `adopting-framework` triggers to match its new frontmatter |
| `scripts/link-skills.sh` | EDIT | discover skills under `plugins/*/skills/` |
| `scripts/link-hooks.sh` | EDIT | link from `plugins/sdd-framework/hooks/` |
| `.claude/skills/*`, `.claude/hooks/*` (symlinks) | EDIT | repointed by the rerun link scripts |

### Callers / dependents

- Vault `.claude/settings.json` still references `.claude/hooks/*.sh` symlinks — unchanged (the symlinks just repoint); the vault keeps its full 12-hook dev harness.
- Vault `.claude/skills-routing.json` stays as the dev-env registry (all 25 routed skills), with one edit: the `adopting-framework` entry's triggers are updated to match its rewritten frontmatter. The plugin's bundled `skills-routing.json` is a separate, sdd-framework-only subset (22 keys).
- `entrypoints` aliases reference canonical skills by NAME (no path) — no rewrite needed.
- `bootstrapping-claude-md` template assets link `rules/domains/framework.md` — these emit consumer-side content (the path the consumer's bootstrapped charter will live at), NOT plugin-internal links; left as-is, confirmed not a broken-link case.

## Edge cases

- Empty / fresh consumer (plugin installed, nothing bootstrapped): enforcement hooks run, read bundled routing from `${CLAUDE_PLUGIN_ROOT}`, write state under the consumer's `.claude/state/` (created if absent); skills resolve rule links from the plugin root. No domain rules / CLAUDE.md yet — `adopting-framework` is the user-invoked step that generates them.
- `${CLAUDE_PLUGIN_ROOT}` unset: the vault's `.claude/hooks/*` symlinks point at the unchanged originals (project-dir routing), so in-vault dev is unaffected by the shipped copies. The shipped copy still uses the `${CLAUDE_PLUGIN_ROOT:-${CLAUDE_PROJECT_DIR:-.}/.claude}` fallback purely for robustness — it never hard-fails on an unset plugin root.
- Broken symlink after move: rerunning `link-skills.sh`/`link-hooks.sh` must leave zero dangling links (`find .claude/skills .claude/hooks -xtype l` empty).
- A skill present in the vault routing but not in a plugin's bundled routing (e.g. a dev-utilities skill): its triggers simply don't fire in a consumer that only installed sdd-framework — expected, not a defect.
- Garbage stdin to a shipped hook: same fail-open behavior as the vault hooks (no decision emitted, exit 0).

## Verification

- `jq . .claude-plugin/marketplace.json` and `jq . plugins/*/.claude-plugin/plugin.json plugins/sdd-framework/skills-routing.json` — all valid JSON.
- `find .claude/skills .claude/hooks -xtype l` after rerunning both link scripts — prints nothing (no broken symlinks).
- Rule-link resolution: for every `${CLAUDE_PLUGIN_ROOT}/rules/...` reference in `plugins/sdd-framework/skills/**/SKILL.md`, the file exists under `plugins/sdd-framework/rules/` (script substituting `${CLAUDE_PLUGIN_ROOT}`=plugin dir, asserting each path).
- No stale links: `grep -rn '\.\./\.\./\.\./\.claude/rules' plugins/sdd-framework/skills/` returns nothing.
- Hook fixture run: pipe crafted stdin to `plugins/sdd-framework/hooks/detect-bypass.sh` with `CLAUDE_PLUGIN_ROOT` set to the plugin dir and `CLAUDE_PROJECT_DIR` to a temp dir; assert it reads the bundled routing and writes metrics under the temp project dir; then garbage stdin → exit 0 (fail-open).
- Skill validators (frontmatter ≤1024, name regex, reference links resolve, fences balanced, word count) pass on every moved skill.
- GREEN subagent: `/plugin marketplace add .` then install `sdd-framework` into a scratch repo; a fresh subagent invokes a chain skill and confirms it resolves its rule link from the plugin root (the consumer-facing behavior that was impossible before).

## Risks

- `${CLAUDE_PLUGIN_ROOT}` substitution inside a markdown link is read by Claude (skill body), not the shell — confirm Claude expands plugin-root references when following a skill's rule link; if not, the rule content must be inlined or the link made relative to the skill dir (`../../../../rules/common/...`). Mitigation: the rule-link verification step above tests resolution before calling it done; fall back to a skill-relative path if `${CLAUDE_PLUGIN_ROOT}` is not expanded in skill prose.
- `_metrics.jsonl` currently lives at `.claude/skills/_metrics.jsonl` (gitignored). With skills moved under `plugins/`, the consumer has no `.claude/skills/` dir — metrics path moves to `.claude/state/_metrics.jsonl`; update the 3 routing/session hooks and `.gitignore` accordingly.
- Large mechanical move (37 skill dirs + symlink/​link-script churn) risks a half-migrated tree — mitigation: do the moves in one atomic step per plugin, rerun link scripts, then run the full verification block before any commit.
- The vault's own dev harness must keep working post-move (authoring is still test-first in-place) — mitigation: the symlink repoint + unchanged `.claude/settings.json` preserve the 12-hook dev environment; verify by running an in-vault skill invocation after the move.
