# Handoff — guardrails-kit logging redesign (resume point)

Resume doc for the next session. **Supersedes** `docs/audits/handoff-guardrails-hooks-audit.md` (the audit-phase handoff — its candidate work items are now mostly executed; see below). Mode for resume: **APPLY** (running the gated SDD chain on the guardrails-kit, each build test-first via `writing-hooks`).

## Where everything lives (reference, do not duplicate)

- **Durable audit + approved logging architecture:** `docs/audits/2026-06-24-guardrails-kit-hooks.md` — read first. Its remediation backlog + improvements are now status-tagged `[DONE]` / `[DEFERRED]`.
- **Per-build specs/plans:** `docs/specs/2026-06-24-*.md` + `docs/plans/2026-06-24-*.md` (correctness-fixes, slim-metrics-schema, hook-common-lib, prompt-corpus-capture).
- **ADR:** `docs/adr/0001-shared-hook-preamble-lib.md` (+ `docs/adr/README.md` index — numbered convention established this session).
- **Lesson captured this session:** `errexit-failopen-idiom` in `.claude/lessons-learned.md`.
- Hooks under work: `plugins/guardrails-kit/hooks/` (8 hooks + `lib/common.sh` + `hooks.json`).

## What's DONE (committed)

Verified per build via RED→GREEN + independent Layer-2 (fresh Sonnet) + spec-drift audit (zero drift each):

- **#1 Correctness fixes** (H1 `reset-turn-budget` GC crash, H2 `friction-log` over-count, M2 `log-skill-usage` fail-open, M1 `quality` link check, L1 `detect-bypass` corrupt-state) — committed.
- **#2 Slim `_metrics.jsonl` schema** — dropped `triggers` + `invoked_without_trigger`, added `v`/`type`/`session`/`ts`; updated consumer `scripts/metrics-report.sh` (`.type` discrimination + stale-path fix) — committed.
- **Lib refactor** — `hooks/lib/common.sh` (`hook_sid`/`hook_state_dir`/`hook_require_json`); 7 hooks migrated; commit `d3302e1`. ADR-0001 recorded.
- **#3a Prompt corpus capture + single-writer** — `reset-turn-budget` opens `pending-prompt.json` (+ monotone `session-turn`); `log-skill-usage` finalizes → `.claude/state/prompts/YYYY-MM-DD.jsonl` (sole writer); `detect-bypass` dropped the `trigger_bypass_warn` metric (keeps warn+flag); `hooks.json` Stop reordered (`friction-log` first). Commit `03d1b81`.

## Verification baseline (snapshot this session)

- `git status --short` → only ` M .claude/settings.json` (NOT touched by this work — leave it / human owns).
- `bash -n` clean on all 9 guardrails hooks + `lib/common.sh`; `jq -e . hooks.json` valid.
- All committed work is audit-clean (zero drift) + Layer-2 ALL PASS.

## What's NEXT — remaining of handoff #3 + tail (human picks order/scope before any build)

`#3` was decomposed (this session, in `grilling`) into 3a–3d; 3a is done. Remaining:

1. **3b — Retention:** daily-rotate `_metrics.jsonl` + `prompts/` and a single **14-day GC**, replacing the crash-prone 7-day session-dir GC in `reset-turn-budget`. (Approved architecture, "Improvements" #5.)
2. **3c — Scratch hygiene:** `SessionEnd` teardown of per-session scratch (+ optional TMPDIR move). **GATED:** first verify a `SessionEnd` hook event actually exists in Claude Code (the vault's `hook-events.md` does NOT list it — use `claude-code-guide` or the official docs). If it doesn't exist, redesign teardown.
3. **3d — State-contract doc** (`state/README` or a glossary row: which files are ephemeral vs durable, who writes each, retention).
4. **#4 — `prompt-coach` skill** in `learning-kit` (reads `.claude/state/prompts/*.jsonl`; the corpus now EXISTS to read). Author via `writing-skills` (RED→GREEN→REFACTOR→VALIDATE).
5. **L2 (config bucket)** — `\d` → `[0-9]` in the `resolving-requirements` trigger in `.claude/skills-routing.json` (routing-data; `skill-routing-sync` rule applies).
6. **Dead-branch config decision** — whether to activate `skill-gate` Pass 1/2 + `detect-bypass` check 1 by populating `editGlobs`/`ruleGates`/`local` skill `files`, or accept inert (the largest lever on whether the guardrails actually guard).
7. **Consolidated logging ADR (ADR-0002)** — DUE once 3b/3c land (two-stream telemetry + capture mechanism + single-writer; deferred twice intentionally so it isn't superseded mid-flight).

## Gates / skills to invoke on resume

- Front door for any build: `sdd-lifecycle` (the chain ran cleanly all session: grilling→specs→plans→pre-impl→inline-driven-development→ADR-gate→spec-drift-audit, each gated).
- Any hook edit → `writing-hooks` first (fixture-execution is RED/GREEN). **Heed the captured lesson:** source a lib with `[ -r "$LIB" ] || exit 0; . "$LIB"`, NEVER `. lib || exit 0` (fails closed under `set -e`).
- `#4` skill → `writing-skills`. Editing `.claude/skills-routing.json` → `skill-routing-sync` rule.
- **Environment quirk (this machine):** `grep`/`rg` are shimmed and error on DIRECT calls in the Bash tool — use `jq`/`awk`/`[[ ]]` for assertions; hooks' own internal `grep` runs fine when they execute.

## Verification model (vault)

No `pnpm`/build/unit-test pipeline. Verification = `writing-hooks` fixture-execution (crafted stdin → run → assert exit/metric/stderr + fail-open + missing-lib exit 0) + `bash -n` + `jq` on JSON + an independent Layer-2 subagent (different model) re-running the fixtures. Each future build re-runs its own RED/GREEN.
