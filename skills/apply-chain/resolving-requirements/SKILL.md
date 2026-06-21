---
name: resolving-requirements
description: >-
  Use at the very start of the chain, before grilling, when the build input is a
  ticket reference rather than a ready description — a ticket ID like
  "TICKET-1234" / "ACME-3310", a ticket URL, or "get/pull/resolve the
  requirements for X", "start the design work for <ticket>". Russian triggers:
  "достань требования", "подтяни требования", "резолвни тикет",
  "начни работу над <тикетом>".
---

# Resolving Requirements

Turn whatever the user hands you into a **resolved requirements bundle** that `grilling` can consume — without losing, paraphrasing, or fabricating any of it. This is the front door of the APPLY chain: `resolving-requirements → grilling → writing-specs → writing-plans → pre-implementation-protocol → (inline-driven-development | subagent-driven-development) → spec-drift-audit`.

**Core principle:** requirements are *sourced*, never *authored*. Your job is faithful retrieval + provenance, not summary. A paraphrased acceptance criterion is a changed acceptance criterion.

**Progress:** before your first artifact, reflect this phase in the task list per [phase-task-visualization](../../../.claude/rules/common/phase-task-visualization.md) — under `sdd-lifecycle` update the existing item; run standalone, seed a single item for this phase.

## Two input modes

| Input | Mode | What you do |
| --- | --- | --- |
| Free-text description, or a ticket URL the user pasted the body of | **direct** | Pass it through to `grilling` unchanged. Nothing to resolve. |
| A ticket **ID** matching the consumer repo's configured pattern (e.g. `^ACME-\d+$`) | **resolve** | Fetch the bundle from the configured remote spec source, then hand it off. Run the recipe below. |

The ticket-ID **pattern**, the **remote spec source**, how to **sync** it, and **where provenance is recorded** are consumer-repo config (its `CONTRIBUTING.md` or a rule) — never baked into this skill. No configured source → you cannot resolve: treat as free-text or ask. (`ACME-3310` here is illustrative only.)

## Resolve recipe (ticket-ID mode)

1. **Sync fresh.** Pull/clone the configured remote spec source into its configured working copy. Fresh every time — no cache, no assumed local layout.
2. **Locate the bundle** by the ticket ID — a match may be a **file or a directory**. Matches are not interchangeable: prefer the **fullest** one (a directory bundle over a lone summary file), so the choice never depends on filesystem enumeration order. If two matches are genuinely equivalent, or you can't tell which is canonical, surface both and ask — never let order decide.
3. **Read ALL of it.** If the match is a directory, read **every** file in it — `summary`, acceptance criteria, edge-cases, and any attachment (`.txt`, notes, mockups). Do not pick the file whose *name* looks canonical and drop the rest; the constraints hide in the edges.
4. **Materialize the bundle** for hand-off — see Output contract.

## Output contract → hand off to `grilling`

Produce one bundle that carries the source content **verbatim** plus a provenance block, then hand it off. A **non-text attachment** (image, mockup, binary) has no verbatim text: carry it **by reference** — its name and path in `files` — never transcribe or describe its content as source. A described mockup is authored requirements, the one thing this skill exists to prevent; `grilling` reads the bytes itself if it needs them. The provenance is what makes the fetch reproducible (a fresh fetch can differ) and keeps every later artifact grounded in a citable source. Keep it with the bundle, not in chat-only memory; cite it wherever the consumer's spec records traceability. The downstream slot exists: `writing-specs` carries this block forward in its conditional **Source** section, and `spec-drift-audit` reads it for its code↔source trace — keep the block intact through `grilling` so that slot is filled, not dropped.

```text
source: <repo URL/path the bundle came from>
revision: <commit SHA fetched (or fetch timestamp if no VCS)>
ticket: <ticket ID, or "free-text">
files: [<every file read, by name>]
---
<the requirements content, verbatim — acceptance criteria especially, unchanged>
```

> **REQUIRED NEXT SKILL:** Use `grilling` to turn this resolved bundle into a shared, concrete design. Pass the verbatim content and the provenance block as its input — do not pre-summarize the requirements into a design.

## Failure path (cannot reach the bundle)

Sync fails (auth/PAT/network) **or** the ID matches nothing:

1. **Surface the error verbatim** to the user — the exact git/find output. For a not-found, also show the lookup you ran and the synced revision so they can confirm the story exists.
2. **Ask, with exactly two options:** paste the requirements as plain text (→ continue in `direct` mode, record `source: free-text fallback (<ticket>, original error: …)`), or abort to fix auth/network/ID.
3. Never auto-retry past one confirming attempt. Never invent content. Never silently downgrade a ticket ID to a free-text guess. The user picks.

## Red Flags — STOP

- Reading the "obvious" file in a bundle directory and skipping the rest.
- Letting filesystem order pick between matches — taking a lone summary file over the fuller directory bundle.
- Transcribing or describing a binary attachment (mockup/image) as if it were source content, instead of carrying it by reference.
- Handing `grilling` your paraphrase/summary instead of the source content.
- Starting design with no `source`/`revision`/`ticket` recorded — the fetch is then non-reproducible.
- Inventing or assuming requirements when the bundle can't be fetched.
- Auto-retrying a deterministic auth/network failure, or silently switching to free-text.
- Blurring "resolve" and "design" into one motion with no hand-off boundary.

## Rationalizations

| Excuse | Reality |
| --- | --- |
| "summary.md is clearly the canonical file." | The directory is the bundle. Edge-cases and mockup notes carry the constraints that break designs. Read all of it. |
| "Two paths matched; I'll take the first one." | Order is not a tie-breaker. Prefer the fullest match; if two are genuinely equivalent, ask which is canonical. |
| "The mockup shows the layout — I'll describe it for `grilling`." | A described image is authored requirements, not sourced. Carry it by reference (name + path); `grilling` reads the bytes itself. |
| "A summary is cleaner to hand to design." | A summary is your compression, with your omissions. `grilling` must see the source; acceptance criteria pass through verbatim. |
| "I'll note where it came from later." | Later you're reconstructing from memory. The fetch is reproducible only if `source` + `revision` are captured now. |
| "The clone failed, I'll just describe the feature." | That fabricates the one input the ticket convention exists to protect. Surface the error and ask. |
