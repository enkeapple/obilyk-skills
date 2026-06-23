# Structural Patterns & the Register Carve-out

Sentence- and paragraph-level patterns to fix, plus the scoring rubric. Pair with the phrase list in [phrases.md](./phrases.md); worked before/after in [examples.md](../assets/examples.md).

## Register carve-out — leave these alone in technical docs

The public `stop-slop` skill targets narrative prose and bans patterns that are **deliberate and correct** in a terse technical register. Do NOT "fix" these:

- **Em-dashes** — used here for parenthetical density. Not a tell.
- **Short fragments** for emphasis or list-like density ("No build. No tests. Just validators.") — keep when intentional.
- **Three-item lists** and tables — a technical doc lives on them.
- **Informative hedges** — "likely", "unverified", "approximately" carry real uncertainty; only empty softeners go.

Applying the narrative bans blindly is the main failure mode of an imported anti-slop catalog: it fights the medium.

## Structural anti-patterns to fix

- **Binary-contrast crutch** — "It's not X, it's Y" dodges the claim. State it: "The point is Y." (Keep a genuine contrast that carries information; cut the rhetorical reflex.)
- **Negative listing for drama** — "Not A. Not B. C." → go straight to "C".
- **False agency** — inanimate subjects performing human actions: "the decision emerges", "the design wants", "X follows naturally". Name who decided / what forces it.
- **Hidden actor (passive)** — "it was decided that" → say who decided. Keep passive only when the actor is genuinely irrelevant.
- **Weak starters** — Wh-openers ("What if…") and a paragraph-leading "So" that announce instead of asserting. Lead with the subject or verb.
- **Rhetorical setup** — a question posed only to answer it. Replace with the direct argument.

## Scoring rubric (5 dimensions, 1–10 each)

A heavier check than the SKILL's lightweight pass — use it when a doc is going out and you want a number.

| Dimension | High score means |
| --- | --- |
| Directness | states the point; no throat-clearing, no hedging |
| Rhythm | sentence length varies; no monotone, no forced staccato |
| Trust | trusts the reader; no over-explaining or hand-holding |
| Authenticity | no manufactured emphasis or performative sincerity |
| Density | every sentence earns its place; no filler |

Sum the five. **Below 35/50: revise.** In a technical register, weight Directness and Density highest — Rhythm and Authenticity matter less for a spec than for an essay.
