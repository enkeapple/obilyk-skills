# Catalog Derivation Contract

The single source of truth for how a skills catalog, a hooks catalog, and — in a marketplace — a plugin index are derived from disk. **Both `bootstrapping-readme` (which writes the blocks) and `auditing-readme` (which checks them) follow this contract verbatim** — they agree by construction only if this file is identical in both skills, so any change here must be applied to both copies in the same change.

Every row in every managed block is derived, never hand-authored. Deriving the same input twice must produce byte-identical output (descriptions, ordering, links) — that determinism is what makes a block auditable.

## Repo mode

Two layouts, detected by one observable: a `.claude-plugin/marketplace.json` at the repo root.

```text
SINGLE-REPO   No marketplace.json. One README at the repo root carrying ONE
              skill-catalog block. ROOT is resolved as below.

MARKETPLACE   marketplace.json present. It lists plugins (each `plugins[].source`
              resolved under `metadata.pluginRoot`, default `./plugins`). The output is:
                - ONE per-plugin README at `plugins/<name>/README.md`, each carrying a
                  skill-catalog block and/or a hooks-catalog block scoped to THAT
                  plugin only — see "Per-plugin README composition"; AND
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
            (e.g. `skills/chain/grilling/SKILL.md` inside `plugins/saleizo-core/README.md`),
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

## Definitions (hooks catalog)

A plugin that wires Claude Code hooks (a `hooks/hooks.json`) gets a **hooks catalog** — the same derived bullet list as a skill catalog, but sourced from the hook wiring. A hook is NOT a skill (it owns no `SKILL.md` and is not routable); it gets its own block kind and marker pair.

```text
ROOT        MARKETPLACE: per plugin, the plugin's `plugins/<name>/hooks/hooks.json`.
            SINGLE-REPO: the repo's hooks manifest if it keeps one (a consumer repo
            may state it explicitly). The catalog is derived from the manifest, never
            from a bare glob of `hooks/*.sh`.

DISCOVERY   Read `hooks.json` and walk every wired command. A hook's identity is the
            basename of its script with the `.sh` extension removed (the command string
            `"${CLAUDE_PLUGIN_ROOT}"/hooks/detect-bypass.sh` → `detect-bypass`). A `.sh`
            present in `hooks/` but NOT wired in `hooks.json` is NOT cataloged — it is
            not an active hook. A wired command whose script file is missing on disk →
            a `malformed hook: <path>` finding (see Edge cases).

EVENT       The hooks.json top-level key the command is wired under
            (`UserPromptSubmit` / `PreToolUse` / `PostToolUse` / `Stop` / …). EVENT is
            the grouping dimension for hooks — the derivable proxy for "when it runs",
            exactly as CATEGORY is for skills. One script wired under MORE THAN ONE
            event appears once under EACH of those events.

ROW LINK    MARKETPLACE: the script path RELATIVE TO THE PLUGIN README's own directory
            (`hooks/<file>.sh`). Link text = the hook name (basename minus `.sh`).

DESCRIPTION Derived in two parts, structure-then-prose:
              1. STRUCTURE comes from hooks.json (always present): the EVENT and, when
                 the wiring group carries one, its `matcher`.
              2. PROSE comes from the script's line-2 header comment when it follows the
                 convention `# <Event> hook[ (matcher: …)]: <text>.` — take <text> (strip
                 the leading `<Event> hook( … ):` prefix), then fold/collapse/120-truncate
                 exactly as a skill DESCRIPTION (no trigger-tail strip needed).
              3. FALLBACK when the comment is absent or non-conforming: synthesize
                 `<event> hook (matcher: <matcher>)`, or `<event> hook` when the group
                 has no matcher. The fallback is never empty, so a hook row is never
                 malformed for lack of prose.

ORDER       Events alphabetical; hooks alphabetical by name within each event.
            Deterministic across runs (one ordering rule, shared with the skill catalog).
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

## Per-plugin README composition (marketplace)

A per-plugin README emits **only the catalog blocks that have content**, never an empty placeholder for a kind the plugin lacks:

```text
H1 TITLE    The plugin's `name` from plugin.json in Title Case — each `-`-separated
            segment capitalized, joined by spaces (`saleizo-controls` → "Guardrails Kit").
            Derived the same way every run. The H1 lives in the human-owned scaffold
            (emitted once on first creation, not regenerated over an existing README);
            this rule fixes what first-creation writes.

BLOCKS      - a skills-catalog block (markers `skills:`) iff the plugin has ≥1 skill;
            - a hooks-catalog block (markers `hooks:`) iff the plugin wires ≥1 hook;
            - when BOTH exist, the skills block precedes the hooks block;
            - a plugin with NEITHER skills nor hooks gets a single EMPTY skills block
              carrying `<!-- no skills found -->` — the only surviving placeholder case.
            A hooks-only plugin (e.g. one shipping only `hooks/`) therefore emits a
            hooks block and NO empty skills block.
```

The `## Skills` / `## Hooks` heading that owns each block is human-authored scaffold (outside the markers).

## Row shape

One bullet-list item per entry, in standard GitHub-Flavored Markdown (a blank line before and after each list), the `name` rendered as a **bold link** with the description after an em dash — no table, no kind column:

```text
- **[<name>](<ROW LINK>)** — <DESCRIPTION>
```

This shape is identical for a skill row, a hook row, and a plugin-index row; only the link base differs.

## Managed block

Each derived block lives inside its own marker pair so it can be regenerated without touching human prose. The skill catalog uses `skills`; the hooks catalog uses `hooks`; the plugin index uses `plugins`:

```text
<!-- skills:start -->
<!-- Generated by bootstrapping-readme — do not edit by hand; rerun the skill. -->

### <category>

- **[<name>](<ROW LINK>)** — <DESCRIPTION>
- …

<!-- skills:end -->
```

```text
<!-- hooks:start -->
<!-- Generated by bootstrapping-readme — do not edit by hand; rerun the skill. -->

### <event>

- **[<name>](hooks/<file>.sh)** — <DESCRIPTION>
- …

<!-- hooks:end -->
```

```text
<!-- plugins:start -->
<!-- Generated by bootstrapping-readme — do not edit by hand; rerun the skill. -->

- **[<name>](plugins/<name>/README.md)** — <DESCRIPTION>
- …

<!-- plugins:end -->
```

The `## Skills` / `## Hooks` / `## Plugins` heading that owns a block is human-authored and lives OUTSIDE the markers; a skill-catalog block contains only `###` category subsections and their bullet lists (or a single bullet list when flat); a hooks-catalog block contains `###` event subsections and their bullet lists; the plugin-index block is a single bullet list.

## Edge cases

- **Duplicate `name`** across two SKILL.md within one ROOT → an error naming both conflicting paths; do not merge or pick one (the `name === dir === symlink` invariant forbids duplicates). The same plugin `name` listed twice in marketplace.json is the analogous plugin-index error.
- **Missing `name`/`description`** (or empty description after the strip) → emit a `malformed frontmatter: <path>` finding; never crash the walk. A marketplace plugin whose `plugin.json` is missing or lacks `name`/`description` is the analogous `malformed plugin: <path>` finding for its index row.
- **Hook wired in hooks.json but its script file is missing** → a `malformed hook: <path>` finding; never crash the walk. (A hook never lacks prose — the DESCRIPTION fallback covers a missing/non-conforming header comment.)
- **Malformed/duplicate markers** (one `start`, two `end`, reversed, nested — for any marker pair) → `bootstrapping-readme` refuses to edit and reports; `auditing-readme` flags it as finding #1, which blocks the other checks.
- **A plugin with neither skills nor hooks** → a single empty skills block carrying `<!-- no skills found -->`. A hooks-only plugin emits a hooks block and NO empty skills block; a skills-only plugin emits a skills block and no hooks block (see Per-plugin README composition).
- **No README, or a README without markers** → create the file (the Title-Case H1 + the owning `## Skills`/`## Hooks`/`## Plugins` heading + block) or insert the block under its heading, leaving existing prose untouched.
