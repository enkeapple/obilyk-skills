# Framework Charter

How to work in this repo, regardless of which module you touch. A TypeScript React Native codebase using **pnpm**. Verification is `pnpm typescript`, `pnpm lint`, and `pnpm test` (Vitest, under `__tests__/`).

## Implementation protocol

1. **Read the request fully.** Restate the change in one line before coding.
2. **Scan every layer the change touches** and classify each: `none` (untouched), `partial` (read, edit some), `full` (rewrite). Typical layers: component / screen, hook, store/slice, navigation, types, native bridge.
3. **Write the contract as code first** — the type, the function signature, the prop interface. Not a prose description. The signature is the contract.
4. **Walk happy path + edge cases** before writing the body: empty list, loading, error, null/undefined, offline, unmounted-while-async.
5. **Code in dependency order** — types → store/logic → hook → component. Never edit a consumer before its contract compiles.

## Suspicion protocol

After each edit, actively hunt for the failure you just created. Each mode has a detection check — run it, don't assume.

- **Missed duplicate code** → before adding a util/hook/component, `rtk grep` for name variants (`format`/`fmt`, `useFoo`/`getFoo`). Wire to the existing one.
- **Shortcut / silent cut** → re-read the request bullet by bullet against the diff. Did every bullet land? No "I'll do that part later" without saying so.
- **Hallucinated symbol** → every imported name, prop, or RN/library API you write must be verified by a read this session. If you didn't read it, you don't know it exists.
- **Test-passes-for-wrong-reason** → invert your assumption. "Would this test still pass if my belief were false?" If yes, you haven't proven anything. Also: "would this still compile/render if my belief were false?"
- **Unverified structure claim** → never state a file path, export, or folder layout you haven't opened this session.

## Zero-hallucination

No structural claim without a read in **this** session. "It's probably in `src/...`" is a guess — open it. Editing a rule doc, a config, or a type declaration **is editing code**: same rigor, same verification.

## Evidence-based verification

Before claiming done, run the repo's real commands and **paste the output**:

```
pnpm typescript
pnpm lint
pnpm test
```

"Should pass" / "looks right" is not evidence. Zero TS errors, zero lint errors, and passing tests, shown, or it is not done.

## Question discipline

Don't ask what the repo or these rules already answer. When a choice is open, pick the **smallest-diff** default, state it in one line, and proceed. Ask only when the choice changes a contract (type, route, or store shape) and the request is genuinely ambiguous.
