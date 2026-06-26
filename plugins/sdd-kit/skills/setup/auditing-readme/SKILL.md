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

**Re-derive, don't skim.** Every row in a managed block is a derived claim, not prose. Re-derive each block from disk via the [catalog-derivation contract](./references/catalog-derivation.md) — the SAME contract `bootstrapping-readme` writes from — then compare. "Looks complete" is not an audit; a row that disagrees with disk is drift, not a detail.

**Audit every managed block the layout calls for** — the contract's *Repo mode* and *Per-plugin README composition* define which. Single-repo: the one root skills block. Marketplace: in EACH `plugins/<name>/README.md` its skills block (iff the plugin has skills) and/or hooks block (iff it wires hooks), PLUS the root README's plugin-index block. Beyond a wrong row, each of these is *itself* drift: a missing per-plugin README; a root README carrying a flat all-skills catalog instead of the plugin index; a hooks-only plugin whose README shows an empty `<!-- no skills found -->` block instead of its hooks catalog; a block rendered as a table or carrying a kind column instead of the bullet shape; a slug H1 where the Title-Case form is derived.

Audit only the managed blocks — scaffold prose (intro, Quickstart, Installation, Philosophy, …) is human-owned and out of scope. Pairs with `bootstrapping-readme`, which generates the blocks this skill keeps true.

## When to use

- Periodic check of `README.md` after adding/renaming/deleting skills or editing a `description`.
- The catalog "looks off" or you are about to rely on it.

## When NOT to use

- No README/catalog exists yet — that is `bootstrapping-readme`.
- Auditing shipped code against a spec — that is `spec-drift-audit`.

## Process

0. **Classify the repo mode** ([catalog-derivation](./references/catalog-derivation.md) → Repo mode). Single-repo → run steps 1–4 once on the root block. Marketplace → run steps 1–4 per block (each plugin's skills/hooks blocks + the root plugin-index), and confirm the set of per-plugin READMEs matches marketplace.json — a listed plugin with no README is finding #1 for that plugin.
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
- Checking only the obvious gap and skipping the other criteria.
- Hand-patching one row instead of regenerating the derived block.
- Editing prose outside the markers.
- In a marketplace, auditing only the root README and skipping the per-plugin blocks, or looking only for `skills:` markers and missing a plugin's hooks block.
