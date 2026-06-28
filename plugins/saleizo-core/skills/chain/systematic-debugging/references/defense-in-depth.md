# Defense in Depth

When a bad value caused a bug, ask not only "how do I fix this occurrence?" but "how do I make this class of bad value **impossible**?" A single checkpoint catches one path; the same bad value re-enters through the next path that lacks it. Validating at every layer the value crosses turns "we fixed the bug" into "the bug cannot recur".

Use this **after** root-cause tracing ([root-cause-tracing.md](./root-cause-tracing.md)) has found the origin — depth complements the source fix, it does not replace it. Reserve it for values whose corruption is costly or has already bitten more than once; do not gold-plate every input.

## The layers

1. **Entry-point validation** — reject obviously-invalid input at the boundary (null/empty, missing, wrong type, out of range) with a clear, actionable error. Fail fast and loud, close to the caller.
2. **Business-logic validation** — check the value makes *semantic* sense for the operation, beyond mere format (e.g. a date that parses but is in the future; an id that is well-formed but unknown).
3. **Environment guards** — refuse dangerous operations in the wrong context (e.g. a destructive action outside a sandbox, a write when a required setting is absent).
4. **Debug instrumentation** — when the other layers fail, capture enough context (inputs, a stack, relevant environment) to diagnose without reproducing.

## Apply it

- Trace the data flow: where does the bad value originate, and every place it is used?
- Map the checkpoints it passes through.
- Add a validation at each layer that could independently stop it.
- Test that **bypassing one layer is caught by another** — disable a layer in a test and confirm the bug is still blocked. If removing any single layer lets the bad value through, that layer's necessity is proven.

The signal you have enough depth: no single missing check re-opens the bug.
