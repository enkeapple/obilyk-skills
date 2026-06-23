# What a Good Test Looks Like

A test verifies **behavior through the public interface**. It reads like a specification, and it survives any refactor that keeps behavior identical.

## The three properties

| Property | Good | Bad |
| ---------- | ------ | ----- |
| **Behavioral** | Asserts what the system does via its public API. | Asserts on private state, internal call order, or a mock's call log. |
| **Minimal** | One behavior per test. An "and" in the name means split it. | `test("validates email and domain and whitespace")` |
| **Intent-revealing** | Name states the behavior: `rejects an expired coupon`. | `test("test1")`, `test("works")` |

## Survives-refactor rule

The defining question: **could this test survive a full rewrite of the internals that keeps the public behavior identical?**

If renaming an internal function or reshaping internal state breaks the test while behavior is unchanged, the test was coupled to implementation. Rewrite it against the public interface.

## Good vs bad

```ts
// BAD — vague name, asserts on a mock instead of behavior
test("retry works", async () => {
  const mock = vi.fn()
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce("ok");
  await retry(mock);
  expect(mock).toHaveBeenCalledTimes(2);
});

// GOOD — names the behavior, exercises real code, asserts the observable result
test("retry returns the value after one transient failure", async () => {
  let attempts = 0;
  const result = await retry(() => {
    attempts++;
    if (attempts < 2) throw new Error("transient");
    return "ok";
  });
  expect(result).toBe("ok");
  expect(attempts).toBe(2);
});
```

## When a test is hard to write

Hard-to-test code is telling you the design is hard to use. Don't fight the test — fix the design:

| Symptom | What it means |
| --------- | --------------- |
| Must mock everything | Code too coupled — use dependency injection. |
| Huge setup | Extract helpers; if still complex, the interface is doing too much. |
| Can't assert without reaching inside | The behavior isn't exposed through the public interface — it should be. |
