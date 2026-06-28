---
name: grilling
description: >-
  Use before any creative or build work — a new feature, component, behavior
  change, or refactor — to turn a fuzzy idea into a shared, concrete design.
  Triggers on: "help me think this through", "brainstorm", "let's design",
  "grill me", "stress-test this plan", "I want to add/build/implement X",
  "refactor/migrate X", "should we…".
---

# Grilling

Interview the user relentlessly until a fuzzy idea becomes a shared, concrete design — then right-size the hand-off: the full chain (via the spec) for a non-trivial change, or straight to implementation for a small single-behavior one. This is collaborative grilling, not a solo design dump.

**Upstream:** the input arrives either as a free-text idea direct from the user, or as a faithful requirements bundle resolved by `resolving-requirements` (ticket mode) — grill it the same way; a resolved bundle is a starting point to interrogate, not a finished design.

**Two core principles:**

- **One decision per question, each with your recommended answer.** Sequence dependent decisions one at a time; batch only genuinely independent siblings into one message, a recommendation on each (limits and examples in the playbook). Bundling dependent questions, or asking without recommendations, is what bewilders. Lead with the answer you'd pick and why; the user corrects or confirms.
- **Explore before you ask.** If the codebase or docs can answer a question, go read them — don't spend a question on it.

> **Hard gate:** Do NOT write code, scaffold, split tickets, or invoke an implementation/planning skill until the design is shared AND the user approves it. This holds for every task, however simple. "Too simple to design" is the rationalization that wastes the most work — the design can be three sentences, but it gets presented and approved.

**Progress:** before your first artifact, reflect this phase in the harness task list (one item `in_progress`; an item turns `completed` only on the user's explicit approval of that phase's artifact; a skipped phase stays listed, marked skipped) — under `sdd-lifecycle` update the existing item; run standalone, seed a single item for this phase.

## The interview loop

Walk the decision tree, resolving dependencies one at a time. The full technique — depth-first ordering, the recommended-answer pattern, explore-vs-ask, good/bad questions, knowing when to stop — is in [references/interview-playbook.md](./references/interview-playbook.md).

1. **Explore context first** — files, docs, recent commits — so questions are informed, not generic.
2. **Ask the next question** following the one-decision rule above. Sequence dependents: wait for the response before opening a branch that depends on it; independent siblings may share one message (see the playbook).
3. **Follow dependencies** — each answer opens the next branch. Resolve a decision before the ones that depend on it.
4. **Keep a running Decisions list** — one line per resolved question: the decision + why (+ the alternative rejected). This is the material you hand to the spec; don't lose it. Format: [assets/decisions-template.md](./assets/decisions-template.md).
5. **YAGNI** — actively prune features the user doesn't need.

Scope check: if the idea is actually several independent subsystems, say so first and help decompose — don't grill the details of something that needs splitting.

## Propose approaches, then design

Once you understand the goal, propose **2-3 approaches** with trade-offs, lead with your recommendation. Then present the design **in sections scaled to complexity** (architecture, data flow, components, error/edge cases), asking after each section whether it's right. Revise until the user approves.

What a good design *is* — design-for-isolation, deep modules, decomposing multi-subsystem ideas, existing-codebase discipline, ruthless YAGNI — is in [references/design-principles.md](./references/design-principles.md). Read it when shaping the design, especially in an unfamiliar or large codebase.

## Hand off (terminal state) — right-size the next step

The design-approval gate above holds for **every** path: even a three-sentence design is presented and approved before anything else. Once it is approved, classify it against the threshold below and take **exactly one** of two exits — do not run the full chain by reflex, and do not skip it by reflex.

**Off-ramp → hand directly to `test-driven-development`.** Take this exit only when **ALL** hold:

- the change is a **single, cohesive behavior** (one logical change), AND
- it touches **no shared/public contract** — no new or changed API endpoint, exported type/signature, schema, persisted shape, event, or navigation route, AND
- it adds **no new surface** and spans **no multiple components / clients / services**, AND
- it fits **one test-first cycle** — no task-by-task plan is needed to track it.

> **REQUIRED SUB-SKILL (off-ramp):** Use `test-driven-development` to implement the approved single-behavior change test-first (RED → GREEN → REFACTOR). No spec, no plan — the approved design is the contract.

**Full chain → hand to `writing-specs`.** Take this exit when the change crosses **any** line above. For a non-trivial design, first dispatch an independent readiness reviewer ([assets/readiness-reviewer-prompt.md](./assets/readiness-reviewer-prompt.md)) to catch a "we're done" that still hides open assumptions — if it returns *Not ready*, grill those branches and re-check. Then hand the gathered design + Decisions list to the spec:

> **REQUIRED SUB-SKILL (full chain):** Use `writing-specs` to turn the approved design and the Decisions list into a concrete spec. Pass every decision as input so nothing is re-litigated. `writing-specs` owns the spec → user-review gate → `writing-plans` chain — do not jump past it to planning or code.

A source file plus its own test is **one** test-first cycle, not "multiple components" — counting it as multi-file is the mis-classification to avoid. **When in doubt about which exit, take the full chain** — a wrongly-skipped spec on a contract or multi-surface change is the expensive rewrite; a slightly-heavy spec on a small change is cheap.

## Red Flags — STOP

- Bundling **dependent** questions in one message (independent siblings may batch; dependents stay sequential).
- Stating a question with no recommended answer of your own.
- Asking something the codebase already answers (go read it).
- Proposing a design/solution before you understand the goal.
- Writing code, scaffolding, or splitting tickets before the user approves the design (the gate holds on both exits).
- Taking the off-ramp to `test-driven-development` for a change that touches a shared contract, spans multiple surfaces, or needs a multi-step plan — that is the full chain via `writing-specs`.
- At the end, splitting tickets or planning by hand instead of taking one of the two exits (`test-driven-development` or `writing-specs`).

## Rationalizations

| Excuse | Reality |
| -------- | --------- |
| "It's simple, I'll just build it." | Simple ideas hide the most unexamined assumptions. Present a 3-sentence design and get approval. |
| "Faster to ask everything at once." | A wall of unrelated and dependent questions is bewildering and gets half-answered. Sequence the dependent ones; batch only independent siblings — that converges faster. |
| "I'll just propose my design." | A design dropped before understanding is a guess. Grill first; let answers shape it. |
| "It's simple — I'll skip the spec and just TDD it." | The off-ramp is only for a single-behavior change with no shared contract and no new surface. Touches an API/schema/event, spans components, or needs a multi-step plan? That is the full chain via `writing-specs`. When in doubt, full chain. |
| "We're done, I'll start on tickets / planning." | grilling never plans or splits tickets. There are exactly two exits — `test-driven-development` (small) or `writing-specs` (full chain) — and only after the design is approved. |
