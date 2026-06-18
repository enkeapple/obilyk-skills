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

Interview the user relentlessly until a fuzzy idea becomes a shared, concrete design — then hand it to the spec. This is collaborative grilling, not a solo design dump.

**Two core principles:**

- **One question at a time, each with your recommended answer.** Asking several at once is bewildering. Lead with the answer you'd pick and why; the user corrects or confirms.
- **Explore before you ask.** If the codebase or docs can answer a question, go read them — don't spend a question on it.

<HARD-GATE>
Do NOT write code, scaffold, split tickets, or invoke an implementation/planning skill until the design is shared AND the user approves it. This holds for every task, however simple. "Too simple to design" is the rationalization that wastes the most work — the design can be three sentences, but it gets presented and approved.
</HARD-GATE>

## The interview loop

Walk the decision tree, resolving dependencies one at a time. The full technique — depth-first ordering, the recommended-answer pattern, explore-vs-ask, good/bad questions, knowing when to stop — is in [references/interview-playbook.md](references/interview-playbook.md).

1. **Explore context first** — files, docs, recent commits — so questions are informed, not generic.
2. **Ask ONE question.** Prefer multiple-choice. Lead with your recommended answer + one line of reasoning. Wait for the response before the next question.
3. **Follow dependencies** — each answer opens the next branch. Resolve a decision before the ones that depend on it.
4. **Keep a running Decisions list** — one line per resolved question: the decision + why (+ the alternative rejected). This is the material you hand to the spec; don't lose it. Format: [references/decisions-template.md](references/decisions-template.md).
5. **YAGNI** — actively prune features the user doesn't need.

Scope check: if the idea is actually several independent subsystems, say so first and help decompose — don't grill the details of something that needs splitting.

## Propose approaches, then design

Once you understand the goal, propose **2-3 approaches** with trade-offs, lead with your recommendation. Then present the design **in sections scaled to complexity** (architecture, data flow, components, error/edge cases), asking after each section whether it's right. Revise until the user approves.

What a good design *is* — design-for-isolation, deep modules, decomposing multi-subsystem ideas, existing-codebase discipline, ruthless YAGNI — is in [references/design-principles.md](references/design-principles.md). Read it when shaping the design, especially in an unfamiliar or large codebase.

## Hand off to the spec (terminal state)

When the design is approved, do **not** write code, tickets, or an implementation plan. For a non-trivial design, first dispatch an independent readiness reviewer ([references/readiness-reviewer-prompt.md](references/readiness-reviewer-prompt.md)) to catch a "we're done" that still hides open assumptions — if it returns *Not ready*, grill those branches and re-check. Then hand the gathered design + Decisions list to the spec:

> **REQUIRED SUB-SKILL:** Use `writing-specs` to turn the approved design and the Decisions list into a concrete spec. Pass every decision as input so nothing is re-litigated.

`writing-specs` is the **only** next step — it owns the spec → user-review gate → `writing-plans` chain. Do not jump past it to planning or code.

## Red Flags — STOP

- Asking several questions in one message (ask one).
- Stating a question with no recommended answer of your own.
- Asking something the codebase already answers (go read it).
- Proposing a design/solution before you understand the goal.
- Writing code, scaffolding, or splitting tickets before the user approves the design.
- At the end, drifting into planning or implementation instead of handing off to `writing-specs`.

## Rationalizations

| Excuse | Reality |
| -------- | --------- |
| "It's simple, I'll just build it." | Simple ideas hide the most unexamined assumptions. Present a 3-sentence design and get approval. |
| "Faster to ask everything at once." | A wall of questions is bewildering and gets half-answered. One at a time converges faster. |
| "I'll just propose my design." | A design dropped before understanding is a guess. Grill first; let answers shape it. |
| "We're done, I'll start on tickets." | The terminal step is `writing-specs`, not planning. The spec is what makes the design buildable and reviewable. |
