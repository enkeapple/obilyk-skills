# auditing-conflicts skill

## Goal

Add a new agnostic, trigger-routed skill `auditing-conflicts` that does a read-only **cross-artifact** coherence audit of a framework repo — finding conflicts/contradictions *between* skills, rules, and routing (9 classes) and ending in a C-drift batched picker — distinct from the four existing one-pair drift auditors.

## Scope

- A new skill at `plugins/sdd-kit/skills/setup/auditing-conflicts/` (`SKILL.md` + `references/` + `assets/`), matching the `setup/auditing-*` family form.
- Detection of **9 conflict classes** in two layers: a **mechanical** layer (deterministic grep/jq: classes 1, 6, 8, 9) and a **judgment** layer (subagent fan-out: classes 2, 3, 4, 5, 7).
- A **report** in the locked finding shape, grouped by class and severity, then one **C-drift** batched picker (`Apply recommended` / `Adjust per-finding` / `Stop`).
- A `ref` routing entry in `.claude/skills-routing.json` and catalog/routing-table rows.
- The two fix lanes invoked on `Apply recommended` (mechanical re-check / behavioral via `writing-skills`/`writing-rules`).

## Out of scope

- **Class 10 (cross-plugin coupling)** — deferred YAGNI; not detected.
- **Re-doing one-pair drift** — `auditing-conflicts` never re-checks spec↔code, README↔disk, CLAUDE.md↔repo, glossary↔code; a drift observation becomes a finding whose disposition *names* the right `auditing-*`/`spec-drift-audit` to run (reference-only).
- **Invoking** any of the four drift auditors (delegation is a disposition string, never a `Skill` call).
- **Auto-fixing without a pick** — read-only until the user picks `Apply recommended`/`Adjust per-finding`.
- Building the skill itself (this spec → `writing-plans` → `writing-skills` RED→GREEN→REFACTOR→VALIDATE).
- Editing the four existing auditors or the validators.
- Any change to `version`/`ruleGates` in `skills-routing.json`.

## Contracts

### SKILL.md frontmatter (NEW)

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
```

`Task` is in `allowed-tools` for the judgment-layer subagent fan-out; `Bash` is for read-only grep/jq inventory and the mechanical re-check on a fix — never to edit artifacts in the read-only phase. (Mirrors `spec-drift-audit`'s read-only-despite-Bash guarantee.)

### Conflict catalog (the detection contract)

| # | Class | Layer | Fix lane | Detection |
|---|-------|-------|----------|-----------|
| 1 | Trigger collision | Mechanical (detect) | **Owner action** — report only | Two routing entries whose `triggers` regexes overlap on a sample prompt set |
| 2 | Responsibility overlap | Judgment | Behavioral | Subagent reads both full bodies; same job claimed |
| 3 | Broken hand-off (semantic) | Judgment | Behavioral | Subagent: a `REQUIRED SUB-SKILL`/Upstream/Downstream target exists but does the wrong thing |
| 4 | Contradictory instructions | Judgment | Behavioral | Subagent: skill A mandates X, skill B forbids X in the same situation |
| 5 | Rule-vs-rule contradiction | Judgment | Behavioral | Subagent over a rule pair |
| 6 | Duplicate canonical-source | Mechanical (detect) | **see split below** | Two artifacts assert ownership of one concern with **no** "canonical source is X / do not duplicate" cross-reference |
| 7 | Rule-vs-skill contradiction | Judgment | Behavioral | Subagent over a rule×skill pair (e.g. F-001) |
| 8 | Routing/invocation invariant | Mechanical | Mechanical | `name`≠dir≠routing-key; model-invocable skill with no routing entry; `disable-model-invocation:true` skill WITH an entry; alias delegating to a nonexistent name |
| 9 | Orphan reference | Mechanical | Mechanical | A structural citation whose target is absent on disk |

**Class-6 lane split (advisory #1 — stated, not "part of 6"):**
- **Mechanical fix lane** — the *missing-cross-reference* sub-case: the fix is to **add** the `canonical source is X` line; verified by re-running the class-6 check (red→green). No pressure-subagent.
- **Behavioral fix lane** — the *genuine content duplication* sub-case (the two artifacts say overlapping things and one must be cut/merged): routes through `writing-rules`/`writing-skills` test-first, because it changes what an artifact says.
- The mechanical layer **detects** all class-6 candidates; the judgment layer decides which sub-case each is (missing xref vs real duplication) and tags the lane.

### Locked finding shape (every finding, mechanical or judgment)

```text
F-NNN · Class <1-9> · Severity <Info|Low|Medium|High>
Title:    <one line>
Evidence: <file:line> "<verbatim citation>"   (one or more)
Why:      <why these two artifacts conflict>
Disposition: <recommended action> → <delegate-target: writing-skills | writing-rules |
              mechanical re-check | "run auditing-readme" (reference-only) | owner action | accept>
```

Zero findings for a class → an explicit `Class N: no conflicts found` line (never an omitted class). Validated live example carried into the report asset:

```text
F-001 · Class 7 · Severity Low
Title:    "Prefer multiple-choice" reads as the picker, but the rule reserves the picker for gates
Evidence: plugins/sdd-kit/skills/chain/grilling/SKILL.md:33 "Ask ONE question. Prefer multiple-choice."
          .claude/rules/common/interactive-gates.md:23 "Do NOT add a picker where the choice is ... already conversational (a one-question recommended-answer interview)."
Why:      "multiple-choice" (content framing) vs "picker" (tool, gates only) not distinguished → inconsistent UX
Disposition: amend grilling:33 to split framing from the picker tool → writing-skills (test-first)
```

### Shortlist signal computations (advisory #2 — pinned so two runs agree)

The mechanical layer narrows ~N² pairs to a deterministic shortlist for the judgment layer. A pair is shortlisted iff **any** signal fires:

| Signal | Concrete computation |
|--------|----------------------|
| Overlapping triggers | The two entries' `triggers` regexes both match ≥1 prompt in a fixed sample set (or share a literal trigger token) |
| Shared description keyword | After lowercasing, stripping a fixed stop-word list (the/a/use/when/to/of/and/skill/…), the two `description`s share ≥2 content tokens |
| Same category | Same `skills/<category>/` directory segment |
| Mutual hand-off ref | One body backtick-names the other in a `REQUIRED SUB-SKILL`/Upstream/Downstream/hand-off context |

The exact stop-word list and sample prompt set are fixed assets in `references/mechanical-checks.md` so the shortlist is reproducible.

### Routing entry (EDIT `.claude/skills-routing.json`)

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

### Class-9 orphan scope (the search contract — per `search-scope-verification.md`)

- Whole-repo sweep: `grep -rE` (never BRE `\|`), **no** `-maxdepth`, **no** `--include` allowlist.
- Doc set: every `SKILL.md` + `references/*.md` + `assets/*.md`, `.claude/rules/**/*.md`, both `CLAUDE.md`, `.claude/skills-routing.json`, hooks config / `*.yml` / `.github/`.
- Citation = a **structural claim**, not prose: (a) a markdown link to a path → target must exist; (b) a backticked skill-name in a hand-off/`REQUIRED SUB-SKILL`/routing context → must be in the dictionary of real names (disk dirs ∪ routing keys); (c) a rule-file path. A prose mention ("skills like `grilling`") is not a citation.
- Audit reads the **working tree**, not HEAD (catch conflicts pre-commit).

### Disagreement resolution (mechanical vs judgment)

The mechanical layer is **authoritative on existence** (deterministic). A judgment subagent may only **annotate** a mechanical finding — downgrade severity to `Info` with a written rationale (e.g. "trigger overlap is intentional, skills complementary") — **never delete** it. The finding stays visible.

## Files touched

| File | Change | Why |
|------|--------|-----|
| `plugins/sdd-kit/skills/setup/auditing-conflicts/SKILL.md` | NEW | The skill body: process (inventory → mechanical → judgment → report → picker), red flags, rationalizations |
| `plugins/sdd-kit/skills/setup/auditing-conflicts/references/conflict-catalog.md` | NEW | The 9-class table (layer, lane, detection) + class-6 split + disagreement rule |
| `plugins/sdd-kit/skills/setup/auditing-conflicts/references/mechanical-checks.md` | NEW | grep/jq recipes for 1/6/8/9, shortlist signal computations, fixed stop-word list + sample prompt set |
| `plugins/sdd-kit/skills/setup/auditing-conflicts/assets/audit-report-example.md` | NEW | Filled report: F-001 (real), a zero-findings class, and a known FALSE conflict downgraded (advisory #3) |
| `.claude/skills-routing.json` | EDIT | Add the `ref` entry above (schema v2) |
| `plugins/sdd-kit/README.md` | EDIT | Add catalog row under the `setup` skills (matches `auditing-glossary`/`auditing-readme` rows at lines 74–75) |
| `CLAUDE.md` (root) | EDIT | Add this routing-table row near lines 43–44 (the `auditing-*` family): `\| Find conflicts/contradictions across skills, rules, and routing \| \`auditing-conflicts\` \|` |

## Edge cases

- **Empty / no conflicts** — report emits an explicit `Class N: no conflicts found` per class and a zero-count summary; the C-drift picker still presents (with only `Stop` meaningful), never skipped silently.
- **No skill-name dictionary match in a consumer repo missing sdd-kit** — a `ref`-only delegate target (`run auditing-readme`) degrades to advice; the audit never errors on an absent delegate (agnostic).
- **Judgment subagent disagrees with mechanical** — annotate-only (downgrade to `Info` + rationale), finding retained; never deleted.
- **False conflict (overlap WITH an explicit `canonical source is X` xref)** — class-6 check must NOT fire; the judgment layer must downgrade. This is a required RED/GREEN test case (advisory #3).
- **Class-9 search returns 0** — only reported as "clean" after the widened (no-allowlist, `grep -E`, no `-maxdepth`) sweep, per `search-scope-verification.md`.
- **Class-1 finding in the report** — trigger collisions carry disposition `owner action required` (which trigger to narrow is a judgment call the owner makes); the `Apply recommended` runner **skips** them and lists them as "owner action" in its summary — it never auto-edits triggers. The report is the deliverable for class 1.
- **Apply recommended, a fix fails** — sequential, stop-on-first-failure with a report of what applied and what did not; no partial silent state.
- **Working tree mid-edit** — audit reads current disk state; an uncommitted artifact is in scope.

## Verification

This is a vault skill change; verification is the **validators + a RED/GREEN subagent run**, not a build/test pipeline (no `pnpm`/Vitest here).

- Validators (per root `CLAUDE.md` → Common commands): frontmatter ≤1024, `name` regex, every `references/*.md` & `assets/*.md` link resolves, fences balanced, word count. Paste output.
- `jq . .claude/skills-routing.json` → valid JSON; the new `ref` entry has `plugin`+`name`, no `files`, key == `name`.
- RED/GREEN subagent runs (staged in a temporary case file, deleted after — not a persisted `test-cases.md`): baseline WITHOUT the skill fails to produce the classified report on planted conflicts; WITH the skill it (a) finds the planted real conflict (e.g. F-001-shaped), (b) emits zero-findings lines for clean classes, (c) **downgrades the planted FALSE conflict** rather than over-reporting — specifically a **class-6** overlap that carries an explicit `canonical source is X` cross-reference (mirroring how `git-conventions.md` defers to `CLAUDE.md`): the class-6 check must NOT fire / the judgment layer must annotate it down to `Info`.
- Manual: invoke on this vault; confirm the report shape matches the locked finding shape and the C-drift picker is presented.

## Risks

- **Judgment-layer over-reporting** — a subagent flags complementary skills as overlapping. Mitigation: the false-conflict RED/GREEN case (advisory #3) + annotate/downgrade rule + mechanical-authoritative-on-existence boundary.
- **Shortlist misses a real pair (recall)** — a conflict whose pair shares no structural signal is never judged. Mitigation: four independent signals (any fires); `log` the shortlist size and dropped-pair count so silent under-coverage is visible (per the no-silent-caps habit). Documented as a known bound in `references/mechanical-checks.md`.
- **Trigger false positives in `detect-bypass.sh`** — overly broad triggers fire on unrelated prompts. Mitigation: triggers kept specific (`audit conflicts`, `conflicting triggers`), not generic words like "conflict".
- **Class-6 split misjudged** — a real duplication tagged mechanical (just adds an xref, hiding the duplication). Mitigation: judgment layer owns the sub-case tag; the mechanical lane only ever *adds* a cross-reference, never declares the duplication resolved.
