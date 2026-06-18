# Lesson Entry Template

Append at the **top** of the `## Entries` section in `.claude/lessons-learned.md`. Never rewrite existing entries — the log is append-only. Every field is required.

```markdown
## YYYY-MM-DD — <one-sentence title>

- **Cause-tag**: <kebab-case-cluster-key>
- **Symptom**: observable behavior that went wrong (error, broken UI, failing test) — not the diagnosis.
- **Root cause**: the actual underlying cause, one statement — not the first thing you tried.
- **Wrong approach**: what was tried first and why it failed.
- **Correct approach**: what actually worked.
- **Prevention**: a concrete check that catches this earlier next time (a grep, a typecheck, a rule reference).
```

The **Cause-tag** is the load-bearing field: reuse an existing tag for a matching cause, mint a new one only for a genuinely new cause class — identical tags are what make clusters countable. (Full rationale in SKILL.md.)

## Good vs bad lessons

| Good (an instruction) | Bad (a story) |
| --- | --- |
| "Assumed `useGetUser` existed; real hook is `useGetUserById`. Prevention: grep the export before importing." | "I made a typo in a hook name." |
| "Upgrading lib X broke a transitive peer dep; build failed. Prevention: check the full peer tree before any bump." | "Be careful with dependency upgrades." |

The bad column reads like a journal. The good column reads like a check someone can run.

## Filled example — a log after one cluster was promoted

```markdown
# Lessons Learned

## Entries

## 2026-06-18 — Transitive peer dep broke the build on upgrade
- **Cause-tag**: dep-upgrade
- **Symptom**: build failed after bumping a dependency; a transitive peer dep was incompatible.
- **Root cause**: only direct deps were checked before the bump, not the transitive peer tree.
- **Wrong approach**: bumped the version and ran the build, expecting it to surface issues.
- **Correct approach**: inspected the full peer tree, pinned the compatible range, then upgraded.
- **Prevention**: before any bump, inspect direct AND transitive peer deps. → promoted to rules/dependency-upgrades.md

## 2026-05-02 — Native module unlinked after framework bump
- **Cause-tag**: dep-upgrade
- **Symptom**: app crashed on launch; a native module was unlinked.
- **Root cause**: the native install/link step was not re-run after the upgrade.
- **Wrong approach**: assumed the JS-level upgrade was enough.
- **Correct approach**: re-ran the native install step; relinked; crash gone.
- **Prevention**: re-run the native install step after every framework upgrade. → promoted to rules/dependency-upgrades.md

## 2026-04-18 — Peer dep mismatch after major chart-lib bump
- **Cause-tag**: dep-upgrade
- **Symptom**: build failed with an unmet peer dependency.
- **Root cause**: major version bumped without checking the new peer requirement.
- **Wrong approach**: upgraded to latest assuming minor compatibility.
- **Correct approach**: read the changelog, matched the required peer version.
- **Prevention**: read the changelog and peer requirements before a major bump. → promoted to rules/dependency-upgrades.md

## Promoted clusters
- dep-upgrade → rules/dependency-upgrades.md (2026-06-18)
```

The rule itself lives in the rule file, not here — the ledger only points to it, and each contributing entry carries a `→ promoted to` back-reference.
