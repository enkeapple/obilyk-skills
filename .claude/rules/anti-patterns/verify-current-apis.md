---
description: 'When about to call a third-party library/framework/SDK API — or a stdlib/runtime API that may be deprecated or changed across versions — that you would otherwise write from training memory, verify the current signature/idiom against an authoritative source (the context7 MCP server, or the library''s own current docs) BEFORE writing it. Targets version-sensitive surface, not trivial stable built-ins. Training recall is not evidence of currency; label any API you could not verify as (unverified — needs doc check). Area-specific to code files; the doc check is mandatory, not optional.'
paths:
  - '**/*.{py,ts,tsx,js,jsx,mjs,cjs,go,rs,rb,java,kt,kts,php,cs,swift,scala,c,cc,cpp,h,hpp,m}'
---

# Verify Current APIs

## When

STOP and run a currency check whenever you are about to write a call to a third-party library, framework, SDK, or language-runtime/stdlib API **from memory**, and the API is plausibly version-sensitive: a stdlib function that may be deprecated, a package that may have been replaced, or a framework idiom that may have changed across major versions. Models are trained on historical code and do not distinguish current from deprecated — "I recall this works" is exactly the signal to verify, not to proceed.

## Why

A model's training data lags real library releases, so an API recalled from memory may be deprecated, removed, or replaced — and the resulting call typically still compiles and passes lint today, then breaks on a version bump or emits a deprecation that nobody traces. Verifying the current form against authoritative docs before writing is cheap; discovering a stale idiom in production is not. The check is the load-bearing act here: a strong model often knows the current form, but "often" is not a discipline — making the verification explicit is what turns a lucky recall into a guarantee.

## Implementation

**Before writing the API call, verify its current form against an authoritative source — do not rely on training recall.**

- **Query the docs first.** Use the context7 MCP server (`resolve-library-id` then `query-docs`) to fetch the current signature/idiom for the library, or read the library's own current documentation. For the Anthropic/Claude API specifically, consult the `claude-api` reference. Only after the current form is confirmed do you write the call.
- **Treat a deprecation or replacement as a hard signal**, not a warning to skip: a deprecated call that "still works" today is a latent break — use the current replacement.
- **Label what you could not verify.** If no authoritative source is reachable, write the call but mark it `(unverified — needs doc check)` inline or in your report, so a reviewer knows it rests on memory, not confirmation.

```text
❌ WRONG — written from memory, no currency check (illustrative — your stack may differ)
  # Python: deprecated since 3.12, returns a naive datetime
  def now_iso(): return datetime.datetime.utcnow().isoformat()
  user.dict()                            # Pydantic v1 idiom on a v2 project

✅ CORRECT — verified current via docs/context7 before writing (illustrative)
  # verified against current Python docs: utcnow() is deprecated → tz-aware now(UTC)
  def now_iso(): return datetime.datetime.now(datetime.UTC).isoformat()
  user.model_dump()                      # verified: Pydantic v2 replaces .dict()
  client.stream(...)                     # (unverified — needs doc check: could not reach docs)
```

## Edge Cases

- **When NOT to apply** — a trivial, stable language built-in you are certain of (`len()`, `str.split()`, basic operators, control flow). The rule targets *version-sensitive library/framework/stdlib* surface, not every line; over-checking every primitive is noise.
- **No docs reachable** — do not block the work: write the call and label it `(unverified — needs doc check)` rather than guessing silently or stalling.
- A strong model often reaches for the doc check unprompted; this rule's job is to make the check **mandatory and recorded**, so it is not skipped under time pressure.
- This rule is distinct from [framework.md](../domains/framework.md)'s Zero-hallucination Rule: that one governs the currency of claims about *this repo's own* skills/rules/hooks (verified by `Read`/`Grep`), while this one governs *external* library/SDK API currency (verified against docs/context7). Different mechanism, different target.
- See also the `writing-lessons` skill — the post-hoc capture for when a stale API does bite. Not required to apply this rule.

## Review Checklist

- [ ] Every version-sensitive third-party / stdlib / framework API introduced in this change was verified against an authoritative source (context7 or the library's current docs) before being written — not recalled from memory.
- [ ] No known-deprecated API was used where a current replacement exists (the stack's deprecations were checked).
- [ ] Any API that could not be verified is explicitly labeled `(unverified — needs doc check)`.
- [ ] Trivial, stable built-ins were not over-checked — the check was scoped to version-sensitive surface.
