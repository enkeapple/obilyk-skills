# Spec: SDD entry-point alias skills

> Status: approved design (grilling + readiness gate passed) → spec for review.

## Goal

Add short, user-typed slash entry points (`/sdd`, `/grill`, `/spec`, `/audit`) to the SDD chain as thin **alias skills** that delegate to the canonical chain skills. Determinism already exists (every skill is invocable as `/<dir-name>`); this only adds memorable short names without duplicating any logic.

## Scope

- New category folder `skills/entrypoints/` holding 4 alias skill directories.
- 4 alias skills + their flat symlinks in `.claude/skills/`:
  - `sdd` → `sdd-lifecycle`
  - `grill` → `grilling`
  - `spec` → `writing-specs`
  - `audit` → `spec-drift-audit`
- Each alias: `disable-model-invocation: true`, body delegates to the canonical skill and forwards `$ARGUMENTS`.
- Reword `skill-routing-sync.md` carve-out + checklist around the invariant **`disable-model-invocation: true` ⇒ no routing key** (covers reference skills AND alias facades), plus a line: renaming a canonical skill requires fixing the alias body that names it.
- Add a `glossary.md` edge-case line generalizing "no routing entry" to all `disable-model-invocation` skills, plus a short "alias skill" sub-kind definition.
- Add the 4 short entry points to the root `CLAUDE.md` skill-routing table.

## Out of scope

- No `.claude/commands/*.md` files — that path is the legacy equivalent of a skill; aliases are real skills.
- No `/plan` alias — collides with the built-in `/plan` (plan mode). Planning is reached via the `/sdd` gate or `/writing-plans`.
- No aliases for `resolving-requirements` (subsumed by `/sdd <ticket>`), `pre-implementation-protocol`, the execution skills (chosen via the inline/subagent fork inside the flow), or any authoring/foundation skill.
- No moving orchestration logic out of canonical skills — aliases only delegate.
- No `agents/` or `context/` directories.
- No change to `skills-routing.json` (aliases get no entry), `detect-bypass.sh`, or any hook.

## Contracts

### Alias SKILL.md frontmatter (each of the 4)

Mirrors the `disable-model-invocation` precedent (`skills/authoring/writing-great-skills/SKILL.md:1-4`) plus `argument-hint` (precedent `skills/process/handoff/SKILL.md:11`). `name` MUST equal the directory name.

```yaml
---
name: sdd
description: Short user-typed entry point that runs the full gated SDD pipeline. Alias for the sdd-lifecycle skill.
disable-model-invocation: true
argument-hint: "<feature idea or ticket ID, optional>"
---
```

### Alias SKILL.md body (each of the 4)

Control prose that steers classification + forwards the typed input. `$ARGUMENTS` is the documented all-args placeholder; control prose is the vault-proven mechanism (handoff). Both are included; verification-by-invocation (below) confirms the input actually arrives.

```text
Use the `sdd-lifecycle` skill. Treat the input below as the build request and
classify it per that skill's entry table (a bare ticket ID or URL routes to
`resolving-requirements`; a free-text idea enters at `grilling`).

Input: $ARGUMENTS
```

Per-alias canonical target and one-line intent:

| Alias dir | Canonical skill named in body | Body intent line |
| --- | --- | --- |
| `sdd` | `sdd-lifecycle` | classify input per entry table (ticket → resolving-requirements; idea → grilling) |
| `grill` | `grilling` | treat input as the idea to grill into a design |
| `spec` | `writing-specs` | treat input as the approved design / requirements to spec |
| `audit` | `spec-drift-audit` | treat input as the spec/area to audit shipped code against |

### Symlink target format

Matches the established relative two-up pattern (`.claude/skills/grilling -> ../../skills/apply-chain/grilling`):

```text
.claude/skills/sdd   -> ../../skills/entrypoints/sdd
.claude/skills/grill -> ../../skills/entrypoints/grill
.claude/skills/spec  -> ../../skills/entrypoints/spec
.claude/skills/audit -> ../../skills/entrypoints/audit
```

### `skill-routing-sync.md` reword (invariant change)

The carve-out at `.claude/rules/common/skill-routing-sync.md:56` keys on "reference/methodology skill … and declares no trigger phrases". Re-key it on the property, not the skill kind:

- Carve-out becomes: **any skill with `disable-model-invocation: true` is not trigger-routed and gets NO `skills` key** — this covers both reference skills (e.g. `writing-great-skills`) and alias-facade skills (e.g. `sdd`).
- Checklist line at `:62` ("Every invocable skill directory … (excluding `disable-model-invocation` reference skills) has exactly one matching key") → exclusion broadened to "(excluding any `disable-model-invocation` skill — reference or alias facade)".
- Add one line under Implementation: renaming/moving a canonical skill requires fixing the alias body that names it (the alias body is a structural skill-name reference).

### `glossary.md` additions

- Edge-case line generalizing the reason at `.claude/rules/domains/glossary.md:44` ("`writing-great-skills` … is NOT trigger-routed"): the cause is `disable-model-invocation: true`, which applies to two sub-kinds — **reference skills** and **alias-facade skills** — both correctly absent from `skills-routing.json`.
- Short definition: an **alias skill** is a thin `disable-model-invocation` facade under `skills/entrypoints/` whose body delegates to one canonical skill and forwards `$ARGUMENTS`; it holds no logic of its own. The invariant `name === dir === SKILL.md name` still holds.

## Files touched

| File | Kind | Why |
| --- | --- | --- |
| `skills/entrypoints/sdd/SKILL.md` | NEW | `/sdd` alias → `sdd-lifecycle` |
| `skills/entrypoints/grill/SKILL.md` | NEW | `/grill` alias → `grilling` |
| `skills/entrypoints/spec/SKILL.md` | NEW | `/spec` alias → `writing-specs` |
| `skills/entrypoints/audit/SKILL.md` | NEW | `/audit` alias → `spec-drift-audit` |
| `.claude/skills/sdd` | NEW (symlink) | discovery symlink → `../../skills/entrypoints/sdd` |
| `.claude/skills/grill` | NEW (symlink) | discovery symlink → `../../skills/entrypoints/grill` |
| `.claude/skills/spec` | NEW (symlink) | discovery symlink → `../../skills/entrypoints/spec` |
| `.claude/skills/audit` | NEW (symlink) | discovery symlink → `../../skills/entrypoints/audit` |
| `.claude/rules/common/skill-routing-sync.md` | EDIT | reword carve-out (~:56) + checklist (~:62) to the `disable-model-invocation ⇒ no key` invariant; add canonical-rename→fix-alias line |
| `.claude/rules/domains/glossary.md` | EDIT | add `disable-model-invocation` generalization (~:44) + "alias skill" sub-kind definition |
| `CLAUDE.md` | EDIT | add the 4 short entry points to the skill-routing table |

Not touched (asserted): `.claude/skills-routing.json`, every `hooks/**` file, `.claude/CLAUDE.md`.

## Edge cases

- **No argument** (`/sdd` with empty input): `$ARGUMENTS` expands empty; the alias body still delegates and the canonical skill runs its normal no-input interview/flow. Acceptable — alias adds no requirement that an arg be present.
- **Bare ticket ID** (`/sdd ACME-123`): the body's classification prose must steer `sdd-lifecycle` to route a bare ID to `resolving-requirements`, NOT mis-classify as a fuzzy idea → `grilling`. This is the load-bearing edge case; verification below exercises it.
- **Multi-word input** (`/grill add dark mode toggle`): `$ARGUMENTS` carries the full string; canonical skill receives it as the idea.
- **`$ARGUMENTS` does not expand** (placeholder unsupported in a skill body in this harness): the verification step catches it; fallback is the handoff-style prose form ("pass the user's typed input to it"). Recorded as a Risk.
- **Name-regex / word-count validators on a near-empty body**: a 1–3 line body passes name-regex (`name` = dir), frontmatter ≤1024, links-resolve (none), fence-balance (none); validators have no minimum-word floor (confirmed conceptually — validators are structural, per root `CLAUDE.md` → Common commands). Aliases are deliberately minimal.
- **`detect-bypass.sh` with no routing entry**: the hook iterates `.skills | to_entries[]` from `skills-routing.json`; an alias absent from that map never matches a loop — no key lookup fails. No hook change needed (confirmed by readiness review reading `detect-bypass.sh`).

## Verification

Structural validators (per root `CLAUDE.md` → "Common commands"; no build/test pipeline exists):

- **Frontmatter / name-regex / fences / links**: each alias `name` equals its dir; frontmatter < 1024 chars; no unbalanced fences; body has no broken reference links.
- **Symlinks resolve**: `ls -l .claude/skills/{sdd,grill,spec,audit}` each points at the matching `skills/entrypoints/<alias>` and resolves.
- **Routing untouched**: `git diff --stat` shows no change to `.claude/skills-routing.json`; `jq '.skills | has("sdd")' .claude/skills-routing.json` → `false` for all 4 aliases.
- **Routing-sync checklist passes for aliases**: under the reworded rule, `find skills/entrypoints -name SKILL.md` vs `jq '.skills|keys'` — the 4 aliases are correctly excluded (each has `disable-model-invocation: true`), not flagged as missing keys.

Verification-by-invocation (REQUIRED — RED/GREEN is N/A for a pure facade, so behavior is proven by use):

- In a session, type `/sdd ACME-1234`; confirm (a) the input reaches `sdd-lifecycle`, and (b) it classifies to `resolving-requirements`, not `grilling`.
- Type `/grill add a setting`; confirm `grilling` starts with that idea as input.
- Type `/spec` and `/audit` (no arg); confirm each launches its canonical skill.
- A `/sdd` absent from the `/` picker *before* a session restart is NOT a RED failure (new top-level skills dir; see Risks) — verify after restart.

### dogfood-generator-sync determination (implementer must record, not skip)

The `glossary.md` and `skill-routing-sync.md` edits are vault-internal harness conventions. Before calling the edits done, grep `skills/foundation/bootstrapping-*/` for the reworded sections; expected determination is `[N/A]` — no `bootstrapping-*` template ships the "alias skill" concept or the `disable-model-invocation ⇒ no key` carve-out to a consumer repo — but record it explicitly per `.claude/rules/common/dogfood-generator-sync.md` rather than skipping silently.

## Risks

- **`$ARGUMENTS` interpolation unproven in this vault.** CC docs list `$ARGUMENTS` as a skill-body placeholder, but the only arg-consuming vault skill (`handoff`) uses prose, not the token. Mitigation: alias body includes BOTH the token and steering prose; verification-by-invocation confirms arrival; documented fallback is prose-only if the token does not expand.
- **Classifier mis-route of a bare ticket ID.** `sdd-lifecycle:29` says "Route the input" assuming a conversational request; a delegated bare ID could fall to `grilling`. Mitigation: explicit classification prose in the alias body (Contracts); exercised by verification.
- **Rule reword regresses an existing check.** Broadening the carve-out from "reference skill" to "any `disable-model-invocation` skill" must not let a genuinely mis-registered skill slip. Mitigation: the invariant is strictly narrower in effect (only `disable-model-invocation` skills are exempted, which is exactly the set that must have no key); re-read the full checklist after the edit.
- **Discovery of a new top-level skills dir may need a restart.** Adding `skills/entrypoints/` + symlinks: per CC docs, adding/removing a top-level skills directory can require a session restart to load. Mitigation: note that the new aliases may only appear in `/` after restart; not a correctness defect.
