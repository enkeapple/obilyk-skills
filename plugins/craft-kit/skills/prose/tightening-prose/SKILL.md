---
name: tightening-prose
description: >-
  Use to remove AI writing tells from an EXISTING chunk of prose — a draft,
  pasted text, weaker-model output, or slop-laden human input — by running a
  fixed catalog the model's own taste reliably misses. NOT a prevention pass on
  a strong model's fresh output (already clean). Triggers on: "tighten this",
  "de-slop", "remove the AI tells", "make this less AI", "cut the fluff/slop",
  "почисти текст", "убери воду из текста", "сделай прямее", "де-слоп".
---

# Tightening Prose

Run a fixed-catalog de-slop pass over an **existing** chunk of prose — a draft, pasted text, weaker-model output, or slop-laden human input. A strong model's own taste removes the obvious tells but reliably leaves a long tail (empty adverbs, binary-contrast crutches, false agency); the catalog closes that gap.

## When to use

On demand, against text that already exists and reads "AI". This is NOT a prevention pass on a strong model's own fresh output — that is already clean, so the pass is a no-op there. Apply only to the prose body; never to code, identifiers, or data.

## Register first — what is NOT slop here

Before cutting, fix the register. In a **technical-doc** register these are deliberate, not tells — leave them:

- **Em-dashes** and short **fragments** used for density.
- Hedges that carry real information — "likely", "unverified", "approximately". Cut only *empty* softeners ("really", "just"), never a hedge that marks genuine uncertainty.
- Precise adverbs that change meaning ("atomically", "lazily"). Kill only adverbs that add no information.

A blanket "ban all em-dashes / all -ly words" is wrong for technical docs and is the main way an imported anti-slop catalog backfires.

## The pass (in order)

1. **Throat-clearing openers** → state the point. ("Here's the thing", "It turns out", "The reality is".)
2. **Emphasis crutches & performative** → delete. ("Let that sink in", "Make no mistake", "I promise".)
3. **Business jargon** → plain verb. ("leverage" → use, "navigate" → handle, "unpack" → explain, "deep dive" → analysis.)
4. **Empty adverbs / softeners** → cut (keep informative ones — see Register).
5. **Name the actor** → kill false agency ("the decision emerges", "X follows naturally"); un-hide passive ("was decided" → who decided).
6. **Binary-contrast & negative-listing crutches** → the direct claim. ("It's not X, it's Y" → "The point is Y"; "Not A. Not B. C." → "C".) An em-dash that *forms* the contrast is consumed here; a parenthetical em-dash stays (see Register).
7. **Vague declaratives** → the specific thing, or cut. ("The stakes are high", "the implications are significant".)
8. **Meta-commentary** → delete. ("As we'll see", "Let me walk you through".)

Full catalogs: [phrases.md](./references/phrases.md), [structures.md](./references/structures.md). Worked before/after, including a leave-it-alone technical case: [examples.md](./assets/examples.md).

## Final check (lightweight)

Re-read once and score 1–10 on **directness** (no hedging/throat-clearing) and **density** (every sentence earns its place). Below ~7 on either → another pass. The full 5-dimension rubric lives in [structures.md](./references/structures.md).

## Red Flags — STOP

- Rewriting code, identifiers, or quoted data as if it were prose.
- Cutting a hedge that marks real uncertainty, or an adverb that carries meaning.
- "Fixing" deliberate em-dashes / fragments in a technical doc.
- Running this on a strong model's own fresh output and calling the no-change result a "pass".
- Changing the meaning to make a sentence punchier — tightening preserves claims.
