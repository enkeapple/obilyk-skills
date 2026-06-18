---
name: lessons-learned-protocol
description: >-
  Use when a session exposed a wrong assumption, a hallucinated symbol or API,
  a test that passed for the wrong reason, a library/version pitfall, or a
  surprising failure worth not repeating — and when you notice you have hit the
  same class of problem before. Triggers on: "lesson learned", "capture this",
  "note this for next time", "this happened before", "should this be a rule".
---

# Lessons Learned Protocol

Capture a lesson so a future session does not repeat it, and promote a lesson to a durable rule once it recurs.

The log lives at `.claude/lessons-learned.md`. It is **append-only**: new entries go at the top of `## Entries`, nothing is rewritten or deleted. A `## Promoted clusters` ledger sits at the bottom. The promotion path turns a recurring lesson into an actionable rule under `.claude/rules/`.

Project-agnostic: paths and rule topics adapt to the repo. A filled example is in [references/lessons-template.md](references/lessons-template.md).

## When to use

- A non-obvious bug got fixed, or a wrong assumption was caught mid-task ("I thought function X existed").
- A hallucinated symbol/API, or a test that passed for the wrong reason.
- A library/version pitfall bit you.
- You notice you are hitting a problem you have seen before — check the log and the recurrence count.

## When NOT to use

- Routine typos or changelog-style notes ("today I fixed X") — the git log already does that.
- A lesson already encoded in `.claude/rules/` — re-capturing wastes the log.

## Two levels — keep the log quiet

Lessons must not nag every session. Two levels keep it quiet:

- **`.claude/lessons-learned.md` is an on-demand archive.** It is NOT loaded into every session. Read it only at capture time, or when you suspect you are repeating a past mistake. It can grow without polluting context.
- **`.claude/rules/` is the small always-on distillate.** Only a cluster that crossed the threshold gets promoted here. Promotion is the filter that keeps always-on guidance short — most lessons stay in the archive and never load by default.

So "I've hit this before" comes from the few promoted **rules**, not from re-reading the whole log. This skill activates at a capture or recurrence moment — it is not a per-task gate.

## Capture an entry

Append at the **top** of `## Entries` using the template in [references/lessons-template.md](references/lessons-template.md) — every field required (Cause-tag, Symptom, Root cause, Wrong approach, Correct approach, Prevention).

**Cause-tag is the load-bearing field.** It is a short kebab-case key for the root-cause *class* (e.g. `hallucinated-symbol`, `dep-upgrade`, `wrong-assumption`). **REUSE an existing tag** when the cause matches an earlier entry — identical tags are what make a cluster countable. Only a genuinely new cause class gets a new tag. Inventing a fresh tag for an existing cause hides recurrence and defeats promotion.

## Promotion-debt scan (run on every capture)

After appending, tally the cause-tags so a crossed threshold cannot slip:

```bash
grep -oE 'Cause-tag\*\*:[[:space:]]*[a-z0-9-]+' .claude/lessons-learned.md \
  | sed -E 's/.*:[[:space:]]*//' | sort | uniq -c | sort -rn
```

Any tag with **count ≥ 3** that is NOT in the `## Promoted clusters` ledger is **promotion debt** — promote it now, or add a ledger line stating why it does not generalize. (Threshold 3 is the rule of three; lower it to 2 if you want earlier promotion. If a Stop hook automates this tally, it is a backstop — still run the scan yourself.)

## Promotion path: lesson → rule

When the same cause-tag reaches the threshold, it is a pattern, not a one-off. Do not decide promotion by gut — dispatch an independent reviewer that judges whether it generalizes and at what level it belongs, using [references/promotion-reviewer-prompt.md](references/promotion-reviewer-prompt.md). It returns one of: Promote (with target rule file + actionable rule text), Keep in lessons (too situational / already covered), or Re-tag (not a real cluster).

If the reviewer says **Promote**, apply its output:

1. **Author the rule with the `writing-rules` skill**, feeding it the reviewer's drafted rule text and target path as the starting point. It owns the rule's shape — `paths` scoping, `## When`, the ✅/❌ example, the Review Checklist.

   > REQUIRED SUB-SKILL: Use `writing-rules` to write the promoted rule file at `.claude/rules/<...>.md`. Do not hand-author it here — this skill owns the *promotion decision and bookkeeping*; `writing-rules` owns the *rule's shape*.
2. Append a back-reference to each contributing entry: `→ promoted to rules/<...>.md`.
3. Add a ledger line under `## Promoted clusters`: `- <cause-tag> → rules/<...>.md (YYYY-MM-DD)`. This is what the scan reads to know the cluster is resolved.
4. Commit the new rule and the back-references + ledger line together.

The rule file is the durable artifact. The ledger only points to it — never leave the actual rule sitting inside the lessons log. If the reviewer says **Keep in lessons**, add a ledger line recording why, so the scan stops flagging it as debt.

## Always change behavior now

Capturing a lesson that does not change what you do next is filler. Apply the Prevention in the current session before moving on.

A lesson reads like an instruction (a check someone can run), not a journal entry — see the good-vs-bad examples in [references/lessons-template.md](references/lessons-template.md).

## Red Flags — STOP

- Writing an entry with no **Cause-tag**, or inventing a new tag for a cause that already has one.
- Rewriting/overwriting the log instead of appending.
- An entry that reads like a changelog ("today I fixed…") with no Prevention.
- A cause-tag at count ≥ 3 with nothing promoted and no ledger line.
- "Promote it" leaving the rule inside the lessons file instead of `.claude/rules/`.
- Promoting on a single occurrence — one incident does not generalize.

## Verification

After capturing or promoting:

```bash
git diff --stat -- .claude/lessons-learned.md .claude/rules/
```

The diff shows the entry was appended (and, for a promotion, the new rule file + back-references + ledger line all changed). Then re-run the promotion-debt tally (above) — it must show no untracked cause-tag at count ≥ 3.
