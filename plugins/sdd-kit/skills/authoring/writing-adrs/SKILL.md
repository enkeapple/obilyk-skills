---
name: writing-adrs
description: Record an architectural decision as an immutable ADR — gate that it is worth one, write it in the repo's own convention, maintain the index, and supersede (never edit) when a decision changes; also audit existing ADRs for drift. Use when the user wants to record or document an architectural decision, write an ADR, or check ADRs against the code. Triggers on "write an ADR", "record this decision", "document this decision", "architectural decision record", "запиши решение", "зафиксируй решение", "напиши ADR", "архитектурное решение".
---

# Writing ADRs

An **ADR** records a decision *already made*, **immutably**. A capable model writes the prose fine on its own; under time pressure — or on a smaller model — it does two damaging things this skill exists to stop: it **documents trivia** (a rename, a constant bump) and it **rewrites an accepted decision in place**, destroying the history while claiming to "preserve" it. The gate and the supersede rule are the load-bearing parts; the template is just shape.

## First — detect the repo's convention, don't impose one

Before writing, read the existing ADRs and match what you find: **where** they live (`docs/adr/`, `docs/adrs/`, `docs/decisions/`…), the **numbering** (`NNN` vs `0001`), the **status vocabulary**, the **section format**, and whether there is a categorized **index**. Match it exactly. No ADRs exist yet → bootstrap a sensible default (`docs/adr/NNNN-kebab-title.md`, the template below, and an index `README.md`) **and say in your report that you established it**, so the team can redirect.

## The Gate — write an ADR ONLY when ALL THREE hold

1. **Hard to reverse** — undoing it later is expensive or wide-reaching.
2. **Surprising without context** — a future reader would ask "why on earth is it this way?".
3. **A genuine trade-off** — real alternatives existed and were weighed; the choice cost something.

Fails any one → **do NOT write an ADR.** Say which test it failed and point to the right home (commit message, a code comment, or a `rule`). A rename, a tweaked constant, a naming choice, a library you would swap in an afternoon — **not** ADRs.

## Operations

- **Author** — apply the Gate; then fill [adr-template.md](references/adr-template.md), linking each claim to a verified `path:line`; then update the index ([index-and-supersession.md](references/index-and-supersession.md)).
- **Supersede** (a decision changed) — **never edit the body of an Accepted ADR.** Write a NEW ADR marked `Supersedes ADR-NNN`; change only the old ADR's **status line** to `Superseded by ADR-MMM`; sync both annotations in the index. Full mechanics: [index-and-supersession.md](references/index-and-supersession.md).
- **Drift audit** (sync) — scan Accepted ADRs whose decision no longer holds in code; **flag** for supersession, never auto-rewrite: [drift-audit.md](references/drift-audit.md).

## Rationalizations

| Excuse | Reality |
| --- | --- |
| "The lead asked for ADRs, so I write them." | The Gate is yours to apply. Trivia dilutes the log. Write the qualifying ones, refuse the rest, and say why. |
| "I'll just update ADR-017 and note the date — history is preserved." | Editing the Decision **destroys** the record. Supersede with a new ADR; the old one keeps its original text, status line only flipped. |
| "Page-size / rename is sort of a decision." | Reversible with no real trade-off = not an ADR. Fails the Gate. |
| "No index yet, I'll skip it." | An unindexed ADR is invisible. Create or update the index every time. |
| "I'll cite the file from memory." | A `path:line` you did not open is a fabricated reference. Verify it. |

## Red Flags — STOP

- About to rewrite the **body** of an Accepted ADR (overwrite instead of supersede).
- Writing an ADR for a rename, a constant, or anything reversible in an afternoon.
- Numbering that collides or leaves gaps — use `max(existing) + 1`.
- An ADR cites a `path:line` you have not opened this session.
- Created or superseded an ADR without updating the index.

## References

- [adr-template.md](references/adr-template.md) — the section template with required slots.
- [index-and-supersession.md](references/index-and-supersession.md) — index format and the supersede mechanics.
- [drift-audit.md](references/drift-audit.md) — the sync/drift procedure.
