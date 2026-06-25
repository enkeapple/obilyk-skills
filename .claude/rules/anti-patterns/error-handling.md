---
description: 'Every error path must have defined behavior — handle it meaningfully or propagate it — never silently swallow. Forbids empty/bare catch blocks and catch-all handlers that log-and-continue where the caller needs to know the operation failed. AI defaults to the happy path (error gaps appear ~2x more often in AI code); this is the explicit counter. Area-specific to code files.'
paths:
  - '**/*.{py,ts,tsx,js,jsx,mjs,cjs,go,rs,rb,java,kt,kts,php,cs,swift,scala}'
---

# Error Handling — Handle or Propagate, Never Swallow

## When

STOP and decide the failure behavior whenever you write code that can fail — file/network/DB I/O, parsing, external calls, anything throwing or returning an error. The default AI failure is to write only the happy path and bolt on a catch-all that hides the error.

## Why

A swallowed error does not disappear — it becomes a silent wrong-state bug discovered far from its cause. AI code shows error-handling gaps roughly twice as often as human code because the model optimizes for "make the happy path run." Every `catch`/`except` is a decision point, not boilerplate.

## Implementation

**Every error you catch must either be handled meaningfully or propagated — never caught-and-ignored.**

- **Handle** = recover, substitute a defined default *with a logged reason*, or translate the error into a result the caller can act on.
- **Propagate** = rethrow / return the error so the caller decides. When in doubt, propagate.
- **No empty or bare catch.** No `except:` / `catch (e) {}` / `catch (e) { /* ignore */ }` that discards the error.
- **Catch the narrowest type you can actually handle**; let everything you cannot handle propagate. A broad catch-all is allowed only at a deliberate boundary (request handler, job runner, `main`, event loop) where its job *is* to convert any failure into a response/log — that is handling, not swallowing.

```text
❌ WRONG — swallows; caller never learns it failed (illustrative — your stack may differ)
  try:
      data = json.loads(open(path).read())
  except:                      # bare, catches everything, including bugs
      data = {}                # silent default, no log, no signal

  try { await save(x); } catch (e) {}        // empty catch — error vanishes

✅ CORRECT — handle with a reason, or propagate (illustrative)
  try:
      data = json.loads(open(path).read())
  except FileNotFoundError:
      log.warning("config %s missing; using defaults", path)
      data = {}                # defined default WITH a logged reason
  # JSONDecodeError is NOT caught here → propagates (a corrupt file is a real error)

  try { await save(x); }
  catch (e) { throw new SaveError(`save failed for ${x.id}`, { cause: e }); }  // propagate
```

## Edge Cases

- **Deliberate boundary catch-all is fine** — a top-level handler that turns any exception into a 500/log/user-message is handling, not swallowing, as long as it is the outermost boundary and does not hide failures the inner caller needed.
- **A component that must fail-open by design** (e.g. a non-critical hook/guard that must never break the host) is a deliberate, documented swallow — that is a stated exception, not a violation. Such a component should say so at the catch site.
- **When NOT to apply** — code that genuinely cannot fail (pure in-memory transforms with no throwing call).

## Review Checklist

- [ ] No empty/bare catch block in the change (grep: `except:` , `catch\s*\([^)]*\)\s*\{\s*\}`).
- [ ] Each catch either logs+recovers with a reason or rethrows/returns the error — none catches-and-continues where the caller needed the failure.
- [ ] Catch types are as narrow as the handling allows; broad catch-alls sit only at a deliberate outer boundary.
- [ ] Any intentional fail-open swallow is annotated as such at the catch site.
