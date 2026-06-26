---
description: 'Before writing a new function/utility/type/module — or a direct call to a raw underlying library — search the codebase for an existing implementation or wrapper that already provides the capability, and reuse or extend it instead of forking a copy or bypassing the project''s own abstraction. AI agents write net-new code without scanning for what exists; the two failure faces are duplicated logic and a raw-library call that skips an existing wrapper (logging/retries/auth baked in). Area-specific to code files.'
paths:
  - '**/*.{py,ts,tsx,js,jsx,mjs,cjs,go,rs,rb,java,kt,kts,php,cs,swift,scala,c,cc,cpp,h,hpp,m}'
---

# Reuse Before Reimplement

## When

STOP and search the codebase first whenever you are about to (a) write a new function, utility, type, constant, or module for a capability, or (b) call a raw/underlying library directly (HTTP client, persistence, config, auth, logging, serialization). The failure this prevents is writing code as if the rest of the repo does not exist — producing a fourth copy of a helper that already lives three directories away, or calling the raw library directly when the project already wraps it.

## Why

AI agents do not scan the codebase before writing; a shared utility or wrapper that exists elsewhere is invisible to them unless they look. The result is duplicated implementations that drift apart over time, and raw-library calls that bypass the logging, retries, auth, and error-handling a project deliberately centralizes in its own wrapper. Two visible faces, one root cause: code written without first searching for what already exists. Searching first is what keeps a codebase one implementation deep instead of four. This is the *operational* form of the DRY principle — concretely "search for and reuse what exists", not the over-broad "never repeat anything" reading that drives premature abstraction.

## Implementation

**Before writing the new code, run a codebase search for an existing implementation or wrapper, and prefer reusing or extending it over a fresh copy or a raw-library call.**

1. **Search by behavior and name.** Grep the whole repo — not just the current directory — for the capability's likely names (the function verb, the type noun) and for the raw library's import. A shared util "three directories away" only counts if you actually look there.
2. **If an implementation exists → reuse or extend it.** Do not fork a second copy. If it is close but not exact, extend it; only write a new one with a one-line justification for why the existing one genuinely does not fit.
3. **If a wrapper/abstraction exists → call through it, not the raw library.** When the repo exposes its own client / service / repository for a capability, use it. Reaching for the raw underlying library re-implements the behavior the wrapper centralizes (logging, retries, auth, error handling).

```text
❌ WRONG — wrote a fresh copy / used the raw lib without searching (illustrative — your stack may differ)
  # new file utils/format_date.py — but lib/dates.py already exports format_iso()
  def format_date(d): ...
  resp = httpx.AsyncClient().get(url)        # raw client; project has BaseHTTPClient (logging/retries/auth)

✅ CORRECT — searched first, reused the existing abstraction (illustrative)
  from lib.dates import format_iso           # found via grep; reused, not re-written
  resp = await http_client.get(url)          # called the project's wrapper, not raw httpx
```

## Edge Cases

- **When NOT to apply** — a genuinely new capability with no existing equivalent (the search came back empty); writing it new is then correct. The rule demands the *search*, not pretending a duplicate exists.
- **The existing one is wrong or inadequate** — reuse is not dogma: if the existing implementation is buggy or mis-fit, fixing/extending (or deliberately replacing) it beats forking a parallel copy that leaves two to maintain. State which you chose and why in one line.
- A direct raw-library call is fine when the project has **no** wrapper for that capability — the abstraction-bypass face fires only when a wrapper actually exists.
- **Tune `paths` per project.** The default glob matches common source extensions; in a repo with a single source root, narrow it (e.g. `src/**`) so the rule loads only on real source edits, not config or generated files.
- See also the `pre-implementation-protocol` skill — at its readiness gate a contract tagged NEW that duplicates an existing one is a No-go; this rule is the during-execution sibling. Not required to apply this rule.
- See also [model-selection](../common/model-selection.md) — when the codebase is large, the search for an existing implementation is best dispatched to a cheap-tier subagent rather than run on the implementer's model. Not required to apply this rule.

## Review Checklist

- [ ] Before writing new code for a capability, a whole-repo codebase search (name + behavior keywords) was run for an existing implementation.
- [ ] No second copy of a helper / util / type was created where an existing one could be reused or extended (or a one-line justification for the new one is recorded).
- [ ] Where the project exposes its own wrapper/abstraction for a capability, the code calls through it rather than the raw underlying library.
- [ ] The existing abstraction that was reused is named, or it is justified in one line why none fit.
