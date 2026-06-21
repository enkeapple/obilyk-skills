---
name: bootstrapping-readme
description: >-
  Use when a skills-bearing repo has no README skills catalog yet (or only a
  stub) and you need to generate the human-facing index of its skills from
  frontmatter on disk. Triggers on: "set up the README", "generate the skills
  catalog", "bootstrap the README", "build the skills index".
allowed-tools: Read, Grep, Glob, Write, Edit
---

# Bootstrapping README

Generate the human-facing **README landing page** a browser reads — distinct from the agent-facing `CLAUDE.md`. It has two zones: a one-time **scaffold** of placeholder prose sections (intro, Quickstart, How it works, Installation, Philosophy, Contributing) the human fills, and a **skills catalog** inside a managed marker block, every row sourced from skill frontmatter on disk. Only the catalog block is derived, regenerated, and audited; the scaffold prose is human-owned once written.

**Every row is derived, never hand-written.** The full derivation — ROOT discovery, category, the description algorithm, ordering, the marker block — is the [catalog-derivation contract](./references/catalog-derivation.md); follow it verbatim. A hand-curated catalog drifts and cannot be audited; a derived one regenerates identically and `auditing-readme` can check it.

Pairs with `auditing-readme`, which checks the block this skill writes for drift.

## When to use

- A skills-bearing repo (skills as `SKILL.md` files with frontmatter) has no README catalog, or only a hand-written stub.
- You added/renamed skills and want the catalog regenerated from disk.

## When NOT to use

- The catalog exists and you only want to know if it drifted — that is `auditing-readme`.
- A consumer app repo with no skills tree — there is nothing to catalog.

## Process

1. **Discover.** Resolve ROOT and glob every `SKILL.md` under it ([catalog-derivation](./references/catalog-derivation.md) → Definitions). Read each one's frontmatter `name` and `description`.
2. **Derive each row** — its link and description per [catalog-derivation](./references/catalog-derivation.md) → DESCRIPTION; group by category and order alphabetically per → ORDER.
3. **Build the block** — the marker pair, the generated-by comment, `###` per category with its bullet list (or one flat bullet list). Each item is `- **[<name>](<link>)** — <description>` (bold link) in standard GitHub-Flavored Markdown (a blank line before and after each list). See [assets/readme-scaffold.md](./assets/readme-scaffold.md).
4. **Write it in, never over prose.** No README → create the full landing-page **scaffold** ([assets/readme-scaffold.md](./assets/readme-scaffold.md)): `# <repo>` H1, the placeholder prose sections as `<!-- TODO -->` stubs, and the managed block under `## Skills`. README without markers → insert only the block under a `## Skills` heading (do NOT inject scaffold sections into a README that already has prose). README with markers → replace only the content between them. Everything outside the markers (the scaffold prose, intro, install, badges, license) is untouched on every re-run.
5. **Stop on an ambiguous file state** — see Edge cases; never guess past it.

## Edge cases

Handle exactly as the [catalog-derivation contract](./references/catalog-derivation.md) → Edge cases states:

- **Malformed/duplicate markers** → refuse to edit, report the file state; do not guess where the block belongs.
- **Duplicate `name`** → error naming both paths; do not merge.
- **Missing/empty `name` or `description`** → a `malformed frontmatter: <path>` row, not a crash.
- **Zero skills under ROOT** → an empty block with a `<!-- no skills found -->` comment.

## Red Flags — STOP

- Writing a description by hand instead of deriving it from frontmatter.
- Rendering the catalog as a table, dropping the bold link, or re-adding a kind column instead of the derived `- **[name](link)** — …` bullet list.
- Regenerating or overwriting the scaffold prose on a re-run — only the managed block is regenerated; the placeholder sections are human-owned after the first write.
- Emitting any prose section INSIDE the markers, or scaffolding a README that already carries prose.
- Overwriting prose outside the markers, or inserting a second `## Skills` section.
- Editing a README whose markers are malformed instead of refusing and reporting.
- Inventing a skill, or omitting one the glob found, so the block disagrees with disk.
