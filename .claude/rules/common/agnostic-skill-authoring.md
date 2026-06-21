---
description: 'How to author or edit a skill so it stays agnostic and portable: a skill must never hard-depend on one project''s stack, paths, commands, or repo-specific vocabulary — parameterize each specific into the role the consumer repo fills, mark an unavoidable concrete example illustrative, and scrub the source''s native assumptions when adapting external material. A skill is agnostic when dropping it unchanged into another repo preserves its full value; project leakage into a skill body is a defect, not a style nit. Applies whenever a skill under .claude/skills/** is authored or edited.'
paths:
  - 'skills/**/*.md'
  - '.claude/skills/**/*.md'
---

# Agnostic Skill Authoring

## When

STOP and apply this whenever you author or edit any skill — a `.claude/skills/<name>/SKILL.md` or its `references/*.md` / `assets/*.md` — **regardless of where the material came from**: written from scratch, lifted from another repo, pasted from docs or the web, or adapted from a sibling skill. The moment skill content is written, it must read and work the same in any consumer repo.

## Why

A skill is a *shared, portable capability*, not project config. It is meant to drop into any consumer repo unchanged and still do its job. A token in the body that assumes *this* project — a package manager or test runner, a directory path, a shell command, a framework or library presented as the default, or domain vocabulary only this repo's glossary defines — couples the skill to one codebase and silently makes it wrong everywhere else. Such leakage is a **defect**, not a cosmetic nit: it is the difference between a reusable instruction and a buried piece of one repo's configuration. One question settles every case: *if I delete every project-specific noun, does the skill still do its job?*

## Implementation

A skill is **agnostic** when dropping it, unchanged, into a different repo preserves its full value and function. Make it so:

1. **Find the coupling before you save — grep, don't eyeball.** A leak is any token in the body that assumes this project: a package manager or test runner (e.g. `pnpm`, `npm run`, `yarn`, `vitest`, `jest`), a path (e.g. `src/`, `app/`, `node_modules/`, `tsconfig.json`), a framework or library name offered as *the* default, a concrete shell command, or vocabulary only this repo defines. Run the grep in the Review Checklist over the file and inspect every hit.
2. **Parameterize, don't bake.** Replace each specific with the *role* the consumer repo fills — "the project's test command", "the consumer repo's lint step", "the framework's router" — so the skill states *what* to do and the target supplies *which* tool.
3. **Mark an unavoidable example illustrative.** When an example genuinely needs a concrete stack to be legible, keep it but label it — `(illustrative — your stack may differ)` — so it reads as a sample, never a requirement. A marked-illustrative example is the one sanctioned escape hatch, not a leak.
4. **Scrub the source when adapting.** Material from another repo, a doc, or a sibling skill carries that source's native assumptions. Strip them: never copy a snippet that names a specific tool or path verbatim into the body as if it were normative. The source is evidence for the *shape* of the instruction, not for its concrete nouns.
5. **Apply the value-preservation test.** Delete every project-specific noun in your head: does the skill still do its job? If removing the specifics guts it, it is mis-scoped — it is project *config*, not an agnostic capability, and does not belong in the shared skill set.

```text
❌ WRONG — leak: a specific runner, command, and path baked into the body as normative.
Run `pnpm test` and confirm the Vitest suite under `src/` is green before you refactor.

✅ CORRECT — parameterized; the consumer repo supplies the command and layout.
Run the project's test command and confirm the suite is green before you refactor.
(The consumer repo fills in the command; in a JS repo this is illustratively `pnpm test`.)
```

## Edge Cases

- **When NOT to apply:** editing a *rule*, a *hook*, a routing manifest, or a `CLAUDE.md` — those are harness files internal to one repo, and they legitimately name that repo's real paths and tools. They are not shareable skills. That is why this rule is scoped to `.claude/skills/**` only.
- A **marked-illustrative** example that names a stack is **not** a leak — it is the sanctioned escape hatch from move 3. Don't flag it.
- A skill's **own structural references** — a relative link to its `references/*.md`, the `Skill` tool, the names of neighbouring skills it hands off to — are part of the skill system, not project coupling. Leave them.
- A user-invoked or reference-only skill (one not reachable by trigger routing) is held to the same agnostic bar as any other skill — being invoked differently does not license stack leaks.

## Review Checklist

- [ ] Grep the skill body for stack/command/path tokens: `grep -nE 'pnpm|npm run|yarn|vitest|jest|tsconfig|node_modules|(^|[^.])src/' .claude/skills/<name>/SKILL.md` — every hit sits inside a marked-illustrative example or is parameterized, never normative prose.
- [ ] Each concrete tool, command, or path is either replaced by the consumer-repo role it fills or explicitly `(illustrative — …)`.
- [ ] No snippet copied verbatim from an external source still carries that source's project nouns.
- [ ] Value-preservation: deleting the project-specific nouns leaves the skill's instruction intact (else it is config, not a skill).
- [ ] Rule applied to skill files only — no leak flagged in a rule, hook, or `CLAUDE.md` (out of scope).
