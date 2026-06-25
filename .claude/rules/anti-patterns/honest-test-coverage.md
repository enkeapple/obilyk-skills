---
description: 'A test earns its place only if it can fail for the right reason: assert observable behavior against intent, not the code''s own current output. Forbids over-mocking that leaves nothing real under test, snapshotting freshly-generated output as the "correct" baseline, and chasing coverage % with assertion-light tests. AI produces green suites that validate its own assumptions; this is the counter. Area-specific to test files.'
paths:
  - '**/*.{test,spec}.{ts,tsx,js,jsx,mjs,cjs}'
  - '**/test_*.py'
  - '**/*_test.{py,go}'
  - '**/tests/**/*.{py,rb,java,kt}'
---

# Honest Test Coverage

## When

STOP and check what the test actually proves whenever you write or review tests — especially a freshly generated suite that already passes. AI produces tests that hit a coverage number and go green, but assert the code's current behavior rather than the intended behavior.

## Why

A test that cannot fail for the right reason is worse than no test: it shows green, blocks nobody, and gives false confidence. The three AI failure modes are over-mocking (so much is faked that nothing real runs), snapshot-blessing (whatever the code emitted is captured as "correct"), and coverage-gaming (lines are executed but nothing meaningful is asserted).

## Implementation

**Assert observable behavior tied to intent — and make sure the test can fail.**

- **Assert behavior, not implementation.** Check inputs → outputs/effects against what the feature is *supposed* to do, not call logs or internal steps.
- **Mock only true external boundaries** (network, clock, filesystem, third-party service). If you must mock the thing under test to make it pass, the unit is too coupled — fix the design, don't mock it away. Don't assert on the mock ("was called with") in place of a real outcome.
- **Never snapshot agent-generated output as the expected baseline** unless a human verified the captured value. An unreviewed snapshot encodes "whatever it did" as truth and tests nothing.
- **Coverage % is not the goal.** A covered line with no meaningful assertion is fake green; either assert the behavior or accept the line is untested in practice.

```text
❌ WRONG — tests the mock / blesses output; cannot fail for the right reason (illustrative)
  const repo = { save: vi.fn() };
  service.create(input, repo);
  expect(repo.save).toHaveBeenCalled();        // asserts the call log, not the result

  expect(render(data)).toMatchSnapshot();       // snapshot auto-captured, never human-verified

✅ CORRECT — asserts observable behavior against intent (illustrative)
  const saved = await service.create(input, realRepo);
  expect(saved.id).toBeDefined();
  expect(await realRepo.find(saved.id)).toEqual({ ...input, id: saved.id });  // real effect
```

## Edge Cases

- **Snapshots are fine when the baseline was human-verified** — the failure mode is *auto-blessing* a generated snapshot, not snapshot testing itself.
- **Mocking a real boundary is legitimate** — a network call, a clock, a paid API. The rule forbids mocking *the unit under test* until the test proves nothing.
- **High coverage is fine when the assertions are real** — the rule targets coverage *as the goal*, not coverage as a byproduct of meaningful tests.

## Review Checklist

- [ ] Each test asserts an observable input→output/effect tied to intent, not a call log or internal step.
- [ ] Mocks are limited to true external boundaries; the unit under test is exercised for real.
- [ ] No snapshot was accepted as the baseline without a human verifying the captured value.
- [ ] Removing the implementation under test would make the test FAIL (it can fail for the right reason) — not pass because it only checks mocks/snapshots.
