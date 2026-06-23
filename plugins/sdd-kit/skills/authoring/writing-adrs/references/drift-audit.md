# Drift Audit (sync)

A "living" ADR claims the code still works the way it says. Over time code moves and an `Accepted` ADR quietly goes false — its `path:line` references rot, or its decision is no longer what the code does. The audit **surfaces** that drift; it never silently rewrites history.

## Procedure

For each ADR with status `Accepted`:

1. **Resolve every `path:line` reference.** A reference that no longer points at the relevant code is drift — record the ADR, the stale reference, and where the code moved (if findable).
2. **Check the decision still holds.** Read the code the ADR governs and confirm it still does what the Decision says. A contradiction (the ADR says "single master API", the code grew three independent api slices) is drift.
3. **Classify each finding**:
   - *stale reference only* — the decision holds, a `path:line` moved → the fix is a corrected reference (a small edit to a living link is allowed; it is not a decision change).
   - *decision no longer holds* → this is a **supersession candidate**, not an edit. Flag it.

## Output — flag, never auto-act

Report findings as a list: each ADR, the drift class, and the recommended disposition. For a *decision-no-longer-holds* finding the recommendation is **"supersede via a new ADR"** (see [index-and-supersession.md](index-and-supersession.md)) — do **not** rewrite the ADR's Decision yourself, and do **not** auto-create the superseding ADR. The decision to supersede is the human's; the audit only makes the drift visible.

```text
DRIFT AUDIT
- ADR-0007 — stale reference: `src/store/root.ts:4` → moved to `src/app/store.ts:11`. Fix: update link.
- ADR-0017 — decision no longer holds: code uses FlatList, ADR says FlashList. Recommend: supersede.
```

Correcting a stale living link is the only write this audit performs on its own. Everything that touches a *decision* is surfaced for the human to act on through the supersede mechanic.
