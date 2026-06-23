---
name: test-driven-development
description: >-
  Use when writing implementation code test-first — a bugfix, behavior change,
  or the build step of a planned feature — and when you feel pressure to "just
  patch it", "add tests after", or keep code you already wrote. Triggers on:
  "fix this bug", "red-green-refactor", "write tests", "TDD".
---

# Test-Driven Development

Write the test first. Watch it fail. Write the minimal code to pass. One behavior at a time.

**Core principle:** if you didn't watch the test fail, you don't know if it tests the right thing.

**Tests verify behavior through the public interface, not implementation.** A good test reads like a spec ("rejects an expired coupon") and survives a refactor. If renaming an internal function breaks a test, that test was coupled to implementation — it was testing the wrong thing.

**Violating the letter of these rules is violating the spirit.** Project-agnostic: use the repo's real test runner and commands.

## When to use

- Always: new features, bug fixes, refactors, behavior changes.
- Exceptions (ask the user first): throwaway prototypes, generated code, config files.

Thinking "skip TDD just this once"? That is the rationalization. Don't.

## The Iron Law

```text
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Wrote code before the test? Delete it. Start over, implementing fresh from the test.

**No exceptions:**

- Don't keep it as "reference".
- Don't "adapt" or "reconcile" it while writing tests — that is testing-after in disguise.
- Don't look at it.
- Delete means delete.

## The cycle — one behavior at a time

Run RED → GREEN → REFACTOR for **one** behavior, then repeat for the next.

1. **RED — write one failing test.** One behavior, clear name, exercises real code through the public interface ([references/tests.md](./references/tests.md)). No mocks unless unavoidable ([references/mocking.md](./references/mocking.md)).
2. **Verify RED (mandatory).** Run the test. Confirm it *fails* (not errors), and fails for the right reason — the feature is missing, not a typo. Passes already? You're testing existing behavior — fix the test. Errors? Fix and re-run until it fails cleanly.
3. **GREEN — minimal code.** The simplest code that passes this one test. No extra options, no speculative features (YAGNI).
4. **Verify GREEN (mandatory).** Run the test. It passes, all other tests still pass, output is pristine (no warnings/errors). Test fails? Fix the code, not the test.
5. **REFACTOR — only while green.** Remove duplication, improve names, extract helpers, deepen modules. Never refactor while red; add no new behavior ([references/refactoring.md](./references/refactoring.md)).
6. **Repeat** with the next failing test.

## Vertical slices, not horizontal

Do **not** write all the tests first and then all the implementation. That "write every test, then write every impl" approach produces tests of *imagined* behavior — they test the shape of things, pass when behavior breaks, and outrun what you've actually learned.

```text
WRONG (horizontal):  RED: test1,test2,test3  →  GREEN: impl1,impl2,impl3
RIGHT (vertical):    test1→impl1  →  test2→impl2  →  test3→impl3
```

Each test responds to what the previous cycle taught you. The first test is a tracer bullet that proves the path end-to-end; every test after it is written against code you now understand.

## Example (one vertical slice)

The TypeScript/Jest below is **illustrative** — use the consumer repo's real language and test runner; the RED→GREEN→REFACTOR shape is what transfers, not the stack.

```ts
// 1. RED — one behavior, public interface, clear name
test("parseDuration reads a single unit", () => {
  expect(parseDuration("45s")).toBe(45);
});
```

```text
// 2. Verify RED:  <test command>  →  FAIL: parseDuration is not defined
```

```ts
// 3. GREEN — minimal code for THIS test only
export function parseDuration(input: string): number {
  const m = /^(\d+)s$/.exec(input);
  if (!m) throw new Error(`invalid: ${input}`);
  return Number(m[1]);
}
```

```text
// 4. Verify GREEN:  <test command>  →  PASS
```

Next cycle: write the failing test for `"30m"`, watch it fail, extend the code minimally, repeat for `"1h30m"`, invalid input, etc. One behavior per loop — never all at once.

## Checklist (per cycle)

Run this every loop. Can't tick all six? You skipped a step — redo the cycle, don't proceed.

- [ ] Test describes behavior, not implementation, through the public interface.
- [ ] Watched it fail — for the right reason (feature missing, not a typo).
- [ ] Wrote the minimal code to pass — no speculative features.
- [ ] Green: this test passes, all others still pass, output pristine.
- [ ] Refactored only while green; no new behavior added.
- [ ] One behavior this cycle — not a batch of tests.

## Layered references

- [references/tests.md](./references/tests.md) — what a good (behavior-driven) test looks like; good vs bad.
- [references/mocking.md](./references/mocking.md) — mock only true boundaries; never test the mock.
- [references/refactoring.md](./references/refactoring.md) — the REFACTOR step: candidates and the never-refactor-while-red rule.

## Rationalizations

| Excuse | Reality |
| -------- | --------- |
| "Too simple to test." | Simple code breaks. The test takes 30 seconds. |
| "I'll test after." | Tests written after code pass immediately — that proves nothing. You never saw them catch anything. |
| "Tests-after achieve the same goal." | Tests-after answer "what does this do?"; tests-first answer "what should this do?" Tests-after are biased by the code you already wrote. |
| "I already manually tested it." | Ad-hoc ≠ systematic. No record, can't re-run, easy to forget cases under pressure. |
| "Deleting hours of work is wasteful." | Sunk cost. The time is gone. Keeping code you can't trust is the actual waste. |
| "Keep it as reference / I'll reconcile it." | You'll adapt it — that's testing-after. Delete means delete. |
| "The code is probably fine, just add tests." | Then test-first costs an hour and proves it. If it's not fine, you caught a bug before production. |
| "TDD is dogmatic; I'm being pragmatic." | TDD is pragmatic: catching bugs pre-commit is faster than debugging in production. |
| "Hard to test." | The test is telling you the design is hard to use. Fix the design. |

## Red Flags — STOP and start over

- Production code written before its test.
- A test that passes the first time you run it.
- Can't explain why the test failed (or never ran it red).
- Writing all the tests up front, then all the implementation (horizontal slicing).
- A test that breaks on an internal rename though behavior is unchanged (implementation-coupled).
- "Keep as reference", "adapt/reconcile existing code", "already spent hours", "just this once", "spirit not ritual".

**All of these mean: delete the code, start over test-first, one behavior at a time.**
