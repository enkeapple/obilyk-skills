---
name: writing-rules
description: >-
  Use when writing or editing a project rule under .claude/rules/ — capturing a
  convention, or promoting a recurring lesson into a durable rule. Triggers on:
  "write a rule", "add a rule",
  "enforce this convention", "stop doing X", "turn this into a rule".
---

# Writing Rules

A rule is a small, **actionable** instruction that loads when relevant and tells the agent what to do or avoid, with the concrete code to pattern-match against. Its body prescribes actions with real examples — if it describes a *topic* instead, it is a doc, not a rule.

**Core contract:** a `description`, an optional `paths` to scope it, and a body of actionable instructions with real ✅/❌ examples. Match the repo's existing rule conventions (frontmatter keys, folder layout) when it has them. Full anatomy and a filled example: [assets/rule-template.md](./assets/rule-template.md).

## When to use

- Capturing a convention so the agent applies it without being told each time.
- A mistake keeps recurring and you want a durable, always-checked guard.
- Promoting a recurring lesson — `writing-lessons` hands off here once a cause-tag cluster crosses the threshold. Your input: the cluster's entries + the reviewer's drafted rule text and target path; your job: shape them into a properly scoped rule. That skill owns the surrounding bookkeeping (back-references, ledger, commit) — return to it after the rule file exists.

## When NOT to use

- A one-off preference for a single task — just say it in the prompt.
- Something mechanically enforceable by a linter/formatter/types — automate it; rules are for judgment a tool can't make.
- No foundational rules yet (domain glossary / framework charter) — create those with `bootstrapping-glossary` first; this skill is for the ordinary rules that hang off them.

## Rule anatomy (the recipe)

A rule has these parts. **This is a recipe, not a gate:** the order is conventional and parts are skippable. A rule that is *actionable and correctly scoped* is valid even if it varies the section order, merges sections, or omits an optional one — only its substance decides validity. Do NOT reject or rewrite a substantively-sound rule over cosmetic template deviation.

1. **Frontmatter.**
   - `description:` (**required**) — one line: what the rule enforces + its key points. A loader reads this to decide relevance.
   - `paths:` (**optional**) — the **scoping mechanism**: glob(s) the rule applies to (e.g. `'**/*.{ts,tsx}'`, `'**/api/**'`), keeping an area-specific rule from loading where it is irrelevant. Include it, scoped as tightly as the rule applies, for an area-specific rule; **omit it for a genuinely always-on rule** (a framework charter, a repo-wide convention). Most rules are area-specific and want `paths`; foundational ones are always-on and have none. The real failure is an *area-specific* rule left unscoped so it nags everywhere — never the mere absence of `paths`.
2. **`## When`** — the triggering condition in one or two sentences: when an agent must apply this.
3. **`## Implementation`** — the instructions. Actionable, with a real ✅/❌ code pair from (or close to) the codebase, in imperative form: "Before X, always Y." / "X is forbidden; use Y instead, because Z." / "When you see X, do Y."
4. **`## Edge Cases`** (optional) — gotchas and **when NOT to apply**, so it is not over-applied.
5. **`## Review Checklist`** — a few grep-able checks an agent or reviewer runs to confirm compliance.

## Make it actionable, not narrative

A rule reads like an instruction someone can follow and check, not an explanation of a topic.

| Rule (do this) | Doc (not a rule) |
| --- | --- |
| "Store money as integer minor units paired with an ISO-4217 code; never `number`." | "Floating point has precision issues, which is why money is tricky…" |
| "Import only from a package's barrel; if a symbol isn't exported, add it to the barrel — don't deep-import." | "We value encapsulation in our packages." |

State an exception as its own line ("Allowed only when the package ships documented subpath exports"), not as a hedge on the main rule.

## One rule, one topic — complex domains become a folder

Each file covers one concern; a rule needing three unrelated `## When`s should be split. Cross-link siblings with relative links (`[error-handling](./error-handling.md)`) instead of duplicating them.

When a concern is genuinely large (an "API layer", an "auth/session layer"), it is a **domain folder** `rules/<domain>/` of focused sibling rules. **The split line is the `paths`:** each sub-aspect that loads on a different set of files gets its own file, so editing one pulls in only the relevant sub-rule. If two would always load together on the same `paths`, they are one rule — merge them. Example (illustrative — your stack/paths may differ):

```text
.claude/rules/api/
  client.md             paths: **/api/client.ts          (auth, refresh)
  definition.md         paths: **/api/**/*.api.ts         (defining endpoints)
  schemas-and-models.md paths: **/api/**/*.schemes.ts     (validation)
  store-integration.md  paths: **/api/**/*.api.ts, store  (cache/tags)
  hooks.md              paths: **/api/hooks/**            (composed hooks)
```

Shared concepts (the auth token, cache tags) are cross-linked once, never duplicated.

## Two-layer review, then test on a cold agent

Three passes catching **different** defect classes; keep them disjoint.

1. **Self-review (every time, cheap).** Check the rule's *form* against the Review Checklist below — what you can verify from the text itself.
2. **Independent cold reviewer** (for a rule that will be widely loaded or promoted from a lesson). Dispatch a fresh subagent with zero shared context, given the existing rules directory, via [assets/rule-reviewer-prompt.md](./assets/rule-reviewer-prompt.md). Its remit is the **author-blind** class you cannot judge from inside your own context: duplication against the existing set (cross-link, don't fork) and scoping/applicability (would the `paths` nag; would two cold readers apply it two ways) — NOT a re-run of the form checklist.
3. **Empirical RED/GREEN.** Static review confirms the rule is well-*formed*, not that it *works* — a rule too vague to steer is a no-op that still costs load. Pick a concrete target case the rule governs (can't name one? the rule has no demand — reconsider it), then dispatch RED (no rule) and GREEN (rule injected) on that case via [assets/rule-efficacy-test-prompt.md](./assets/rule-efficacy-test-prompt.md). RED must show the mistake (else it's a no-op here — cut it or find a real case); GREEN must comply on every Review-Checklist item (else sharpen the Implementation with a stronger imperative or a ✅/❌ closer to the case, and re-run). Skip only for a pure-policy rule with no single target case (e.g. an always-on charter) — and say so.

## Review Checklist

- Frontmatter has a `description`; an area-specific rule has `paths` scoped as tightly as it applies, an always-on rule omits it deliberately.
- `## When` and `## Review Checklist` are present.
- Implementation is imperative with a real ✅/❌ example, and any exception is its own line.
- Covers one topic; overlaps with an existing rule are cross-linked, not duplicated.
- Empirically RED/GREEN-tested that it steers a cold agent — or a pure-policy skip is stated.

## Red Flags — STOP

- Declaring a rule done on static review alone — never empirically RED/GREEN-tested that it steers a cold agent (a no-op rule passes static review).
- The body explains a topic, or is a story / rationale, with no instruction — and a code rule with no ✅/❌ example.
- An *area-specific* rule left always-on (broad/global `paths`, or none) so it nags outside its area. (Missing `paths` on a genuinely always-on rule is correct, not a defect.)
- Rejecting or rewriting an otherwise-sound rule because its layout doesn't match the template exactly.
