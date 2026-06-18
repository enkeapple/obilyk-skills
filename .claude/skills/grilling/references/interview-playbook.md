# Interview Playbook

How to grill well. The goal is not to extract answers — it is to walk the user down every branch of the design tree until the shape is decided and shared.

## Walk the decision tree, depth-first

A design is a tree of decisions, and later decisions depend on earlier ones. Resolve them in dependency order — never ask a leaf question while the trunk is undecided.

- Start at the **riskiest / most-load-bearing** decision, not the easiest or the UI. (For "notify when items match," the matching model is the trunk; the button colour is a leaf.)
- Each answer opens the next branch. Follow it before backing out to a sibling.
- When a branch is fully resolved, say so and move to the next sibling explicitly, so the user tracks where you are.

## One question at a time, with your recommended answer

This is the core mechanic. Every question:

1. States **one** decision (never bundle).
2. Leads with **the answer you'd pick** and one line of reasoning.
3. Prefers a small **multiple-choice** set over open-ended where possible.
4. Then waits.

The recommended answer is not optional — it turns a quiz into a collaboration. The user confirms, corrects, or picks a different option, which is far faster than authoring an answer from scratch.

```text
✅ "How should matches be delivered? I'd start in-app only (notifications list)
    and add email/push later — smallest thing that delivers the value, and the
    matching engine doesn't change when you add channels. In-app only, or is a
    specific channel the actual point of the feature?"

❌ "How should notifications work? What channels? Real-time or batched? What
    about dedup? And do we need user preferences?"   ← five questions, no rec
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

As each decision resolves, record one line — this is the material the spec is built from, so do not lose it. Capture format is in [decisions-template.md](decisions-template.md).

## Knowing when to stop

Stop grilling when new questions stop changing the shape — the remaining unknowns are implementation sub-variants, not design decisions. Then move to approaches and the design presentation. Grilling forever is its own failure: the point is a decided design, not an exhaustive interrogation.

## Under time pressure

"We don't have much time" is not a reason to skip the interview — it is a reason to grill the **trunk** decisions only and let the leaves default. A three-question grill that nails the matching model beats a fast start that rebuilds it next week. Keep the gate; shrink the depth.
