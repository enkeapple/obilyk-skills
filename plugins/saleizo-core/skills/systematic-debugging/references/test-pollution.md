# Test Pollution

A test that **passes alone but fails in the suite** (or fails only in a certain order) is rarely a bug in that test — it is **pollution**: an earlier test left shared state behind (a global, a cache, a file, a database row, an env var, a registered handler) that the later test inherits. The failing test is the *victim*, not the culprit.

## Confirm it is pollution

- The test passes when run in isolation, fails when run after the full suite (or a specific subset).
- Reordering or shuffling the suite changes which tests fail.
- The failure references state the test never set up itself.

## Find the culprit by bisection

You do not need to read every test. Let the suite tell you which one pollutes:

1. Pick the observable pollution — the leftover file, the dirty global, the unexpected row.
2. Run tests **one at a time, in suite order**, and after each one check whether the pollution is now present.
3. The first test after which the pollution appears is the culprit.

```text
# illustrative — the shape, not a specific runner
for each test in suite_order:
    run(test)
    if pollution_present():   # the leftover file / dirty global / stray record
        report "culprit:", test ; stop
```

Bisecting (run the first half, check; narrow to the half that pollutes) is faster on a large suite; sequential is simpler and deterministic.

## Fix at the source — isolation, not the victim

Fix the **culprit's** cleanup, never the victim's assertion:

- Reset the shared state in teardown/setup (clear the global, truncate the table, remove the temp file, restore the env).
- Better, **make the state unshareable**: give each test its own instance / temp dir / transaction so isolation holds by construction and cannot regress (this is the [defense-in-depth.md](./defense-in-depth.md) move applied to tests).

Loosening or special-casing the victim's assertion to make it pass is the symptom-patch trap — it leaves the pollution live for the next test to trip over.
