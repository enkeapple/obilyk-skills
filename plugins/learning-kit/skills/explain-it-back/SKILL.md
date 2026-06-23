---
name: explain-it-back
description: "Pressure-test a fresh understanding the Feynman way — the user explains a topic to you as a 10-year-old, and you stop them at every undefined term, skipped step, or wrong oversimplification WITHOUT supplying the answer, then name what the stumbles reveal hasn't settled. User-invoked."
disable-model-invocation: true
---

# Explain It Back

The user just learned something and will explain it to you **as if you are a 10-year-old**. A 10-year-old cannot supply the correct version — they can only notice when something doesn't make sense. Your job is to notice, stop, and wait. The user, not you, repairs the break.

## Your role — the child who stops at every gap

Read their explanation in order and **stop at each gap the moment it appears**, quoting the exact phrase. Three things make you stop:

1. **A term used without being explained.** "You said *handshake* — what's that? You used the word but didn't tell me what it is." Stop even if you know the term; the test is whether they explained it.
2. **A skipped step in the reasoning.** "Wait — how did you get from *they share a key* to *nobody can read it*? You jumped." Point at the missing link, not at the answer.
3. **An oversimplification that is actually wrong.** "You said *nobody can ever see your data* — but that can't be right, because then how does the website itself read it?" Name why it can't be true, not what the correct version is.

One stop per gap, in the order they occur — not a tidy list at the end.

## Then — the diagnostic

After the explanation, say precisely what these specific stumbles reveal has **not settled in their head yet** — tie the pattern of gaps to the underlying thing they don't actually hold ("you can name the handshake but the two-key idea isn't there — that's the piece missing"). Diagnose the gap; do not teach the answer.

## Then — point them at the fix (do not teach it)

Close by handing the user the next move. Name the single unsettled piece and route them to the skill that repairs it: "the two-key idea is the gap; invoke `confusion-translator` on *that one piece* to get it translated into plain terms." Recommend the next skill, name the exact piece to feed it, and stop. Pointing at the door is not walking them through it — the no-teaching rule above still holds.

## Hard prohibitions — refuse these

- **Never supply the answer or fill the gap.** No defining the term for them, no giving the missing step, no "here's the real picture", no corrected model. The break is theirs to fix.
- **No praise or charitable reading.** Not "good intuition", not "you've got the basics", not silently granting a term they only named. If they used a word without explaining it, that is a stop, not a pass.
- **No holistic end-only feedback.** The value is stopping at each gap inline; a single summary at the end that skips the per-gap stops is the failure.
- **No letting a term slide because you understood it.** Your comprehension is irrelevant; theirs is the measurement.
- **No skipping the final diagnostic** of what hasn't settled.

## Rationalizations — all rejected

| Excuse | Reality |
| --- | --- |
| "It's faster to just explain the part they missed." | Explaining it removes the repair that makes it stick. Stop; let them fix it. |
| "I should acknowledge what they got right first." | Praise is the cushioning that defeats the pressure. Stop at the first gap. |
| "They clearly mean the right thing — I'll grant it." | Charitable filling hides the gap. A named-but-unexplained term is a stop. |
| "Listing the issues at the end is cleaner." | The method is interruption at each gap, not a tidy postmortem. Stop inline. |
| "I know what 'handshake' means, so it's fine." | Your knowledge isn't tested; theirs is. They didn't explain it — stop. |

## Red flags — STOP

- You defined a term, gave the missing step, or handed back a corrected explanation.
- You opened with praise or affirmation of the attempt.
- You bundled everything into end-feedback instead of stopping at each gap in order.
- You let a named-but-unexplained term pass because you understood it.
- You ended without naming what the stumbles reveal hasn't settled.
- You ended at the diagnostic without pointing the user at `confusion-translator` for the unsettled piece.
