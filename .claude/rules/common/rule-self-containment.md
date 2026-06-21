---
description: 'A rule must be self-contained — fully understandable and applicable from its own text, without loading another rule or a lesson. Lightweight "see also" / canonical-source pointers are allowed (delete the link and the rule still applies); load-bearing references ("follow the checklist in X"), inheritance / "extends" chains, and links to a specific lesson entry are forbidden. Applies whenever a rule under .claude/rules/** is authored or edited.'
paths:
  - '.claude/rules/**/*.md'
---

# Rule Self-Containment

## When

STOP and apply this whenever you author or edit a rule under `.claude/rules/**` and you are about to point at another rule, the framework charter, the glossary, or `lessons-learned.md` to carry part of this rule's instruction. The moment you write "see X", "as in Y", "follow the process in Z", or "this builds on …", decide first whether the link is *load-bearing* or merely *see-also*.

## Why

Rules load on demand and independently — the loader pulls the one whose `paths` match the file in hand, not its transitive neighbours. So a rule that cannot be *applied* without opening another rule has a hidden dependency the loader does not satisfy: the agent gets half an instruction. The dependency also rots silently — the linked rule is renamed, re-scoped so it no longer loads, or (for a lesson) **deleted on promotion** (a lesson entry is removed once its cause-tag is promoted 3×), and the dangling pointer leaves the rule empty. Self-containment is what lets each rule be loaded, read, and trusted alone.

## Implementation

**A rule's instructions and its ✅/❌ example must be complete on their own.** State every step, threshold, and check the reader must perform *in this file*. Then, optionally, add a pointer to a neighbour — but only as **see-also**: a link the reader can ignore and still fully comply.

The decision test, applied to every link in the body: **delete the link. Can the reader still apply the rule?**

- **Yes** → it is a see-also / canonical-source pointer. Allowed. (e.g. "See also [markdown-style](./markdown-style.md) for fence conventions.")
- **No** → it is load-bearing. Forbidden — inline the borrowed instruction, or this rule is a fragment.

```text
# ❌ WRONG — load-bearing: the instruction lives in another rule; delete the link and nothing remains
## Implementation
Before committing, run the readiness checklist from [pre-implementation-protocol](../../skills/...).
All of its steps apply here.

# ❌ WRONG — references a specific lesson entry; that entry is deleted on promotion → dangling pointer
When scoping a skill, apply the check captured in lessons-learned.md → `skill-value-vs-noop` entry #2.

# ✅ CORRECT — self-contained instruction; the link is see-also (deletable)
## Implementation
Before committing, confirm in this turn: the tests you ran pass, the diff matches the approved
spec, and no debug code remains. (See also [pre-implementation-protocol](../../...) for the
broader readiness gate — not required to apply this rule.)
```

Three things are forbidden outright, regardless of the delete-the-link test:

- **Inheritance / "extends" chains.** A rule must not declare it "extends", "inherits from", or "builds on" another rule, and must not form a transitive chain (A needs B, B needs C). Each rule stands at depth zero.
- **Borrowing an instruction by reference** — "follow the steps in X", "apply X's checklist", "the process in Y governs here". Inline the steps you actually need.
- **Linking a specific lesson entry.** Lessons are transient; a numbered/named entry vanishes on promotion. If a durable check came from a lesson, inline the check. A see-also to the `lessons-learned.md` *file* as a mechanism (where lessons live) is fine; a pointer to one entry is not.

## Edge Cases

- **Canonical-source pointer is allowed when this rule still states its own actionable part.** `git-conventions.md` points at CLAUDE.md → Git boundary as the single source of truth for the autonomy boundary *and* deliberately does not restate it — but that file still fully delivers its own concern (commit format). That is the allowed shape: defer the part you intentionally do NOT own, while remaining complete for the part you do. It crosses the line only if applying the rule *requires* opening the canonical source.
- **CLAUDE.md and the framework charter are not "rules" in the `paths`-scoped sense.** A canonical-source pointer to them (for a boundary this rule explicitly does not own) is a see-also, not a load-bearing rule dependency.
- **Glossary terms.** Linking the glossary to define a term is see-also — the rule must still read correctly for someone who knows the term and never opens the link.
- This rule does not forbid *cross-linking* (still encouraged to avoid duplication, per the `writing-rules` skill). It forbids the link being *load-bearing*. Cross-link freely; just keep each rule applicable without following the link.

## Review Checklist

- [ ] Delete-the-link test passes for every link in the body: removing any link leaves the rule fully applicable (grep the body for `](`, check each).
- [ ] No required-step phrasing borrowing another rule's instruction — grep for `follow the`, `checklist in`, `process in`, `steps in`, `as in`, `per ` pointing at another rule.
- [ ] No `extends` / `inherits` / `builds on` another rule; no transitive A→B→C chain.
- [ ] No link to a specific lesson entry (numbered/named); any `lessons-learned.md` link points at the file as a mechanism, not an entry.
- [ ] The rule's own `## Implementation` and ✅/❌ example are complete without opening any linked file.
