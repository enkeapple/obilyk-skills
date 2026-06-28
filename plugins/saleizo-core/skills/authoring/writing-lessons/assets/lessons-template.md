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

Each problem-describing field — **Symptom**, **Root cause**, **Wrong approach**, **Correct approach**, **Prevention** — is a terse statement, **~250–300 characters max**. Past that it is drifting into a story (see Good vs bad below); tighten it. The **Cause-tag** (a short kebab key) and the one-sentence title are exempt.

The **Cause-tag** is the load-bearing field: reuse an existing tag for a matching cause, mint a new one only for a genuinely new cause class — identical tags are what make clusters countable. (Full rationale in SKILL.md.)

## Good vs bad lessons

| Good (an instruction) | Bad (a story) |
| --- | --- |
| "Assumed `useGetUser` existed; real hook is `useGetUserById`. Prevention: grep the export before importing." | "I made a typo in a hook name." |
| "Upgrading lib X broke a transitive peer dep; build failed. Prevention: check the full peer tree before any bump." | "Be careful with dependency upgrades." |

The bad column reads like a journal. The good column reads like a check someone can run.

## Filled example — a live backlog

Steady state: a couple of un-promoted candidate entries in `## Entries`, plus a `## Promoted clusters` ledger whose tags' entry bodies have already been **deleted** on promotion. A promoted cluster lives only as a ledger line, never as a retained entry — git keeps the deleted bodies.

```markdown
# Lessons Learned

## Entries

## 2026-06-20 — Imported a hook that does not exist
- **Cause-tag**: hallucinated-symbol
- **Symptom**: build failed — `useGetUser` is not exported; the real hook is `useGetUserById`.
- **Root cause**: imported a remembered symbol name without grepping the actual exports.
- **Wrong approach**: trusted memory of the API surface and imported the assumed name.
- **Correct approach**: grepped the module's exports, found `useGetUserById`, fixed the import.
- **Prevention**: grep the export list before importing any symbol you did not just define.

## 2026-05-30 — Assumed a barrel re-exported a helper
- **Cause-tag**: hallucinated-symbol
- **Symptom**: runtime "undefined is not a function" on a helper assumed to be re-exported.
- **Root cause**: assumed a barrel file re-exported a helper it did not.
- **Wrong approach**: imported from the barrel by analogy with sibling helpers.
- **Correct approach**: imported from the defining module directly.
- **Prevention**: confirm a barrel actually re-exports a symbol before importing from there.

## Promoted clusters
- dep-upgrade → rules/dependency-upgrades.md (2026-06-18)
```

Two live entries share `hallucinated-symbol` (a cluster at count 2, still below the promotion threshold). The `dep-upgrade` cluster was already promoted, so its entry bodies are gone — only the ledger line remains, pointing at the rule that now carries the guidance.
