# Flatten & Decompose Plugin Architecture — Implementation Plan

**Goal:** Split nested `saleizo-core`/`saleizo-design` into 8 flat, per-concern plugins (skills at `plugins/<kit>/skills/<name>/`), updating every manifest and live reference in lockstep.
**Architecture:** A migration, not a feature. Each task moves one concern's skills with `git mv` (history preserved), writes/edits the affected manifests (`marketplace.json`, `plugin.json`, `skills-routing.json`), and ends with a **structural verification command** standing in for a unit test (no build/test pipeline exists). Verify-then-commit per task.
**Tech stack:** Claude Code plugin manifests (JSON), markdown skills, `git mv`, `jq`/`grep`/`find` for structural checks.

## Global constraints

- No skill **body/behavior** edits — only path strings the move invalidates (spec → Out of scope).
- `git mv` for every move (preserve history) — never copy+delete.
- Editing `.claude/skills-routing.json` is **denied** until `.claude/rules/common/skill-routing-sync.md` is Read in the same turn (`skill-gate.sh` ruleGate) — every routing task reads it first.
- A new `plugin.json` lists **every** skill its plugin owns; `skills/shared/` is NOT a skill and is never listed.
- The invariant `name === dir === SKILL.md name:` holds; routing key === dir === `name:` for every routed skill. Only `plugin:` + on-disk path change.
- Skill counts (must reconcile): core 12, commands 5, authoring 5, foundation 10, design 3, prose 3 = 38 total; routing entries stay 32.
- **Execute Tasks 1–7 strictly in order, one at a time** — Tasks 1/2/3/5 each append to the *same* `.claude-plugin/marketplace.json` and Tasks 2/3/5 each edit the *same* `.claude/skills-routing.json`; running them out of order or in parallel overwrites a prior entry. Each `jq` edit reads the file's current (committed) state and writes it back via a temp file + `mv` (never an in-place pipe that could truncate on error).
- ADR `docs/adr/*` and `.claude/lessons-learned.md` are immutable historical records — never updated for moved paths.
- `git` commit only (human owns it per CLAUDE.md git boundary) — each task's commit step is the **proposed** one-line Conventional Commit; the human runs it.

## File map (single responsibility)

| Path | Responsibility |
| --- | --- |
| `plugins/saleizo-commands/` | NEW plugin: 5 alias skills (no routing entries) |
| `plugins/saleizo-authoring/` | NEW plugin: 5 `writing-*` skills |
| `plugins/saleizo-foundation/` | NEW plugin: 10 setup skills + `skills/shared/placeholder-keys.md` |
| `plugins/saleizo-prose/` | NEW plugin: 3 prose skills + `skills/shared/` |
| `plugins/saleizo-core/` | shrunk to 12 flat chain+handoff skills |
| `plugins/saleizo-design/` | shrunk to 3 flat skills |
| `.claude-plugin/marketplace.json` | +4 plugin entries |
| `.claude/skills-routing.json` | 18 `plugin:` flips |
| `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/domains/glossary.md`, `.claude/rules/common/skill-routing-sync.md`, READMEs | live cross-reference updates |

---

## Task 1 — Create `saleizo-commands` (5 aliases)

**Files:** `plugins/saleizo-commands/.claude-plugin/plugin.json` (NEW), `plugins/saleizo-commands/README.md` (NEW), `plugins/saleizo-commands/skills/{adr,audit,grill,sdd,spec}/` (moved), `.claude-plugin/marketplace.json` (EDIT).
**Interfaces — Consumes:** the 5 alias dirs at `plugins/saleizo-core/skills/aliases/*`. **Produces:** plugin `saleizo-commands` with 5 skills; no routing entries (aliases are `disable-model-invocation`).

- [ ] **Define the check (RED).** Confirm the target does not yet exist:
  ```bash
  test ! -d plugins/saleizo-commands && echo "RED: saleizo-commands absent (expected)"
  ```
- [ ] **Move the alias skills:**
  ```bash
  mkdir -p plugins/saleizo-commands/skills
  for s in adr audit grill sdd spec; do
    git mv plugins/saleizo-core/skills/aliases/$s plugins/saleizo-commands/skills/$s
  done
  rmdir plugins/saleizo-core/skills/aliases 2>/dev/null || true
  ```
- [ ] **Write `plugins/saleizo-commands/.claude-plugin/plugin.json`:**
  ```json
  {
    "name": "saleizo-commands",
    "description": "Short user-typed alias commands that delegate to the canonical SDD skills (/sdd, /grill, /spec, /audit, /adr).",
    "version": "1.0.0",
    "skills": [
      "./skills/adr",
      "./skills/audit",
      "./skills/grill",
      "./skills/sdd",
      "./skills/spec"
    ]
  }
  ```
- [ ] **Write `plugins/saleizo-commands/README.md`** — a skills catalog matching the style of `plugins/saleizo-learning/README.md` (read it first), one row per alias with its `argument-hint` and the canonical skill it delegates to.
- [ ] **Add the marketplace entry** to `.claude-plugin/marketplace.json` `plugins[]` (append via temp file):
  ```bash
  jq '.plugins += [{"name":"saleizo-commands","source":"./plugins/saleizo-commands"}]' .claude-plugin/marketplace.json > mp.tmp && mv mp.tmp .claude-plugin/marketplace.json
  ```
- [ ] **Verify (GREEN):** every `plugin.json` skill path resolves, marketplace source exists, each alias has a SKILL.md:
  ```bash
  d=plugins/saleizo-commands
  jq -r '.skills[]' $d/.claude-plugin/plugin.json | while read p; do test -f "$d/$p/SKILL.md" && echo "ok $p" || echo "MISSING $p"; done
  jq -e '.plugins[]|select(.name=="saleizo-commands")' .claude-plugin/marketplace.json >/dev/null && echo "marketplace ok"
  test ! -d plugins/saleizo-core/skills/aliases && echo "core/aliases removed"
  ```
  Expect: 5 `ok`, `marketplace ok`, `core/aliases removed`.
- [ ] **Commit (proposed):** `git add -A && git commit -m "refactor(plugins): extract saleizo-commands from saleizo-core"`

---

## Task 2 — Create `saleizo-authoring` (5 writing-* skills)

**Files:** `plugins/saleizo-authoring/` (NEW plugin.json + README + 5 skill dirs), `.claude-plugin/marketplace.json` (EDIT), `.claude/skills-routing.json` (EDIT — 5 flips).
**Interfaces — Consumes:** `plugins/saleizo-core/skills/authoring/{writing-adrs,writing-hooks,writing-lessons,writing-rules,writing-skills}`. **Produces:** plugin `saleizo-authoring`; routing entries for those 5 names now `plugin: saleizo-authoring`.

- [ ] **Read the routing-sync rule (gate prerequisite):** Read `.claude/rules/common/skill-routing-sync.md`.
- [ ] **Define the check (RED).** The 5 entries still name the old plugin:
  ```bash
  jq -r '.skills["writing-adrs"].plugin' .claude/skills-routing.json   # expect: saleizo-core (RED)
  ```
- [ ] **Move the skills:**
  ```bash
  mkdir -p plugins/saleizo-authoring/skills
  for s in writing-adrs writing-hooks writing-lessons writing-rules writing-skills; do
    git mv plugins/saleizo-core/skills/authoring/$s plugins/saleizo-authoring/skills/$s
  done
  rmdir plugins/saleizo-core/skills/authoring 2>/dev/null || true
  ```
- [ ] **Write `plugins/saleizo-authoring/.claude-plugin/plugin.json`** (version `1.0.0`, description "Test-first authoring of skills, hooks, rules, lessons, and ADRs.", `skills[]` = the 5 `./skills/writing-*`).
- [ ] **Write `plugins/saleizo-authoring/README.md`** — catalog of the 5 skills (style per existing per-plugin READMEs).
- [ ] **Add marketplace entry** (append via temp file):
  ```bash
  jq '.plugins += [{"name":"saleizo-authoring","source":"./plugins/saleizo-authoring"}]' .claude-plugin/marketplace.json > mp.tmp && mv mp.tmp .claude-plugin/marketplace.json
  ```
- [ ] **Flip the 5 routing `plugin` fields** in `.claude/skills-routing.json` (`kind`/`name`/`triggers` untouched; temp-file + `mv` per edit):
  ```bash
  for s in writing-adrs writing-hooks writing-lessons writing-rules writing-skills; do
    jq --arg s "$s" '.skills[$s].plugin="saleizo-authoring"' .claude/skills-routing.json > rt.tmp && mv rt.tmp .claude/skills-routing.json
  done
  ```
- [ ] **Verify (GREEN):** plugin paths resolve + routing parity (every entry naming `saleizo-authoring` has its dir there):
  ```bash
  d=plugins/saleizo-authoring; jq -r '.skills[]' $d/.claude-plugin/plugin.json | while read p; do test -f "$d/$p/SKILL.md" || echo "MISSING $p"; done; echo "paths checked"
  jq -r '.skills|to_entries[]|select(.value.plugin=="saleizo-authoring")|.key' .claude/skills-routing.json | while read n; do test -d plugins/saleizo-authoring/skills/$n && echo "ok $n" || echo "DRIFT $n"; done
  ```
  Expect: `paths checked`, 5 `ok`, no `MISSING`/`DRIFT`.
- [ ] **Commit (proposed):** `git add -A && git commit -m "refactor(plugins): extract saleizo-authoring from saleizo-core"`

---

## Task 3 — Create `saleizo-foundation` (10 setup skills + shared)

**Files:** `plugins/saleizo-foundation/` (NEW), `.claude-plugin/marketplace.json` (EDIT), `.claude/skills-routing.json` (EDIT — 10 flips).
**Interfaces — Consumes:** `plugins/saleizo-core/skills/setup/{adopting-framework,auditing-claude-md,auditing-glossary,auditing-hooks,auditing-readme,auditing-conflicts,bootstrapping-claude-md,bootstrapping-glossary,bootstrapping-readme,reviewing-telemetry}` + `setup/shared/`. **Produces:** plugin `saleizo-foundation` (10 skills, fixes the `reviewing-telemetry`-absent-from-manifest drift); `skills/shared/placeholder-keys.md`.

- [ ] **Read** `.claude/rules/common/skill-routing-sync.md` (gate).
- [ ] **Define the check (RED):** `jq -r '.skills["adopting-framework"].plugin' .claude/skills-routing.json` → `saleizo-core`.
- [ ] **Move the 10 skills + shared:**
  ```bash
  mkdir -p plugins/saleizo-foundation/skills
  for s in adopting-framework auditing-claude-md auditing-glossary auditing-hooks auditing-readme auditing-conflicts bootstrapping-claude-md bootstrapping-glossary bootstrapping-readme reviewing-telemetry; do
    git mv plugins/saleizo-core/skills/setup/$s plugins/saleizo-foundation/skills/$s
  done
  git mv plugins/saleizo-core/skills/setup/shared plugins/saleizo-foundation/skills/shared
  rmdir plugins/saleizo-core/skills/setup 2>/dev/null || true
  ```
- [ ] **Write `plugins/saleizo-foundation/.claude-plugin/plugin.json`** (version `1.0.0`, description "Adopt/bootstrap/audit the framework in a consumer repo + telemetry review.", `skills[]` = the 10 `./skills/<name>`; `shared` NOT listed).
- [ ] **Write `plugins/saleizo-foundation/README.md`** — catalog of the 10 skills.
- [ ] **Add marketplace entry** (append via temp file):
  ```bash
  jq '.plugins += [{"name":"saleizo-foundation","source":"./plugins/saleizo-foundation"}]' .claude-plugin/marketplace.json > mp.tmp && mv mp.tmp .claude-plugin/marketplace.json
  ```
- [ ] **Flip the 10 routing `plugin` fields** (temp-file + `mv` loop as in Task 2, list = the 10 names above, value `saleizo-foundation`).
- [ ] **Verify (GREEN)** — paths resolve, routing parity, AND `../shared/` links still resolve in the moved skills:
  ```bash
  d=plugins/saleizo-foundation; jq -r '.skills[]' $d/.claude-plugin/plugin.json | while read p; do test -f "$d/$p/SKILL.md" || echo "MISSING $p"; done
  jq -r '.skills|to_entries[]|select(.value.plugin=="saleizo-foundation")|.key' .claude/skills-routing.json | while read n; do test -d $d/skills/$n || echo "DRIFT $n"; done
  # link resolution: every relative .md link in moved skills resolves
  grep -rhoE '\]\(([^)]+\.md)\)' $d/skills | sed -E 's/.*\(([^)]+)\)/\1/' >/dev/null
  for f in $(find $d/skills -name '*.md'); do grep -oE '\]\((\.\.?/[^)]+\.md)\)' "$f" | sed -E 's/.*\((.*)\)/\1/' | while read l; do test -f "$(dirname "$f")/$l" || echo "BROKEN LINK $f -> $l"; done; done
  echo "checked"
  test -f $d/skills/shared/placeholder-keys.md && echo "shared moved"
  ```
  Expect: no `MISSING`/`DRIFT`/`BROKEN LINK`, `shared moved`, `checked`.
- [ ] **Commit (proposed):** `git add -A && git commit -m "refactor(plugins): extract saleizo-foundation from saleizo-core"`

---

## Task 4 — Flatten the `saleizo-core` remainder (12 chain+handoff skills)

**Files:** `plugins/saleizo-core/skills/<name>/` (12 moved up one level), `plugins/saleizo-core/.claude-plugin/plugin.json` (EDIT — flat paths + major bump). **No routing edit** (entries keep `plugin: saleizo-core`, `name` unchanged; routing carries no file paths).
**Interfaces — Consumes:** `plugins/saleizo-core/skills/chain/*` (11) + `skills/session/handoff`. **Produces:** flat `saleizo-core` with 12 skills.

- [ ] **Define the check (RED):** `test -d plugins/saleizo-core/skills/chain && echo "RED: still nested"`.
- [ ] **Move chain + handoff up:**
  ```bash
  for s in grilling writing-specs writing-plans pre-implementation-protocol resolving-requirements sdd-lifecycle test-driven-development inline-driven-development subagent-driven-development systematic-debugging verifying-implementation; do
    git mv plugins/saleizo-core/skills/chain/$s plugins/saleizo-core/skills/$s
  done
  git mv plugins/saleizo-core/skills/session/handoff plugins/saleizo-core/skills/handoff
  rmdir plugins/saleizo-core/skills/chain plugins/saleizo-core/skills/session 2>/dev/null || true
  ```
- [ ] **Rewrite `plugins/saleizo-core/.claude-plugin/plugin.json`** — `skills[]` = the 12 `./skills/<name>` (flat); `version` → next **major** (e.g. `2.0.0`); description → "Gated spec-driven-development chain (resolving → grilling → spec → plan → implement → verify) + handoff."
- [ ] **Verify (GREEN):** 12 paths resolve, no nested category dirs remain, no stray skill left behind:
  ```bash
  d=plugins/saleizo-core; jq -r '.skills[]' $d/.claude-plugin/plugin.json | while read p; do test -f "$d/$p/SKILL.md" || echo "MISSING $p"; done
  test $(jq '.skills|length' $d/.claude-plugin/plugin.json) -eq 12 && echo "count=12"
  find $d/skills -maxdepth 1 -mindepth 1 -type d -exec test -f '{}/SKILL.md' ';' -o -print  # prints any non-skill dir
  # relative links inside the moved skills still resolve (references/*.md move with the skill, but confirm)
  for f in $(find $d/skills -name '*.md'); do grep -oE '\]\((\.\.?/[^)]+\.md)\)' "$f" | sed -E 's/.*\((.*)\)/\1/' | while read l; do test -f "$(dirname "$f")/$l" || echo "BROKEN $f -> $l"; done; done
  echo "checked"
  ```
  Expect: no `MISSING`, `count=12`, no leftover category dirs, no `BROKEN`.
- [ ] **Commit (proposed):** `git add -A && git commit -m "refactor(plugins): flatten saleizo-core to bump major"` *(major bump justified in body if needed).*

---

## Task 5 — Split `saleizo-prose` out of `saleizo-design` (3 skills + shared)

**Files:** `plugins/saleizo-prose/` (NEW), `.claude-plugin/marketplace.json` (EDIT), `.claude/skills-routing.json` (EDIT — 3 flips).
**Interfaces — Consumes:** `plugins/saleizo-design/skills/prose/{humanizing-prose,tightening-prose,drafting-release-notes}` + `prose/shared/`. **Produces:** plugin `saleizo-prose` (lists all 3 — fixes `drafting-release-notes`-absent drift); routing for the 3 → `plugin: saleizo-prose`.

- [ ] **Read** `.claude/rules/common/skill-routing-sync.md` (gate).
- [ ] **Define the check (RED):** `jq -r '.skills["tightening-prose"].plugin' .claude/skills-routing.json` → `saleizo-design`.
- [ ] **Move the 3 prose skills + shared:**
  ```bash
  mkdir -p plugins/saleizo-prose/skills
  for s in humanizing-prose tightening-prose drafting-release-notes; do
    git mv plugins/saleizo-design/skills/prose/$s plugins/saleizo-prose/skills/$s
  done
  git mv plugins/saleizo-design/skills/prose/shared plugins/saleizo-prose/skills/shared
  rmdir plugins/saleizo-design/skills/prose 2>/dev/null || true
  ```
- [ ] **Write `plugins/saleizo-prose/.claude-plugin/plugin.json`** (version `1.0.0`, description "De-slop and humanize prose; draft store release notes.", 3 `./skills/<name>`; `shared` not listed).
- [ ] **Write `plugins/saleizo-prose/README.md`** — catalog of the 3 skills.
- [ ] **Add marketplace entry** (append via temp file):
  ```bash
  jq '.plugins += [{"name":"saleizo-prose","source":"./plugins/saleizo-prose"}]' .claude-plugin/marketplace.json > mp.tmp && mv mp.tmp .claude-plugin/marketplace.json
  ```
- [ ] **Flip the 3 routing `plugin` fields** to `saleizo-prose` (temp-file + `mv` loop, list = the 3 names).
- [ ] **Verify (GREEN):** paths resolve, routing parity, `../../shared/` links resolve:
  ```bash
  d=plugins/saleizo-prose; jq -r '.skills[]' $d/.claude-plugin/plugin.json | while read p; do test -f "$d/$p/SKILL.md" || echo "MISSING $p"; done
  jq -r '.skills|to_entries[]|select(.value.plugin=="saleizo-prose")|.key' .claude/skills-routing.json | while read n; do test -d $d/skills/$n || echo "DRIFT $n"; done
  for f in $(find $d/skills -name '*.md'); do grep -oE '\]\((\.\.?/[^)]+\.md)\)' "$f" | sed -E 's/.*\((.*)\)/\1/' | while read l; do test -f "$(dirname "$f")/$l" || echo "BROKEN LINK $f -> $l"; done; done
  test -f $d/skills/shared/scoring-rubric.md && echo "shared moved"; echo checked
  ```
  Expect: no `MISSING`/`DRIFT`/`BROKEN LINK`, `shared moved`, `checked`.
- [ ] **Commit (proposed):** `git add -A && git commit -m "refactor(plugins): extract saleizo-prose from saleizo-design"`

---

## Task 6 — Flatten the `saleizo-design` remainder (3 skills)

**Files:** `plugins/saleizo-design/skills/<name>/` (3 moved up), `plugins/saleizo-design/.claude-plugin/plugin.json` (EDIT — flat + major bump). **No routing edit** (codebase-design keeps `plugin: saleizo-design`; the other 2 are `disable-model-invocation`, unrouted).
**Interfaces — Consumes:** `skills/design/{codebase-design,improve-codebase-architecture}` + `skills/review/auditing-code-quality`. **Produces:** flat `saleizo-design`, 3 skills.

- [ ] **Define the check (RED):** `test -d plugins/saleizo-design/skills/design && echo "RED: still nested"`.
- [ ] **Move up** (these 3 are the complete remaining set — `design/` holds exactly `codebase-design` + `improve-codebase-architecture`, `review/` holds exactly `auditing-code-quality`; `prose/` already left in Task 5):
  ```bash
  git mv plugins/saleizo-design/skills/design/codebase-design plugins/saleizo-design/skills/codebase-design
  git mv plugins/saleizo-design/skills/design/improve-codebase-architecture plugins/saleizo-design/skills/improve-codebase-architecture
  git mv plugins/saleizo-design/skills/review/auditing-code-quality plugins/saleizo-design/skills/auditing-code-quality
  rmdir plugins/saleizo-design/skills/design plugins/saleizo-design/skills/review 2>/dev/null || true
  ```
- [ ] **Rewrite `plugins/saleizo-design/.claude-plugin/plugin.json`** — `skills[]` = the 3 flat paths; `version` → next **major**; description unchanged or "Deep-module design vocabulary, architecture review, code-quality review."
- [ ] **Verify (GREEN):**
  ```bash
  d=plugins/saleizo-design; jq -r '.skills[]' $d/.claude-plugin/plugin.json | while read p; do test -f "$d/$p/SKILL.md" || echo "MISSING $p"; done
  test $(jq '.skills|length' $d/.claude-plugin/plugin.json) -eq 3 && echo "count=3"
  find $d/skills -maxdepth 1 -mindepth 1 -type d ! -exec test -f '{}/SKILL.md' ';' -print  # any non-skill dir
  for f in $(find $d/skills -name '*.md'); do grep -oE '\]\((\.\.?/[^)]+\.md)\)' "$f" | sed -E 's/.*\((.*)\)/\1/' | while read l; do test -f "$(dirname "$f")/$l" || echo "BROKEN $f -> $l"; done; done
  echo checked
  ```
  Expect: no `MISSING`, `count=3`, no leftover category dirs, no `BROKEN`.
- [ ] **Commit (proposed):** `git add -A && git commit -m "refactor(plugins): flatten saleizo-design"`

---

## Task 7 — Update live cross-references (CLAUDE.md ×2, glossary, routing-sync, READMEs)

**Files:** `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/domains/glossary.md`, `.claude/rules/common/skill-routing-sync.md`, `README.md`, `plugins/saleizo-core/README.md`, `plugins/saleizo-design/README.md`, and (REVIEW) the illustrative example assets.
**Interfaces — Consumes:** the new plugin set on disk. **Produces:** docs/rules consistent with the 8-plugin flat layout.

- [ ] **Define the check (RED):** whole-repo grep for live stale category paths returns hits (in docs/rules/READMEs):
  ```bash
  grep -rn "skills/\(chain\|authoring\|setup\|session\|aliases\|design\|prose\|review\)/" --exclude-dir=.git . | grep -vE "docs/adr/|lessons-learned\.md"
  ```
  Expect: nonzero hits now (RED).
- [ ] **Edit `CLAUDE.md` (root):** "publishes 5 plugins" → 8; rewrite the plugin roster (add commands/authoring/foundation/prose; update saleizo-core/design descriptions); the `plugins/<kit>/skills/<category>/<name>/` path convention → `plugins/<kit>/skills/<name>/`; routing-table and where-rules-live sections; the aliases-path note.
- [ ] **Edit `.claude/CLAUDE.md`:** the `behavioral-baseline.md` reference → `../plugins/saleizo-foundation/skills/bootstrapping-claude-md/references/behavioral-baseline.md`; any `plugins/saleizo-core/skills/<category>/` path; plugin-roster/kit-count prose; hook-location prose if it cites moved paths.
- [ ] **Edit `.claude/rules/domains/glossary.md`:** path-convention row → flat; "five kits" → eight; ownership table; aliases-location note (`plugins/saleizo-commands/skills/`); `improve-codebase-architecture` plugin reference (now saleizo-design, still unrouted).
- [ ] **Edit `.claude/rules/common/skill-routing-sync.md`:** `plugins/saleizo-core/skills/aliases/` → `plugins/saleizo-commands/skills/`.
- [ ] **Edit `README.md` (root):** plugin catalog — add the 4 new plugins, update install snippet/descriptions/links.
- [ ] **Edit `plugins/saleizo-core/README.md` and `plugins/saleizo-design/README.md`:** reduce catalogs to the skills each still owns; flat paths.
- [ ] **Review the illustrative example assets** (`auditing-conflicts/assets/audit-report-example.md`, `auditing-readme`/`bootstrapping-readme` `catalog-derivation.md`/`readme-scaffold.md`, now under `saleizo-foundation`): edit a category path ONLY where it asserts a real current path; leave illustrative-only examples.
- [ ] **Verify (GREEN):** the same grep returns only immutable-record hits:
  ```bash
  grep -rn "skills/\(chain\|authoring\|setup\|session\|aliases\|design\|prose\|review\)/" --exclude-dir=.git . | grep -vE "docs/adr/|lessons-learned\.md"
  ```
  Expect: empty output.
- [ ] **Commit (proposed):** `git add -A && git commit -m "docs(plugins): update CLAUDE.md, glossary, README for flat plugin layout"`

---

## Task 8 — Whole-system verification gate (the spec's Verification section)

**Files:** none edited — this task runs the spec's full verification and the drift auditors; any failure loops back to the owning task.
**Interfaces — Consumes:** the entire post-migration tree. **Produces:** a green structural verdict.

- [ ] **Manifest ↔ disk parity (all plugins):**
  ```bash
  for d in plugins/*/; do m=$d.claude-plugin/plugin.json; [ -f "$m" ] || continue; jq -r '.skills[]?' "$m" | while read p; do test -f "$d$p/SKILL.md" || echo "MISSING $d$p"; done; done; echo "manifests checked"
  jq -r '.plugins[].source' .claude-plugin/marketplace.json | while read s; do test -f "$s/.claude-plugin/plugin.json" || echo "BAD marketplace source $s"; done; echo "marketplace checked"
  ```
- [ ] **Routing ↔ disk parity (all 32 entries):**
  ```bash
  jq -r '.skills|to_entries[]|"\(.key) \(.value.plugin)"' .claude/skills-routing.json | while read n p; do test -d plugins/$p/skills/$n && echo "ok $n@$p" || echo "DRIFT $n@$p"; done | grep -c ok
  jq -r '.skills|to_entries[]|"\(.key) \(.value.plugin)"' .claude/skills-routing.json | while read n p; do test -d plugins/$p/skills/$n || echo "DRIFT $n@$p"; done
  ```
  Expect: `32` ok, no `DRIFT`.
- [ ] **No live stale category paths** (Task 7 grep) → empty.
- [ ] **Reference-link resolution across all moved/new skills:**
  ```bash
  for f in $(find plugins/saleizo-{commands,authoring,foundation,prose,core,design}/skills -name '*.md'); do grep -oE '\]\((\.\.?/[^)]+\.md)\)' "$f" | sed -E 's/.*\((.*)\)/\1/' | while read l; do test -f "$(dirname "$f")/$l" || echo "BROKEN $f -> $l"; done; done; echo "links checked"
  ```
  Expect: no `BROKEN`.
- [ ] **Invocation smoke-check** — invoke one moved skill per new plugin by bare name (via the `Skill` tool): an alias (`/sdd`), `writing-adrs`, a foundation skill (`auditing-readme`), a prose skill (`tightening-prose`); confirm each loads from its new plugin.
- [ ] **Drift auditors** — run `auditing-conflicts`, `auditing-readme`, `auditing-glossary` (and `auditing-claude-md`) over the repo; confirm no new orphan refs / catalog drift / glossary drift introduced by the move.
- [ ] **Commit (proposed):** none — verification only; the per-task commits already landed. Report the green verdict to the owner.

---

## Self-review

- **Show-don't-describe:** every code/command step has a real command + expected output; doc-edit steps (Tasks 7) name the exact file + exact substring change (the prose targets are enumerated, not "update docs"). ✓
- **Type/name consistency:** plugin names, skill lists, and routing values match the spec's Contracts table verbatim across all tasks; counts reconcile (12+5+5+10+3+3 = 38; routing 32). ✓
- **Test-first adapted:** each task defines its structural check (RED), applies the move/edit, re-runs green, commits — the vault's verification model (no unit-test runner). ✓
- **Coverage:** every spec Files-touched row maps to a task (new plugins 1/2/3/5; flattens 4/6; refs 7; final verify 8). ✓
