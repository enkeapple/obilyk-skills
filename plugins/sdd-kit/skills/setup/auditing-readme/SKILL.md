---
name: auditing-readme
description: >-
  Use to check whether the README skills catalog still matches the skills on
  disk (names, descriptions, categories, links) and to correct it when it
  drifts. Triggers on: "audit the README", "is the skills catalog accurate",
  "README drift", "check the skills index", "update the README catalog".
allowed-tools: Read, Grep, Glob, Edit
---

# Auditing README

Verify each README's managed block against disk, report the drift per criterion, then correct it. **A stale catalog is worse than none**: it tells a browsing human the repo has skills it dropped, or hides ones it gained.

**Audit every managed block the layout calls for.** In a **single-repo** that is the one root README's skills-catalog block. In a **marketplace** (`.claude-plugin/marketplace.json` present) that is, in EACH `plugins/<name>/README.md`, its skills-catalog block (when the plugin has skills) and/or its **hooks-catalog** block (when the plugin wires hooks) — re-derived from that plugin's own ROOT / `hooks.json`, links plugin-relative — PLUS the root README's **plugin-index** block (re-derived from marketplace.json / each `plugin.json`). A missing per-plugin README, a root README still carrying a flat all-skills catalog instead of the plugin index, a hooks-only plugin whose README carries an empty `<!-- no skills found -->` block instead of its hooks catalog, or a slug H1 where the Title-Case H1 is derived, is itself drift. Repo mode, the block kinds, and the per-plugin composition are defined in the [catalog-derivation contract](./references/catalog-derivation.md) → Repo mode / Per-plugin README composition.

**Every row is a derived claim, not prose to skim.** Re-derive each block from disk via the [catalog-derivation contract](./references/catalog-derivation.md) — the SAME contract `bootstrapping-readme` writes from — and compare. Eyeballing "looks complete" is not an audit; a row that disagrees with disk is drift, not a detail. Each block is a derived **bullet list** of bold links (`- **[name](link)** — description`); a block rendered as a table, missing the bold link, or carrying a kind column is itself drift from the contract. Audit only the managed blocks — the scaffold prose around them (intro, Quickstart, Installation, Philosophy, …) is human-owned and out of scope.

Pairs with `bootstrapping-readme`, which generates the block this skill keeps true.

## When to use

- Periodic check of `README.md` after adding/renaming/deleting skills or editing a `description`.
- The catalog "looks off" or you are about to rely on it.

## When NOT to use

- No README/catalog exists yet — that is `bootstrapping-readme`.
- Auditing shipped code against a spec — that is `spec-drift-audit`.

## Process

0. **Classify the repo mode** ([catalog-derivation](./references/catalog-derivation.md) → Repo mode). Single-repo → audit the one root block (steps 1–4 once). Marketplace → for each plugin audit the block kinds its composition calls for (a `skills:` block iff it has skills, a `hooks:` block iff it wires hooks — [catalog-derivation](./references/catalog-derivation.md) → Per-plugin README composition) AND the root README's `plugins:` index block; run steps 1–4 per block. Also confirm the set of per-plugin READMEs matches the plugins in marketplace.json — a listed plugin with no README is finding #1 for that plugin — and that a hooks-only plugin's README carries its hooks block, not an empty skills block.
1. **Locate the managed block.** Find its marker pair (`<!-- skills:start --> … <!-- skills:end -->`, `<!-- hooks:start --> … <!-- hooks:end -->`, or `<!-- plugins:start --> … <!-- plugins:end -->` for the root index). **Criterion 1 first:** if the markers are missing, duplicated, reversed, or nested, that is finding #1 and it **blocks** criteria 2–6 (you cannot trust a malformed block) — report and stop.
2. **Re-derive the block from disk** per the [catalog-derivation contract](./references/catalog-derivation.md) (a skills catalog → ROOT, discovery, category, description, ordering, row shape; a hooks catalog → `hooks.json`, discovery, event grouping, description incl. header-comment/fallback, ordering, row shape; the plugin index → marketplace.json / each plugin.json, description, ordering, row shape).
3. **Compare every criterion** (see Report) — do not stop at the first drift; check all five across every row.
4. **Classify** each as Confirmed / Drift / Malformed.

## Report

Produce a report before editing (see [assets/audit-report-example.md](./assets/audit-report-example.md)):

1. **Findings** — table: criterion → what disk shows → status, over the five criteria (per block):
   1. markers well-formed; 2. every entry appears exactly once (each SKILL.md in a skills catalog; each `hooks.json`-wired hook in a hooks catalog; each marketplace.json plugin in the index); 3. grouping + ordering match disk (by category for skills, by event for hooks); 4. each description matches the derived one; 5. each row link resolves and the row is the bold-link bullet shape `- **[name](link)** — …` (no table, no kind column).
   - Plus, per per-plugin README: the block kinds present match the plugin's composition (no empty skills block where a hooks block is due), and the H1 is the derived Title-Case form.
2. **Summary** — counts per status.
3. **Recommended disposition** — for any drift, **regenerate the block** (rerun `bootstrapping-readme`); the block is fully derived, so re-deriving resolves every drift at once.

## Apply the correction

- Regenerate the block content from disk; replace only what is between the markers — prose outside is untouched.
- Re-run the compare pass on the regenerated block; it should show all Confirmed.

## Red Flags — STOP

- "The catalog looks complete" — no per-criterion re-derivation = the audit did not happen.
- Passing a block rendered as a table or carrying a kind column instead of flagging it as drift from the bullet contract.
- Checking only the obvious gap and skipping the other criteria.
- Hand-patching one row instead of regenerating the derived block.
- Editing prose outside the markers.
- Passing a hooks-only plugin's empty `<!-- no skills found -->` block as correct instead of flagging the missing hooks catalog — or skipping a plugin's hooks block because you only looked for `skills:` markers.
- In a marketplace, auditing only the root README and skipping the per-plugin blocks — or passing a root README that still carries a flat all-skills catalog instead of the plugin index.
