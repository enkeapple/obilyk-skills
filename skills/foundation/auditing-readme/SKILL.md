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

Verify the README skills catalog against the skills on disk, report the drift per criterion, then correct it. **A stale catalog is worse than none**: it tells a browsing human the repo has skills it dropped, or hides ones it gained.

**Every row is a derived claim, not prose to skim.** Re-derive the catalog from frontmatter via the [catalog-derivation contract](./references/catalog-derivation.md) — the SAME contract `bootstrapping-readme` writes from — and compare. Eyeballing "looks complete" is not an audit; a row that disagrees with disk is drift, not a detail. The catalog is a derived **bullet list** (`- [name](link) — description`); a block rendered as a table or carrying a kind column is itself drift from the contract.

Pairs with `bootstrapping-readme`, which generates the block this skill keeps true.

## When to use

- Periodic check of `README.md` after adding/renaming/deleting skills or editing a `description`.
- The catalog "looks off" or you are about to rely on it.

## When NOT to use

- No README/catalog exists yet — that is `bootstrapping-readme`.
- Auditing shipped code against a spec — that is `spec-drift-audit`.

## Process

1. **Locate the managed block.** Find the `<!-- skills:start --> … <!-- skills:end -->` pair. **Criterion 1 first:** if the markers are missing, duplicated, reversed, or nested, that is finding #1 and it **blocks** criteria 2–6 (you cannot trust a malformed block) — report and stop.
2. **Re-derive the catalog from disk** per the [catalog-derivation contract](./references/catalog-derivation.md) (ROOT, discovery, category, description algorithm, ordering, bullet row shape).
3. **Compare every criterion** (see Report) — do not stop at the first drift; check all five across every skill.
4. **Classify** each as Confirmed / Drift / Malformed.

## Report

Produce a report before editing (see [assets/audit-report-example.md](./assets/audit-report-example.md)):

1. **Findings** — table: criterion → what disk shows → status, over the five criteria:
   1. markers well-formed; 2. every SKILL.md appears exactly once; 3. grouping + ordering match disk; 4. each description matches the derived one; 5. each row link resolves and the row is the bullet shape (no table, no kind column).
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
