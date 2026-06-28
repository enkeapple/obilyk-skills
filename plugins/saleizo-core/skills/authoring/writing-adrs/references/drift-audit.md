# Drift Audit (sync)

A "living" ADR claims the code still works the way it says. Over time code moves and an `Accepted` ADR quietly goes false — its `Related files` anchors rot, or its decision is no longer what the code does. The audit **surfaces** that drift; it never silently rewrites history.

## Procedure

For each ADR with status `Accepted`:

1. **Resolve the `Related files` anchors.** Each is a file + symbol (with at most one short `path:line`). A symbol that no longer exists at the named file is drift — record the ADR, the stale anchor, and where it moved (if findable). Resolving at the symbol level, not a line number, is deliberate: a symbol survives the edits that a line range does not.
2. **Check the decision still holds.** Read the code the ADR governs and confirm it still does what the Decision says. A contradiction (the ADR says "single master API", the code grew three independent api slices) is drift.
3. **Classify each finding**:
   - *stale anchor only* — the decision holds, a symbol moved file → the fix is a corrected anchor in `Related files` (a small edit to a living reference is allowed; it is not a decision change).
   - *decision no longer holds* → this is a **supersession candidate**, not an edit. Flag it.

## Output — flag, never auto-act

Report findings as a list: each ADR, the drift class, and the recommended disposition. For a *decision-no-longer-holds* finding the recommendation is **"supersede via a new ADR"** (see [index-and-supersession.md](index-and-supersession.md)) — do **not** rewrite the ADR's Decision yourself, and do **not** auto-create the superseding ADR. The decision to supersede is the human's; the audit only makes the drift visible.

```text
DRIFT AUDIT
- ADR-0007 — stale anchor: `root.ts → configureStore` moved to `store.ts`. Fix: update Related files.
- ADR-0017 — decision no longer holds: code uses FlatList, ADR says FlashList. Recommend: supersede.
```

Correcting a stale anchor in `Related files` is the only write this audit performs on its own. Everything that touches a *decision* is surfaced for the human to act on through the supersede mechanic.
