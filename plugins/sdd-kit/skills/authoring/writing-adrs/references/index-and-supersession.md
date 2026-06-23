# Index & Supersession

## The index

ADRs are discoverable only through an index — a `README.md` in the ADR directory listing every ADR. **Update it on every author and every supersede**, in the same change as the ADR itself.

Match the repo's existing index shape. If ADRs are grouped by category (data layer, navigation, storage…), add the new entry **under the right category heading** — do not append to a flat tail. If the index is flat, keep it flat. Each entry is a link plus a superseded annotation where it applies:

```text
## Index

### Data layer

- [ADR-0001 — Single RTK Query master API](0001-single-rtk-query-master-api.md)

### UI / Lists

- [ADR-0017 — FlashList for lists >50 items](0017-flashlist-for-large-lists.md) — _Superseded by ADR-0025_
- [ADR-0025 — React Compiler makes manual memoization redundant](0025-react-compiler.md) — _supersedes ADR-0017_
```

No index file exists → create one (title + an `## Index` section + a pointer to the template) and report that you established it.

## Supersession — the immutable-record mechanic

An Accepted ADR is **history**. When the decision changes you record a *new* decision; you never edit the old one's reasoning. The damaging shortcut — rewriting ADR-017's Context/Decision to the new choice and adding `Updated: <date>` — looks like "keeping it current" but **erases why the original choice was made** and breaks every reference to it. Do not do it.

The mechanic, every time:

1. **Write a NEW ADR** for the current decision (next number, full template). Add a line under its status: `Supersedes ADR-NNN`.
2. **In the old ADR, change ONLY the status line** to `Superseded by ADR-MMM`. Leave its Context / Decision / Options / Consequences **byte-for-byte intact** — that is the historical record.
3. **Update the index** for BOTH: annotate the old entry `_Superseded by ADR-MMM_` and add the new entry `_supersedes ADR-NNN_`.

```text
✅ CORRECT
  0017 (unchanged body) Status: Superseded by ADR-0025
  0025 (new ADR)        Status: Accepted / Supersedes ADR-0017
  index: both annotated

❌ WRONG
  0017 body rewritten to the new decision + "Updated: 2026-06-24"
  → original rationale destroyed, no new ADR, references dangling
```

A `Deprecated` decision (dropped with no replacement) is the one case with no successor: flip the old status to `Deprecated`, annotate the index, write no new ADR.
