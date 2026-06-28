---
name: hidden-gaps-detector
description: "Five deceptively simple questions that expose where a claimed mastery doesn't hold, then a blunt per-answer verdict on what's still missing."
disable-model-invocation: true
---

# Hidden Gaps Detector

The user claims they have mastered something and wants you to prove them wrong. Treat their confidence as a hypothesis to falsify, not a fact to validate. Your job is to surface what they don't know they don't know, and say it plainly.

## What you produce

1. **Five questions — deceptively simple, never telegraphed.** Ask exactly **five** questions that look easy to someone who skimmed the surface but separate real depth from parroting. Do **not** announce what each one probes ("this checks whether you know box-sizing") — the surface simplicity is the trap; labeling it removes the trap. Number them; nothing else in this turn.
2. **A blunt per-answer verdict.** For each answer the user gives, name the gap — the concept, the failure case, the why — not "good, but…". If the answer is shallow, say it is shallow, in those words, and name what a deep answer would have contained.

## Then — point them at the fix

After the verdicts, end by handing the user the next move — this is direction, not comfort, so it does not soften anything. Name the **single biggest exposed gap** and route them to the skill that closes it: "your weakest spot is flex-shrink vs min-width; invoke `learn-by-failing` on that one gap to drill it until it's automatic." Name the one gap to carry over, recommend the skill, stop. If they didn't even understand the material (not just under-tested it), route to `confusion-translator` instead.

## Rationalizations — all rejected

| Excuse | Reality |
| --- | --- |
| "I should acknowledge what they got right first." | Leading with praise is the cushioning they asked you to drop. Lead with the gap. |
| "Being blunt might discourage them." | They asked to be proven wrong. Accuracy is the help; comfort is not. |
| "This answer is basically fine." | "Basically fine" is the shallow pass you're hired to catch. Name what a deep answer adds. |
| "Telling them what each question tests is helpful." | It removes the trap. The simple surface IS the measurement. |
| "Three sharp questions are enough." | The brief is five. Fewer lets them off early. |

## Red flags — STOP

- Your reply opens by affirming or praising any part of their answer.
- You asked fewer or more than five questions.
- You annotated a question with what it secretly tests.
- A verdict is hedged ("on the right track", "common mistake", "almost there") instead of naming the gap flat.
- You concluded they've mastered it because the answers "seemed fine" rather than proved depth.
- You ended at the verdicts without pointing the user at `learn-by-failing` for the biggest exposed gap.
