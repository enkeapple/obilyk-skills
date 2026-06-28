---
name: writing-specs
description: >-
  Use to turn an approved design or written requirements into a concrete spec —
  reached from `grilling`'s handoff, or directly when continuing a half-finished
  feature (reverse-engineer the spec first), or when you feel pressure to "just
  start coding" or "skip the ceremony". Triggers on: "write a spec", "spec this
  out", "turn this design into a spec", "finish this half-done feature".
---

# Writing Specs

Write a small spec before writing code. The spec is the artifact that gates implementation: if a question about the change cannot be answered from the spec, the spec is wrong — fix the spec, not the code.

**Violating the letter of this rule is violating the spirit.** A plan you describe in chat is not a spec. A spec is a file a reviewer can pick up cold and a future session can resume from.

Project-agnostic: fill the blanks (paths, commands, type syntax) from the repo you are in.

**Progress:** before your first artifact, reflect this phase in the harness task list (one item `in_progress`; an item turns `completed` only on the user's explicit approval of that phase's artifact; a skipped phase stays listed, marked skipped) — under `sdd-lifecycle` update the existing item; run standalone, seed a single item for this phase.

## When to use

- Any change touching 2+ files across layers (e.g. UI + state, endpoint + client, schema + handler).
- Refactors that change a public interface (function signature, endpoint shape, exported type, event contract).
- Migrations (moving/splitting a module, changing a data shape, swapping a dependency).
- Continuing a half-finished feature handed off to you — reverse-engineer the spec from the existing code first.

## When NOT to use

No spec is needed when the change is **small** — and "small" is the off-ramp predicate, ALL of which must hold:

- a **single, cohesive behavior** (one logical change), AND
- it touches **no shared/public contract** — no new or changed API endpoint, exported type/signature, schema, persisted shape, event, or navigation route, AND
- it adds **no new surface** and spans **no multiple components / clients / services**, AND
- it fits **one test-first cycle** — no task-by-task plan (a source file plus its own test is one cycle, not "multiple files").

The trivial end of this predicate — one-line fixes, typo/format/rename with no semantic change, cosmetic single-file tweaks — obviously qualifies. A change crossing **any** line above needs a spec (see "When to use"); when in doubt, write the spec.

## Spec location and naming

Put it where the project keeps design docs. If there is no convention, default to `docs/specs/YYYY-MM-DD-<topic>.md`. Keep specs short (under ~250 lines). A long spec means the scope is too big — decompose it.

## Required sections (in order)

Write these as a positive recipe — every section, in this order:

0. **Source** (*conditional* — the one optional section) — when this spec traces to a resolved ticket/source bundle from `resolving-requirements`, copy its provenance block (`source` / `revision` / `ticket` / `files`) here verbatim, so traceability to the citable source survives into the spec instead of dying at the hand-off. Omit for a free-text idea. `verifying-implementation` reads this block to trace code↔source.
1. **Goal** — one or two sentences. What changes for the user / the codebase. No "and also".
2. **Scope** — bullet list of what is in.
3. **Out of scope** — bullet list of what looks related but is NOT in. Be explicit; this is where churn comes from. An empty Out-of-scope list means the scope is suspiciously broad.
4. **Contracts** — types / API shapes / param lists / state shape. Quote *actual code* in the project's language. If reusing existing types, link to the file with line numbers. No prose where a code block belongs.
5. **Files touched** — table: file(s) → kind of change (NEW / EDIT / DELETE) → one-line why. Run discovery (grep/read/glob) to fill this without guessing.
6. **Edge cases** — at minimum: empty, error, and loading/in-flight states. For mutations: idempotency, partial success, concurrent calls.
7. **Verification** — the *real* command(s) whose output proves the spec is satisfied (typecheck / lint / test / build), discovered from the project (package.json, Makefile, CI config, etc.), plus any manual steps. Never invent commands.
8. **Risks** — known unknowns + mitigation. "Risk: lib X v1.2 has a known issue with Z — confirmed fixed in 1.3, which we use."

### Templates

The copy-paste template lives in [assets/spec-template.md](./assets/spec-template.md): one canonical template, notes for the refactor and retroactive variants, and a filled example. Load it when you start writing.

## No Placeholders

A spec is concrete or it is fiction. Each Required section above defines what "concrete" means for it — real type/signature code in Contracts, discovered paths in Files touched, the repo's real commands in Verification, the actual states in Edge cases. The one rule those sections do not carry: **a deferred decision is never a placeholder.** No "TBD" / "TODO" / "decide during implementation" — a cut is an Out-of-scope line, not a TODO.

## Process

1. Read the request twice. Identify the domain concepts.
2. Run discovery (grep/read/glob) — enough to fill **Files touched** and **Contracts** without guessing.
3. Draft the spec. Ask the user ONE clarifying question only for a true product/business ambiguity. Implementation sub-variants are not ambiguities — pick the simplest one that satisfies the spec and note it.
4. Self-review (below). Save the spec.
5. **User Review Gate, then Implementation hand-off** (below) — do not implement from the spec directly.

## Two-layer review — self first, then an independent cold pass

Two passes with **disjoint remits** — why each is needed and why they must not overlap: [references/review-layers.md](./references/review-layers.md).

- **Self-review** (author pass, every time): No Placeholders (above), Out-of-scope list non-empty, all 8 required sections present and internally consistent. This pass is blind to what you misread.
- **Independent cold reviewer** (anything **beyond small** — more than one surface/module, a shared contract, or a destructive/irreversible op): dispatch a fresh zero-context subagent ([assets/spec-reviewer-prompt.md](./assets/spec-reviewer-prompt.md)); hand it the original request / approved design *alongside* the spec — without the source it collapses into a second self-review. Its remit is the author-blind class: **conformance to source** and **ambiguity** (any requirement two engineers would build differently).

Fix what it finds and re-review; do not code against a spec with open issues.

## User Review Gate

The spec gates the plan; the user gates the spec. After the spec passes review, do NOT roll straight into planning — stop and ask the user:

> "Spec written and saved to `<path>`. Please review it and tell me if you want any changes before I write the implementation plan."

Wait for the response. If they request changes, make them and re-run the reviewer loop. Proceed only once the user approves.

## Implementation

Once the user approves the spec:

> REQUIRED SUB-SKILL: Use `writing-plans` to turn the approved spec into a task-by-task implementation plan. Do NOT invoke any other skill and do NOT start writing code — `writing-plans` is the next step.

## Red Flags — if you catch yourself here, STOP

Fast trip-wires: the moment you notice one, you are about to skip the spec. The counter to each is its row in **Rationalizations** below.

- Time pressure ("demo in an hour").
- A verbal plan in chat instead of a file.
- Starting with "the obvious part", speccing the rest later.
- "It's basically the same as X" — the *difference* unwritten.
- "It's 40% done, I'll just finish it."

## Rationalizations

Every excuse means the same thing: **write the spec first.**

| Excuse | Reality |
| -------- | --------- |
| "No time, demo in an hour." | The spec is the *fastest safe path*. Ten lines pinning the contract prevents the parallel/conflicting implementation you rewrite at 11pm. Time pressure is exactly when unscoped churn hurts most. |
| "I'll write a quick verbal plan instead." | A plan in chat is not reviewable, not diffable, and gone next session. The spec *is* the plan, persisted. |
| "I'll leave the cut parts as TODOs." | TODOs are silent scope. Move each one to the Out-of-scope list so the cut is a recorded decision, not a leak. |
| "The code is 40% done, just finish it." | You cannot finish what you have not scoped. Reverse-engineer the spec from the existing code first; half-built code with no spec is where churn hides. |
| "I'll read the code first, then maybe spec." | Discovery *feeds* the spec — do both, but the spec is the output. Reading without writing the contract down means re-deriving it three times. |
| "It's obvious / too simple to spec." | Then the spec is 15 lines and costs nothing. If it is genuinely a one-liner, see "When NOT to use". |
| "It's basically the same as X." | Then write down what is *different* — the diff is the spec, the sameness goes in Out-of-scope. Unwritten "same as X" is where churn hides. |
| "We'll figure out the API shape during implementation." | Pin it in Contracts now, as a code block in the file. A contract described in prose gets re-derived — differently — by every caller. |
