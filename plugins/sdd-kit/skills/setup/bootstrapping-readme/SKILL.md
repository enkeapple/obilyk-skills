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

Generate the human-facing **README landing page(s)** a browser reads — distinct from the agent-facing `CLAUDE.md`. Each README has two zones: a one-time **scaffold** of placeholder prose sections (intro, Quickstart, How it works, Installation, What's Inside, Philosophy, Contributing) the human fills, and a **managed marker block** regenerated from disk. Only the marker block is derived and audited; the scaffold prose is human-owned once written.

**Every row in the managed block is derived from disk, never hand-written.** What you emit — repo mode (single-repo vs marketplace), block kinds (skills / hooks / plugin index), ROOT discovery, category, the description algorithm, ordering, link bases, per-plugin composition, the marker blocks — is fully specified by the [catalog-derivation contract](./references/catalog-derivation.md); classify the layout in step 0 and follow the contract verbatim. A hand-curated catalog drifts and cannot be audited; a derived one regenerates identically, so `auditing-readme` (which checks the block this skill writes) can verify it.

## When to use

- A skills-bearing repo (skills as `SKILL.md` files with frontmatter) has no README catalog, or only a hand-written stub.
- You added/renamed skills and want the catalog regenerated from disk.

## When NOT to use

- The catalog exists and you only want to know if it drifted — that is `auditing-readme`.
- A consumer app repo with no skills tree — there is nothing to catalog.

## Process

0. **Classify the repo mode.** Is there a `.claude-plugin/marketplace.json` at the repo root? No → **single-repo**: one README, steps 1–4 once. Yes → **marketplace**: run steps 1–4 once per plugin (a per-plugin README at `plugins/<name>/README.md` carrying only the catalog blocks it has — skills and/or hooks per the contract's Per-plugin README composition, ROOT and links per the MARKETPLACE column), then once more for the root README as a **plugin index** (step 1′).
1. **Discover.** Resolve ROOT and glob every `SKILL.md` under it for the skills catalog; read `hooks/hooks.json` (when present) for the hooks catalog ([catalog-derivation](./references/catalog-derivation.md) → Definitions, both kinds). For each skill read frontmatter `name`/`description`; for each wired hook take its script basename, its event, and the line-2 header comment (fallback to `<event> hook (matcher: …)`).
   - **1′ (plugin index, marketplace root only).** Instead of skills: read `marketplace.json` → each plugin's `plugin.json` `name` + `description` ([catalog-derivation](./references/catalog-derivation.md) → Plugin index). Each row links to `plugins/<name>/README.md`.
2. **Derive each row** — its link and description per [catalog-derivation](./references/catalog-derivation.md) → DESCRIPTION; a skill row groups by category, a hook row by event, and both order alphabetically per → ORDER (the plugin index is a single alphabetical list, no groups).
3. **Build the block** — the marker pair (`skills:` for a skill catalog, `hooks:` for a hooks catalog, `plugins:` for the index), the generated-by comment, `###` per group with its bullet list (or one flat bullet list). Each item is `- **[<name>](<link>)** — <description>` (bold link) in standard GitHub-Flavored Markdown (a blank line before and after each list). Emit only the block kinds the plugin has; skills before hooks when both. See [assets/readme-scaffold.md](./assets/readme-scaffold.md).
4. **Write it in, never over prose.** No README → create the full landing-page **scaffold** ([assets/readme-scaffold.md](./assets/readme-scaffold.md)): the Title-Case H1 (plugin/repo `name` → "Title Case"), the placeholder prose sections as `<!-- TODO -->` stubs, and each managed block under its `## Skills` / `## Hooks` heading (or `## Plugins` for the index). README without markers → insert only the block(s) under their heading(s) (do NOT inject scaffold sections into a README that already has prose). README with markers → replace only the content between them. Everything outside the markers (the scaffold prose incl. the H1, intro, install, badges, license) is untouched on every re-run.
5. **Stop on an ambiguous file state** — see Edge cases; never guess past it.

## Edge cases

Handle each exactly as the [catalog-derivation contract](./references/catalog-derivation.md) → Edge cases states — malformed/duplicate markers, duplicate `name`, missing/empty `name`/`description`, a wired hook whose script is missing, and a plugin with neither skills nor hooks. Never guess past an ambiguous file state (step 5): refuse and report.

## Red Flags — STOP

- Writing a description by hand instead of deriving it from frontmatter.
- Rendering the catalog as a table, dropping the bold link, or re-adding a kind column instead of the derived `- **[name](link)** — …` bullet list.
- Regenerating or overwriting the scaffold prose on a re-run — only the managed block is regenerated; the placeholder sections are human-owned after the first write.
- Emitting any prose section INSIDE the markers, scaffolding a README that already carries prose, overwriting prose outside the markers, or inserting a second `## Skills` section.
- Editing a README whose markers are malformed instead of refusing and reporting.
- Inventing a skill, omitting one the glob found, or cataloging a `hooks/*.sh` not wired in `hooks.json` — so the block disagrees with disk.
- Writing a slug H1 (`# guardrails-kit`) instead of the Title-Case H1 (`# Guardrails Kit`) when first creating a per-plugin README.
- In a marketplace, emitting one flat root catalog of every skill instead of a per-plugin README + a root plugin index — or using repo-root-relative skill/hook links in a per-plugin README (they must be plugin-relative so the plugin is self-contained).
