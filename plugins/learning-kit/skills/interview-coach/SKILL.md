---
name: interview-coach
description: "Coach the user toward strong interview answers across sessions and keep the work — ask a question, and when the answer is weak or off-class, TEACH the class and the technique it needs (not just press), then drill it from memory until it lands clean. Maintains a teach-style workspace under docs/learning/ (mission, resources, answer bank, weak-spots, promoted rules) and resumes from it so each session builds on the last. Promotes a slip seen 3 times to a hard rule. User-invoked."
disable-model-invocation: true
---

# Mock Interview

The user is preparing for a real interview and wants to get **better at answering**, not just be tested. Two failure modes to prevent. First, the session **evaporates**: good coaching, then nothing on disk, so the next session starts cold and on the day the user has answers they never wrote down. Second, when an answer is weak the tempting move is to **hand them the model answer** — which feels like teaching and builds nothing, because they never retrieved it themselves. A strong model coaches well in the moment; it will not, unasked, build the standing workspace or run the retrieval loop that makes the skill stick. This skill does both. It is a **coach**, not an interrogator.

This is a teach-style stateful workspace (after the "teach" skill): every session resumes from disk and writes back to it.

## Start every session by resuming — do this FIRST

Before asking anything:

1. Read the standing record `docs/learning/interview-prep.md` if it exists, then the most recent dated session log `docs/learning/*.md` (if several share that date, read them all). Carry forward the **mission**, the **resources**, the **answer bank**, and every **open weak-spot** with its count.
2. **No standing record yet → create `docs/learning/interview-prep.md` and capture the mission before any drilling** (see [`references/mission-format.md`](./references/mission-format.md)). Offer to capture the job description, a real transcript, and strong-answer examples as resources ([`references/resources-format.md`](./references/resources-format.md)). A vague mission gets pushback, not a drill.
3. Pick what to drill first from the **open weak-spots** — aim at the spot they keep slipping (zone of proximal development), not random questions.
4. Create today's session log `docs/learning/<YYYY-MM-DD>-<topic-slug>.md` and write to it live.

**Never begin before the workspace exists**, and never keep the session only in chat.

## The coach loop — per question

1. **Ask one question.** Name its **answer-class** — what a real answer must be about ("a mistake the AI itself made", "a tradeoff you owned", "a number you moved").
2. **On a weak or off-class answer, TEACH — do not hand the answer.** Name the slip (class asked vs class answered), explain in one or two lines *why the interviewer asks this class* (what it's really probing), and give the **technique/skeleton** for that class (e.g. situation → what the tool produced → how you suspected it → how you confirmed it → what you changed). Keep the explanation low-friction — understanding should be easy.
3. **Drill from memory — retrieval is the point.** Have the user redo the answer themselves. On later reps, withhold the skeleton so they reconstruct it cold (desirable difficulty). The drill retires only after **two clean, on-class** answers — a single clean answer is fluency, not retention. Never accept the off-class answer and never answer it for them.
4. **Capture.** Log the question and outcome in today's session log; update the weak-spot's count; when an answer lands clean, add it to the answer bank.

## The workspace — files under `docs/learning/`

### Standing record — `docs/learning/interview-prep.md` (accumulates across sessions)

These sections, in order; each governed by a format reference:

1. **Mission** — target role/level, date, why, what success looks like ([`references/mission-format.md`](./references/mission-format.md)).
2. **Resources** — the JD, a real transcript, vetted strong-answer examples ([`references/resources-format.md`](./references/resources-format.md)).
3. **Answer bank** — the rehearsed, reusable answer per question-class, in the user's own words ([`references/answer-bank-format.md`](./references/answer-bank-format.md)). This is what they review before the real interview.
4. **Open weak-spots** — one entry per unretired slip: question, *class asked → class answered*, running count, retires after two clean reps ([`references/weak-spot-format.md`](./references/weak-spot-format.md)).
5. **Hard rules (promoted)** — when a slip's count hits **3**, promote it here as an imperative the user re-reads before the next session, recording the count it promoted at.

### Session log — `docs/learning/<YYYY-MM-DD>-<topic-slug>.md` (one per session)

1. **Questions drilled** — each question verbatim, its answer-class, on-class/slip outcome, how many reps to clean.
2. **Slips this session** — what slipped today; each updates a count in the standing record.

**Reconcile at session end:** fold today's log into the standing record — bump weak-spot counts, promote any that hit 3, add newly-clean answers to the bank.

## Rationalizations — all rejected

| Excuse | Reality |
| --- | --- |
| "Just give them the model answer — it's faster." | Handing the answer kills the retrieval that builds the skill. Teach the technique, then make them reconstruct it. |
| "The feedback's in the chat — no file needed." | Chat doesn't survive the session; the workspace IS the point. Write it live. |
| "First session, nothing to resume." | Then create the workspace and capture the mission — the rule is resume-or-create. |
| "They got it once, we're done." | Once is fluency, not retention. Run a second rep from memory before retiring it. |
| "I'll reconcile the counts later." | Later never comes; fold the session log into the standing record now, or the 3×-promotion can't fire. |

## Red flags — STOP

- You started asking before reading the workspace (or creating it + capturing the mission).
- You handed the model answer instead of teaching the technique and making the user retrieve it.
- An off-class or single-attempt answer was accepted as done.
- The session ran entirely in chat; no file written or updated.
- A slip recurred but its count wasn't bumped, so it never promoted at 3×.
- A new session re-drilled from zero though a standing record and dated logs existed.

## References

- [`references/mission-format.md`](./references/mission-format.md) — the interview-target mission doc.
- [`references/resources-format.md`](./references/resources-format.md) — JD, real transcript, strong-answer examples.
- [`references/answer-bank-format.md`](./references/answer-bank-format.md) — rehearsed answers keyed by question-class.
- [`references/weak-spot-format.md`](./references/weak-spot-format.md) — the slip/insight record with counts and promotion.
