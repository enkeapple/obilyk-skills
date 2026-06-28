---
description: "Format reference for the interview-coach workspace — mission, resources, answer bank, and open weak-spots sections."
---

# Workspace format — interview-coach standing record

Four sections of `docs/learning/interview-prep.md`, each with its format rules.

## Mission

Grounds every question and drill: a question that doesn't serve the mission is noise. Capture it before the first drill; a vague mission gets an interview, not a guess.

**Required sections:**

- **Mission header** — `Mission: <role/level> interview at <where>, <date>`. Name the concrete interview, not "get better at interviews".
- **Why** — 1–3 sentences on what changes if the user lands this. Concrete stakes, not "do well".
- **Success looks like** — a bulleted list of the observable things they must be able to do on the day: the question classes they must answer clean (e.g. "tell an AI-mistake story where the AI, not the inputs, was wrong, and I caught it"), the dimensions being judged (depth, ownership, communication).
- **Constraints** — time before the interview, format (live coding / system design / behavioral), language, anything that shapes the prep.
- **Out of scope** — question areas explicitly not prepping now, to keep focus.

**Rules:**

- **One mission per workspace.** A different interview gets its own `docs/learning/` workspace.
- **Specificity wins.** "Pass the Principal AI Engineer behavioral round on the 24th" beats "interview prep".
- **Vague mission → pushback.** If the user can't name the role, date, or what they're judged on, interview them before writing.
- **Update when it changes** (date moves, round type changes); don't leave stale guidance.
- **Keep it under one screen** — it's a compass, not a plan.

## Resources

Coaching grounded in the real interview context beats generic advice. A bare link is useless in a week — annotate every entry with when to reach for it.

**Required sections:**

- **The role** — the job description / posting, and any notes on what this company/team weights. One line on what each implies for the prep.
- **Real material** — actual artifacts: a transcript of a prior interview or screening (e.g. a recorded mock), recruiter notes, the take-home prompt. These are gold — drill against the *actual* questions asked, not invented ones.
- **Strong-answer examples** — vetted examples of what a strong answer to a given class looks like (a write-up, a known framework like STAR, a colleague's answer). Note which question-class each one models.

Optional **Gaps** — question areas where no good reference exists yet, flagged for research.

**Rules:**

- **Vet the source.** Real transcripts, the actual JD, recognized frameworks, experienced interviewers — not generic "top 10 interview questions" listicles.
- **Annotate for use.** Every entry: what it is + one line on when to consult it.
- **Curate, don't hoard.** Five sharp resources beat thirty mediocre ones; drop what proved unhelpful.
- **Prefer the user's real context** (their transcript, their JD) over invented scenarios whenever available.

## Answer bank

The canonical, compressed answer per question-class. This is what the user reviews right before the real interview. Add an entry **only once the answer landed clean in a drill** — the bank holds rehearsed answers, not drafts.

**Entry format** (keyed by question-class, not by a single question):

- **Question-class** (bold) — the canonical name of the class (e.g. `AI-mistake incident`, `owned tradeoff`, `conflict with a stakeholder`).
- **Triggers** — example phrasings an interviewer uses to ask this class, so the user recognizes it live.
- **The answer** — the user's rehearsed answer in **their own words** (never the coach's words), following the technique skeleton for that class (e.g. situation → what happened → how they responded → result/what changed). One tight paragraph or a few bullets.
- **_Watch for_** — the slip this answer must avoid (the off-class drift the user kept making), drawn from the matching weak-spot.

**Rules:**

- **Own words only.** An answer written by the coach is not rehearsed; make the user produce it, then record theirs.
- **One answer per class**, reused across phrasings — don't memorize per-question.
- **Keep it tight** — interview-length, not an essay; the bank is for last-minute review.
- **Cross-link the weak-spot** it resolves, so a regression is visible.
- **Update as it sharpens** — revise the entry when a later drill produces a better version.

## Open weak-spots

A record of recurring slips with counts — drives what the next session drills first. Lives in the standing record's **Open weak-spots** section (one entry each).

**Entry format:**

- **Title** — a concise name for the slip (e.g. "Blames inputs on AI-mistake questions").
- **The slip** — *class asked → class answered*: the answer-class the question demanded and the class the user actually gave instead.
- **Why it matters** — one line on how this reads to an interviewer (e.g. "lands as dodging / not owning the failure").
- **Count** — how many sessions the same slip recurred. Increment on each recurrence; this is what drives promotion.
- **Status** — `open` until the user answers this class clean **twice**, then `retired`.

**Promotion to a hard rule:**

When **Count reaches 3**, promote the weak-spot into the standing record's **Hard rules (promoted)** section as a short imperative the user re-reads before each session (e.g. "Answer the AI-mistake question with an AI mistake, not a requirements gap"), and record the count it promoted at. The recurring-slip-becomes-a-rule mechanism is the whole reason the workspace persists counts across sessions.

**Rules:**

- **Record real recurring slips, not one-offs** — a single fumble isn't a weak-spot; a pattern is.
- **One slip per entry**; don't bundle.
- **Keep the count honest** — only bump when the *same* class-slip recurs.
- **Retire on evidence** — two clean on-class answers, not one.
