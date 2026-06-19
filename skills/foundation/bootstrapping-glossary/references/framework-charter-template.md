# Framework Charter Template

The charter governs *how* to work in this repo, regardless of module. It is concrete — grounded in this repo's real commands, patterns, and failure modes — not generic advice. Every command and pattern named is one you confirmed by reading the repo.

## Template

```markdown
# Framework Rules

Stack-agnostic process rules: how to approach work, verify it, and avoid this repo's common failure modes. They apply regardless of which module you touch. Domain rules live alongside under `.claude/rules/`.

## Implementation Protocol

Before any implementation:

1. Read the full request. Identify the domain concepts and the layers touched.
   <!-- If the repo has a glossary, add: "If the request mentions <ambiguous terms>, read the glossary FIRST and name the domain." -->
2. Scan every layer the change touches (<list this repo's layers, e.g. screen → hook → api → store → navigation>). Classify each: NONE / PARTIAL / FULL.
3. Design contracts AS CODE, not prose — for every contract the change touches, write the concrete type / endpoint shape / state delta / param list. If you can't write it as code yet, the task isn't understood: grep/read until you can.
4. Think through behaviour: 1 happy path + the edge cases (empty / error / in-flight; for mutations: idempotency, partial success).
5. Only then write code, in dependency order. For PARTIAL, implement only the missing layers.

If genuinely ambiguous: stop, ask ONE question. Phases are not optional; abbreviate for trivial fixes, never skip.

## Suspicion Protocol

Run every phase presuming something is wrong. After each phase, check for this repo's recurring failure modes:

1. **Missed code** — searched only the obvious name. Grep 2 naming variants (verb/noun swap, abbreviation, legacy prefix); re-scan if any hit.
2. **Shortcut / silent cut** — re-read the request bullet by bullet; each bullet must point to a line in the plan/code. A bullet with no pointer is a silent cut.
3. **Hallucinated symbol** — every API/hook/route/constant referenced is verified by grep/read this session, not from memory.
4. **Test passes for the wrong reason** — for any new test, invert the expectation once and confirm it fails; revert.
5. **Unverified structure claim** — every "X has Y / exports Z / endpoint accepts P" is backed by a read this session, or labelled `(unverified)`.

If suspicion confirms a defect: STOP, name the failure mode, go back one phase — do not patch silently.

## Zero-hallucination rule

No structural claim about the repo without a read this session. Trigger phrases that mean STOP-and-read: "by analogy…", "it should be similar…", "I assume the slice has…", "probably accepts…". This binds plans, code, questions, and chat equally. **Editing a rule doc is editing code** — every symbol/path/anchor in a `.claude/rules/*.md` is a structural claim, re-verify before writing it.

## Evidence-Based Verification

After any code change, run and SHOW the output of the repo's real checks (no "should pass"):

- `<real typecheck command>`
- `<real lint command>`
- `<real test command, if any — else state there is no suite and what you verified manually>`
- For UI changes: exercise it (simulator/browser) or say explicitly you couldn't.

## Question Discipline

Don't ask what the repo or rules already answer. Before asking, check: is it in the code (grep/read)? in `.claude/rules/`? a technical sub-variant? If yes → decide, justify in one line, proceed (pick the closest existing pattern, smallest diff, no shared-interface change). Reserve questions for genuine product/business decisions with no precedent.
```

## Notes

- Replace every `<placeholder>` with this repo's real layers, commands, and patterns — the value is in the specifics, not the headings.
- Keep it about *process*; concrete stack conventions (styles, naming, file layout) belong in their own rules, cross-linked.
- The suspicion failure modes should reflect the failures THIS repo actually hits — add or drop modes based on the lessons log (`writing-lessons`) if one exists.
