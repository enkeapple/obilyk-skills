---
name: improve-codebase-architecture
description: Use when the user wants an architecture review, asks to improve/refactor a codebase's structure, find deepening opportunities, reduce shallow modules, or make an area more testable or AI-navigable — and wants candidates surfaced visually before committing.
disable-model-invocation: true
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

A capable agent, asked to "review the architecture", will jump straight to a prose list of recommendations. This skill exists to stop that: it forces an explicit process — explore, then present candidates *visually*, then grill the chosen one — and a shared vocabulary, neither of which happens by default.

This command is _informed_ by the project's domain model and built on a shared design vocabulary:

- Run the `codebase-design` skill for the architecture vocabulary (**module**, **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality**) and its principles (the deletion test, "the interface is the test surface", "one adapter = hypothetical seam, two = real"). Use these terms exactly in every suggestion — don't drift into "component," "service," "API," or "boundary."
- The project's **domain glossary** (whatever the consumer repo calls it — a `CONTEXT.md`, a domain-rules glossary, etc.) gives names to good seams; the project's **architecture decision records (ADRs)**, wherever they live, record decisions this command should not re-litigate.

## Process

### 1. Explore

Read the project's domain glossary and any ADRs in the area you're touching first.

Then dispatch an exploration subagent (e.g. the `Explore` agent type) to walk the codebase. Don't follow rigid heuristics — explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? A "yes, concentrates" is the signal you want.

### 2. Present candidates visually

The deliverable is **always a written, self-contained visual artifact** — never a prose or markdown bullet list in the chat. The diagrams carry the weight; a chat list is the exact failure this skill exists to prevent, and "I'm in a hurry", "just read them aloud", "markdown is fine", or "skip the report" are the pressure to resist, not an exception that converts the deliverable into chat prose. The recommended, illustrative format is a self-contained HTML file (Tailwind + Mermaid via CDN) written to the OS temp directory so nothing lands in the repo. A consumer repo may substitute another medium **only if it stays visual, self-contained, and written to a file** — substitution swaps the format, it never downgrades it to a chat list. See [HTML-REPORT.md](HTML-REPORT.md) for the full scaffold, diagram patterns, and styling guidance.

If the user insists on chat prose *after* being told the report is one temp file with zero repo footprint, that is an explicit, informed override of the skill — name what it costs ("dropping the visual report loses the before/after diagrams that carry the deepening case") and do not slide into it silently as though the first request settled it.

Resolve the temp dir from `$TMPDIR`, falling back to `/tmp` (or `%TEMP%` on Windows), and write to `<tmpdir>/architecture-review-<timestamp>.html` so each run gets a fresh file. Open it for the user — `xdg-open <path>` on Linux, `open <path>` on macOS, `start <path>` on Windows — and tell them the absolute path.

For each candidate, render a card with:

- **Files** — which files/modules are involved
- **Problem** — why the current architecture is causing friction
- **Solution** — plain English description of what would change
- **Benefits** — explained in terms of locality and leverage, and how tests would improve
- **Before / After diagram** — side-by-side, custom-drawn, illustrating the shallowness and the deepening
- **Recommendation strength** — one of `Strong`, `Worth exploring`, `Speculative`, rendered as a badge

End the report with a **Top recommendation** section: which candidate you'd tackle first and why.

**Use the project's domain glossary for the domain, and the `codebase-design` vocabulary for the architecture.** If the glossary defines "Order," talk about "the Order intake module" — not "the FooBarHandler," and not "the Order service."

**ADR conflicts**: if a candidate contradicts an existing ADR, only surface it when the friction is real enough to warrant revisiting the ADR. Mark it clearly in the card (e.g. a warning callout: _"contradicts ADR-0007 — but worth reopening because…"_). Don't list every theoretical refactor an ADR forbids.

Do NOT propose interfaces yet. Confirm the artifact was actually written (the file exists and you have its absolute path) **before** asking the pick question — never ask "which would you like to explore?" off a chat list that was never written to a file. After the file is written, ask the user: "Which of these would you like to explore?"

### Holding the visual form under pressure

| Excuse | Reality |
| --- | --- |
| "User's in a hurry — just give bullets." | The hurry is the pressure the skill exists to resist; the report is one temp file, seconds to write, zero repo footprint. |
| "They want to read it aloud at the review." | Produce the visual artifact and read talking points *from* it — don't replace it with a chat list. |
| "A markdown list is basically the same." | A list drops the before/after diagrams that carry the deepening case — the load-bearing part of the deliverable. |
| "The format is 'illustrative / recommended', so prose is fine." | Illustrative means HTML vs another *visual, file-written* medium; it never licenses a non-visual chat list. |

**Red Flags — STOP:**

- Emitting the recommendations as a chat prose / markdown bullet list instead of a written visual artifact.
- Treating "skip the report / I'm in a hurry / markdown is fine" as license to downgrade rather than the pressure to resist.
- Citing "illustrative / recommended" to drop the visual form (it only permits another visual, self-contained, file-written medium).
- Asking "which would you like to explore?" off a list that was never written to a file.

### 3. Grilling loop

Once the user picks a candidate, run the `grilling` skill to walk the design tree with them — constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

Side effects happen inline as decisions crystallize — keep the project's domain model current as you go:

- **Naming a deepened module after a concept not in the domain glossary?** Add the term to the glossary. If the project has no glossary yet, create the base set with the `bootstrapping-glossary` skill; if it has one, sharpen the entry with `auditing-glossary`.
- **Sharpening a fuzzy term during the conversation?** Update the glossary right there (via `auditing-glossary`).
- **User rejects the candidate with a load-bearing reason?** Offer an ADR, framed as: _"Want me to record this as an ADR so future architecture reviews don't re-suggest it?"_ Only offer when the reason would actually be needed by a future explorer to avoid re-suggesting the same thing — skip ephemeral reasons ("not worth it right now") and self-evident ones.
- **Want to explore alternative interfaces for the deepened module?** Run the `codebase-design` skill and use its design-it-twice parallel sub-agent pattern.
