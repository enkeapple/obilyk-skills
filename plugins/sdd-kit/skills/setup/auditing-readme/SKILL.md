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

**Audit every managed block the layout calls for.** In a **single-repo** that is the one root README's skills-catalog block. In a **marketplace** (`.claude-plugin/marketplace.json` present) that is the skills-catalog block in EACH `plugins/<name>/README.md` (re-derived from that plugin's own ROOT, links plugin-relative) PLUS the root README's **plugin-index** block (re-derived from marketplace.json / each `plugin.json`). A missing per-plugin README, or a root README still carrying a flat all-skills catalog instead of the plugin index, is itself drift. Repo mode and both block kinds are defined in the [catalog-derivation contract](./references/catalog-derivation.md) → Repo mode.

**Every row is a derived claim, not prose to skim.** Re-derive each block from disk via the [catalog-derivation contract](./references/catalog-derivation.md) — the SAME contract `bootstrapping-readme` writes from — and compare. Eyeballing "looks complete" is not an audit; a row that disagrees with disk is drift, not a detail. Each block is a derived **bullet list** of bold links (`- **[name](link)** — description`); a block rendered as a table, missing the bold link, or carrying a kind column is itself drift from the contract. Audit only the managed blocks — the scaffold prose around them (intro, Quickstart, Installation, Philosophy, …) is human-owned and out of scope.

Pairs with `bootstrapping-readme`, which generates the block this skill keeps true.

## When to use

- Periodic check of `README.md` after adding/renaming/deleting skills or editing a `description`.
- The catalog "looks off" or you are about to rely on it.

## When NOT to use

- No README/catalog exists yet — that is `bootstrapping-readme`.
- Auditing shipped code against a spec — that is `spec-drift-audit`.

## Process

0. **Classify the repo mode** ([catalog-derivation](./references/catalog-derivation.md) → Repo mode). Single-repo → audit the one root block (steps 1–4 once). Marketplace → audit each `plugins/<name>/README.md` skills-catalog block AND the root README's `plugins:` index block; run steps 1–4 per block. Also confirm the set of per-plugin READMEs matches the plugins in marketplace.json — a listed plugin with no README is finding #1 for that plugin.
1. **Locate the managed block.** Find its marker pair (`<!-- skills:start --> … <!-- skills:end -->`, or `<!-- plugins:start --> … <!-- plugins:end -->` for the root index). **Criterion 1 first:** if the markers are missing, duplicated, reversed, or nested, that is finding #1 and it **blocks** criteria 2–6 (you cannot trust a malformed block) — report and stop.
2. **Re-derive the block from disk** per the [catalog-derivation contract](./references/catalog-derivation.md) (a skills catalog → ROOT, discovery, category, description, ordering, row shape; the plugin index → marketplace.json / each plugin.json, description, ordering, row shape).
3. **Compare every criterion** (see Report) — do not stop at the first drift; check all five across every row.
4. **Classify** each as Confirmed / Drift / Malformed.

## Report

Produce a report before editing (see [assets/audit-report-example.md](./assets/audit-report-example.md)):

1. **Findings** — table: criterion → what disk shows → status, over the five criteria (per block):
   1. markers well-formed; 2. every entry appears exactly once (each SKILL.md in a catalog; each marketplace.json plugin in the index); 3. grouping + ordering match disk; 4. each description matches the derived one; 5. each row link resolves and the row is the bold-link bullet shape `- **[name](link)** — …` (no table, no kind column).
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
- In a marketplace, auditing only the root README and skipping the per-plugin blocks — or passing a root README that still carries a flat all-skills catalog instead of the plugin index.
