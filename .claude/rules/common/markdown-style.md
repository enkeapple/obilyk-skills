---
description: 'Markdown style for rules/docs — CommonMark + GFM baseline (the standard subset Obsidian renders), no Obsidian-only extensions. Fenced-code language, blanks around blocks, standard links not wikilinks, GFM tables with spaced delimiter rows.'
paths:
  - '**/*.md'
---

# Markdown Style Rules

## When

Writing or editing any `.md` file in this repo — `.claude/rules/**`, `.claude/CLAUDE.md`, `CLAUDE.md`, `docs/**`.

## Why

These files are read by Claude Code, GitHub, and Obsidian. We standardise on the **CommonMark + GitHub-Flavored Markdown** subset — which is exactly the *standard* base Obsidian renders — and deliberately avoid Obsidian's proprietary extensions. That keeps every file portable: what you write renders the same in Obsidian and on GitHub, and Claude Code can actually resolve the links. No linter config is committed; this rule is the source of truth for markdown style here.

## Implementation

### Use — standard baseline (CommonMark + GFM)

- **ATX headings** (`#`, `##`, `###`): one `#` H1 per file as the title, sections at `##`, sub-points at `###`. Blank line **before and after** every heading.
- **Fenced code with a language**: ` ```ts `, ` ```tsx `, ` ```bash `, ` ```json `; use ` ```text ` for directory trees, ASCII diagrams, and plain output. Never a bare ` ``` ` opening fence. Blank line before and after the block. A fence opened with _N_ backticks closes only on a line of _N_-or-more backticks — so to show a fenced block **as example content**, wrap it in a longer fence (four backticks ` ````text ` around inner three-backtick blocks); the inner fences are then literal text and keep no language of their own.
- **Standard links and images**: `[text](relative/path.md)` and `![alt](path.png)`. Use relative paths between rule files.
- **GFM tables**: leading/trailing pipes, one header separator row. Put a space on each side of every pipe and every delimiter cell — `| --- | --- |`, never the unspaced `|---|---|`. The **dash count is free**: a new table uses a plain `---` per cell; an existing wider row (`| -------- | --------- |`) stays as-is — only the spacing is required. Don't *add* new hand-alignment, but don't *collapse* an existing aligned row either.
- **Lists**: `- ` unordered, `1. ` ordered, `- [ ]` / `- [x]` task lists. Blank line before and after the list.
- **Emphasis & misc**: `**bold**`, `_italic_`, `` `inline code` ``, `> blockquote`, `---` horizontal rule.
- **YAML frontmatter**: the leading `--- … ---` block (what Obsidian calls "properties"). Required for path-scoped rules via `paths:`. This is shared standard — keep it, and keep it free of trailing whitespace.

### Tables — spaced delimiter row

The header-separator row needs a space on each side of every pipe and around each cell's dash-run, matching the padded cells above it. The dash run can be a single `---` or a wider one — only the surrounding spaces are required.

```text
✅ CORRECT
| Concept | Lives in | What it represents |
| --- | --- | --- |
| skill | `.claude/skills/<name>/` | a routable capability |

❌ WRONG — unspaced delimiter, no cell padding
| Concept | Lives in | What it represents |
|---|---|---|
|skill|`.claude/skills/<name>/`|a routable capability|
```

Alignment colons follow the same spacing: `| :--- | :---: | ---: |`, never `|:---|:---:|---:|`.

### Avoid — Obsidian-only extensions (not portable)

- **Wikilinks** `[[note]]` and **embeds** `![[note]]` — Claude Code does not resolve them. Use standard `[text](path)`.
- **Callouts** `> [!note]` / `> [!warning]` — render as plain blockquotes everywhere else. Use a **bold lead-in** or a normal blockquote.
- **Inline tags** `#tag` — collide with headings outside Obsidian and mean nothing to Claude.
- **Block references** `^block-id` and `[[note#^id]]`.
- **Obsidian comments** `%% … %%` — use standard HTML comments `<!-- … -->` (also stripped from Claude's context).
- **Highlight** `==text==`, **math** `$…$` / `$$…$$`, and **Mermaid / Dataview / query** blocks — non-standard; do not rely on them in shared rules.

## Edge Cases

- Frontmatter must be the very first thing in the file (nothing above the opening `---`), then a blank line before the H1.
- Documenting a fence *inside* prose: wrap it in single backticks, e.g. `` ` ```ts ` ``, so it does not open a real code block. For a *multi-line* fenced block shown as an example, use the four-backtick wrapper (` ````text ` … ` ```` `) instead — the inner three-backtick fences are content and must be left untouched (no language added, never "closed" by tooling that counts fences naively).
- These files are prose-heavy by design — long single-line instructions, `<!-- comments -->`, and unaligned tables are **intentional**. If a markdownlint editor extension flags `MD013` (line length), `MD033` (inline HTML), or `MD060` (table alignment) on its defaults, ignore them or relax them in your **personal** editor settings; this repo commits no config.
- Fenced-code language is the most common miss — get it right while writing (a bare ` ``` ` becomes ` ```text `).
- The spaced-delimiter rule is about the delimiter row and single-space cell padding only — it does **not** require padding every cell to equal width. A one-line `| --- | --- |` is correct even when the data rows have varied content.

## Review Checklist

- [ ] Frontmatter is first, has a `description`, and `paths: ['**/*.md']`; no trailing whitespace in it.
- [ ] One `#` H1; blank line before and after every heading and every fenced block / list / table.
- [ ] No bare ` ``` ` opening fence — every code block declares a language (` ```text ` for trees/output).
- [ ] Links are standard `[text](path)` / `![alt](path)`, not wikilinks `[[…]]` / embeds `![[…]]`.
- [ ] Tables use a **spaced** delimiter row `| --- | --- |` (grep for the unspaced form: `grep -rnE '\|-{2,}\|' --include='*.md' .` — `-r` recurses without relying on shell `globstar`; fenced ❌-example blocks, including the one in this rule, are expected hits to skip).
- [ ] No Obsidian-only extensions: callouts `> [!…]`, inline `#tag`, `^block-id`, `%% … %%`, `==highlight==`, `$math$`, Mermaid/Dataview.
