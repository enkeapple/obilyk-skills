---
description: >-
  Before adding a rule under .claude/rules/, scope it to a reproduced need, not
  its stated purpose. Name a concrete target file/task where the mistake occurs;
  grep the existing rule set for an overlap (cross-link / extend, don't fork);
  confirm it needs judgment a linter can't make; RED a cold agent on the target
  case — if the baseline already complies, the rule is a no-op, don't ship it.
paths:
  - '.claude/rules/**/*.md'
---

# Scoping Rule Value to a Reproduced Need

## When

You are about to author a new rule file under `.claude/rules/**`, or split a new rule out of an existing one. This is the moment — before writing the body — to prove the rule earns its context load. It is the rule-side counterpart of [scoping-skill-value](./scoping-skill-value.md) (which governs `SKILL.md` and does not fire on rule files); it stays a separate always-on guard so it loads even on a manual rule edit that never invokes the `writing-rules` skill (see-also — that skill owns the full RED→GREEN methodology and the cold reviewer; not required to apply this rule).

## Implementation

Before writing the rule, clear all four gates. Failing any one means **do not ship it as written** — cut it, fold it into an existing rule, or automate it instead.

1. **Name a concrete target case.** Point at a real file or task in this repo where the mistake the rule prevents would naturally occur. Cannot name one? The rule has no demand — there is nothing to scope it to; stop.
2. **Grep the existing rule set for an overlap.** Search `.claude/rules/**` (`grep -ri "<concept>" .claude/rules/`) before writing. An existing rule already in the area → **cross-link or extend it, do not fork a near-duplicate** — two rules on the same concern drift apart and both load.
3. **Confirm it needs judgment, not automation.** A constraint a linter, formatter, or type system enforces mechanically belongs in that tool, not in a rule. Rules are for the judgment a tool cannot make.
4. **RED the literal rule against a cold baseline.** Hand a cold agent the target-case task with NO rule in context. A strong model frequently already does the right thing — that is the inversion test failing, and the rule would be a no-op that only costs load. Ship only when RED shows the mistake AND a GREEN run (rule injected) shows the cold agent now complies on every Review-Checklist item.

```text
❌ WRONG — scoped to the stated purpose; no target case, no overlap grep, baseline already complies.
Asked to "add a rule to reuse existing code before writing new", write a fresh rule file and ship it.
(reuse-before-reimplement.md already owns this — it is a duplicate; and a cold agent told to reuse
already searches, so the new rule steers nothing.)

✅ CORRECT — run the four gates first, then decide.
Name the target case → grep .claude/rules/ → find reuse-before-reimplement.md already covers it →
cross-link / extend instead of forking. For a genuinely new concern: RED a cold agent on the case,
confirm it commits the mistake, ship only if GREEN shows the rule fixes it.
```

Keep this rule's own instruction self-contained — links above are see-also, deletable without losing the four gates (per [rule-self-containment](./rule-self-containment.md)).

## Edge Cases

- **When NOT to apply:** a foundational/charter rule promoted from a cause-tag cluster (glossary, framework charter) whose value is policy, not a single reproducible case — say so explicitly and skip gate 4, but still run gates 2 and 3.
- A rule that bundles light principle-prose *plus* a reproduced need is fine — keep the load-bearing part scoped to the reproduced case and treat the principle as scaffolding, not the justification.
- This rule governs the *scoping decision* for a rule. The full RED→GREEN→REFACTOR loop and the independent cold reviewer live in the `writing-rules` skill — cross-link, don't restate.
- **Strong-model no-op / contaminated control.** A strong cold agent already greps-before-forking (gate 2) and already recognises a vague no-op rule (gates 1, 4), so an in-vault RED of *this rule* reproduces no failure — and once the rule is on disk a cold explorer reads and applies it, so the control is contaminated too. That does not mean cut it: its load is earned in **weaker / non-agentic consumer harnesses** where recon and the no-op check are not default, and as the path-scoped guard that fires on a manual `.claude/rules/**` edit bypassing the `writing-rules` skill. Treat this as the gate-4-skip carve-out above — a policy distillate, like its sibling [scoping-skill-value](./scoping-skill-value.md), not a reproduced-failure rule.

## Review Checklist

- [ ] Named a concrete target file/task the rule governs before writing it (gate 1).
- [ ] Grepped `.claude/rules/**` for an overlapping rule; an existing one was cross-linked or extended, not forked (gate 2).
- [ ] Confirmed the constraint needs judgment, not a linter/formatter/type check (gate 3).
- [ ] RED-ran the literal rule on the target case; baseline-complied → cut or re-aimed, not shipped; GREEN shows a cold agent complies (gate 4) — or the gate-4 skip is justified for a pure-policy/charter rule.
- [ ] Did not duplicate the `writing-rules` methodology or `scoping-skill-value`; cross-linked them instead.
