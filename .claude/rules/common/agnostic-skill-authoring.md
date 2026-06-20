---
description: 'How to author/edit a skill so it stays agnostic and shareable across projects — no hard-coded stack, path, command, or repo-specific vocab in the body; parameterize specifics to the consumer repo, mark unavoidable examples illustrative, and scrub external-source assumptions when adapting material. The canonical "agnostic by default" policy lives in CLAUDE.md → Non-negotiables #2; this rule adds the how-to + grep checks.'
paths:
  - '.claude/skills/**/*.md'
---

# Agnostic Skill Authoring

## When

Authoring or editing any skill — `.claude/skills/<name>/SKILL.md` or its `references/*.md` — **regardless of where the material came from**: written from scratch, lifted from another repo, pasted from docs/Context7/web, or adapted from an existing skill. The moment skill content is written, it must read the same in any consumer repo.

## Canonical Source — Do Not Duplicate

The **"agnostic by default" policy** — *that* a skill must never hard-depend on one project's stack, paths, or commands, and that project leakage is a defect — lives in [.claude/CLAUDE.md](../../CLAUDE.md) → "Non-negotiables" #2 and is enforced as a check in [framework.md](../domains/framework.md) → "Suspicion Protocol" #2 and the Completeness Checklist (row 5). Those are the single source of truth for the *what* and *why*. This rule only adds the *how*: the concrete moves that make a skill agnostic and the grep checks that catch a leak. When the two overlap, CLAUDE.md wins.

## Implementation

A skill is **agnostic** when dropping it, unchanged, into a different repo preserves its full value and function. Make it so:

1. **Find the coupling before you save.** A leak is any token in the body that assumes *this* project: a package manager or test runner (`pnpm`, `npm run`, `vitest`, `jest`), a path (`src/`, `app/`, `node_modules/`, `tsconfig.json`), a framework/library name presented as the default, a shell command, or domain vocabulary that only this repo's glossary defines. Grep for it (see checklist) — don't eyeball.
2. **Parameterize, don't bake.** Replace a specific with the role the consumer repo fills — "the project's test command", "the consumer repo's lint step", "the framework's router" — so the skill states *what* to do and the target supplies *which* tool.
3. **Mark an unavoidable example illustrative.** When an example genuinely needs a concrete stack to be legible, keep it but label it — `(illustrative — your stack may differ)` — so it reads as a sample, never a requirement.
4. **Scrub the source when adapting.** Material from another repo, a doc, or another skill carries that source's native assumptions. Strip them: never copy a snippet that names a specific tool/path verbatim into the body as if it were normative. The source is evidence for the *shape* of the instruction, not for its concrete nouns.
5. **Value-preservation test.** Ask: if I delete every project-specific noun, does the skill still do its job? If removing the specifics guts it, it is mis-scoped — it is project *config*, not an agnostic capability, and does not belong in the shared skill set.

```text
❌ WRONG — leak: a specific runner, command, and path baked into the body as normative.
Run `pnpm test` and confirm the Vitest suite under `src/` is green before you refactor.

✅ CORRECT — parameterized; the consumer repo supplies the command and layout.
Run the project's test command and confirm the suite is green before you refactor.
(The consumer repo fills in the command; in a JS repo this is illustratively `pnpm test`.)
```

## Edge Cases

- **When NOT to apply:** editing a *rule*, *hook*, `skills-routing.json`, or either `CLAUDE.md` — those are vault-internal harness files and legitimately name this repo's real paths and tools. They are not shareable skills. That is why this rule is scoped to `.claude/skills/**` only.
- A **marked-illustrative** example that names a stack is **not** a leak — it is the sanctioned escape hatch from move 3. Don't flag it.
- A skill's **own structural references** — a relative link to its `references/foo.md`, the `Skill` tool, the names of neighbouring skills it hands off to — are part of the skill system, not project coupling. Leave them.
- A `disable-model-invocation` reference skill (e.g. `writing-skills`) is held to the same agnostic bar as any other skill — being user-invoked does not license stack leaks.

## Review Checklist

- [ ] Grep the skill body for stack/command/path tokens: `grep -nE 'pnpm|npm run|yarn|vitest|jest|tsconfig|node_modules|(^|[^.])src/' .claude/skills/<name>/SKILL.md` — every hit sits inside a marked-illustrative example or is parameterized, never normative prose.
- [ ] Each concrete tool/command/path is either replaced by the consumer-repo role it fills or explicitly `(illustrative — …)`.
- [ ] No snippet copied verbatim from an external source still carries that source's project nouns.
- [ ] Value-preservation: deleting the project-specific nouns leaves the skill's instruction intact (else it is config, not a skill).
- [ ] Rule applied to skill files only — no leak flagged in a rule/hook/CLAUDE.md (out of scope).
