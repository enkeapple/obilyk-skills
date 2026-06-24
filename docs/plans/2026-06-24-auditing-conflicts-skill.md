# auditing-conflicts Skill — Implementation Plan

**Goal:** Build the agnostic, trigger-routed skill `auditing-conflicts` (read-only cross-artifact conflict auditor, 9 classes, two layers, C-drift picker) per the approved spec.
**Architecture:** A `setup/auditing-*`-family skill = `SKILL.md` (process + red flags + rationalizations) + two `references/*.md` (the detection contract, and the mechanical recipes) + one `assets/*.md` (a filled report example). Plus three EDITs to wire routing and catalogs. Built test-first via `writing-skills`: RED = subagent pressure run / mechanical fixture check, GREEN = compliance + validators.
**Tech stack:** Markdown skill files, `.claude/skills-routing.json` (schema v2), bash/grep/jq + `Task` subagents for the skill's runtime. No build/pnpm/Vitest — verification is validators + subagent runs.

## Global constraints

- Source of truth is the spec `docs/specs/2026-06-24-auditing-conflicts-skill.md`; copy its contracts verbatim, do not re-derive. (one line each below ↓)
- Iron Law: no skill content written before a baseline subagent RED is observed for that task's behavior.
- Agnostic-by-default: no hard dependency on sdd-kit being installed; delegation to other auditors is a disposition string, never a `Skill` invocation.
- `name` === directory === `SKILL.md name:` === routing key = `auditing-conflicts`.
- Read-only until the user picks a C-drift disposition; the audit phase never edits artifacts.
- Validators must pass: frontmatter ≤1024 bytes, `name` regex `^[a-z0-9-]+$`, every `references/*.md`/`assets/*.md` link resolves, fences balanced (even count), word count sane.
- `skills-routing.json` stays valid JSON; the new entry is `kind:"ref"` (plugin+name, NO files), key == name (per `skill-routing-sync.md`).
- **RED scenario files are transient subagent inputs**, written to the **session scratchpad** (shown below as `<scratch>/`), NOT `/tmp` and NOT a handoff doc — delete them after the run. This is distinct from the vault's "never hand-write `/tmp`" plan-persistence rule, which governs handoff state, not ephemeral pressure-run prompts.

## File map

| File | Responsibility |
|------|----------------|
| `plugins/sdd-kit/skills/setup/auditing-conflicts/SKILL.md` | Frontmatter + process (inventory→mechanical→judgment→report→picker) + disagreement rule + two fix lanes + red flags + rationalizations |
| `.../references/conflict-catalog.md` | The 9-class detection contract: layer, fix lane, detection method; class-6 lane split; finding shape |
| `.../references/mechanical-checks.md` | grep/jq recipes for classes 1/6/8/9; shortlist signal computations; fixed stop-word list + sample prompt set; class-9 search rules |
| `.../assets/audit-report-example.md` | Filled report: real F-001, a zero-findings class line, a FALSE class-6 (carrying a `canonical source is X` xref) downgraded to Info |
| `.claude/skills-routing.json` | Add the `ref` entry |
| `plugins/sdd-kit/README.md` | Catalog row under `setup` skills |
| `CLAUDE.md` (root) | Routing-table row |

---

## Task 1 — Frontmatter + conflict-catalog reference (the detection contract)

**Files:** `plugins/sdd-kit/skills/setup/auditing-conflicts/SKILL.md` (NEW), `.../references/conflict-catalog.md` (NEW)

**Interfaces:**
- Consumes: nothing (first task).
- Produces: the skill directory + `name: auditing-conflicts`; the 9-class catalog table and the locked finding shape that Tasks 2–4 reference.

**Steps:**

- [ ] **RED — baseline subagent run, no skill.** Stage a temporary scenario file `<scratch>/ac-red-1.md` asking a general-purpose subagent: *"Audit this vault for conflicts between skills, rules, and routing; produce a classified report."* Dispatch it WITHOUT any auditing-conflicts skill. Expected failure (record verbatim): it produces ad-hoc prose, no 9-class taxonomy, no locked finding shape, no class/severity grouping. Confirm RED.

- [ ] **GREEN — write the frontmatter** (verbatim from spec Contracts):
```yaml
---
name: auditing-conflicts
description: >-
  Use to find conflicts and contradictions BETWEEN skills, rules, and routing
  in a framework repo — overlapping triggers, duplicated ownership, broken
  hand-offs, rule-vs-rule or rule-vs-skill contradictions, routing/invocation
  invariant breaks, orphan references — distinct from the one-pair drift
  auditors. Triggers on: "audit conflicts", "check for skill/rule conflicts",
  "find contradictions", "conflicting triggers", "проверь конфликты",
  "аудит конфликтов", "противоречия между скиллами/рулами".
allowed-tools: Read, Grep, Glob, Bash, Task
---

# Auditing Conflicts
```

- [ ] **GREEN — write `references/conflict-catalog.md`** with the 9-class table verbatim from the spec (columns: # | Class | Layer | Fix lane | Detection), the class-6 lane split (mechanical = missing-cross-reference sub-case fixed by adding the `canonical source is X` line; behavioral = genuine duplication routed through `writing-rules`/`writing-skills`; mechanical detects all candidates, judgment tags the sub-case), the locked finding shape:
```text
F-NNN · Class <1-9> · Severity <Info|Low|Medium|High>
Title:    <one line>
Evidence: <file:line> "<verbatim citation>"   (one or more)
Why:      <why these two artifacts conflict>
Disposition: <recommended action> → <delegate-target: writing-skills | writing-rules |
              mechanical re-check | "run auditing-readme" (reference-only) | owner action | accept>
```
  and the disagreement rule (mechanical authoritative on existence; judgment may only annotate — downgrade to `Info` with rationale — never delete). Zero findings for a class → explicit `Class N: no conflicts found`.

- [ ] **Validate frontmatter:**
```bash
F=plugins/sdd-kit/skills/setup/auditing-conflicts/SKILL.md
awk 'f&&/^---$/{exit} /^---$/{f=1;next} f{print}' "$F" | wc -c   # expect <= 1024
grep -nE '^name: [a-z0-9-]+$' "$F"                               # expect: name: auditing-conflicts
```
  Expected: byte count ≤ 1024; the name line matches.

- [ ] **GREEN re-run.** Re-dispatch the Task-1 scenario WITH the frontmatter + catalog present. Expected: the subagent now classifies findings into the 9 classes and uses the locked finding shape. Confirm GREEN.

- [ ] **Commit:**
```bash
git add plugins/sdd-kit/skills/setup/auditing-conflicts/SKILL.md plugins/sdd-kit/skills/setup/auditing-conflicts/references/conflict-catalog.md
git commit -m "feat(auditing-conflicts): add skill frontmatter and 9-class conflict catalog"
```

---

## Task 2 — SKILL.md body: process, fix lanes, red flags, rationalizations

**Files:** `plugins/sdd-kit/skills/setup/auditing-conflicts/SKILL.md` (EDIT)

**Interfaces:**
- Consumes: the catalog + finding shape from Task 1 (`references/conflict-catalog.md`).
- Produces: the runnable process the report/fix tasks rely on (the `## Process` step names, the C-drift picker, the two fix lanes).

**Steps:**

- [ ] **RED — over-report/auto-fix pressure.** Stage `<scratch>/ac-red-2.md`: a subagent given a planted intentional trigger overlap (two complementary skills) AND told "fix anything you find while you're here". Dispatch WITHOUT the body (frontmatter+catalog only). Expected failure: it either auto-edits artifacts (no read-only discipline) or over-reports the intentional overlap as High without annotation. Confirm RED.

- [ ] **GREEN — write the body** with these sections (real content, not placeholders):
  - `## Process` (ordered): 1. **Inventory** (working tree, not HEAD — read every `SKILL.md`, rule, `skills-routing.json`); 2. **Mechanical layer** — run the `references/mechanical-checks.md` recipes → precise findings for classes 1/6/8/9 + a shortlist of candidate pairs; 3. **Judgment layer** — fan out one subagent per shortlisted candidate (`Task` tool), full bodies in, finding-shape out, on a different model + fresh context (cite `model-selection.md`); 4. **Report** — group by class+severity, zero-findings line per clean class; 5. **Disposition** — one C-drift batched picker.
  - **Disagreement rule** paragraph (mechanical authoritative on existence; judgment annotate-only → `Info` + rationale, never delete).
  - **Two fix lanes** (on `Apply recommended`, the finding itself is the RED): mechanical lane (classes 8, 9, the missing-xref sub-case of 6) = edit + re-run the same mechanical check (red→green), no pressure-subagent; behavioral lane (classes 2/3/4/5/7, the duplication sub-case of 6) = route through `writing-skills`/`writing-rules` real RED→GREEN; class 1 = `owner action`, skipped by the runner; sequential, stop-on-first-failure.
  - The C-drift picker block (verbatim shape, mirroring `spec-drift-audit`):
```text
- `Apply recommended` → apply the per-finding recommended dispositions (run each in its fix lane, sequential, stop-on-first-failure).
- `Adjust per-finding` → walk findings one by one.
- `Stop` → take no action now.
```
  - `## Red Flags — STOP` and `## Rationalizations` (table) covering: "I'll just fix the overlap while here" → report it, read-only; "the intentional overlap is a conflict" → judgment annotates to Info, mechanical keeps it visible; "scan only the obvious orphan" → class-9 whole-repo sweep; "prose report" → locked finding shape.

- [ ] **Validate fences + word count:**
```bash
F=plugins/sdd-kit/skills/setup/auditing-conflicts/SKILL.md
test $(( $(grep -o '```' "$F" | wc -l) % 2 )) -eq 0 && echo "fences balanced"   # expect: fences balanced
wc -w "$F"                                                                       # expect: sane (< ~1500)
```

- [ ] **GREEN re-run.** Re-dispatch the Task-2 scenario WITH the body. Expected: subagent stays read-only, reports the intentional overlap but the judgment annotation downgrades it to `Info` with a rationale, and presents the C-drift picker instead of editing. Confirm GREEN.

- [ ] **REFACTOR.** The red-flags / rationalizations table is written during the GREEN step above; now close any *new* loophole the GREEN re-run subagent invented (e.g. a fresh excuse to auto-fix, or to skip the picker). Add a rationalization row per new loophole and re-run until none remain.

- [ ] **Commit:**
```bash
git add plugins/sdd-kit/skills/setup/auditing-conflicts/SKILL.md
git commit -m "feat(auditing-conflicts): add process, fix lanes, red flags, rationalizations"
```

---

## Task 3 — mechanical-checks.md reference (recipes + reproducible shortlist)

**Files:** `plugins/sdd-kit/skills/setup/auditing-conflicts/references/mechanical-checks.md` (NEW)

**Interfaces:**
- Consumes: the catalog classes 1/6/8/9 and the shortlist concept from Task 1.
- Produces: the deterministic recipes the `## Process` mechanical step (Task 2) calls; the fixed stop-word list + sample prompt set later runs reuse.

**Steps:**

- [ ] **RED — non-reproducible shortlist.** Stage `<scratch>/ac-red-3.md`: ask **two independent subagents** (two separate `Task` dispatches with fresh contexts — NOT the same subagent run twice) to "shortlist candidate conflicting skill pairs in this vault" WITHOUT the pinned computations. Expected failure: the two runs return different shortlists (ad-hoc keyword judgment). Confirm RED (divergence observed).

- [ ] **GREEN — write the recipes**, each a real command:
  - **Class 1 (trigger collision):** read all `triggers` via `jq`, test each pair's regexes against a fixed sample-prompt set; collision = both match ≥1 sample.
```bash
jq -r '.skills | to_entries[] | "\(.key)\t\(.value.triggers|join("|"))"' .claude/skills-routing.json
```
  - **Class 8 (routing/invocation invariant):** name===dir===key; model-invocable skill with no routing entry; `disable-model-invocation:true` WITH an entry; alias → nonexistent name.
```bash
# every routed ref key must equal a real skill dir name:
comm -23 <(jq -r '.skills|keys[]' .claude/skills-routing.json|sort) \
         <(find plugins -name SKILL.md|sed -E 's#.*/([^/]+)/SKILL.md#\1#'|sort)
```
  - **Class 9 (orphan ref) — per `search-scope-verification.md`:** whole repo, `grep -rE` (never BRE `\|`), no `-maxdepth`, no `--include`. Build the name dictionary = disk dirs ∪ routing keys; flag a backticked skill-name in a hand-off/`REQUIRED SUB-SKILL`/routing context that is not in the dictionary; flag a markdown link whose target path is absent.
  - **Class 6 (duplicate canonical-source) detection:** two artifacts asserting ownership of one concern with no `canonical source is X` / `do not duplicate` cross-reference.
  - **Shortlist signal computations** (pin each so two runs agree — verbatim from spec): overlapping triggers (both match ≥1 sample, or share a literal token); shared description keyword (lowercase, strip the fixed stop-word list, ≥2 shared content tokens); same `skills/<category>/` segment; mutual hand-off ref. Include the **exact stop-word list** (`the a an to of and or use when this that skill rule for with`) and the **fixed sample-prompt set** as literal lists in this file.
  - A **known-bound note** (per the spec Risks): the shortlist can miss a pair sharing no signal; the skill must `log` shortlist size + dropped-pair count (no silent caps).

- [ ] **Validate link + reachability** of any path cited in this reference:
```bash
F=plugins/sdd-kit/skills/setup/auditing-conflicts/references/mechanical-checks.md
grep -oE '\([^)]+\.md\)' "$F" | tr -d '()' | while read p; do test -e "$(dirname "$F")/$p" || echo "BROKEN: $p"; done   # expect: no output
```

- [ ] **GREEN re-run.** Re-dispatch two independent subagents (two separate `Task` dispatches, fresh contexts) WITH `mechanical-checks.md`. Expected: identical shortlist from both (determinism). Confirm GREEN.

- [ ] **Commit:**
```bash
git add plugins/sdd-kit/skills/setup/auditing-conflicts/references/mechanical-checks.md
git commit -m "feat(auditing-conflicts): add mechanical recipes and reproducible shortlist signals"
```

---

## Task 4 — audit-report-example.md asset (the GREEN gate fixture)

**Files:** `plugins/sdd-kit/skills/setup/auditing-conflicts/assets/audit-report-example.md` (NEW)

**Interfaces:**
- Consumes: the locked finding shape (Task 1).
- Produces: the worked example the SKILL.md body links to; the false-conflict case the Layer-2 GREEN gate (Task 5) asserts.

**Steps:**

- [ ] **RED — link from the body is broken / no example.** Confirm the SKILL.md body references `assets/audit-report-example.md` but the file does not yet exist:
```bash
test -e plugins/sdd-kit/skills/setup/auditing-conflicts/assets/audit-report-example.md || echo "MISSING (expected RED)"
```

- [ ] **GREEN — write the filled report** with three required cases:
  1. **Real F-001** (verbatim, lines must match disk):
```text
F-001 · Class 7 · Severity Low
Title:    "Prefer multiple-choice" reads as the picker, but the rule reserves the picker for gates
Evidence: plugins/sdd-kit/skills/chain/grilling/SKILL.md:33 "Ask ONE question. Prefer multiple-choice."
          .claude/rules/common/interactive-gates.md:23 "Do NOT add a picker where the choice is ... already conversational (a one-question recommended-answer interview)."
Why:      "multiple-choice" (content framing) vs "picker" (tool, gates only) not distinguished → inconsistent UX
Disposition: amend grilling:33 to split framing from the picker tool → writing-skills (test-first)
```
  2. A **zero-findings class line**, e.g. `Class 5 (rule-vs-rule): no conflicts found`.
  3. A **FALSE class-6 conflict downgraded** — an overlap that DOES carry an explicit `canonical source is X` cross-reference (e.g. `git-conventions.md` deferring to `CLAUDE.md` → "Canonical Source — Do Not Duplicate"), shown as annotated down to `Severity Info` with the rationale that the cross-reference resolves it. This is the over-report guard.

- [ ] **Validate cited lines resolve on disk:**
```bash
sed -n '33p' plugins/sdd-kit/skills/chain/grilling/SKILL.md         # expect the "Prefer multiple-choice" line
sed -n '23p' .claude/rules/common/interactive-gates.md              # expect the "Do NOT add a picker" line
grep -n "Canonical Source — Do Not Duplicate" .claude/rules/common/git-conventions.md   # expect a hit (the false-conflict basis)
```
  Expected: each citation in the asset matches the real file content.

- [ ] **Commit:**
```bash
git add plugins/sdd-kit/skills/setup/auditing-conflicts/assets/audit-report-example.md
git commit -m "feat(auditing-conflicts): add filled report example with false-conflict downgrade case"
```

---

## Task 5 — Wire routing + catalogs + full Layer-2 GREEN gate

**Files:** `.claude/skills-routing.json` (EDIT), `plugins/sdd-kit/README.md` (EDIT), `CLAUDE.md` root (EDIT)

**Interfaces:**
- Consumes: the skill name + triggers (Task 1).
- Produces: a routed, catalogued, model-invocable skill (final deliverable).

**Steps:**

- [ ] **RED — unrouted skill.** Confirm the skill is invisible to routing:
```bash
jq '.skills | has("auditing-conflicts")' .claude/skills-routing.json   # expect: false (RED)
```

- [ ] **GREEN — add the `ref` entry** to `.claude/skills-routing.json` (verbatim from spec):
```json
"auditing-conflicts": {
  "kind": "ref",
  "plugin": "sdd-kit",
  "name": "auditing-conflicts",
  "triggers": [
    "audit conflicts",
    "check for (skill|rule) conflicts",
    "find contradictions",
    "conflicting triggers",
    "проверь конфликты",
    "аудит конфликтов",
    "противоречия между (скиллами|правилами)"
  ]
}
```

- [ ] **GREEN — add the catalog row** to `plugins/sdd-kit/README.md` under the `setup` skills (match the `auditing-glossary`/`auditing-readme` row form at lines 74–75):
```markdown
- **[auditing-conflicts](skills/setup/auditing-conflicts/SKILL.md)** — Use to find conflicts and contradictions BETWEEN skills, rules, and routing in a framework repo — distinct from the one-pair drift auditors.
```

- [ ] **GREEN — add the routing-table row** to root `CLAUDE.md` near the `auditing-*` family (lines 43–44), exact text:
```markdown
| Find conflicts/contradictions across skills, rules, and routing | `auditing-conflicts` |
```

- [ ] **Validate routing invariants** (per `skill-routing-sync.md`):
```bash
jq . .claude/skills-routing.json >/dev/null && echo "valid json"
jq '.skills["auditing-conflicts"] | {has_plugin:has("plugin"), has_name:has("name"), no_files:(has("files")|not), key_eq_name:(.name=="auditing-conflicts")}' .claude/skills-routing.json
# expect: all true
```

- [ ] **Full validator pass** on the finished skill (frontmatter ≤1024, name regex, all `references/`+`assets/` links resolve, fences balanced, word count):
```bash
F=plugins/sdd-kit/skills/setup/auditing-conflicts/SKILL.md
awk 'f&&/^---$/{exit} /^---$/{f=1;next} f{print}' "$F" | wc -c
grep -nE '^name: [a-z0-9-]+$' "$F"
test $(( $(grep -o '```' "$F" | wc -l) % 2 )) -eq 0 && echo "fences balanced"
for D in $(find plugins/sdd-kit/skills/setup/auditing-conflicts -name '*.md'); do
  grep -oE '\]\(([^)]+\.md)\)' "$D" | sed -E 's/\]\(([^)]+)\)/\1/' | while read p; do
    case "$p" in /*) t="$p";; *) t="$(dirname "$D")/$p";; esac
    test -e "$t" || echo "BROKEN: $D -> $p"
  done
done   # expect: no output (every references/assets link resolves)
```

- [ ] **Layer-2 GREEN gate (independent verification subagent).** Stage a temporary case file (deleted after) with the cases from the spec Verification section; dispatch a fresh subagent (different model) to run them WITH the finished skill and return PASS/FAIL with verbatim evidence. Cases: (a) finds the planted real conflict in the locked shape; (b) emits zero-findings lines for clean classes; (c) **downgrades the FALSE class-6 overlap** (one carrying a `canonical source is X` xref) to `Info` rather than over-reporting. Confirm the subagent inverts each case and returns PASS.

- [ ] **Commit:**
```bash
git add .claude/skills-routing.json plugins/sdd-kit/README.md CLAUDE.md
git commit -m "feat(auditing-conflicts): wire routing entry and skill catalog rows"
```

---

## Self-review

- Show-don't-describe: every code step has a real block; every command step has the exact command + expected output; every task ends in a commit. ✔
- Type/name consistency: `auditing-conflicts` (name===dir===key) used identically across Tasks 1–5; the locked finding shape defined in Task 1 is referenced (not redefined) in Tasks 2/4; the C-drift picker labels match `interactive-gates.md` archetype C-drift. ✔
- Test-first: each task observes a RED before the GREEN content; the final Layer-2 gate includes the false-conflict class-6 downgrade per the spec. ✔
