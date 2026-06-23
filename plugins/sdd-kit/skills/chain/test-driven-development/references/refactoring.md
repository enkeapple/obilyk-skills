# Refactoring (the third step of the cycle)

Refactoring is changing structure **without changing behavior**. In TDD it happens only after GREEN, with the tests as your safety net.

## The one hard rule

**Never refactor while red.** Get to green first. If a test is failing, you don't know whether a structural change broke behavior or the behavior was never there. Green is the baseline that makes refactoring safe.

## Candidates (after green)

- **Remove duplication** — the same logic in two places becomes one.
- **Improve names** — a name that now misleads (the code grew past it) gets renamed.
- **Extract helpers** — a step that reads as a paragraph becomes a named function.
- **Deepen modules** — push complexity behind a small interface; callers should see less, not more. A deep module = simple interface, substantial implementation.
- **Apply SOLID where it falls out naturally** — don't impose patterns the code isn't asking for (YAGNI applies to structure too).
- **Let new code teach you about old code** — the behavior you just added often reveals a better shape for what was already there.

## Procedure

1. Make one structural change.
2. Re-run the tests. Still green? Keep it. Red? Revert it — the change altered behavior.
3. Repeat, one change at a time.

Add no new behavior during refactor. New behavior means a new RED test first — that is the next cycle, not this one.

## Stop signal

If a "refactor" requires changing a test's assertions, it is not a refactor — you are changing behavior. Back out, and drive that change with a failing test instead.
