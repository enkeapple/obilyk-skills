---
name: humanizing-prose
description: >-
  Use to rewrite an EXISTING draft into natural, publication-ready prose for a
  narrative / article register — a blog post, LinkedIn post, newsletter, essay,
  or marketing copy — by cutting the narrative AI tells a strong model leaves
  behind (binary contrasts, contrast em-dashes, dramatic fragments, rhetorical
  reader-gambits) that a terse technical pass deliberately keeps. For technical
  docs use `tightening-prose` instead — its carve-outs are the opposite.
  Triggers on: "polish this for the article/post/blog", "make this publish-ready",
  "rewrite this as an article", "humanize this draft", "make it read like a human
  wrote it", "под статью", "перепиши под пост/статью", "для блога", "очеловечь
  текст", "подготовь к публикации".
---

# Humanizing Prose

Rewrite an **existing** draft into natural, publication-ready prose for a **narrative / article register** — blog post, LinkedIn post, newsletter, essay, marketing copy. A strong model removes the loud AI tells (throat-clearing, "Let that sink in") on its own, but reliably leaves a long tail of *narrative* tells: binary contrasts, contrast-forming em-dashes, dramatic fragments, rhetorical reader-gambits. This pass closes that gap.

## When to use

On demand, against narrative text headed for publication that still reads "AI".

## These ARE tells here — the inverted carve-out

What a technical pass *keeps*, a narrative article must *cut*. This inversion is the whole reason the skill is separate:

- **Contrast / parenthetical em-dashes** → recast as a clean sentence. The reflexive em-dash is the single loudest AI tell in narrative prose.
- **Binary-contrast crutch** — "It's not X, it's Y" / "isn't about A. It's about B" → state the claim directly: "Y." The model reaches for this by reflex; cut it every time.
- **Dramatic fragments** — "Not luck. Not connections. Consistency." → one sentence.
- **Rhetorical reader-gambits** — "What if you could…?", "The question is whether you'll be one of them." → make the assertion.
- **Negative listing for drama** and **staccato monotone** → vary sentence length; state things straight.

## The pass (in order)

1. **Throat-clearing openers** → state the point. ("Here's the thing", "The reality is", "When it comes to".)
2. **Emphasis crutches & performative** → delete. ("Let that sink in", "Make no mistake", "Plot twist:", "Period.".)
3. **Business jargon** → plain verb. ("leverage" → use, "deep dive" → analysis, "unpack" → explain.)
4. **Empty adverbs & filler** → cut. ("genuinely", "truly", "at the end of the day", "in today's fast-paced world".)
5. **Name the actor** → kill false agency. ("the decision emerges naturally" → say who decides, or why it follows.)
6. **Apply the inverted carve-out above.**
7. **Vague declaratives** → the specific thing, or cut.
8. **Meta-commentary** → delete. ("As we'll see", "Let me walk you through".)

Full phrase catalog: [phrases.md](./references/phrases.md). Structural catalog and the register-contrast table: [narrative-tells.md](./references/narrative-tells.md). Worked before/after: [examples.md](./assets/examples.md).

## Final check (lightweight)

Re-read once and score 1–10 on **directness** (no hedging/throat-clearing) and **density** (every sentence earns its place), then ask: does any sentence still read "AI" — an em-dash contrast, a binary-contrast reflex, a rhetorical gambit? Any surviving tell → another pass. The full 5-dimension rubric lives in [scoring-rubric.md](../shared/scoring-rubric.md).

## Red Flags — STOP

- Running this on a **technical doc** — use `tightening-prose`; here you would strip meaningful em-dashes, adverbs, and fragments.
- Keeping a binary contrast or contrast-em-dash because it "sounds punchy" — that *is* the tell.
- Changing the meaning to make a line snappier — humanizing preserves claims.
- Rewriting code, identifiers, or quoted data as if it were prose.
- Running this on a strong model's own fresh output and calling the no-change result a "pass".
