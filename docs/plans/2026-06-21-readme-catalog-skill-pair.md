# README catalog skill pair — Implementation Plan

**Goal:** Author the `bootstrapping-readme` / `auditing-readme` foundation skill pair that maintains a human-facing README skills catalog inside a managed block, sourced from skill frontmatter on disk.
**Architecture:** Two markdown skills under `skills/foundation/`, mirroring the `bootstrapping-glossary` / `auditing-glossary` pair. A shared **catalog-derivation contract** (discovery → category → kind → description → row), copied identically into each skill's `references/catalog-derivation.md`, makes the generator and auditor agree by construction. Each skill is authored test-first in the vault sense: a RED baseline subagent run WITHOUT the skill, then GREEN WITH it.
**Tech stack:** Claude Code skills (SKILL.md + `references/` + `assets/`), `.claude/skills` flat symlinks, `.claude/skills-routing.json`. No build/test pipeline.

## Ledger

- T1 `bootstrapping-readme`: **done** — RED observed (cold baseline: no markers, non-reproducible format, hand-rewritten descriptions, kind from the unreliable `disable-model-invocation` signal, sync pointed at the wrong `auditing-claude-md` skill). GREEN: skill produced markers + 27/27 skills once + deterministic descriptions + routing-based kind (writing-skills & improve-codebase-architecture → user-invoked, codebase-design → auto-routed proving kind ≠ folder/flag). Validators pass (frontmatter 388B, name regex, links resolve, fences 0, json valid, symlink + routing synced). Commit proposed.
- T2 `auditing-readme`: **done** — RED observed (cold baseline: prose not a per-criterion report, kind mis-derived from `disable-model-invocation`, no disposition, conflated "no README" with audit). GREEN: skill produced the 6-criteria findings table, derived kind from routing (writing-skills → user-invoked), caught missing skills + dead link + stale description, recommended regenerate. Validators pass (frontmatter 391B, name match, fences 0, byte-identical catalog-derivation, symlink + routing synced). Owner correction applied (dropped the `auditing-glossary` analogy from the asset). Commit proposed.
- T3 dogfood `README.md`: **done** — generated README.md (verbatim intro + managed block, 28 rows = 28 SKILL.md on disk, 7 categories). Independent auditing-readme cross-check: 6/6 criteria Confirmed, 0 drift — the generator's output passes the auditor (dogfood proof, D8). Commit proposed.

Owner corrections applied this turn: (1) dropped the `auditing-glossary` analogy from auditing-readme's asset; (2) removed all vault-rule references (`dogfood-generator-sync`, `markdown-style`) from both skills' bodies/references — agnostic leak. catalog-derivation.md re-synced byte-identical after the scrub.

## Global constraints

- **Iron Law:** no skill written before a RED baseline subagent run is observed failing. Wrote it first → delete, restart. (Spec → Verification.)
- **Agnostic:** no vault-specific paths/commands baked into a skill body; examples marked illustrative. (`agnostic-skill-authoring`.)
- **dogfood-generator-sync (D8):** the pair IS its own generator+auditor; RED/GREEN runs on the GENERATED README, not a hand-edited one; the two skills move in lockstep.
- **Routing+symlink sync (`skill-routing-sync`):** a new skill is not done until its `.claude/skills/<name>` flat symlink exists AND its `skills-routing.json` entry matches disk (`key === dir === SKILL.md name`).
- **Validators:** frontmatter ≤1024 bytes, `name` regex `^[a-z0-9-]+$`, every `references/*.md` + `assets/*.md` link resolves, fences balanced, word count sane — for every new SKILL.md.
- **markdown-style:** generated block + all docs use spaced table delimiters `| --- | --- |` and blank lines around headings/tables.
- **Git boundary:** the human owns the commit; each task ends with a proposed one-line Conventional Commit, not an autonomous `git commit`.

The full contracts (catalog-derivation algorithm, managed-block format, kind table, audit drift criteria, routing entries, edge cases D9) live in `docs/specs/2026-06-21-readme-catalog-skill-pair.md` — copy them verbatim, do not paraphrase.

---

## Task 1 — Author `bootstrapping-readme` (generator) + routing + symlink

**Files**

- `skills/foundation/bootstrapping-readme/references/catalog-derivation.md` (NEW) — the derivation contract (canonical copy).
- `skills/foundation/bootstrapping-readme/assets/readme-block-example.md` (NEW) — filled managed-block example.
- `skills/foundation/bootstrapping-readme/SKILL.md` (NEW) — generator skill body.
- `.claude/skills/bootstrapping-readme` (NEW) — flat symlink.
- `.claude/skills-routing.json` (EDIT) — add the `bootstrapping-readme` entry.

**Interfaces**

- **Consumes:** the spec's Catalog-derivation contract and Managed-block format (verbatim).
- **Produces:** `references/catalog-derivation.md` (the shared algorithm Task 2 duplicates); the marker block format (`<!-- skills:start --> … <!-- skills:end -->`) Task 2 audits and Task 3 emits.

**Steps**

- [ ] **RED — baseline failure (before writing anything).** Dispatch a cold `general-purpose` subagent with this exact prompt and record the verbatim output:

  ```text
  This repo catalogs reusable "skills" as markdown files at skills/<category>/<name>/SKILL.md,
  each with YAML frontmatter (name, description). Create a README.md section that catalogs every
  skill so a human browsing GitHub can scan them. Do it however you think best.
  ```

  Expected failure (the gap the skill must close): no stable format across runs; skills missed or invented; descriptions hand-written rather than derived from frontmatter; no machine-updatable markers; "kind" (auto-routed / user-invoked / alias) absent or guessed. Paste the run.

- [ ] **Write the derivation contract.** Create `references/catalog-derivation.md` containing the spec's `Catalog-derivation contract` block verbatim (ROOT / DISCOVERY / CATEGORY / ROW LINK / KIND / DESCRIPTION / ORDER), plus the kind clarification that `user-invoked` is D4's reference flag.

- [ ] **Write the example asset.** Create `assets/readme-block-example.md` with a filled managed block (the spec's Managed-block format example), marked illustrative:

  ````text
  <!-- skills:start -->
  <!-- Generated by bootstrapping-readme — do not edit by hand; rerun the skill. -->

  ### apply-chain

  | Skill | What it does | Kind |
  | --- | --- | --- |
  | [grilling](skills/apply-chain/grilling/SKILL.md) | Turn a fuzzy idea into a shared, concrete design. | auto-routed |
  <!-- skills:end -->
  ````

- [ ] **Write `SKILL.md`.** Frontmatter verbatim from spec (Contracts → Skill frontmatter, `bootstrapping-readme`); `allowed-tools: Read, Grep, Glob, Write, Edit`. Body sections: When to use / When NOT (→ `auditing-readme` for drift checks) / Process (discover via `references/catalog-derivation.md` → build block → insert under `## Skills`, never touch prose outside markers) / the D9 edge-case handling (no README, README without markers, malformed/duplicate markers → refuse+report, duplicate name → error, malformed frontmatter → finding, zero skills → placeholder block) / Red Flags. Pairs-with note → `auditing-readme`.

- [ ] **Create the flat symlink.**

  ```bash
  ln -s ../../skills/foundation/bootstrapping-readme .claude/skills/bootstrapping-readme
  readlink .claude/skills/bootstrapping-readme   # → ../../skills/foundation/bootstrapping-readme
  ```

- [ ] **Add the routing entry.** Insert into `.claude/skills-routing.json` `.skills` (before the closing braces), verbatim from spec → Routing entries (`bootstrapping-readme`). Then:

  ```bash
  jq . .claude/skills-routing.json >/dev/null && echo "valid json"
  jq -r '.skills["bootstrapping-readme"].files[0]' .claude/skills-routing.json   # → .claude/skills/bootstrapping-readme/SKILL.md
  ```

- [ ] **GREEN — with the skill.** Dispatch a subagent WITH `bootstrapping-readme` in context, asked to generate the catalog block for THIS vault. Confirm: every on-disk `SKILL.md` present exactly once; categories match the `skills/` dir layout; each description equals the derivation output; each `kind` matches the routing rule (D6); block well-formed. Paste the generated block.

- [ ] **Validators.** Run and paste:

  ```bash
  f=skills/foundation/bootstrapping-readme/SKILL.md
  sed -n '/^---$/,/^---$/p' "$f" | wc -c            # ≤ 1024
  grep -E '^name: bootstrapping-readme$' "$f"        # exact name, regex-clean
  for l in references/catalog-derivation.md assets/readme-block-example.md; do test -f "skills/foundation/bootstrapping-readme/$l" && echo "ok $l"; done
  find skills -name SKILL.md | wc -l; jq '.skills | keys | length' .claude/skills-routing.json
  ```

  **Fence-balance caveat:** a naive `grep -c '^```' % 2` will MISREAD this file as unbalanced — both the SKILL.md body and `readme-block-example.md` legitimately wrap inner three-backtick blocks in a four-backtick fence (` ````text `), per `markdown-style`. Confirm fences balance by eye accounting for the four-backtick wrappers; do not "fix" a non-bug.

- [ ] **Propose commit** (human runs): `feat(skills): add bootstrapping-readme skill with catalog derivation`

---

## Task 2 — Author `auditing-readme` (auditor) + routing + symlink

Depends on Task 1 (shares the derivation contract; GREEN drifts a generated block).

**Files**

- `skills/foundation/auditing-readme/references/catalog-derivation.md` (NEW) — identical duplicate of Task 1's contract (mirrors `placeholder-keys.md` in both glossary skills).
- `skills/foundation/auditing-readme/assets/audit-report-example.md` (NEW) — filled drift-report example.
- `skills/foundation/auditing-readme/SKILL.md` (NEW) — auditor skill body.
- `.claude/skills/auditing-readme` (NEW) — flat symlink.
- `.claude/skills-routing.json` (EDIT) — add the `auditing-readme` entry.

**Interfaces**

- **Consumes:** Task 1's `references/catalog-derivation.md` (copied verbatim) and the marker block format.
- **Produces:** the per-finding drift report (drift criteria 1–6 → regenerate disposition) consumed at the audit gate.

**Steps**

- [ ] **RED — baseline failure.** Dispatch a cold subagent (no skill) with:

  ```text
  Here is a README "## Skills" section listing this repo's skills, and the skills on disk at
  skills/<category>/<name>/SKILL.md. Check whether the README still matches the skills on disk.
  ```

  Expected failure: eyeballs it, declares it "looks fine"; misses a renamed skill / a stale description / a broken link; produces no per-finding report and no recommended disposition. Paste the run.

- [ ] **Duplicate the derivation contract.** Copy Task 1's `references/catalog-derivation.md` verbatim to `skills/foundation/auditing-readme/references/catalog-derivation.md`. Confirm byte-identical:

  ```bash
  diff skills/foundation/bootstrapping-readme/references/catalog-derivation.md \
       skills/foundation/auditing-readme/references/catalog-derivation.md && echo "identical"
  ```

- [ ] **Write the report example.** Create `assets/audit-report-example.md` mirroring `auditing-glossary`'s report shape: a `{finding → what disk shows → status}` table over drift criteria 1–6, a summary, and a "recommended disposition: regenerate block" line.

- [ ] **Write `SKILL.md`.** Frontmatter verbatim from spec (`auditing-readme`); `allowed-tools: Read, Grep, Glob, Edit`. Body: When to use / When NOT (docs don't exist → `bootstrapping-readme`; shipped-code-vs-spec → `spec-drift-audit`) / Process (re-derive catalog via `references/catalog-derivation.md`; check the six drift criteria, criterion 1 markers blocks 2–6) / Report format (per-finding table + regenerate disposition) / Apply corrections (regenerate block, surgical) / Red Flags (no per-claim verification = no audit). Pairs-with → `bootstrapping-readme`.

- [ ] **Create the flat symlink.**

  ```bash
  ln -s ../../skills/foundation/auditing-readme .claude/skills/auditing-readme
  readlink .claude/skills/auditing-readme   # → ../../skills/foundation/auditing-readme
  ```

- [ ] **Add the routing entry.** Insert the `auditing-readme` entry verbatim from spec → Routing entries. Then `jq . .claude/skills-routing.json >/dev/null && echo valid`.

- [ ] **GREEN — with the skill.** In a scratch copy (not the committed README), generate a block via Task 1's skill, then introduce two drifts: (a) rename a skill dir so a row points at a missing path; (b) make one row's description diverge from frontmatter. Dispatch a subagent WITH `auditing-readme`; confirm it flags exactly criterion 2 (missing/extra skill) and criterion 4 (stale description), each with the regenerate disposition. Paste the report.

- [ ] **Validators + sync.** Same validator block as Task 1 against `auditing-readme/SKILL.md`; plus:

  ```bash
  for s in bootstrapping-readme auditing-readme; do readlink ".claude/skills/$s" && jq -e ".skills[\"$s\"]" .claude/skills-routing.json >/dev/null && echo "$s synced"; done
  ```

- [ ] **Propose commit:** `feat(skills): add auditing-readme skill mirroring bootstrapping-readme`

---

## Task 3 — Dogfood: generate and commit the vault's `README.md`

Depends on Tasks 1 and 2 (generator exists; auditor confirms clean).

**Files**

- `README.md` (NEW) — the vault's own catalog, produced by running `bootstrapping-readme`.

**Interfaces**

- **Consumes:** `bootstrapping-readme` (generator) and `auditing-readme` (clean-check).
- **Produces:** the committed root README dogfood artifact (closes D8).

**Steps**

- [ ] **Generate.** Invoke `bootstrapping-readme` against the vault. With no existing README, it creates `README.md` with a `# sdd-workflow` H1, a short `## Skills` heading, and the marker block containing all categories. Confirm prose outside the markers is the only hand-authored part.

- [ ] **Verify completeness.** Every `SKILL.md` on disk appears exactly once in the block:

  ```bash
  diff <(find skills -name SKILL.md -exec grep -h '^name:' {} \; | sed 's/name: //' | sort) \
       <(sed -n '/skills:start/,/skills:end/p' README.md | grep -oE '\[[a-z0-9-]+\]\(' | tr -d '[](' | sort) \
    && echo "all skills catalogued exactly once"
  ```

  This count diff is a quick smoke test only and is brittle (the link regex assumes each row link text is exactly the skill name with no nested brackets). The **authoritative** completeness proof is the clean GREEN `auditing-readme` cross-check in the next step — trust that over the diff if they disagree.

- [ ] **GREEN cross-check.** Invoke `auditing-readme` on the freshly generated `README.md`; confirm a clean report (no drift across criteria 1–6). A clean audit of the generator's own output proves the pair agrees.

- [ ] **Validators.** Fence balance + markdown-style on `README.md`:

  ```bash
  test "$(grep -c '^```' README.md)" -ge 0; grep -nE '\|-{2,}\|' README.md && echo "FAIL unspaced delimiter" || echo "delimiters spaced"
  ```

- [ ] **Propose commit:** `docs: add README skills catalog (dogfood bootstrapping-readme)`

---

## Self-review

- **Show-don't-describe:** every command step has an exact command + expected output; every authoring step names the verbatim source (spec section) for its content; each task ends with a proposed commit. Skill *bodies* are prose artifacts — their "code" is the frontmatter (shown) and the structural section list (enumerated), with full contracts pulled verbatim from the spec rather than re-paraphrased here.
- **Type consistency:** the shared artifact name `references/catalog-derivation.md`, the marker pair `<!-- skills:start/end -->`, the kind values `{auto-routed, user-invoked, alias}`, and the six drift criteria are used identically across Tasks 1–3.
- **Iron Law:** Tasks 1 and 2 each open with a RED baseline before any writing; Task 3 is dogfood execution (no new skill) so it has no RED of its own — its proof is the clean GREEN cross-check.
