# Condition-Based Waiting

Flaky, intermittent test failures are usually a **timing race**: the test guesses *how long* an async operation takes with a fixed delay, instead of waiting for the *condition* it actually depends on. The guess passes on a fast machine and fails under load or in CI.

## The fix

**Wait for the condition you care about, not a guess about how long it takes.** Replace a fixed delay with a poll that checks the real predicate until it holds or a timeout elapses.

```text
# ❌ WRONG — guessed delay; races under load
do_async_thing()
sleep(20ms)                      # "should be enough"
assert results.length == 3       # ~30% flaky in CI

# ✅ CORRECT — wait on the actual condition (illustrative pseudocode)
do_async_thing()
wait_for(() => results.length == 3, timeout: 2s)   # resolves the instant it's true
assert results.length == 3
```

`wait_for` polls the predicate on a short interval (a few ms) until it returns true or the timeout fires; it returns the moment the condition holds, so it is both faster and immune to load.

Typical predicates: an event has arrived, a state has reached a value, a count has met a threshold, a file/record exists.

## The deeper cause is often upstream

A guessed delay frequently masks a *real* bug: the function under test returns **before** its async work completes (a missing await/await-equivalent, an unawaited callback). Before reaching for a longer wait, check whether the operation should expose a completion signal (a promise/future/done-callback) the test can await directly — then the race disappears at the source. See [root-cause-tracing.md](./root-cause-tracing.md).

## The one legitimate fixed delay

When you are testing *timing itself* (a debounce, a throttle, a rate limit), a real delay is unavoidable — but **document why** inline, and still wait for a triggering condition first where you can. An undocumented `sleep(n)` in any other test is a flaky-test red flag.
