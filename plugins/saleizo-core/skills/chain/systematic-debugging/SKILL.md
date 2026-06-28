---
name: systematic-debugging
description: >-
  Use when a bug, test failure, crash, flaky test, or unexpected behavior
  appears and the cause is NOT yet known — investigate to a confirmed root cause
  before proposing any fix. A standalone debugging entry (not the full SDD
  chain); once the cause is confirmed it hands the fix to test-driven-development.
  Triggers on: "debug this", "why is this failing", "track down this bug",
  "root cause", "this test is flaky", "unexpected behavior", "diagnose this",
  "почему падает", "найди причину", "отладь", "разберись почему", "флакает тест".
---

# Systematic Debugging

Find the root cause before you touch a fix. A patch at the place the error *surfaces* hides the bug; it does not remove it.

## The Iron Law

```text
NO FIX WITHOUT A CONFIRMED ROOT CAUSE FIRST
```

Reached for a fix before you can state *why* it breaks? Stop. You are guessing. Guess-and-check is slower than investigation, not faster — every blind patch adds a variable.

## When to use

- A failure whose cause you cannot yet name: a crash, a wrong value, a flaky/intermittent test, behavior that "shouldn't happen".
- **Not** for: a fix whose cause is already understood — go straight to `test-driven-development` (write the failing test, then fix). This skill is the *diagnosis* that precedes that.
- Standalone: it does not require the SDD chain. Invoke it directly on a bug; it ends by handing off to `test-driven-development`.

## The four phases

### 1. Reproduce and read the evidence

- Reproduce it **reliably** — what exact steps trigger it? An intermittent failure you cannot trigger on demand is not yet understood (for timing/flaky cases see [references/condition-based-waiting.md](./references/condition-based-waiting.md)).
- Read the error and stack trace **completely** — not the first line. The real signal is often mid-stack.
- Check **recent changes** — what moved last (diff, recent commits, a new dependency, a config change)?
- In a **multi-component path**, log what data *enters* and *exits* each boundary, so you can see which hop corrupts it.

### 2. Trace to the root — never fix at the symptom

Follow the bad value **backward** through the call chain to where it originated, then fix at the source. The error location is where it *surfaced*, rarely where it *started*. Full technique: [references/root-cause-tracing.md](./references/root-cause-tracing.md).

Sharpen it by **pattern analysis**: find a **working** example of the same pattern in the codebase; read it **completely** — partial understanding breeds bugs, so don't skim-and-adapt; list every difference between working and broken, however small; and check what the working version *depends on* that the broken path is missing. The difference is usually the cause. A test that fails only **in company** (passes when run alone) is shared-state pollution, not a bug in the test itself — see [references/test-pollution.md](./references/test-pollution.md).

### 3. One hypothesis, tested minimally

- State it explicitly: **"X is the root cause, because Y."** One hypothesis at a time.
- Test it with the **smallest possible change** — one variable. Confirm or refute before trying anything else.
- Refuted? Form a **new** hypothesis from what you just learned. Do not stack a second change on an unconfirmed first.
- **After 3+ failed fix attempts, stop fixing.** Repeated failure means the hypothesis space is wrong — question the design/architecture and escalate to the owner rather than attempting "one more".
- Don't understand something load-bearing? Say so and ask — a known unknown beats a confident wrong guess.

### 4. Hand off the confirmed cause to the fix

With the root cause confirmed, hand off to `test-driven-development`: write the failing test that **reproduces that cause** through the public interface, watch it fail for the right reason, then make it pass. The reproduction test is what proves the fix sticks and guards against regression. Consider whether the same class of bad value can enter elsewhere — if so, validate at more than one layer ([references/defense-in-depth.md](./references/defense-in-depth.md)).

## When there is no single root cause

Sometimes a failure is genuinely environmental, timing-, or external-dependency-driven, with no single internal cause. **Assume incomplete investigation first** — most "no root cause" verdicts are a trace that stopped too early. Only once you have traced every boundary and still find none: document the investigation, implement appropriate handling (a bounded retry, an explicit timeout, a clear surfaced error), add a way to observe recurrence, and **say so explicitly** — never silently patch a symptom and call it fixed.

## Rationalizations — each is the trap

| Excuse | Reality |
| --- | --- |
| "It's a simple bug, skip the process." | Simple bugs have root causes too; the process is fast for them. |
| "Emergency — no time to investigate." | Systematic debugging is *faster* than guess-and-check thrashing. |
| "I'll just try this and see if it works." | The first move sets the pattern. A blind try adds a variable, it doesn't remove one. |
| "I see the problem, let me fix it." | Seeing the symptom is not understanding the cause. State the *why* first. |
| "Bump the timeout / add a retry to make it pass." | That hides a race; it does not remove it. Find why it isn't ready (condition-based-waiting). |
| "One more fix attempt." (after 2+) | 3+ failures = wrong hypothesis space. Question the design, don't re-roll. |
| "Wrap it in try/catch so it stops crashing." | Swallowing the symptom loses the evidence and ships the bug. Trace it instead. |

## Red Flags — STOP

- About to change code while unable to state the root cause in one sentence.
- Fixing at the line the error surfaced without tracing where the bad value originated.
- Making more than one change before confirming the last hypothesis.
- "Quick fix now, investigate later" / "just try changing X" / "increase the timeout".
- A 3rd fix attempt on the same bug with no new understanding — escalate instead.
- Patching a symptom (try/catch, retry, longer wait) in place of removing the cause.

## Signals from your partner that you're off track

Treat each as a STOP, not noise — it means switch back to investigating:

- **"Is that actually happening?"** — you assumed without verifying. Go confirm it.
- **"Will that show us anything?"** — you skipped gathering evidence. Instrument first.
- **"Stop guessing."** — you're proposing fixes before understanding. Return to tracing.
- **"Think harder / question the basics."** — stop poking symptoms; challenge a fundamental assumption.
- **"Are we stuck?"** (frustrated) — the current approach isn't working; change it, don't repeat it.

## References

- [references/root-cause-tracing.md](./references/root-cause-tracing.md) — trace a bad value backward to its origin.
- [references/test-pollution.md](./references/test-pollution.md) — an order-dependent / "only fails in company" test failure: bisect to the polluting test, then fix isolation.
- [references/condition-based-waiting.md](./references/condition-based-waiting.md) — kill flaky timing bugs by waiting on the condition, not a guessed delay.
- [references/defense-in-depth.md](./references/defense-in-depth.md) — when one fix isn't enough: validate at every layer the bad value crosses.
