# Interview Playbook

How to grill well. The goal is not to extract answers — it is to walk the user down every branch of the design tree until the shape is decided and shared.

## Walk the decision tree, depth-first

A design is a tree of decisions, and later decisions depend on earlier ones. Resolve them in dependency order — never ask a leaf question while the trunk is undecided.

- Start at the **riskiest / most-load-bearing** decision, not the easiest or the UI. (For "notify when items match," the matching model is the trunk; the button colour is a leaf.)
- Each answer opens the next branch. Follow it before backing out to a sibling.
- When a branch is fully resolved, say so and move to the next sibling explicitly, so the user tracks where you are.

## One decision per question — sequence dependents, batch independent siblings

This is the core mechanic. Every question:

1. States **one** decision (a question carries one decision, not a grab-bag).
2. Leads with **the answer you'd pick** and one line of reasoning.
3. Prefers a small **multiple-choice** set over open-ended where possible.
4. Then waits.

The recommended answer is not optional — it turns a quiz into a collaboration. The user confirms, corrects, or picks a different option, which is far faster than authoring an answer from scratch.

**Sequence dependents; batch independent siblings.** Resolve **dependent** decisions one at a time, depth-first — never ask a leaf while its trunk is open, because the trunk's answer changes the leaf's options. But decisions that are **mutually independent** — no answer changes the options or relevance of another — may be asked together in **one message** as a short numbered set, each still carrying its own recommended answer. This cuts round-trips without the bewilderment the one-at-a-time rule guards against. Two limits keep a batch from becoming a wall: **at most 3–4** decisions per message, and **a recommended answer on every one**. When unsure whether two decisions are independent, treat them as dependent and ask sequentially — an answer invalidated by another costs more than one extra round-trip.

```text
✅ batch — three INDEPENDENT decisions, one message, a recommendation each:
   "Three independent calls on the export feature:
    1. Default format — I'd pick CSV (opens anywhere, no dep). CSV / JSON / XLSX?
    2. Action placement — I'd put Export in the toolbar (discoverable). Toolbar / row menu?
    3. Filename — I'd default to a timestamp (no collisions). Timestamp / user-named?"

✅ sequential — a DEPENDENT pair, trunk first:
   "How are matches delivered? I'd start in-app only … In-app, or is a channel the point?"
   (wait — the answer decides whether a follow-up about per-channel prefs even applies)

❌ "How should notifications work? What channels? Real-time or batched? What
    about dedup? And do we need user preferences?"   ← unbounded, no recs, and dependent
```

## Explore before you ask

A question you can answer from the repo is a wasted turn. Before asking:

- Grep / read the code, docs, recent commits for the answer.
- Ask the user only what the codebase **cannot** tell you: intent, priorities, product trade-offs, external constraints.

"What state library does this project use?" → go look. "Should saved searches sync across devices?" → ask; the code can't decide product scope.

## Good vs bad questions

| Good | Bad |
| --- | --- |
| Concrete, one decision, with a recommendation and a default. | A broad topic ("how should auth work?") with no framing. |
| About intent / priorities / trade-offs the user owns. | About facts the codebase already answers. |
| Multiple-choice with a lead option. | Open-ended essay prompt that stalls the user. |

## Keep a running Decisions log

As each decision resolves, record one line — this is the material the spec is built from, so do not lose it. Capture format is in [decisions-template.md](../assets/decisions-template.md).

## Knowing when to stop

Stop grilling when new questions stop changing the shape — the remaining unknowns are implementation sub-variants, not design decisions. Then move to approaches and the design presentation. Grilling forever is its own failure: the point is a decided design, not an exhaustive interrogation.

## Under time pressure

"We don't have much time" is not a reason to skip the interview — it is a reason to grill the **trunk** decisions only and let the leaves default. A three-question grill that nails the matching model beats a fast start that rebuilds it next week. Keep the gate; shrink the depth.
