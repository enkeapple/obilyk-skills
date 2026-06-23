# Vault → Plugin Marketplace Implementation Plan

**Goal:** Restructure the repo into a Claude Code marketplace publishing 3 plugins (`sdd-framework`, `learning-skills`, `dev-utilities`) while keeping it a working in-place dev environment.

**Architecture:** The repo root gains `.claude-plugin/marketplace.json`; each plugin lives under `plugins/<name>/` with its own `.claude-plugin/plugin.json`. Skill dirs MOVE from `skills/<category>/` into `plugins/<plugin>/skills/<category>/` (git mv, nesting preserved). The 3 consumer-facing agnostic rules and the 5 enforcement hooks are COPIED into `sdd-framework` (originals stay in the vault). Dev symlinks `.claude/skills/*` are repointed by an updated `link-skills.sh`.

**Tech stack:** Bash hooks, JSON manifests, Markdown skills. No build/test pipeline — "tests" are structural assertions (grep/find/jq), hook fixture runs, the skill validators, and a GREEN plugin-install run.

## Global constraints

- Verification is structural: `jq` validity, `find -xtype l` (no broken symlinks), grep/path-resolution assertions, hook fixture execution, skill validators (frontmatter ≤1024, name regex, links resolve, fences balanced, word count), and a GREEN plugin-install run. No `pnpm`/build/unit-suite exists.
- Conventional Commits, imperative, ≤72 chars, no AI attribution. One logical change per commit.
- Skill bodies are NOT edited except `adopting-framework` (rewrite) and the mechanical rule-link rewrite. No methodology changes.
- `name === dir === SKILL.md name:` invariant holds after every move.

### Deviations from the spec's literal Files-touched (resolved here, flag at gate)

1. `scripts/link-hooks.sh` is NOT edited — hooks are copied (not moved); `hooks/` keeps all 12 originals as the vault's dev-symlink source.
2. The 3 agnostic rules are COPIED into the plugin (kept in `.claude/rules/common/` for the vault), not moved — a move breaks in-vault resolution and vault-internal references.
3. Rule links are rewritten to the plugin-internal relative form `../../../rules/common/X.md` (resolves in both vault and installed contexts), not the `${CLAUDE_PLUGIN_ROOT}/...` form the spec sketched.

---

### Task 1: Marketplace + 3 plugin manifests

**Files:**

- Create: `.claude-plugin/marketplace.json`
- Create: `plugins/sdd-framework/.claude-plugin/plugin.json`
- Create: `plugins/learning-skills/.claude-plugin/plugin.json`
- Create: `plugins/dev-utilities/.claude-plugin/plugin.json`

**Interfaces:**

- Consumes: nothing (first task).
- Produces: marketplace named `sdd-workflow` with `pluginRoot: "./plugins"` and 3 entries `sdd-framework`/`learning-skills`/`dev-utilities`.

- [ ] **Step 1: Write the failing assertion**

```bash
test -f .claude-plugin/marketplace.json && jq -e '.plugins | length == 3' .claude-plugin/marketplace.json
```

- [ ] **Step 2: Run it, confirm it fails**
Run: the command above
Expected: FAIL — `test -f` returns non-zero (file absent).

- [ ] **Step 3: Create the manifests**

```bash
mkdir -p .claude-plugin plugins/sdd-framework/.claude-plugin plugins/learning-skills/.claude-plugin plugins/dev-utilities/.claude-plugin
cat > .claude-plugin/marketplace.json <<'JSON'
{
  "name": "sdd-workflow",
  "metadata": { "pluginRoot": "./plugins" },
  "plugins": [
    { "name": "sdd-framework",   "source": "sdd-framework" },
    { "name": "learning-skills", "source": "learning-skills" },
    { "name": "dev-utilities",   "source": "dev-utilities" }
  ]
}
JSON
cat > plugins/sdd-framework/.claude-plugin/plugin.json <<'JSON'
{ "name": "sdd-framework", "description": "Gated spec-driven-development chain plus skill/hook/rule authoring and foundation bootstrapping.", "version": "0.1.0" }
JSON
cat > plugins/learning-skills/.claude-plugin/plugin.json <<'JSON'
{ "name": "learning-skills", "description": "User-invoked learning skills: translate confusion, expose gaps, build learning plans.", "version": "0.1.0" }
JSON
cat > plugins/dev-utilities/.claude-plugin/plugin.json <<'JSON'
{ "name": "dev-utilities", "description": "Deep-module design vocabulary, architecture review, and prose tightening/humanizing.", "version": "0.1.0" }
JSON
```

- [ ] **Step 4: Run the assertion, confirm it passes**
Run: `jq -e '.plugins|length==3' .claude-plugin/marketplace.json && for p in sdd-framework learning-skills dev-utilities; do jq -e '.name' plugins/$p/.claude-plugin/plugin.json; done`
Expected: PASS — prints `3` then each plugin name.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin plugins/*/.claude-plugin && git commit -m "feat(plugins): add marketplace and 3 plugin manifests"
```

---

### Task 2: Move learning-skills (personal/*)

**Files:**

- Move: `skills/personal/` → `plugins/learning-skills/skills/personal/`

**Interfaces:**

- Consumes: `plugins/learning-skills/` (Task 1).
- Produces: 7 SKILL.md under `plugins/learning-skills/skills/personal/`.

- [ ] **Step 1: Write the failing assertion**

```bash
[ "$(find plugins/learning-skills/skills -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')" = "7" ]
```

- [ ] **Step 2: Run it, confirm it fails**
Run: the command above; `echo $?`
Expected: FAIL — `1` (target dir absent, count 0).

- [ ] **Step 3: Move the dir**

```bash
mkdir -p plugins/learning-skills/skills
git mv skills/personal plugins/learning-skills/skills/personal
```

- [ ] **Step 4: Confirm it passes**
Run: `find plugins/learning-skills/skills -name SKILL.md | wc -l && git status --porcelain=v1 | grep -c '^R'`
Expected: PASS — `7`, and renames detected (non-zero R count).

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "refactor(plugins): move learning skills into learning-skills plugin"
```

---

### Task 3: Move dev-utilities (design/*+ prose/*)

**Files:**

- Move: `skills/design/` → `plugins/dev-utilities/skills/design/`
- Move: `skills/prose/` → `plugins/dev-utilities/skills/prose/`

**Interfaces:**

- Consumes: `plugins/dev-utilities/` (Task 1).
- Produces: 4 SKILL.md (`codebase-design`, `improve-codebase-architecture`, `tightening-prose`, `humanizing-prose`).

- [ ] **Step 1: Write the failing assertion**

```bash
[ "$(find plugins/dev-utilities/skills -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')" = "4" ]
```

- [ ] **Step 2: Run it, confirm it fails**
Run: above; `echo $?`
Expected: FAIL — `1`.

- [ ] **Step 3: Move the dirs**

```bash
mkdir -p plugins/dev-utilities/skills
git mv skills/design plugins/dev-utilities/skills/design
git mv skills/prose  plugins/dev-utilities/skills/prose
```

- [ ] **Step 4: Confirm it passes**
Run: `find plugins/dev-utilities/skills -name SKILL.md | wc -l`
Expected: PASS — `4`.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "refactor(plugins): move design and prose skills into dev-utilities plugin"
```

---

### Task 4: Move sdd-framework skills (apply-chain, authoring, foundation, process, entrypoints)

**Files:**

- Move: `skills/{apply-chain,authoring,foundation,process,entrypoints}/` → `plugins/sdd-framework/skills/<category>/`

**Interfaces:**

- Consumes: `plugins/sdd-framework/` (Task 1).
- Produces: 26 SKILL.md under `plugins/sdd-framework/skills/`. After this task `skills/` is empty.

- [ ] **Step 1: Write the failing assertion**

```bash
[ "$(find plugins/sdd-framework/skills -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')" = "26" ]
```

- [ ] **Step 2: Run it, confirm it fails**
Run: above; `echo $?`
Expected: FAIL — `1`.

- [ ] **Step 3: Move the categories**

```bash
mkdir -p plugins/sdd-framework/skills
for c in apply-chain authoring foundation process entrypoints; do
  git mv "skills/$c" "plugins/sdd-framework/skills/$c"
done
```

- [ ] **Step 4: Confirm it passes**
Run: `find plugins/sdd-framework/skills -name SKILL.md | wc -l && find skills -name SKILL.md 2>/dev/null | wc -l`
Expected: PASS — `26` then `0` (skills/ drained).

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "refactor(plugins): move sdd chain, authoring, foundation skills into sdd-framework"
```

---

### Task 5: Bundle the 3 agnostic rules + rewrite 17 skill links

**Files:**

- Create (copy): `plugins/sdd-framework/rules/common/{phase-task-visualization,interactive-gates,scoping-skill-value}.md`
- Modify: 11 SKILL.md under `plugins/sdd-framework/skills/` (17 link occurrences)

**Interfaces:**

- Consumes: moved sdd-framework skills (Task 4).
- Produces: every agnostic rule link inside the plugin resolves to `plugins/sdd-framework/rules/common/*` via `../../../rules/common/X.md`.

- [ ] **Step 1: Write the failing assertion**

```bash
# RED: old-form links still present, plugin rules dir absent
grep -rl '\.\./\.\./\.\./\.claude/rules/common/\(phase-task-visualization\|interactive-gates\|scoping-skill-value\)' plugins/sdd-framework/skills/ | wc -l
```

- [ ] **Step 2: Run it, confirm it fails (shows work to do)**
Run: above
Expected: `11` (files still using the old `.claude/rules` path); `ls plugins/sdd-framework/rules/common 2>/dev/null` → absent.

- [ ] **Step 3: Copy the rules and rewrite the links**

```bash
mkdir -p plugins/sdd-framework/rules/common
for r in phase-task-visualization interactive-gates scoping-skill-value; do
  cp ".claude/rules/common/$r.md" "plugins/sdd-framework/rules/common/$r.md"
done
# Rewrite ../../../.claude/rules/common/<the 3>.md -> ../../../rules/common/<the 3>.md
grep -rlZ '\.\./\.\./\.\./\.claude/rules/common/\(phase-task-visualization\|interactive-gates\|scoping-skill-value\)' plugins/sdd-framework/skills/ \
  | xargs -0 sed -i '' -E 's#\.\./\.\./\.\./\.claude/rules/common/(phase-task-visualization|interactive-gates|scoping-skill-value)\.md#../../../rules/common/\1.md#g'
```

- [ ] **Step 4: Confirm it passes (links resolve, none stale)**
Run:

```bash
# no stale .claude/rules links left for the 3 rules
grep -rl '\.\./\.\./\.\./\.claude/rules/common/\(phase-task-visualization\|interactive-gates\|scoping-skill-value\)' plugins/sdd-framework/skills/ | wc -l
# every rewritten link resolves to a real file (resolve relative to each SKILL.md dir)
for f in $(grep -rl '\.\./\.\./\.\./rules/common/' plugins/sdd-framework/skills/); do
  ( cd "$(dirname "$f")" && for t in $(grep -oE '\.\./\.\./\.\./rules/common/[a-z-]+\.md' "$(basename "$f")"); do test -f "$t" || echo "BROKEN: $f -> $t"; done )
done
```

Expected: PASS — first command `0`; second prints nothing (no `BROKEN:` lines).

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "refactor(plugins): bundle agnostic rules into sdd-framework and repoint skill links"
```

---

### Task 6: Ship the 5 enforcement hooks + hooks.json

**Files:**

- Create (copy+edit): `plugins/sdd-framework/hooks/{detect-bypass,skill-gate,log-skill-usage,token-guard,reset-turn-budget}.sh`
- Create: `plugins/sdd-framework/hooks/hooks.json`

**Interfaces:**

- Consumes: nothing from prior tasks (the bundled routing.json arrives in Task 7; this task only needs the scripts wired).
- Produces: plugin hooks reading routing via `${CLAUDE_PLUGIN_ROOT:-${CLAUDE_PROJECT_DIR:-.}/.claude}/skills-routing.json`, writing state to `${CLAUDE_PROJECT_DIR}/.claude/state/`.

- [ ] **Step 1: Write the failing assertion**

```bash
test -f plugins/sdd-framework/hooks/hooks.json && grep -q 'CLAUDE_PLUGIN_ROOT' plugins/sdd-framework/hooks/detect-bypass.sh
```

- [ ] **Step 2: Run it, confirm it fails**
Run: above; `echo $?`
Expected: FAIL — `1` (dir absent).

- [ ] **Step 3: Copy, repoint ROUTING/METRICS, write hooks.json**

```bash
mkdir -p plugins/sdd-framework/hooks
for h in detect-bypass skill-gate log-skill-usage token-guard reset-turn-budget; do
  src=$(find hooks -name "$h.sh"); cp "$src" "plugins/sdd-framework/hooks/$h.sh"
done
# Repoint ROUTING to the bundled copy with graceful fallback; move METRICS out of .claude/skills/
sed -i '' -E \
  -e 's#ROUTING="\$\{CLAUDE_PROJECT_DIR:-\.\}/\.claude/skills-routing\.json"#ROUTING="${CLAUDE_PLUGIN_ROOT:-${CLAUDE_PROJECT_DIR:-.}/.claude}/skills-routing.json"#' \
  -e 's#METRICS="\$\{CLAUDE_PROJECT_DIR:-\.\}/\.claude/skills/_metrics\.jsonl"#METRICS="${CLAUDE_PROJECT_DIR:-.}/.claude/state/_metrics.jsonl"#' \
  plugins/sdd-framework/hooks/*.sh
cat > plugins/sdd-framework/hooks/hooks.json <<'JSON'
{
  "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/reset-turn-budget.sh" }] }],
  "PreToolUse": [{ "matcher": "Edit|Write|MultiEdit", "hooks": [{ "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/skill-gate.sh" }] }],
  "PostToolUse": [
    { "matcher": ".*", "hooks": [{ "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/token-guard.sh" }] },
    { "matcher": "Read|Skill|Edit|Write|MultiEdit", "hooks": [{ "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/detect-bypass.sh" }] }
  ],
  "Stop": [{ "hooks": [{ "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/log-skill-usage.sh" }] }]
}
JSON
chmod +x plugins/sdd-framework/hooks/*.sh
```

- [ ] **Step 4: Fixture run — confirm bundled routing is read and fail-open holds**
Run:

```bash
jq . plugins/sdd-framework/hooks/hooks.json >/dev/null && echo JSON_OK
# detect-bypass reads bundled routing: point PLUGIN_ROOT at the plugin, PROJECT_DIR at a temp dir
tmp=$(mktemp -d); cp .claude/skills-routing.json plugins/sdd-framework/skills-routing.json 2>/dev/null || true
echo '{"hook_event_name":"PostToolUse","tool_name":"Read","session_id":"t"}' \
  | CLAUDE_PLUGIN_ROOT="$PWD/plugins/sdd-framework" CLAUDE_PROJECT_DIR="$tmp" bash plugins/sdd-framework/hooks/detect-bypass.sh; echo "exit=$?"
# garbage stdin -> fail-open
echo 'not json' | CLAUDE_PLUGIN_ROOT="$PWD/plugins/sdd-framework" CLAUDE_PROJECT_DIR="$tmp" bash plugins/sdd-framework/hooks/detect-bypass.sh; echo "garbage_exit=$?"
```

Expected: PASS — `JSON_OK`; first run `exit=0` (no crash, reads routing from PLUGIN_ROOT); `garbage_exit=0` (fail-open). (The temp routing copy is scratch; Task 7 writes the real bundled file.)

- [ ] **Step 5: Commit**

```bash
git add plugins/sdd-framework/hooks && git commit -m "feat(hooks): ship curated enforcement hooks in sdd-framework plugin"
```

---

### Task 7: Bundled skills-routing.json (22 keys)

**Files:**

- Create: `plugins/sdd-framework/skills-routing.json`

**Interfaces:**

- Consumes: vault `.claude/skills-routing.json` (25 routed keys).
- Produces: 22-key routing = vault minus `codebase-design`, `tightening-prose`, `humanizing-prose`; each `files` path rewritten to `skills/<category>/<name>/SKILL.md`.

- [ ] **Step 1: Write the failing assertion**

```bash
jq -e '(.skills | keys | length == 22) and (has("codebase-design") | not)' plugins/sdd-framework/skills-routing.json 2>/dev/null
```

- [ ] **Step 2: Run it, confirm it fails**
Run: `jq -e '.skills' plugins/sdd-framework/skills-routing.json`
Expected: FAIL — file absent or still the scratch copy from Task 6 (25 keys).

- [ ] **Step 3: Derive the bundled routing from the vault file**

```bash
jq '
  .skills |= with_entries(select(.key | IN("codebase-design","tightening-prose","humanizing-prose") | not))
  ' .claude/skills-routing.json > plugins/sdd-framework/skills-routing.json
# The vault files point at flat .claude/skills/<name>/SKILL.md; rewrite each to its real category path:
python3 - <<'PY'
import json,glob,os
p="plugins/sdd-framework/skills-routing.json"; d=json.load(open(p))
real={}
for f in glob.glob("plugins/sdd-framework/skills/*/*/SKILL.md"):
    real[os.path.basename(os.path.dirname(f))]=f.replace("plugins/sdd-framework/","")
for k,v in d["skills"].items():
    v["files"]=[real[k]] if k in real else v["files"]
json.dump(d,open(p,"w"),indent=2,ensure_ascii=False)
PY
```

- [ ] **Step 4: Confirm it passes**
Run:

```bash
jq -e '.skills | keys | length == 22' plugins/sdd-framework/skills-routing.json
for k in $(jq -r '.skills | keys[]' plugins/sdd-framework/skills-routing.json); do
  f=$(jq -r ".skills[\"$k\"].files[0]" plugins/sdd-framework/skills-routing.json)
  test -f "plugins/sdd-framework/$f" || echo "MISSING: $k -> $f"
done
```

Expected: PASS — `true`; no `MISSING:` lines.

- [ ] **Step 5: Commit**

```bash
git add plugins/sdd-framework/skills-routing.json && git commit -m "feat(plugins): bundle sdd-framework routing manifest"
```

---

### Task 8: Rewrite adopting-framework + update vault routing triggers

**Files:**

- Modify: `plugins/sdd-framework/skills/foundation/adopting-framework/SKILL.md`
- Modify: `.claude/skills-routing.json` (the `adopting-framework` triggers)

**Interfaces:**

- Consumes: the bundled marker `plugins/sdd-framework/skills-routing.json` (Task 7) — the install-verify step checks `${CLAUDE_PLUGIN_ROOT}/skills-routing.json` resolves.
- Produces: a 4-step user-invoked bootstrap body; no `skill-routing-sync` link; frontmatter triggers describing post-install bootstrap.

- [ ] **Step 1: Write the failing assertion**

```bash
F=plugins/sdd-framework/skills/foundation/adopting-framework/SKILL.md
! grep -q 'skill-routing-sync' "$F" && grep -q 'post-install' "$F"
```

- [ ] **Step 2: Run it, confirm it fails**
Run: above; `echo $?`
Expected: FAIL — `1` (still the old copy-procedure body, still links skill-routing-sync).

- [ ] **Step 3: Rewrite the body + frontmatter, and the vault trigger entry**
Replace the body's procedure with the 4 steps from the spec (verify install → `bootstrapping-glossary` → `bootstrapping-claude-md` → verify), drop the copy/symlink/wiring/routing-sync steps and the `skill-routing-sync` link, and rewrite `description`/`triggers` to post-install bootstrap language. Then mirror the trigger change in the vault registry:

```bash
# illustrative — exact triggers come from the rewritten frontmatter:
python3 - <<'PY'
import json
TRIG=["adopt the framework","bootstrap this repo for sdd","post-install setup",
      "set up sdd in this repo","onboard this repo to sdd"]
# Mirror the SAME triggers into BOTH the vault registry and the bundled plugin routing (spec requirement).
for p in (".claude/skills-routing.json","plugins/sdd-framework/skills-routing.json"):
    d=json.load(open(p))
    d["skills"]["adopting-framework"]["triggers"]=TRIG
    json.dump(d,open(p,"w"),indent=2,ensure_ascii=False)
PY
```

- [ ] **Step 4: Confirm it passes**
Run:

```bash
F=plugins/sdd-framework/skills/foundation/adopting-framework/SKILL.md
grep -q 'post-install' "$F" && ! grep -q 'skill-routing-sync' "$F" && echo BODY_OK
# triggers mirrored into BOTH registries:
jq -e '.skills["adopting-framework"].triggers | length > 0' .claude/skills-routing.json
jq -e '.skills["adopting-framework"].triggers | length > 0' plugins/sdd-framework/skills-routing.json
head -5 "$F" | grep -q '^name: adopting-framework'
```

Expected: PASS — `BODY_OK`, `true`, and the name line matches (invariant intact).

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "refactor(adopting-framework): rewrite as post-install bootstrap orchestrator"
```

---

### Task 9: Repoint dev symlinks (link-skills.sh) and verify

**Files:**

- Modify: `scripts/link-skills.sh` (scan `plugins/*/skills/` instead of `skills/`)
- Regenerate: `.claude/skills/*` symlinks

**Interfaces:**

- Consumes: all moved skills (Tasks 2–4).
- Produces: every `.claude/skills/<name>` resolves into `plugins/<plugin>/skills/<category>/<name>`. `link-hooks.sh` is unchanged (hooks not moved).

- [ ] **Step 1: Write the failing assertion**

```bash
# RED: dev symlinks are stale (point into the now-empty skills/ tree) -> broken links exist
find .claude/skills -xtype l | wc -l
```

- [ ] **Step 2: Run it, confirm it fails**
Run: above
Expected: FAIL — non-zero count (dangling symlinks into moved dirs).

- [ ] **Step 3: Update the SRC scan in link-skills.sh**

```bash
# Three literal substitutions (BSD sed on darwin). The rel= rule only swaps the
# ../../skills/ prefix for ../../plugins/, regardless of the ${src_dir#...} tail.
sed -i '' \
  -e 's#^SRC="$REPO/skills"#SRC="$REPO/plugins"#' \
  -e 's#find "$SRC" -name SKILL.md -print0#find "$SRC" -path "*/skills/*" -name SKILL.md -print0#' \
  -e 's#rel="../../skills/#rel="../../plugins/#' \
  scripts/link-skills.sh
# Sanity: the three edits landed before running
grep -q 'SRC="$REPO/plugins"' scripts/link-skills.sh \
  && grep -q '"\*/skills/\*"' scripts/link-skills.sh \
  && grep -q 'rel="../../plugins/' scripts/link-skills.sh && echo SED_OK
bash scripts/link-skills.sh
```

- [ ] **Step 4: Confirm it passes**
Run: `find .claude/skills .claude/hooks -xtype l | wc -l && ls .claude/skills | grep -v _metrics | wc -l`
Expected: PASS — `0` broken links; ~37 skill symlinks present (all resolve).

- [ ] **Step 5: Commit**

```bash
git add scripts/link-skills.sh .claude/skills && git commit -m "chore(scripts): repoint skill dev-symlinks into plugins tree"
```

---

### Task 10: Full verification + GREEN plugin-install run

**Files:**

- Modify: `.gitignore` (add `.claude/state/_metrics.jsonl`; drop the now-dead `.claude/skills/_metrics.jsonl` path)

**Interfaces:**

- Consumes: everything above.
- Produces: a clean structural verdict + a confirmed install in a scratch repo.

- [ ] **Step 1: Write the failing assertion (gitignore + whole-tree checks staged)**

```bash
grep -q '.claude/state/_metrics.jsonl' .gitignore
```

- [ ] **Step 2: Run it, confirm it fails**
Run: above; `echo $?`
Expected: FAIL — `1` (metrics path not yet in .gitignore).

- [ ] **Step 3: Fix .gitignore and run the full verification block**

```bash
# .gitignore: metrics now under state/
sed -i '' 's#\.claude/skills/_metrics\.jsonl#.claude/state/_metrics.jsonl#' .gitignore
# JSON validity
jq . .claude-plugin/marketplace.json plugins/*/.claude-plugin/plugin.json plugins/sdd-framework/skills-routing.json plugins/sdd-framework/hooks/hooks.json >/dev/null && echo JSON_OK
# No broken symlinks
find .claude/skills .claude/hooks -xtype l | wc -l
# No stale .claude/rules links in shipped skills
grep -rn '\.\./\.\./\.\./\.claude/rules' plugins/sdd-framework/skills/ | wc -l
# Skill validators: run the repo's validator pass over each moved SKILL.md (frontmatter ≤1024, name regex, links, fences, word count)
```

- [ ] **Step 4: Confirm it passes + GREEN install**
Run:

```bash
# structural
echo JSON_OK; [ "$(find .claude/skills .claude/hooks -xtype l|wc -l|tr -d ' ')" = 0 ] && echo NO_BROKEN_LINKS
[ "$(grep -rn '\.\./\.\./\.\./\.claude/rules' plugins/sdd-framework/skills/|wc -l|tr -d ' ')" = 0 ] && echo NO_STALE_RULE_LINKS
# Scripted fallback (always runs): every rewritten rule link resolves from its real skill dir
for f in $(grep -rl '\.\./\.\./\.\./rules/common/' plugins/sdd-framework/skills/); do
  ( cd "$(dirname "$f")" && for t in $(grep -oE '\.\./\.\./\.\./rules/common/[a-z-]+\.md' "$(basename "$f")"); do test -f "$t" || echo "BROKEN: $f -> $t"; done )
done && echo RULE_LINKS_RESOLVE
# In-vault path check: resolve the SAME link through a dev symlink (catches non-dereferenced relative resolution)
( cd .claude/skills/grilling && test -f "$(grep -oE '\.\./\.\./\.\./rules/common/phase-task-visualization\.md' SKILL.md | head -1)" && echo VAULT_SYMLINK_RESOLVES )
# GREEN install (manual/agent step): /plugin marketplace add "$PWD"; /plugin install sdd-framework@sdd-workflow
scratch=$(mktemp -d); git -C "$scratch" init -q
```

Expected: PASS — `JSON_OK`, `NO_BROKEN_LINKS`, `NO_STALE_RULE_LINKS`, `RULE_LINKS_RESOLVE`, `VAULT_SYMLINK_RESOLVES`; validators clean; and a fresh subagent in the scratch repo invokes e.g. `grilling` confirming its `../../../rules/common/phase-task-visualization.md` link resolves from the installed plugin root.

- [ ] **Step 5: Commit**

```bash
git add .gitignore && git commit -m "chore: move metrics path to state and finalize plugin migration"
```
