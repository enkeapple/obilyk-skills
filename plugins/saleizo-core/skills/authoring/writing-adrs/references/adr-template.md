# ADR Templates

The two ADR **shapes** — this file is shape only. The readability discipline (be brief / one screen, `path:line` only in `Related files`, no embedded "developers MUST…" list) and convention-matching live in the skill body and are not restated here. **Pick the register** per the body's "Pick the register": **narrative** for a conceptual / approach decision, **template** for a decision bound to one concrete mechanism.

Optional header fields both shapes share: **`Related`** carries provenance and cross-links — the originating ticket/issue id (illustrative: `PROJ-1234`), sibling ADRs, and the conventions doc that holds any practices the decision implies (the "no embedded rules" link goes here). **`Deciders`** is optional too. Resist `Implementation Notes` and raw external-URL dumps — that bloat is a smaller model's tell.

## Narrative shape

The lighter form — `Context` + `Decision` + `Related files`, **no** separate `Options`/`Consequences` sections. The trade-off (why not the alternatives, what it cost) is woven into the prose. Default to this for most decisions.

```text
# ADR-NNNN — <short imperative title>

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Deciders:** <team / author>                                  (optional)
- **Related:** <ticket id, e.g. PROJ-1234>, [ADR-NNNN](NNNN-….md), [conventions doc](…)   (optional)

## Context
<What forced it: the problem, constraints, current state. ≤ ~120 words.>

## Decision
<We <decision in one or two sentences, active voice>. Then, in prose: why the chosen
path won over the alternatives — name them and what they cost — and the cost we
accept. Name code by file + symbol (`handleTokenRefresh` in `baseQuery.ts`); no
path:line here. ≤ ~120 words.>

## Related files   (optional, keep short)
- `baseQuery.ts` → `handleTokenRefresh` — <one-line what it is>
```

## Template shape

The heavier form — for a weighty mechanism-bound decision where a reader wants the alternatives and costs laid out navigably. The four bold slots are **REQUIRED** — an ADR in this register missing any one is incomplete. (If two full sections feel like bloat, use the narrative shape instead.)

```text
# ADR-NNNN — <short imperative title>

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Deciders:** <team / author>                                  (optional)
- **Related:** <ticket id, e.g. PROJ-1234>, [ADR-NNNN](NNNN-….md), [conventions doc](…)   (optional)

## Context           (REQUIRED)
The problem, the constraints, the current state. What forced a decision. (≤ ~120 words.)

## Decision          (REQUIRED)
The single choice made, in one short paragraph (≤ ~120 words). Name the code that
implements it by file + symbol in plain text (`handleTokenRefresh` in `baseQuery.ts`)
— NO `path:line` here; line anchors go in `Related files` only.

## Options considered (REQUIRED)
- **Option A (chosen)** — why it won.
- **Option B** — why it lost.
- **Option C** — why it lost.

## Consequences       (REQUIRED)
- Negative / cost: … (the price you are accepting — there is always one; this is the
  load-bearing part, do not skip it)
- Follow-ups: what must change later as a result.
- (Positive only if it is not already obvious from the Decision — skip the redundant restate.)

## Related files      (optional, keep short)
- `baseQuery.ts` → `handleTokenRefresh` — <one-line what it is>
- `utils.ts` → `forceLogout` — <one-line what it is>
```

## Shape-only notes

- **`Status`** uses the repo's vocabulary. Default set: `Accepted`, `Superseded by ADR-MMM`, `Deprecated`. A brand-new ADR for a decision already in code is `Accepted`, not `Proposed`.
- **Numbering.** `max(existing number) + 1`, zero-padded to the repo's width. Never backfill a gap, never reuse a number, never collide.
- **The weighed alternatives are what justify the ADR existing** — the `Options considered` slot (template) or the "why the chosen path won" paragraph (narrative) is the trade-off the Gate required. If you cannot fill it with real alternatives, the decision probably failed the Gate.
