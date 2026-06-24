# Handoff — guardrails-kit hooks audit + logging redesign

Resume doc for the next session. Mode: AUDIT (read-only review + forward-looking design). No code was written or intended this session — all build work is deferred and goes test-first.

## Where everything lives (reference, do not duplicate)

- **Audit report (the durable artifact):** `docs/audits/2026-06-24-guardrails-kit-hooks.md`. Read this first; it contains all findings, the remediation backlog, AND the approved logging design.
- Hooks under audit: `plugins/guardrails-kit/hooks/` (8 hooks).

## What's done

- All 8 hooks audited via one-subagent-per-hook fixture-execution (`writing-hooks` methodology). Per-hook PASS/FAIL + evidence captured in the report.
- Two high-severity bugs independently re-verified in main context: **H1** `reset-turn-budget` GC deletes the live session dir → crash + state loss (`mkdir -p` doesn't refresh mtime on macOS); **H2** `friction-log` counts lines not results → phantom `error` events on multi-line error text.
- Report sections written: Summary table, per-hook findings, dead-in-this-repo branches, cross-hook interactions, `friction-log` explanation, ranked remediation backlog, **Improvements — .claude/state folder & logging**, **What to fix — consolidated**, **Proposed logging architecture (approved design)**.
- `_metrics.jsonl` clarified for the user (single shared cross-session file; no `session` field on any record — verified on the live file).

## Approved design decisions (logging redesign) — locked, do not re-litigate

- Retention ≤ **14 days** for both streams + per-session scratch.
- Prompt record = **text + outcome** (tools_used, friction, bypass).
- Corpus scope = **only the user's own `UserPromptSubmit` prompts** (not subagent dispatches).
- **Two separate JSONL streams** (telemetry vs prompt corpus), one template convention: every record carries `v` + `type` + `session`.
- Drop the `triggers` regex field (−61% file size) and drop the `invoked_without_trigger` event.
- Capture: prompt record opened at `UserPromptSubmit`, finalized at `Stop` by a single writer (`log-skill-usage`).
- Analysis layer = a new user-invoked skill in `learning-kit`, working name `prompt-coach` / `prompt-insights` (narrow prompt-quality sibling of a global "Insights"-style command).

## Next (tomorrow) — pick start, each built separately and TEST-FIRST

The human decides order/scope before any build. Candidate work items (all deferred this session):

1. **Fix correctness bugs** via `writing-hooks` (fixture RED → fix → GREEN), priority: H1 → H2 → M2 (`log-skill-usage` fail-open) → M1 (`quality` hidden link) → L1 (`detect-bypass` exit 5).
2. **Slim `_metrics.jsonl` schema** — drop `triggers`, drop `invoked_without_trigger`, add `session` + `v` + `type` to every record (closes the per-session gap the user raised).
3. **Build the prompt corpus** — new `prompts/YYYY-MM-DD.jsonl`, opened at `UserPromptSubmit`, finalized at `Stop`; 14-day GC; replaces the crash-prone 7-day session-dir GC.
4. **Author the `prompt-coach` skill** in `learning-kit` via `writing-skills` (RED→GREEN→REFACTOR→VALIDATE) — reads the corpus, audits prompting quality.
5. **Config decision (not code):** whether to activate the dead enforcement branches (`skill-gate` Pass 1/2, `detect-bypass` check 1) by populating `editGlobs`/`ruleGates`/`local`-skill `files` in `.claude/skills-routing.json`.

## Gates / skills to invoke on resume

- Any hook edit → invoke `writing-hooks` first (fixture-execution is its RED/GREEN). Hook files in `hooks/guards/` are protected by `edit-write-guard`; the guardrails-kit hooks under `plugins/guardrails-kit/hooks/` are normal edits but still test-first.
- The new skill → invoke `writing-skills`.
- Editing `.claude/skills-routing.json` → `skill-routing-sync` rule applies.

## Verification baseline

N/A — vault audit, no consumer typecheck/lint pipeline. Verification here = skill validators + subagent fixture runs (already done for the audit; future builds re-run their own RED/GREEN).
