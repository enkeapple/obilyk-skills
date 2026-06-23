# Mocking Guidelines

Default to **real code**. A mock is a liability: it can drift from the thing it stands in for, so the test passes while production breaks. Reach for one only at a true boundary, and even then assert on behavior, not on the mock.

## Mock only true boundaries

Justified:
- **Non-determinism:** time, randomness, UUIDs.
- **External I/O you don't own:** network, third-party APIs.
- **Slow or destructive operations.**

Everything else: use the real implementation or an in-memory fake.

## Don't test the mock

The failure mode: asserting that a mock was called instead of that the system produced a result.

```ts
// BAD — proves the mock works, not the feature
expect(fetchUser).toHaveBeenCalledWith("u1");

// GOOD — proves the observable outcome through the interface
const profile = await getProfile("u1");
expect(profile.displayName).toBe("Ada Lovelace");
```

Assert on the value your code returns or the state it changes — not on the mock's call log.

## Don't mock what you don't understand

Mocking a dependency whose contract you haven't read produces a mock that behaves differently from the real thing. Read the real contract first, or use a fake that honors it.

## Never add test-only seams to production

`getInternalStateForTest()` / `__testHook` leak test concerns into shipped code and invite implementation-coupled assertions. If you can't test through the real API, the design is too coupled — fix the design (see [refactoring.md](refactoring.md)).
