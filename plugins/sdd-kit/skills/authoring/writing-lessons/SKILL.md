---
name: writing-lessons
description: >-
  Use when a session exposed a wrong assumption, a hallucinated symbol or API,
  a test that passed for the wrong reason, a library/version pitfall, or a
  surprising failure worth not repeating — and when you notice you have hit the
  same class of problem before. Triggers on: "lesson learned", "capture this",
  "note this for next time", "this happened before", "should this be a rule".
---

# Lessons Learned Protocol

Capture a lesson so a future session does not repeat it, and promote a lesson to a durable rule once it recurs.

The log lives at `.claude/lessons-learned.md`. It is a **transient backlog** of un-promoted candidate rules: new entries go at the top of `## Entries`; when a cause-tag is promoted to (or already covered by) a rule, its entry bodies are **deleted** and the tag is recorded in the `## Promoted clusters` ledger at the bottom — git keeps the history (`git log -S '<cause-tag>'`). Deletion happens only via this skill, inside a confirmed promotion. The promotion path turns a recurring lesson into an actionable rule under `.claude/rules/`.

Project-agnostic: paths and rule topics adapt to the repo. A filled example is in [assets/lessons-template.md](./assets/lessons-template.md).

## When to use

Capture a lesson only when **both** conditions hold (the bar):

- **(A) Reusable check** — you can name a concrete check / Prevention a future session will actually run.
- **(B) Recurring class** — it is an error *class* a competent future agent would repeat (non-obvious; plausibly recurs), not a one-off tied to this exact spot.

Turns that pass the bar look like:

- A non-obvious bug got fixed, or a wrong assumption was caught mid-task ("I thought function X existed").
- A hallucinated symbol/API/skill-name, or a test that passed for the wrong reason.
- A library/version pitfall bit you.
- You notice you are hitting a problem you have seen before — check the log and the recurrence count.

These genuine-failure classes are MUST-capture — do not let the bar talk you out of them.

## When NOT to use

Most turns produce no lesson — that is normal, not a skipped step. Do not capture when:

- The negative test fires: all you'd write is "today I did X" with no reusable check (fails (A)).
- A one-off tied to this exact spot that a future agent would not repeat (fails (B)).
- Routine typos or changelog-style notes — the git log already does that.
- A lesson already encoded in `.claude/rules/` — re-capturing wastes the log.

## Two levels — keep the log quiet

Lessons must not nag every session. Two levels keep it quiet:

- **`.claude/lessons-learned.md` is an on-demand backlog.** It is NOT loaded into every session. Read it only at capture time, or when you suspect you are repeating a past mistake. It stays small because promoted clusters leave it (only a ledger line remains).
- **`.claude/rules/` is the small always-on distillate.** Only a cluster that crossed the threshold gets promoted here. Promotion is the filter that keeps always-on guidance short — most lessons stay in the archive and never load by default.

So "I've hit this before" comes from the few promoted **rules**, not from re-reading the whole log. This skill activates at a capture or recurrence moment — it is not a per-task gate.

## Before capturing: dedup against rules and the ledger

The log holds only un-promoted candidates. Before appending, derive the cause-tag and check the `## Promoted clusters` ledger AND the rules under `.claude/rules/` for that class:

- **Covered, and the rule handles this instance** → SKIP — do not add an entry; the rule already carries the guidance.
- **Tag is in the ledger but the rule is too narrow for this variant** → SCALE the rule now via `writing-rules`; do NOT add a backlog entry (a promoted tag never re-enters `## Entries`).
- **Not covered** → add/increment an entry in `## Entries` (below).

## Capture an entry

Append at the **top** of `## Entries` using the template in [assets/lessons-template.md](./assets/lessons-template.md) — every field it lists is required (the template is the authoritative field set).

**Cause-tag is the load-bearing field.** It is a short kebab-case key for the root-cause *class* (e.g. `hallucinated-symbol`, `dep-upgrade`, `wrong-assumption`). **REUSE an existing tag** when the cause matches an earlier entry — identical tags are what make a cluster countable. Only a genuinely new cause class gets a new tag. Inventing a fresh tag for an existing cause hides recurrence and defeats promotion.

## Promotion-debt scan (run on every capture)

After appending, tally the cause-tags so a crossed threshold cannot slip:

```bash
grep -oE '^[[:space:]]*-[[:space:]]+\*\*Cause-tag[^[:alnum:]]+[a-z0-9-]+' .claude/lessons-learned.md \
  | sed -E 's/.*Cause-tag[^[:alnum:]]+//' | sort | uniq -c | sort -rn
```

Any tag with **count ≥ 3** that is NOT in the `## Promoted clusters` ledger is **promotion debt** — promote it now, or add a ledger line stating why it does not generalize. Under the backlog model promoted tags are deleted from `## Entries`, so any tag still at count ≥ 3 here is always live debt. (Threshold 3 is the rule of three; lower it to 2 if you want earlier promotion. If a Stop hook automates this tally, it is a backstop — still run the scan yourself.)

## Promotion path: lesson → rule

When the scan flags a cause-tag at the threshold with no ledger line, it is a pattern, not a one-off. Do not decide by gut: follow the full procedure in [references/promotion.md](./references/promotion.md) — it dispatches an independent reviewer ([assets/promotion-reviewer-prompt.md](./assets/promotion-reviewer-prompt.md)) and, on a **Promote** verdict, drives authoring the rule via `writing-rules`, deleting the contributing entry bodies, and recording the ledger line, all in one commit.

## Always change behavior now

Capturing a lesson that does not change what you do next is filler. Apply the Prevention in the current session before moving on — a lesson is an instruction (a check someone runs), not a journal entry ([assets/lessons-template.md](./assets/lessons-template.md) shows the good-vs-bad split).

## Red Flags — STOP

- Writing an entry with no **Cause-tag**, or inventing a new tag for a cause that already has one.
- Deleting an entry body OUTSIDE a confirmed-promotion change (the only standalone deletion allowed was the one-time backlog cleanup).
- An entry that reads like a changelog ("today I fixed…") with no Prevention.
- A cause-tag at count ≥ 3 with nothing promoted and no ledger line.
- "Promote it" leaving the rule inside the lessons file instead of `.claude/rules/`.
- Promoting on a single occurrence — one incident does not generalize.

## Verification

After capturing or promoting:

```bash
git diff --stat -- .claude/lessons-learned.md .claude/rules/
```

The diff shows a capture as one added entry; a promotion as the new/extended rule + the deleted entry bodies + the ledger line, all in one commit. Then re-run the promotion-debt tally (above) — it must show no untracked cause-tag at count ≥ 3.
