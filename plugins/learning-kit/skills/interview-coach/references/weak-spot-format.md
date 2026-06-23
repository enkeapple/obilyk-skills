# Weak-spot format — the slip record with counts and promotion

Adapted from the "teach" skill's LEARNING-RECORD format: a record captures *that* a recurring slip exists and *why* it changes what to drill next. These live in the standing record's **Open weak-spots** section (one entry each) and drive what the next session drills first.

## Entry format

Each weak-spot is one entry:

- **Title** — a concise name for the slip (e.g. "Blames inputs on AI-mistake questions").
- **The slip** — *class asked → class answered*: the answer-class the question demanded and the class the user actually gave instead.
- **Why it matters** — one line on how this reads to an interviewer (e.g. "lands as dodging / not owning the failure").
- **Count** — how many sessions the same slip recurred. Increment on each recurrence; this is what drives promotion.
- **Status** — `open` until the user answers this class clean **twice**, then `retired`.

## Promotion to a hard rule

When **Count reaches 3**, promote the weak-spot into the standing record's **Hard rules (promoted)** section as a short imperative the user re-reads before each session (e.g. "Answer the AI-mistake question with an AI mistake, not a requirements gap"), and record the count it promoted at. The recurring-slip-becomes-a-rule mechanism is the whole reason the workspace persists counts across sessions.

## Rules

- **Record real recurring slips, not one-offs** — a single fumble isn't a weak-spot; a pattern is.
- **One slip per entry**; don't bundle.
- **Keep the count honest** — only bump when the *same* class-slip recurs.
- **Retire on evidence** — two clean on-class answers, not one.
