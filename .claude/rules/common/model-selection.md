---
description: >-
  When dispatching a subagent or workflow agent, assign its model to a DIFFERENT
  one from the implementer for review passes, so the reviewer does not inherit the
  implementer's blind spots. Reading/explore roles take the cheapest tier; an
  implement role takes the cheapest tier that reliably does it. Each dispatch
  carries a one-line cost rationale.
---

# Model Selection by Role

## When

STOP and choose the model deliberately whenever you spawn work in a separate context — an `Explore`/research subagent, an implementer subagent, a reviewer subagent, or a `Workflow` `agent()` call with a `model` option. Applies to every dispatch, in any mode (AUTHOR / AUDIT / APPLY) and in a consumer repo.

## Why

Two distinct levers, with one weak by default and one strong:

- **Cost-tiering** (cheap model for reading, capable model for hard work) a strong caller usually already applies on its own — keep it, but it is not where the value is.
- **Reviewer-model diversity is the lever that does not happen by default.** A reviewer left on the implementer's model inherits its failure modes and rationalizations and tends to ratify the same mistakes — even with fresh context. Forcing a *different* model is a genuinely independent pass, and one a capable agent will skip unless told (it reasons "review is as hard as writing, keep it on the strong model" and reuses the implementer's model).

## Implementation

Pick the model by the dispatched agent's **role**, and state the cost rationale in the dispatch (one line, so the choice is auditable):

- **review → a model DIFFERENT from the one that implemented (the load-bearing rule).** This is the lever a capable agent skips by default — it reuses the implementer's model, reasoning "review is as hard as writing". For a routine per-task review prefer a different, often *cheaper* tier: independence, not raw power, is what catches the implementer's blind spots, and it saves tokens. For the final whole-change or high-risk review use the most-capable tier — but still a different model than the implementer where the harness offers more than one. _Rationale: the model switch buys defect-catching a same-model reviewer structurally cannot._
- **cost-tiering of the other roles (a strong caller usually already does this — light scaffolding, not the point):** a read-only research/explore role takes the cheapest capable tier (bulk-token, low-judgment); a well-specified implement task takes the cheapest tier that reliably does it (count turns, not just per-token price), escalating to the most-capable tier only for subtle, correctness-critical, or multi-file integration work. Do NOT default every implement task to the premium model.

Name **tiers**, not a fixed model — the current Claude mapping is illustrative (cheap ≈ Haiku, standard ≈ Sonnet, most-capable ≈ Opus) and will shift as models are renamed.

```text
❌ WRONG — caller's premium model inherited for everything; reviewer == implementer.
  dispatch(explore "map the auth module")        model: opus    # premium model just to read files
  dispatch(implement "add one well-specified fn") model: opus    # mechanical task overpaying
  dispatch(review the diff)                       model: opus    # same model → same blind spots

✅ CORRECT — model by role, each with a cost rationale, reviewer differs from implementer.
  dispatch(explore "map the auth module")        model: haiku   # bulk-token read role → cheapest tier
  dispatch(implement "add one well-specified fn") model: sonnet  # mechanical, full spec → standard, not premium
  dispatch(review the diff)                       model: opus    # DIFFERENT from implementer → independent pass
```

## Edge Cases

- **When NOT to apply:** work you do yourself in the main context (no dispatch) — you cannot reselect your own running model mid-turn; this rule governs *spawned* agents only.
- **Implementer already on the most-capable tier** → there is no *higher* model for the reviewer. Keep the reviewer a different model anyway (a strong-but-distinct one) for independence; if the harness exposes only one top-tier model, fall back to a fresh-context same-model reviewer and **say so** — independence of context is the residual lever.
- **Only one model available** (no tier choice) → the cost-tiering collapses; still dispatch the reviewer as a fresh context and state that the diversity lever is unavailable.
- A `BLOCKED`/stuck subagent that needs *more* reasoning is re-dispatched on a more capable model — escalating capability on a real block is not a violation of "cheapest that works".

## Review Checklist

- [ ] The reviewer's model differs from the implementer's (or, top-tier/single-model harness, the reviewer is at least a fresh context and that is stated) — the load-bearing check.
- [ ] Each subagent/workflow dispatch states the model tier AND a one-line cost rationale for that role.
- [ ] No premium model used for a pure research/explore/read-only role, and no premium default for a mechanical implement task.
- [ ] Model named as a tier (cheap/standard/most-capable) with any concrete model marked illustrative — not a hard-coded model as the only option.
- [ ] Not applied to non-dispatched, in-context work.
