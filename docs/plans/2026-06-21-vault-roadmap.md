# Vault Roadmap — Evidence-Gated, Dogfood-First

> **Date:** 2026-06-21 · **Mode:** planning artifact (not an implementation change)
> **Governing principle:** no roadmap item enters a wave without an *observed RED* — a real failure seen while the chain runs, not a defect imagined in review. This is the vault's Iron Law applied to its own evolution.

## 1. Context — why this shape

A full read-only audit (2026-06-21) found the vault **structurally clean**:

- **Validators** — 28 skills pass: frontmatter ≤1024, `name` regex, `name === dir === symlink`, `references/`/`assets/` links resolve, fences balanced, word counts sane.
- **Routing** — 23 trigger-routed keys in sync with disk; 4 alias entrypoints (`/sdd /grill /spec /audit`) + `improve-codebase-architecture` correctly un-routed (`disable-model-invocation`).
- **Hooks** — 11 hooks (guards/quality/routing/session) all symlinked and wired in `settings.json`; `ruleGates` empty (expected — no `src/`).
- **Rules** — 8 common + 2 domain, no duplicated responsibility.
- **Lessons** — backlog empty, zero promotion debt, `## Promoted clusters` empty.

So the leverage is **not** fixing defects (there are none worth pre-empting) and **not** speculatively adding skills (that violates the Iron Law). The vault's stated purpose is to *surface its own bottlenecks*. It has **never been exercised end-to-end on a real consumer repo** — so it has produced zero real evidence about where it breaks. This roadmap is a plan to generate that evidence, then act only on it.

## 2. Wave 0 — Dogfood run (the only committed work)

Run the full chain on a real, existing project against one real change, and capture every point of friction.

**Target selection (gate on entry):**

- Use an **existing real project** (legacy + real stack + live requirements), not a synthetic stub — a clean stub will not load the chain or expose project-leak.
- Pick **one change that crosses a shared contract** (a new/changed API endpoint, schema, persisted shape, event, navigation route, or one spanning multiple components/services). Rationale: only a contract-crossing change takes the **full-chain exit** through `writing-specs`. A single-behavior change would take `grilling`'s TDD off-ramp and leave `writing-specs → writing-plans → pre-implementation-protocol → subagent-/inline-driven-development` untested.

**The run:**

```
resolving-requirements? → grilling → writing-specs → writing-plans →
pre-implementation-protocol → (subagent- | inline-)driven-development → spec-drift-audit
```

Each implementation task is test-first via `test-driven-development` (real unit tests on the consumer repo's stack — APPLY-mode "test", not a subagent pressure run).

**Capture protocol — at every seam, record the friction:**

- a skill that asked something the codebase already answered, or asked it badly;
- a hand-off that lost context (the downstream skill re-litigated a decision, or missed an artifact the upstream produced — e.g. the Decisions list);
- a skill too rigid (forced ceremony the change didn't need) or too generic (gave no usable guidance);
- project-specific leakage the agnostic skill failed to keep the consumer repo filling;
- a gate that fired wrong (auto-advanced, or blocked with no derivable path forward).

**Funnel into existing machinery — do not invent a new format:**

- Each bottleneck → an entry in `.claude/lessons-learned.md` with a **cause-tag**, captured the same turn via the `writing-lessons` skill (honors the (A)+(B) bar + cause-tag discipline).
- Quantitative signal from `.claude/skills/_metrics.jsonl` (bypass events, invocation frequencies) — read it after the run for skills that were routed-around or never fired.

**Wave 0 output (the deliverable that gates Wave 1):**

- A populated lessons backlog with cause-tags.
- A short metrics read-out (which skills bypassed / unused / over-invoked).

## 3. Wave 1 — Promote (gated on Wave 0 output)

Strictly downstream of evidence. No item here is committed until Wave 0 produces it.

- Any cause-tag that recurred **3×** in the Wave 0 backlog → promote to a rule or a skill edit via `writing-rules` (deletes the contributing lesson entries, records the tag in `## Promoted clusters`).
- A bottleneck that recurred but did not hit 3× stays a lesson — not yet a rule.
- A new skill is authored **only** if a Wave 0 bottleneck is a *missing capability* with a reproducible RED — and then test-first via `writing-skills` (RED → GREEN → REFACTOR → VALIDATE).

This wave has no pre-numbered items by design; its contents are whatever Wave 0 surfaces.

## 4. Hypotheses / Watchlist (NOT committed work)

Candidate work from the audit, parked here until Wave 0 produces an observed RED for it. Listing ≠ promising. Each graduates to a wave only on evidence.

**Candidate capability gaps (no skill today):**

| # | Hypothesis | Watch for in Wave 0 |
| --- | --- | --- |
| H1 | Requirements-traceability (code ↔ source ticket / acceptance criteria) | `spec-drift-audit` compares code↔spec but not code↔source-requirements — does drift slip through? |
| H2 | drift → TDD loop (close a found drift test-first) | `spec-drift-audit` is read-only; is the "fix code" disposition left dangling with no skill? |
| H3 | release / PR workflow | After `spec-drift-audit`, is the PR step ad-hoc and error-prone? |
| H4 | rollback / feature-flag strategy | Does a risky/contract-crossing change reach implementation with no rollback plan? |
| H5 | observability validation (metrics/logs/alerts the spec assumed) | Is monitoring silently dropped from the built feature? |
| H6 | breaking-change impact analysis (trace schema/API change to consumers) | `spec-drift-audit` flags schema drift critical but offers no consumer-impact step — is that a real gap? |

**Coherence seams (minor, debatable — confirm or dismiss in Wave 0):**

- S1 — `grilling` produces a Decisions list; `writing-specs` consumes it only under "approved design", with no named slot. Does a decision get re-litigated downstream?
- S2 — `pre-implementation-protocol` uses a Go/No-go verdict while other gates use the present→approve model. Does the inconsistency confuse the run?

**Harness / meta observations (parked):**

- M1 — no committed fixture tests for any hook (CLAUDE.md describes fixture-execution; none exist on disk).
- M2 — `quality.sh` validates skills but not rule files.
- M3 — the lessons→rule promotion pipeline has never been exercised end-to-end (Wave 0 + Wave 1 will be its first real run).
- M4 — no automation flags stale symlinks or overlapping routing triggers.

## 5. Out of scope (YAGNI)

- No new skills authored now — all six candidates (H1–H6) wait for RED.
- No harness tooling (CI, auto-validators for rules, symlink/trigger linters) until dogfood shows manual checks actually proceed to fail.
- No preemptive fix of the Decisions-list seam (S1) or the Go/No-go gate (S2) — they ride the watchlist and surface only if Wave 0 hits them.

## 6. Definition of Done (this roadmap)

The roadmap is *done driving* when:

1. Wave 0 has run end-to-end on a real contract-crossing change.
2. Every observed bottleneck is captured as a tagged lesson (or the run produced none, recorded explicitly).
3. Each watchlist hypothesis (H1–H6, S1–S2, M1–M4) is resolved to one of: **confirmed** (→ Wave 1 with its RED), or **dismissed** (no RED observed — recorded so it is not re-raised by reflex).

## 7. Next step

This document is the planning artifact. Execution of **Wave 0 is a separate future session**: open the chosen consumer repo and enter the chain at `resolving-requirements` (ticket) or `grilling` (free-text idea), carrying the capture protocol above.
