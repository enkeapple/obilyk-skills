# Vault Expansion Audit — candidate skills / rules / hooks / agents

> Status: **exploratory** — gap analysis, not an approved design. Captured 2026-06-21.
> Method: full inventory of `skills/**`, `.claude/rules/**`, `hooks/**`, then targeted greps to confirm each gap is real (not a duplicate of something that already exists).

## Current inventory (baseline)

- **Skills (26):** `apply-chain/` (resolving-requirements, grilling, writing-specs, writing-plans, pre-implementation-protocol, test-driven-development, inline-driven-development, subagent-driven-development, spec-drift-audit, sdd-lifecycle); `authoring/` (writing-skills, writing-rules, writing-lessons); `foundation/` (bootstrapping-claude-md, auditing-claude-md, bootstrapping-glossary, auditing-glossary); `design/` (codebase-design, improve-codebase-architecture); `process/` (handoff); `prose/` (tightening-prose); `entrypoints/` (sdd, grill, spec, audit).
- **Rules:** `common/` (agnostic-skill-authoring, dogfood-generator-sync, git-conventions, interactive-gates, markdown-style, phase-task-visualization, scoping-skill-value, skill-routing-sync); `domains/` (framework, glossary).
- **Hooks:** `guards/` (bash-read-guard, edit-write-guard, read-guard, security-guard); `quality/` (quality); `routing/` (detect-bypass, log-skill-usage, skill-gate); `session/` (lessons-nudge, reset-turn-budget, token-guard).

## Evidence gathered (verified this session)

- `skills/authoring/writing-skills/SKILL.md` mentions hooks only as "no dependency on any repo hook" — it does **not** teach authoring a hook. No `writing-hooks` / `auditing-hooks` skill exists.
- `hooks/quality/quality.sh` already runs, on PostToolUse: frontmatter ≤1024, balanced fences, `name` regex `^[a-z0-9-]+$`, `name == dir`, reference-link resolution. It does **not** check project-leakage tokens (`pnpm`, `src/`, …) nor word-count — both of which the operating manual lists as validators.
- No `.claude/agents/` registry exists; subagents are ad-hoc prompt assets (e.g. `grilling`'s `assets/readiness-reviewer-prompt.md`).
- No root `README.md` exists (`ls README*` → none) and no skill covers one — the only top-level docs are the two agent-facing `CLAUDE.md` files. There is no human-facing skill catalog (the GitHub landing page a browser would read), unlike e.g. [mattpocock/skills](https://github.com/mattpocock/skills/blob/main/README.md) whose README is a generated index of every skill with name + description + link.

## Candidate gaps

| # | Candidate | Type | Gap it closes | Confidence |
|---|---|---|---|---|
| S1 | `writing-hooks` (+ `auditing-hooks`) | skill | Authoring asymmetry — hooks are the only first-class artifact with no test-first authoring/audit pair (skills/rules/lessons/claude-md/glossary all have one) | High — verified no such skill |
| S2 | `debugging` / root-cause | skill | Missing link between an observed failure and the TDD fix; today execution jumps straight into `test-driven-development` | Medium — judgment call |
| S3 | `auditing-routing` | skill | `skill-routing-sync` exists as a *rule* but there's no audit skill (foundation pattern is bootstrap+audit per target) | Medium |
| S4 | repo-orientation / onboarding | skill | APPLY mode on an unfamiliar consumer repo starts with no orientation skill before `grilling` | Low–Medium |
| H1 | leak-validator | hook | `agnostic-skill-authoring` rule exists but nothing mechanically flags `pnpm`/`src/`-shaped leakage in an agnostic skill | High — verified absent in quality.sh |
| H2 | word-count validator | hook | Listed as a validator in CLAUDE.md but absent from `quality.sh` | High — verified absent |
| A1 | subagent registry | agents | RED/GREEN pressure-test runner, readiness-reviewer, leak-detector are ad-hoc prompt assets, not reusable agent types | Medium |
| R1 | `reviewing-code` | skill | Correctness/quality diff review exists only as `subagent-driven-development`'s `code-quality-reviewer-prompt.md` asset — no routable skill, none for inline mode; chain goes implement → spec-drift-audit with no bug-hunt step | High — verified |
| H3 | integrity hook (`SessionStart`) | hook | `skill-routing-sync` invariant (SKILL.md ↔ routing key ↔ flat symlink) is enforced manually; no `SessionStart` hook is wired and no hook does `readlink` | High — verified |
| H4 | promotion-debt nudge | hook | 3× cause-tag promotion threshold is scanned manually by `writing-lessons`; a `Stop`-side check (next to `lessons-nudge.sh`) could flag a tag that hit 3× un-promoted | Medium |
| H5 | `markdown-style` enforcement | hook | No hook references markdown — the `markdown-style` rule is manual-only; `quality.sh` already mechanizes fences/frontmatter/links and could host heading-level / fence-lang checks | High — verified |
| R2 | `reconciling-spec` | skill | `spec-drift-audit` only reports drift + dispositions (no "update the spec"/"reconcile"); when drift is intentional, nothing amends the spec to the new truth — open feedback loop | Medium |
| S5 | `restructuring-vault` | skill | Moving a skill/asset dir + atomically fixing symlinks, routing, and cross-links is recurring and error-prone (cf. commit 89d90ce references→assets); partly covered by `skill-routing-sync` but no end-to-end safe-refactor procedure | Medium |
| H6 | guard direct `lessons-learned.md` edits | hook | Non-negotiable #6 forbids editing `lessons-learned.md` outside `writing-lessons`, but `edit-write-guard.sh` doesn't cover it (it already guards `.claude/hooks`/settings) — rule exists, enforcement doesn't | High — verified |
| H7 | glossary-coverage checker | hook/agent | `auditing-glossary` asserts "a claim that greps to nothing is a hallucination" but verifies it manually; a hook/agent grepping each ownership-table cell and failing on zero hits mechanizes it | High — verified |
| RT | token-budget policy rule | rule | `token-guard.sh` enforces a per-turn/session budget with no rule documenting the thresholds/policy — source of truth lives only in hook code | Low–Medium |
| S6 | `bootstrapping-readme` (+ `auditing-readme`) | skill | No root `README.md` and no skill owns one — the vault has no human-facing skill catalog (the GitHub landing page), only agent-facing `CLAUDE.md`. Slots into the foundation bootstrap+audit pattern; the README is a generated index of every skill (name + description + link, cf. `mattpocock/skills`), kept true by the audit half against `skills/**` frontmatter. **Agnostic caveat:** must catalog skills from disk frontmatter, never hard-code this vault's list — same generator works on any skills-bearing repo. | High — verified no README and no skill |

## Recommendation (for grilling, not yet approved)

Start with **S1 (writing-hooks / auditing-hooks)**: it is the cleanest single design, the gap is verified, and it slots into the existing `authoring/` + `foundation/` pattern. **H1/H2** are a cheap, mechanizable second batch (close the stated-vs-real validator gap). **A1** is the most ambitious (changes how the vault runs RED/GREEN) and should come last.

**S6 (bootstrapping-readme / auditing-readme)** is a strong early pick alongside S1: same foundation bootstrap+audit shape, verified gap, low blast radius (a doc, not a guard), and it produces the one thing the repo currently lacks for a human visitor. Its audit half also exercises the "frontmatter-as-source-of-truth" pattern the validators already rely on. Sequence S6 after S1 only because hooks are the more glaring authoring asymmetry; S6 has the better effort/payoff ratio if a quick win is wanted first.

## Open questions

1. Priority axis: authoring-symmetry (S1) vs enforcement (H1/H2) vs agent registry (A1) vs apply-chain extension (S2/S4).
2. For S1 — is a single `writing-hooks` enough, or is the bootstrap/audit pair (per the foundation convention) required?
3. For A1 — a real `.claude/agents/` registry, or keep prompt-assets and just standardize them?
4. For S6 — is the README a one-shot generated artifact (bootstrap writes it, audit re-checks drift vs `skills/**` frontmatter), or should a `Stop`/`SessionStart` hook regenerate it so it never drifts? And does it stay agnostic (catalog from disk) vs become a vault-specific landing page?

## Rejected as not relevant (recorded so they aren't re-proposed)

- `writing-pr` — already covered by the `git-conventions` rule.
- `verifying` / run-the-app — project-leak risk; an agnostic vault doesn't run a consumer app.
- `resolving-conflicts` / merge — not core to SDD.
- `subagent-dispatch-prompt` as a standalone rule — already embedded in `subagent-driven-development`.
- body/references/assets placement rule — already owned by `writing-skills` (SKILL.md:98).

## Notes

- Each accepted candidate is itself a skill/hook change → governed by the Iron Law: RED (baseline subagent failure) before any authoring.
- This file is an analysis artifact, not a plan. Promote chosen candidates through `grilling → writing-specs → …`.
