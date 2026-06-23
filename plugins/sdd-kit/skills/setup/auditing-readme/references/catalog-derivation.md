# Catalog Derivation Contract

The single source of truth for how a skills catalog — and, in a marketplace, a plugin index — is derived from disk. **Both `bootstrapping-readme` (which writes the blocks) and `auditing-readme` (which checks them) follow this contract verbatim** — they agree by construction only if this file is identical in both skills, so any change here must be applied to both copies in the same change.

Every row in every managed block is derived, never hand-authored. Deriving the same input twice must produce byte-identical output (descriptions, ordering, links) — that determinism is what makes a block auditable.

## Repo mode

Two layouts, detected by one observable: a `.claude-plugin/marketplace.json` at the repo root.

```text
SINGLE-REPO   No marketplace.json. One README at the repo root carrying ONE
              skill-catalog block. ROOT is resolved as below.

MARKETPLACE   marketplace.json present. It lists plugins (each `plugins[].source`
              resolved under `metadata.pluginRoot`, default `./plugins`). The output is:
                - ONE per-plugin README at `plugins/<name>/README.md`, each carrying a
                  skill-catalog block scoped to THAT plugin's skills only; AND
                - the ROOT README at `README.md` carrying a PLUGIN-INDEX block
                  (an index of the plugins, NOT a flat catalog of every skill).
```

Mode decides ROOT, the ROW LINK base, and which block kind(s) are emitted; the description algorithm, ordering, and row shape are shared.

## Definitions (skill catalog)

```text
ROOT        SINGLE-REPO: `skills/` when it exists and at least one SKILL.md sits in a
            sub-directory of it; otherwise the directory that directly holds the
            SKILL.md files. If `skills/` exists, ROOT is `skills/` regardless of stray
            SKILL.md elsewhere.
            MARKETPLACE: per plugin, ROOT is that plugin's `plugins/<name>/skills/`
            directory; each plugin's catalog is derived independently from its own ROOT.
            (A consumer repo may state ROOT explicitly if its layout differs.)

DISCOVERY   Every `**/SKILL.md` under ROOT. A skill's identity is its frontmatter
            `name`. A SKILL.md missing `name` or `description` is NOT silently
            dropped — it becomes a malformed-frontmatter finding (see Edge cases).

CATEGORY    The first path segment of (skill-directory path relative to ROOT).
            `chain/grilling` → `chain`; a path nested deeper than one level keeps the
            FIRST segment. A skill directory directly under ROOT is uncategorized. If
            NO skill has a category segment, render flat (one bullet list, no `###`).
            The category folder IS the grouping dimension — it is the derivable proxy
            for "purpose". Arbitrary functional labels (e.g. "Testing"/"Debugging") are
            NOT derivable from disk and are out of scope; do not invent them.

ROW LINK    SINGLE-REPO: the repo-root-relative path to the source SKILL.md
            (e.g. `skills/chain/grilling/SKILL.md`).
            MARKETPLACE: the path RELATIVE TO THE PLUGIN README's own directory
            (e.g. `skills/chain/grilling/SKILL.md` inside `plugins/sdd-kit/README.md`),
            so the plugin README resolves when the plugin is published standalone.
            Link text = `name` in both modes.

DESCRIPTION The frontmatter `description`, folded to a single string, then:
              1. strip from the first match of /\s*Triggers?( on)?:.*/is to the end
                 (drops the trigger-phrase tail, including a "Russian triggers:" tail);
              2. collapse all whitespace/newlines to single spaces and trim;
              3. if longer than 120 characters, truncate at the last word boundary
                 ≤120 and append a single `…`.
            If the result is empty after stripping → treat as missing (malformed finding).

ORDER       Categories alphabetical (a flat render has none); rows alphabetical by
            `name` within each category. Deterministic across runs.
```

## Plugin index (marketplace root only)

The ROOT README's managed block indexes the plugins, not the skills:

```text
DISCOVERY   Read `.claude-plugin/marketplace.json`. For each `plugins[]` entry, resolve
            `<metadata.pluginRoot default ./plugins>/<source>/.claude-plugin/plugin.json`
            and read its `name` and `description`.

ROW LINK    `plugins/<name>/README.md`, repo-root-relative (the per-plugin README this
            skill also generates). Link text = plugin `name`.

DESCRIPTION the plugin.json `description`, run through the same fold/strip/120-truncate
            as a skill description (a plugin description has no trigger tail, so the strip
            is a no-op there).

ORDER       Plugins alphabetical by `name`. Deterministic across runs.
```

## Row shape

One bullet-list item per entry, in standard GitHub-Flavored Markdown (a blank line before and after each list), the `name` rendered as a **bold link** with the description after an em dash — no table, no kind column:

```text
- **[<name>](<ROW LINK>)** — <DESCRIPTION>
```

This shape is identical for a skill row and a plugin-index row; only the link base differs.

## Managed block

Each derived block lives inside its own marker pair so it can be regenerated without touching human prose. The skill catalog uses `skills`; the plugin index uses `plugins`:

```text
<!-- skills:start -->
<!-- Generated by bootstrapping-readme — do not edit by hand; rerun the skill. -->

### <category>

- **[<name>](<ROW LINK>)** — <DESCRIPTION>
- …

<!-- skills:end -->
```

```text
<!-- plugins:start -->
<!-- Generated by bootstrapping-readme — do not edit by hand; rerun the skill. -->

- **[<name>](plugins/<name>/README.md)** — <DESCRIPTION>
- …

<!-- plugins:end -->
```

The `## Skills` / `## Plugins` heading that owns a block is human-authored and lives OUTSIDE the markers; a skill-catalog block contains only `###` category subsections and their bullet lists (or a single bullet list when flat); the plugin-index block is a single bullet list.

## Edge cases

- **Duplicate `name`** across two SKILL.md within one ROOT → an error naming both conflicting paths; do not merge or pick one (the `name === dir === symlink` invariant forbids duplicates). The same plugin `name` listed twice in marketplace.json is the analogous plugin-index error.
- **Missing `name`/`description`** (or empty description after the strip) → emit a `malformed frontmatter: <path>` finding; never crash the walk. A marketplace plugin whose `plugin.json` is missing or lacks `name`/`description` is the analogous `malformed plugin: <path>` finding for its index row.
- **Malformed/duplicate markers** (one `start`, two `end`, reversed, nested — for either marker pair) → `bootstrapping-readme` refuses to edit and reports; `auditing-readme` flags it as finding #1, which blocks the other checks.
- **Zero skills under ROOT** → an empty block carrying a single `<!-- no skills found -->` comment (in marketplace mode, that plugin's own README still gets the empty block).
- **No README, or a README without markers** → create the file (`# <repo or plugin>` H1 + the owning `## Skills`/`## Plugins` heading + block) or insert the block under its heading, leaving existing prose untouched.
