# Decisions Log Template

The running record of what the grill decided. Keep it updated as decisions resolve; at hand-off you pass it whole to `writing-specs` so nothing is re-litigated and no decision is lost.

Two parts: the **decisions** (each resolved branch) and a **design summary by section** (the shape, organized the way a spec consumes it).

## Decisions

One line per resolved decision. Record the alternative you rejected — it prevents re-opening settled branches.

```markdown
## Decisions

- **Matching model:** scheduled job re-running each saved filter (pull). Rejected: per-write fan-out (push) — overkill for "notified later". 
- **Notification channel:** in-app + email. Rejected: push — not worth the setup for v1.
- **Dedup:** high-water-mark timestamp per saved search. Rejected: storing every notified id — unbounded growth.
- **Cadence:** nightly. Rejected: real-time — "later" tolerates delay (YAGNI).
```

## Design summary by section

The decided shape, in the sections a spec is built from. Keep each concrete — this is the input `writing-specs` turns into Contracts / Files touched / Edge cases.

```markdown
## Design summary

### Goal
<one or two sentences>

### Architecture / data flow
<the components and how data moves between them>

### Data model / contracts (sketch)
<the entities and their key fields — concrete enough to become real types in the spec>

### Edge cases
<empty / error / in-flight, plus the concrete domain cases the grill surfaced>

### Out of scope
<every cut made during the grill — explicit, not deferred to "later">

### Open implementation sub-variants
<the few things deliberately left to the implementer — NOT design decisions>
```

At hand-off: "Here are the decisions and the design summary — `writing-specs`, turn these into a concrete spec." The `Out of scope` and `Edge cases` sections are the ones most often lost between brainstorm and spec; carry them verbatim.
