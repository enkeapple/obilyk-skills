---
name: writing-rules
description: >-
  Use when writing or editing a project rule under .claude/rules/, capturing a
  convention so the agent stops repeating a mistake, or promoting a recurring
  lesson into a durable rule. Triggers on: "write a rule", "add a rule",
  "enforce this convention", "stop doing X", "turn this into a rule".
---

# Writing Rules

A rule is a small, **actionable** instruction that loads when relevant and tells the agent what to do or avoid — with the concrete code to pattern-match against. It is either **scoped** to the files it governs (via `paths`) or **always-on** (no `paths`) — both are valid.

**Core contract: a rule has a `description`, an optional `paths` to scope it, and a body of actionable instructions with real examples — not a prose essay.** `paths` scopes an *area-specific* rule to the files it governs; **omit it for a genuinely always-on rule** (a framework charter, a repo-wide convention) that should load every session. The real failure is an *area-specific* rule left unscoped so it nags everywhere — not the mere absence of `paths`. If its body describes a topic instead of prescribing actions, it is a doc, not a rule.

Project-agnostic: match the repo's existing rule conventions (frontmatter keys, folder layout) when it has them. The full anatomy and a filled example are in [references/rule-template.md](references/rule-template.md).

## When to use

- Capturing a convention so the agent applies it without being told each time.
- Promoting a recurring lesson to a rule — `lessons-learned-protocol` hands off here once a cause-tag cluster crosses the threshold. Your input: the cluster's entries + the reviewer's drafted rule text and target path; your job: shape them into a properly scoped rule. That skill owns the surrounding bookkeeping (back-references, ledger, commit) — return to it after the rule file exists.
- A mistake keeps recurring and you want a durable, always-checked guard.

## When NOT to use

- A one-off preference for a single task — just say it in the prompt.
- Something mechanically enforceable by a linter/formatter/types — automate it; rules are for judgment a tool can't make.
- No foundational rules yet (domain glossary / framework charter) — create those with `bootstrapping-domain-rules` first; this skill is for the ordinary rules that hang off them.

## Rule anatomy (the recipe)

A rule has these parts. **This is a recipe, not a gate:** the order is conventional and parts are skippable — a rule that is *actionable and correctly scoped* is valid even if it varies the section order, merges sections, or omits an optional one. Do NOT skip, reject, or rewrite a substantively-sound rule over cosmetic template deviation — only its substance decides validity (actionable? scoped right? has an example?).

1. **Frontmatter.**
   - `description:` (**required**) — one line: what the rule enforces + its key points. This is what a loader reads to decide relevance.
   - `paths:` (**optional**) — glob(s) the rule applies to (e.g. `'**/*.{ts,tsx}'`, `'**/api/**'`). **This is the scoping mechanism** — it keeps an area-specific rule from loading where it is irrelevant. Include it, scoped as tightly as the rule applies, for an area-specific rule; **omit it for a genuinely always-on rule** that must load every session (a framework charter, a repo-wide convention). Most rules are area-specific and want `paths`; foundational ones are always-on and have none.
2. **`## When`** — the triggering condition in one or two sentences: the situation in which an agent must apply this.
3. **`## Implementation`** — the actual instructions. Actionable, with a real ✅/❌ code pair from (or close to) the codebase. Use imperatives and one of these forms:
   - "Before X, always Y."
   - "X is forbidden; use Y instead, because Z."
   - "When you see X, do/run Y."
4. **`## Edge Cases`** (optional) — gotchas and **when NOT to apply** the rule, so it is not over-applied.
5. **`## Review Checklist`** — a few bullet checks an agent (or reviewer) runs to confirm compliance, ideally grep-able.

## Make it actionable, not narrative

A rule reads like an instruction someone can follow and check, not an explanation of a topic.

| Rule (do this) | Doc (not a rule) |
|---|---|
| "Store money as integer minor units paired with an ISO-4217 code; never `number`." | "Floating point has precision issues, which is why money is tricky…" |
| "Import only from a package's barrel; if a symbol isn't exported, add it to the barrel — don't deep-import." | "We value encapsulation in our packages." |

State the exception as its own line ("Allowed only when the package ships documented subpath exports"), not as a hedge on the main rule.

## One rule, one topic — and complex domains become a folder

Each file covers one concern. Cross-link siblings with relative links (`[error-handling](./error-handling.md)`) instead of duplicating them. A rule that needs three unrelated `## When`s should be split.

When a concern is genuinely large (an "API layer", an "auth/session layer"), it is not one big file — it is a **domain folder** `rules/<domain>/` of focused sibling rules, each its own file with its own tight `paths`. **The split line is the `paths`**: each sub-aspect that loads on a different set of files gets its own rule, so editing one file pulls in only the relevant sub-rule, not the whole domain. Example — an `api` domain:

```text
.claude/rules/api/
  client.md             paths: **/api/client.ts          (auth, refresh)
  definition.md         paths: **/api/**/*.api.ts         (defining endpoints)
  schemas-and-models.md paths: **/api/**/*.schemes.ts     (validation)
  store-integration.md  paths: **/api/**/*.api.ts, store  (cache/tags)
  hooks.md              paths: **/api/hooks/**            (composed hooks)
```

Shared concepts (the auth token, cache tags) are cross-linked once between the files, never duplicated. If two sub-rules would always load together on the same `paths`, they are one rule — merge them.

## Self-review / reviewer

Before saving, check it against the Review Checklist below. For a rule that will be widely loaded or promoted from a lesson, dispatch an independent reviewer using [references/rule-reviewer-prompt.md](references/rule-reviewer-prompt.md) — it checks scoping, actionability, and duplication of existing rules.

## Review Checklist

- Frontmatter has a `description`. An area-specific rule has `paths` scoped as tightly as it applies; an always-on rule omits `paths` deliberately.
- There is a `## When` and a `## Review Checklist`.
- Implementation is imperative with a real ✅/❌ example — not a topic explanation.
- Exceptions / when-NOT-to-apply are stated explicitly.
- Covers one topic; overlaps with an existing rule are cross-linked, not duplicated.

## Red Flags — STOP

- No `description` in the frontmatter — the loader can't judge relevance. (Missing `paths` is *not* a defect by itself — that is exactly how an always-on rule is written.)
- The body explains a topic instead of prescribing actions.
- No ✅/❌ example for a code rule.
- No Review Checklist.
- An *area-specific* rule left always-on — a broad/global `paths`, or no `paths` at all — so it nags outside its area.
- Skipping or rejecting an otherwise-sound rule because its layout doesn't match the template exactly.
- A "rule" that is really a story or a rationale with no instruction.
