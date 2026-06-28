# Before / After Examples

Worked transformations to emulate. The last one is a **leave-it-alone** technical case — the most important one for this skill, because it shows the register carve-out in action.

## 1 — Throat-clearing + false agency + jargon

**Before:**

> Here's the thing: when it comes to rate limiting, it's not just about blocking traffic — it's about protecting the system. The token-bucket algorithm leverages an elegant mechanism, and the decision to use Redis emerges naturally from our requirements.

**After:**

> Rate limiting protects the backend from a single client's burst. A token bucket bounds the sustained rate while allowing short bursts; Redis holds the shared bucket state so the limit stays global across instances.

Cut: throat-clearing ("Here's the thing", "when it comes to"), binary-contrast crutch ("not just X — it's Y"), empty adverb ("elegantly" → removed), false agency ("the decision emerges naturally" → named the reason). Note the em-dash is **kept** — it carries a parenthetical, not drama.

## 2 — Vague declarative + telling-not-showing

**Before:**

> The stakes are high. This is genuinely hard. The implications are significant.

**After:**

> A wrong limit either rejects paying customers (429s on valid traffic) or lets one client exhaust the database connection pool.

Replaced three importance-claims with the specific failure they were gesturing at.

## 3 — Meta-commentary + rhetorical setup

**Before:**

> Let me walk you through the design. What if we could just let the bucket refill over time?

**After:**

> The bucket refills at a fixed rate up to its capacity.

Cut the structure-announcement and the rhetorical question; stated the mechanism.

## 4 — Leave it alone (technical register)

**Before (already good — do NOT change):**

> The read-modify-write must be atomic — two concurrent requests for the same key cannot both spend the last token. Refill is computed lazily. No background ticker, no sweep over dormant buckets.

A naive anti-slop pass would flag the em-dash, the adverbs ("atomically", "lazily"), and the fragment ("No background ticker, no sweep…"). All three are **correct here**: the em-dash is parenthetical, the adverbs carry technical meaning, and the fragment is deliberate density. Tightening must leave this untouched.
