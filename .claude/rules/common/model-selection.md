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
- **cost-tiering of the other roles (a strong caller usually already does this — light scaffolding, not the point):** the operative default is *the cheapest model sufficient for the task* — escalating capability is the exception you justify per dispatch, not the starting point. A read-only research/explore role takes the cheapest capable tier (bulk-token, low-judgment); a well-specified implement task takes the cheapest tier that reliably does it (count turns, not just per-token price), escalating to the most-capable tier only for subtle, correctness-critical, or multi-file integration work. Do NOT default every implement task to the premium model.
- **reuse / existing-code search before implementing → dispatch it cheap, do NOT search inline on the implementer's tier.** The lookup for an existing implementation or wrapper (the search behind [reuse-before-reimplement](../anti-patterns/reuse-before-reimplement.md) — see-also, not required to apply this rule) is mechanical, high-recall, low-judgment work. When it is non-trivial (a large or unfamiliar codebase), dispatch it to a cheap-tier subagent rather than spending the implementer's often-premium tier grepping inline. _Rationale: an implementer searching on its own expensive model is the silent default — a cheap search subagent returns the same hits for a fraction of the tokens._

Name **tiers**, not a fixed model — the current Claude mapping is illustrative (cheap ≈ Haiku, standard ≈ Sonnet, most-capable ≈ Opus) and will shift as models are renamed.

### Quick reference — dispatched role → tier

A scannable default for the **cost-tiering** lever. Default a well-specified implement task to **standard**; escalate to **most-capable** only on a real trigger (first attempt failed, 5+ files, an architectural decision, or security-critical code). The **review** rows are deliberately not a fixed tier: a review tier is read off the *implementer's* model (one tier different), never off this table by task — that is the load-bearing rule above, and it overrides any row here.

The **Tier** column is authoritative; the model in parentheses is illustrative and will shift as models are renamed — bind to the tier, not the name.

| Task type | Tier (illustrative model) | Why |
| --- | --- | --- |
| Exploration / search | cheap (≈ Haiku) | fast, cheap, good enough for finding files |
| Reuse / existing-code search before implementing | cheap (≈ Haiku) | mechanical high-recall lookup; don't burn the implementer's tier grepping inline |
| Simple, single-file edit | cheap (≈ Haiku) | clear instructions, low judgment |
| Writing docs | cheap (≈ Haiku) | structure is simple |
| Multi-file implementation | standard (≈ Sonnet) | best balance for coding |
| Complex architecture / design | most-capable (≈ Opus) | deep reasoning over many interacting parts |
| Debugging a hard bug | most-capable (≈ Opus) | must hold the whole system in mind |
| Security analysis / security-critical code | most-capable (≈ Opus) | cannot afford a missed vulnerability |
| Routine per-task review | **one tier different from the implementer** (prefer cheaper) | independence, not raw power, catches blind spots |
| Final / high-risk / security review | most-capable **and** different from the implementer | top capability *and* an independent pass |

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
- [ ] The review tier was derived from the implementer's model (one tier different), NOT read as a fixed task-type row from the quick-reference table.
- [ ] Each subagent/workflow dispatch states the model tier AND a one-line cost rationale for that role.
- [ ] No premium model used for a pure research/explore/read-only role, and no premium default for a mechanical implement task.
- [ ] A non-trivial pre-implementation reuse/existing-code search was dispatched to a cheap tier, not run inline on the implementer's (premium) model.
- [ ] Model named as a tier (cheap/standard/most-capable) with any concrete model marked illustrative — not a hard-coded model as the only option.
- [ ] Not applied to non-dispatched, in-context work.
