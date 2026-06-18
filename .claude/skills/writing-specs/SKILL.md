---
name: writing-specs
description: >-
  Use when starting any non-trivial feature, refactor, or migration, before
  writing implementation code, or when continuing a half-finished feature, or
  when you feel pressure to "just start coding" or "skip the ceremony".
  Triggers on: "implement", "build a", "let's add", "refactor X", "migrate Y",
  "finish this half-done feature".
---

# Writing Specs

Write a small spec before writing code. The spec is the artifact that gates implementation: if a question about the change cannot be answered from the spec, the spec is wrong — fix the spec, not the code.

**Violating the letter of this rule is violating the spirit.** A plan you describe in chat is not a spec. A spec is a file a reviewer can pick up cold and a future session can resume from.

Project-agnostic: fill the blanks (paths, commands, type syntax) from the repo you are in.

## When to use

- Any change touching 2+ files across layers (e.g. UI + state, endpoint + client, schema + handler).
- Refactors that change a public interface (function signature, endpoint shape, exported type, event contract).
- Migrations (moving/splitting a module, changing a data shape, swapping a dependency).
- Continuing a half-finished feature handed off to you — reverse-engineer the spec from the existing code first.

## When NOT to use

- One-line fixes, typo/format/rename with no semantic change.
- Cosmetic tweaks confined to a single file.

## Spec location and naming

Put it where the project keeps design docs. If there is no convention, default to `docs/specs/YYYY-MM-DD-<topic>.md`. Keep specs short (under ~250 lines). A long spec means the scope is too big — decompose it.

## Required sections (in order)

Write these as a positive recipe — every section, in this order:

1. **Goal** — one or two sentences. What changes for the user / the codebase. No "and also".
2. **Scope** — bullet list of what is in.
3. **Out of scope** — bullet list of what looks related but is NOT in. Be explicit; this is where churn comes from. An empty Out-of-scope list means the scope is suspiciously broad.
4. **Contracts** — types / API shapes / param lists / state shape. Quote *actual code* in the project's language. If reusing existing types, link to the file with line numbers. No prose where a code block belongs.
5. **Files touched** — table: file(s) → kind of change (NEW / EDIT / DELETE) → one-line why. Run discovery (grep/read/glob) to fill this without guessing.
6. **Edge cases** — at minimum: empty, error, and loading/in-flight states. For mutations: idempotency, partial success, concurrent calls.
7. **Verification** — the *real* command(s) whose output proves the spec is satisfied (typecheck / lint / test / build), discovered from the project (package.json, Makefile, CI config, etc.), plus any manual steps. Never invent commands.
8. **Risks** — known unknowns + mitigation. "Risk: lib X v1.2 has a known issue with Z — confirmed fixed in 1.3, which we use."

### Templates

The copy-paste template lives in [references/spec-template.md](references/spec-template.md): one canonical template, notes for the refactor and retroactive variants, and a filled example. Load it when you start writing.

## Process

1. Read the request twice. Identify the domain concepts.
2. Run discovery (grep/read/glob) — enough to fill **Files touched** and **Contracts** without guessing.
3. Draft the spec. Ask the user ONE clarifying question only for a true product/business ambiguity. Implementation sub-variants are not ambiguities — pick the simplest one that satisfies the spec and note it.
4. Self-review (below). Save the spec. Get user approval.
5. Only then implement.

## Self-review (before showing the user)

- No "TBD" / "TODO" anywhere — a cut becomes an Out-of-scope line, not a TODO.
- Every type / file / path mentioned exists, or is explicitly marked NEW.
- Verification uses real commands from this repo, not invented ones.
- Out-of-scope list is non-empty.
- A reviewer can pick this up cold and know what to build.

For anything beyond a small spec, dispatch an independent reviewer subagent for a cold second pass before you start coding — use [references/spec-reviewer-prompt.md](references/spec-reviewer-prompt.md). Fix any issues it finds and re-review; do not code against a spec with open issues.

## Red Flags — STOP, you are skipping the spec

- "We don't have time for ceremony / the demo is in an hour."
- "I'll just write a quick plan in the chat."
- "I'll start with the obvious part and spec the rest later."
- Leaving TODO/TBD in place of a scope decision.
- Describing the contract verbally instead of in a code block in a file.
- "It's basically the same as X" — without writing down what is *different* (Out of scope).
- "It's 40% done, I'll just finish it" — without reverse-engineering the spec first.

**All of these mean: write the spec first.**

## Rationalizations

| Excuse | Reality |
|--------|---------|
| "No time, demo in an hour." | The spec is the *fastest safe path*. Ten lines pinning the contract prevents the parallel/conflicting implementation you rewrite at 11pm. Time pressure is exactly when unscoped churn hurts most. |
| "I'll write a quick verbal plan instead." | A plan in chat is not reviewable, not diffable, and gone next session. The spec *is* the plan, persisted. |
| "I'll leave the cut parts as TODOs." | TODOs are silent scope. Move each one to the Out-of-scope list so the cut is a recorded decision, not a leak. |
| "The code is 40% done, just finish it." | You cannot finish what you have not scoped. Reverse-engineer the spec from the existing code first; half-built code with no spec is where churn hides. |
| "I'll read the code first, then maybe spec." | Discovery *feeds* the spec — do both, but the spec is the output. Reading without writing the contract down means re-deriving it three times. |
| "It's obvious / too simple to spec." | Then the spec is 15 lines and costs nothing. If it is genuinely a one-liner, see "When NOT to use". |

## Anti-patterns

- "We'll figure out the API shape during implementation." — No. Pin it in Contracts.
- A spec that is mostly prose with no code blocks — Contracts must be concrete.
- A spec with no Out-of-scope list — guarantees scope creep.
- A spec written after the code is half-done and not labeled as such — write it first, or mark it explicitly as a retroactive design doc.
