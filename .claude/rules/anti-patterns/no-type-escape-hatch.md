---
description: 'Do not silence the type/safety checker to reach green — no `any`, `@ts-ignore`/`@ts-expect-error` (without reason), `# type: ignore`, unchecked casts, or `unwrap()`-style force just to make an unknown type compile. Model the unknown explicitly (validate at the boundary, narrow from `unknown`, a real union) or fix the type; an unavoidable suppression needs a justified inline waiver. The escape-hatch token list is stack-specific and illustrative — tune per language. Area-specific to code files.'
paths:
  - '**/*.{ts,tsx,py,go,rs,kt,kts,swift,scala,cs}'
---

# No Type Escape Hatch

## When

STOP whenever you cannot immediately name the correct type and feel the pull to reach for an escape hatch — `any`, a blanket `@ts-ignore`, `# type: ignore`, an unchecked cast, a force-unwrap — just to make the code compile and the linter pass. That is the exact moment the rule applies.

## Why

An escape hatch does not solve the type problem — it hides it. The code compiles, the linter is green, and the unmodeled shape surfaces weeks later as a runtime error nobody can trace back to the suppression. "Pristine output" achieved by silencing the checker is fake green: the check still passes, but it now checks nothing at that point.

## Implementation

**Model the unknown instead of silencing the checker.**

- Type the boundary: validate/parse external data into a real type at the edge (a schema validator, a parser), so the inside of your code is genuinely typed.
- Use the language's *safe* unknown, then narrow: TS `unknown` + a type guard, a discriminated union, an `Option`/`Result` — not `any`, not a blind cast.
- **If a suppression is genuinely unavoidable** (a mistyped third-party lib, a known-safe cast), it gets a **single-line waiver with a reason** at the call site (`@ts-expect-error <why>`, `# type: ignore[code]  # <why>`), never a blanket file-level disable.

```text
❌ WRONG — silences the checker to move on (illustrative — your stack may differ)
  function parse(res: any) {          // any: the unknown shape is now unchecked everywhere
    return res.data.items;
  }
  user_id = payload["id"]  # type: ignore   # blanket ignore, no reason, hides a real gap

✅ CORRECT — model the unknown, narrow it (illustrative)
  const Schema = z.object({ data: z.object({ items: z.array(Item) }) });
  function parse(res: unknown) {        // unknown, then validated
    return Schema.parse(res).data.items;
  }
  user_id = int(payload["id"])  # typed at the boundary; or # type: ignore[arg-type]  # lib X mistypes this
```

## Edge Cases

- **`unknown`, generics, and a documented narrowing are NOT suppressions** — they keep the checker live. The rule forbids *defeating* the checker, not expressing genuine polymorphism.
- **A waiver at a true boundary is allowed** — a mistyped dependency or a provably-safe cast, with a one-line reason. The violation is the *unjustified* or *blanket* suppression.
- **Tune the token list per stack** — the forbidden set differs by language (TS `any`/`as`/`@ts-ignore`; Python `# type: ignore`/`cast()`-abuse; Go empty `interface{}` as a dodge; Rust `unwrap()`/`unsafe`); the principle is identical.

## Review Checklist

- [ ] No new `any` / blanket `@ts-ignore` / unreasoned `# type: ignore` / unchecked cast introduced to silence the checker (grep the stack's tokens).
- [ ] Unknown external data is modeled (validated/narrowed) at its boundary, not propagated as `any`.
- [ ] Any unavoidable suppression carries a single-line inline waiver with a reason — no file-level disables.
- [ ] "Green" was reached by typing the code, not by suppressing the check.
