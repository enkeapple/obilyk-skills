---
description: >-
  When you fix or improve a pattern in one of the vault's own dogfooded artifacts
  (.claude/CLAUDE.md, root CLAUDE.md, a .claude/rules/** doc, a vault SKILL/glossary)
  that ALSO ships to consumer repos via a generator under skills/**, propagate the
  same fix into the bootstrapping-* template AND add/confirm the mirror drift-check
  in the matching auditing-* skill — same turn. Fixing only the instance lets the
  generator regenerate the bug and the auditor never catches it.
paths:
  - '.claude/CLAUDE.md'
  - 'CLAUDE.md'
  - '.claude/rules/**/*.md'
  - 'skills/**/SKILL.md'
  - 'skills/**/references/*.md'
  - 'skills/**/assets/*.md'
---

# Dogfood ↔ Generator ↔ Auditor Sync

## When

STOP whenever you fix or improve a *pattern* in one of the vault's own **dogfooded** artifacts — `.claude/CLAUDE.md`, the root `CLAUDE.md`, a `.claude/rules/**` doc, or a vault `SKILL.md`/glossary — that the vault ALSO ships to consumer repos through a generator under `skills/**` (a `bootstrapping-*` template, a scaffolded doc).

Does NOT apply when: you are editing only the generator/template itself, or the fix has no consumer-facing twin (a purely vault-internal artifact with no `bootstrapping-*` that emits it).

## Why

This is the promoted `fix-instance-not-generator` cluster — it recurred three times before promotion: lesson-capture routing and the status block (both logged), then the lessons backlog model (this turn's generator gap). Each fixed the vault's own files while the `bootstrapping-claude-md` template kept shipping the old shape, and twice the `auditing-*` mirror was missed too. (Per the backlog model the contributing entries are deleted on promotion; git holds them via `git log -S 'fix-instance-not-generator'`.) The vault dogfoods its own generated artifacts, so a fixed pattern has up to **three copies that must move in the same turn**: the **INSTANCE** (the vault file you just fixed), the **GENERATOR** (the template under `skills/foundation/bootstrapping-*/references/*` that emits it to consumers), and the **AUDITOR** (the matching `auditing-*` skill that must flag the old shape as drift in a consumer repo). Fix the instance alone and the generator regenerates the bug while the auditor stays blind to it.

Distinct from its siblings — cross-link, don't restate: [scoping-skill-value.md](./scoping-skill-value.md) (scope value to a reproduced failure), [skill-routing-sync.md](./skill-routing-sync.md) (disk ↔ routing sync), [agnostic-skill-authoring.md](./agnostic-skill-authoring.md) (the generator fix must stay agnostic — no vault paths/commands leaked into the template). None of them own instance↔generator↔auditor propagation.

## Implementation

In the **same turn** you fix the instance:

1. **Locate the generator.** Grep the bootstrapping skills for the section you changed; if a template emits this pattern, apply the SAME fix there — kept agnostic (no vault-specific paths/commands; conditional where the consumer may differ, per [agnostic-skill-authoring.md](./agnostic-skill-authoring.md)).
2. **Locate or add the audit mirror.** Confirm the matching `auditing-*` skill flags the OLD shape as drift; if it cannot catch the just-fixed drift in a consumer repo, add the inverse check.
3. **Prove it on the GENERATED output, not the hand-fixed instance.** RED a subagent that follows the now-fixed template and confirm it produces the new shape (GREEN). A clean instance never proves the generator was fixed.

```text
❌ WRONG — instance-only fix; generator keeps shipping the bug, auditor never flags it.
Rewrote the lessons / status-block wording in the vault's .claude/CLAUDE.md and stopped.
bootstrapping-claude-md's operating-manual-template.md still emits the old shape, so every
generated CLAUDE.md regenerates it — and auditing-claude-md has no check to catch the drift.

✅ CORRECT — same turn, all three copies move together.
1. Fixed the instance (.claude/CLAUDE.md).
2. grep -rln "<changed section phrase>" skills/foundation/bootstrapping-*/ → applied the same
   fix to assets/operating-manual-template.md, kept agnostic.
3. Added the mirror drift-check to auditing-claude-md (flags the old shape in a consumer repo).
4. RED/GREEN on a subagent following the fixed template — confirms the generated output is correct.
```

## Edge Cases

- **No generator emits this pattern** → record `[N/A] — no bootstrapping-* template ships this` explicitly and stop; do not invent a generator edit.
- **The auditor already catches the drift** → confirm it (a grep is enough); only add a check when the just-fixed shape would slip past in a consumer repo.
- **The instance is vault-only** (no consumer twin, e.g. `skills-routing.json`, a hook) → this rule does not apply; [skill-routing-sync.md](./skill-routing-sync.md) governs routing sync instead.
- Keep the generator fix **agnostic** — propagating a fix that bakes in a vault path/command is its own defect ([agnostic-skill-authoring.md](./agnostic-skill-authoring.md)).

## Review Checklist

- [ ] Greped the bootstrapping templates for the fixed section; the generator carries the same fix — or `[N/A]` (no generator emits this pattern) stated explicitly.
- [ ] The generator fix is agnostic — no vault paths/commands leaked into the template.
- [ ] The matching `auditing-*` skill flags the old shape as drift in a consumer repo (existing check confirmed, or a new inverse check added).
- [ ] RED/GREEN ran on the GENERATED output, not only the hand-fixed instance — or the skip is justified ([N/A] generator).
