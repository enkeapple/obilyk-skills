---
name: writing-adrs
description: Record an architectural decision as an immutable ADR — gated, and superseded (never edited) when it changes — and audit existing ADRs for drift. Use when the user wants to record or document an architectural decision, write an ADR, or check ADRs against the code. Triggers on "write an ADR", "record this decision", "document this decision", "architectural decision record", "запиши решение", "зафиксируй решение", "напиши ADR", "архитектурное решение".
---

# Writing ADRs

An **ADR** records a decision *already made*, **immutably**, so a future reader learns *why*. A capable model writes the prose fine on its own — left unaided it even references code at the file/symbol level and keeps trade-offs as facts. The damage comes from two directions this skill exists to stop:

- **The model under pressure** — documents trivia (a rename, a constant bump) and **rewrites an accepted decision in place**, destroying the history while claiming to "preserve" it.
- **An over-eager record** — every claim nailed to a `path:line` range and a "developers MUST…" checklist bolted on, until the record reads as an unreadable code-map that rots on the next commit. (This was the old shape of this very skill; the fix below is mostly *subtractive*.)

The load-bearing parts are the **Gate**, the **immutable supersede**, and **keeping the record readable**. The templates are just shape.

## First — match the repo's convention, don't impose one

Before writing, read the existing ADRs and match the **structure** you find: **where** they live (`docs/adr/`, `docs/adrs/`, `docs/decisions/`…), the **numbering** (`NNN` vs `0001`), the **status vocabulary**, the **section format**, and whether there is a categorized **index**. Match that exactly. No ADRs exist yet → bootstrap a sensible default (`docs/adr/NNNN-kebab-title.md`, a template below, an index `README.md`) **and say in your report that you established it**, so the team can redirect.

**Convention-matching stops at structure — the readability discipline below overrides it.** If the existing ADRs scatter `path:line` through their prose or carry inlined "Required practices" lists, that is exactly the rot this skill fixes — do **not** copy it. Match their location / numbering / status / sections; never reproduce a line-anchor-in-prose habit or an embedded-rules list just because the repo's older ADRs have one.

## The Gate — write an ADR ONLY when ALL THREE hold

1. **Hard to reverse** — undoing it later is expensive or wide-reaching.
2. **Surprising without context** — a future reader would ask "why on earth is it this way?".
3. **A genuine trade-off** — real alternatives existed and were weighed; the choice cost something.

Fails any one → **do NOT write an ADR.** Say which test it failed and point to the right home (commit message, a code comment, or the repo's conventions doc). A rename, a tweaked constant, a naming choice, a library you would swap in an afternoon — **not** ADRs.

## Pick the register

Two registers carry the same decision; pick one and say which. Offer the choice as a picker (or, with no picker tool, a numbered markdown list — never silently pick):

- **Narrative** — the lighter form: `Context` + `Decision` + `Related files`, no separate `Options`/`Consequences` sections. The trade-off is **woven into the prose** in one phrase ("chosen over X because…, at the cost of Y"). Default to this for most decisions — conceptual / approach / cross-cutting, or any decision where two full sections would be bloat.
- **Template** — the heavier form: explicit `Options considered` + `Consequences` slots, for a weighty mechanism-bound decision where a reader genuinely wants the alternatives and costs laid out navigably.

Pick the register by **this decision's weight**, not by the shape the repo's existing ADRs happen to use (convention-matching governs location / numbering / status / sections, not the register). The only difference is **how the trade-off is presented** — woven into prose vs explicit slots. Neither register drops it: *why not the alternatives* and *what it cost* is what makes a record an ADR, not a code comment — and it is immutable history that never goes stale (only code refs rot, and those live in `Related files`). Both obey the readability discipline below; fill the matching shape in [adr-template.md](references/adr-template.md).

## Keep it readable (both registers)

- **Be brief — a record, not a walkthrough.** Each section is a few sentences, not a code tour. `Context` and `Decision` ≤ ~120 words each; state *what* was decided and *why*, not a play-by-play of every branch in the code. If you are narrating control flow, you are writing documentation that rots — cut it. The whole ADR should fit on one screen.
- **`path:line` goes ONLY in `Related files` — never in `Decision` or any prose.** In the body, name code by **file + symbol** in plain text (`handleTokenRefresh` in `baseQuery.ts`) with no line numbers. All line anchors live in one short `Related files` section at the end: the **important** files only (a handful — never a 40-link dump), each as **file → symbol**, with at most one short `path:line` for the single anchor that pinpoints the decision — never a range. A `path:line` in the Decision prose is the anti-pattern that turns a record into a code-map; it rots on the next commit. Any reference you write is one you opened this session — an unopened `path:line` is fabricated.
- **No embedded rules.** An ADR records the decision and its consequences, *not* a "developers MUST…" checklist. Durable practices belong in the repo's conventions location (a rule, a lint check, a `CONTRIBUTING` note) — the ADR **links** to it, it does not inline it. A long "Required practices" list inside an ADR is a rules doc smuggled into a record.

## Operations

- **Author** — apply the Gate; pick the register; fill the matching shape in [adr-template.md](references/adr-template.md); then update the index ([index-and-supersession.md](references/index-and-supersession.md)).
- **Supersede** (a decision changed) — **never edit the body of an Accepted ADR.** Write a NEW ADR marked `Supersedes ADR-NNN`; change only the old ADR's **status line** to `Superseded by ADR-MMM`; sync both annotations in the index. Full mechanics: [index-and-supersession.md](references/index-and-supersession.md).
- **Drift audit** (sync) — scan Accepted ADRs whose decision no longer holds in code; **flag** for supersession, never auto-rewrite: [drift-audit.md](references/drift-audit.md).

## Rationalizations

| Excuse | Reality |
| --- | --- |
| "The lead asked for ADRs, so I write them." | The Gate is yours to apply. Trivia dilutes the log. Write the qualifying ones, refuse the rest, and say why. |
| "I'll just update ADR-017 and note the date — history is preserved." | Editing the Decision **destroys** the record. Supersede with a new ADR; the old one keeps its original text, status line only flipped. |
| "Page-size / rename is sort of a decision." | Reversible with no real trade-off = not an ADR. Fails the Gate. |
| "Pin claims to `path:line` in the Decision so it is precise." | `path:line` belongs ONLY in `Related files`, never in prose. In the body use file + symbol names; keep one short line for the single anchor that matters, in `Related files`. |
| "The existing ADRs here all use `path:line` / a practices list, so I match them." | Convention-matching covers structure only. Do not copy a line-anchor-in-prose habit or an embedded-rules list — that is the rot this skill removes. |
| "I should explain every branch so the Decision is complete." | An ADR is a record, not a walkthrough. A few sentences of *what* and *why*; control-flow narration is rot-prone documentation — cut it. |
| "Add a 'Required practices' list so the rules are captured here." | That is a rules doc, not a record. Put practices in the repo's conventions location and link to it. |
| "No index yet, I'll skip it." | An unindexed ADR is invisible. Create or update the index every time. |

## Red Flags — STOP

- About to rewrite the **body** of an Accepted ADR (overwrite instead of supersede).
- Writing an ADR for a rename, a constant, or anything reversible in an afternoon.
- Any `path:line` in `Decision` or other prose (it belongs ONLY in `Related files`), or a line **range**, or a `Related files` section grown into a long link dump.
- A `Context` or `Decision` running past a few sentences / ~120 words, or narrating control flow branch-by-branch — that is a walkthrough, not a record. Cut it.
- A "Required practices" / "developers MUST" list inlined in the ADR — link to the conventions doc.
- Numbering that collides or leaves gaps — use `max(existing) + 1`.
- An ADR cites a `path:line` you have not opened this session.
- Created or superseded an ADR without updating the index.

## References

- [adr-template.md](references/adr-template.md) — the narrative and template shapes with required slots.
- [index-and-supersession.md](references/index-and-supersession.md) — index format and the supersede mechanics.
- [drift-audit.md](references/drift-audit.md) — the sync/drift procedure.
