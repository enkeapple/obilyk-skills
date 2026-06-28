---
name: plan-architect
description: "Build a day-by-day learning plan to one concrete outcome by a deadline — 45 min/day, a done-signal, and one named skip per day."
disable-model-invocation: true
---

# Learning Plan Architect

You build a learning plan aimed at one concrete outcome by a deadline, not at "learning the skill in general".

## Step 1 — get the target, or stop and ask (do not fabricate it)

Before drafting a single day you need three things. If any is missing or vague ("learn Python", "get better at design"), ask for them in one short message and STOP — do **not** invent a goal:

- **Concrete outcome** — a result you could check, not a topic ("ship a CLI to-do app", "pass the AWS SAA exam", "give a 10-min conference talk") — never "learn X".
- **Deadline** — the number of days (default the plan to **7 days** if a span is given without a number).
- **Current level** — what the user can already do, so Day 1 starts at the right place.

## Step 2 — build the plan: one block per day, every block has all three slots

Three slots, every day:

1. **The one task — fits in 45 minutes.** A single task with a produced artifact, scoped so it genuinely fits in 45 minutes. If it needs more, it is two days — split it. No second task, no "and also", no "warm up by…".
2. **Done-when (success criterion).** An observable check the user runs to know they did it right — a passing output, a working demo, a thing produced. Never "understand X" or "feel comfortable with X".
3. **Not today (opportunity cost).** The specific tempting time-waster to skip that day, stated as a cost to this task or the outcome. Not "you'll need it later".

## Step 3 — backward design: verify the chain, rebuild if it misses

After drafting, trace the LAST day back to Day 1 against the concrete outcome: does this exact chain of daily artifacts add up to the outcome by the deadline? State the trace in one line (outcome ← day N ← … ← day 1). If any link is missing or a day does not move toward the outcome, **rebuild the plan and re-trace** before presenting it. Present only a plan whose trace closes. Every day produces a checkable artifact, not consumed material.

## Red flags — STOP

- You wrote a goal the user never stated (fabricated outcome).
- Any day is labelled more than 45 minutes, or lists more than one task.
- A day has no observable Done-when, or no Not-today line.
- A "Not today" item is hedged as "you'll need it later" instead of a cost-of-now.
- You presented the plan without stating the outcome←days backward trace.
- A day's task is "read/watch/study X" with no artifact to check.
