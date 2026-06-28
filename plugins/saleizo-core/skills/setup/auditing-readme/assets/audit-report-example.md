# Audit Report Example

Illustrative (a real report covers the README on disk and every skill the glob finds). The report is a per-finding table over the five drift criteria, then a summary, then a recommended disposition. In a marketplace, run one such table per managed block — each per-plugin `skills:` and/or `hooks:` block plus the root `plugins:` index; the example below is a single skills block.

## Findings

| # | Criterion | What disk shows | Status |
| --- | --- | --- | --- |
| 1 | Markers well-formed | One `skills:start` + one `skills:end`, in order | Confirmed |
| 2 | Every SKILL.md once | `old-planning-helper` listed but absent on disk; `writing-hooks` on disk but missing from block | Drift |
| 3 | Grouping + ordering match disk | Block has 2 categories; disk has 7 (`design`, `entrypoints`, `foundation`, `process`, `prose` missing) | Drift |
| 4 | Description matches frontmatter | `grilling` row reads "brainstorming feature ideas"; derived description is "Use before any creative or build work…" | Drift |
| 5 | Links resolve + bold-link bullet shape | `skills/apply-chain/old-planning-helper/SKILL.md` does not exist; rows rendered as plain links (no bold) instead of `- **[name](link)** — …` | Drift |

## Summary

- Confirmed: 1 · Drift: 4 · Malformed: 0
- Criterion 1 passed, so criteria 2–5 were evaluated. (Had markers been malformed, finding #1 blocks the rest.)

## Recommended disposition

**Regenerate the block** by rerunning `bootstrapping-readme` — the block is fully derived, so every drift above is resolved by re-deriving from disk. No row needs a hand-edit. Prose outside the markers is untouched.
