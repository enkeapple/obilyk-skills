# ADR Template

Match the repo's existing ADR shape first. When there is none, use this. The four bold slots are **REQUIRED** — an ADR missing any one is incomplete, not "lean". Keep it terse: an ADR is a record, not an essay. Resist adding `Deciders`, `Implementation Notes`, `References`-to-external-URLs, or `Rationale` sections unless the repo's own ADRs already carry them — that bloat is a smaller model's tell.

```text
# ADR-NNNN — <short imperative title>

Date: YYYY-MM-DD
Status: Accepted

## Context           (REQUIRED)
The problem, the constraints, the current state. What forced a decision.

## Decision          (REQUIRED)
The single choice made, in one short paragraph. Link the code that
implements it: `src/shared/api/baseApi.ts:8`.

## Options considered (REQUIRED)
- **Option A (chosen)** — why it won.
- **Option B** — why it lost.
- **Option C** — why it lost.

## Consequences       (REQUIRED)
- Positive: …
- Negative: … (the cost you are accepting — there is always one)
- Follow-ups: what must change later as a result.
```

## Notes

- **`Status`** uses the repo's vocabulary. Default set: `Accepted`, `Superseded by ADR-MMM`, `Deprecated`. A brand-new ADR for a decision already in code is `Accepted`, not `Proposed`.
- **Living links.** Every factual claim about the code points at a real `path:line` you opened this session — that is what makes the ADR verifiable later and drift-auditable. No invented references.
- **Numbering.** `max(existing number) + 1`, zero-padded to the repo's width. Never backfill a gap, never reuse a number, never collide.
- **`Options considered` is the slot that justifies the ADR existing** — it is the trade-off the Gate required. If you cannot fill it with real weighed alternatives, the decision probably failed the Gate.
