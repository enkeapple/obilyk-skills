# Guardrails-kit hooks — correctness audit (2026-06-24)

State-of-the-hooks report. Read-only audit of all 8 hooks in `plugins/guardrails-kit/hooks/`, run one-subagent-per-hook via the `writing-hooks` fixture-execution methodology (crafted stdin → run script → assert decision + fail-open on garbage). No code was changed. The two high-severity findings were independently re-verified in the main context.

**Method:** each hook was driven with a fixture matrix (happy path, edge cases, documented behaviors, garbage/non-JSON stdin) in an isolated `CLAUDE_PROJECT_DIR` sandbox. Cross-hook interactions and "dead in this repo's config" findings were synthesized afterward, since an isolated per-hook subagent cannot see them.

## Summary

| Hook | Event | Verdict | Headline issue |
| --- | --- | --- | --- |
| `reset-turn-budget` | UserPromptSubmit | **BUGS (high)** | GC deletes the live session dir → hook crashes (`exit 1`), turn state wiped |
| `friction-log` | Stop | **BUGS (high)** | Multi-line error text counted per-line → phantom `error` events, inflated counts |
| `quality` | PostToolUse | **BUGS (med)** | Backtick-skip regex silently hides a broken reference link |
| `log-skill-usage` | Stop | **BUGS (med + noise)** | `set -e` + jq on malformed routing → `exit 5` (not fail-open); up to ~28 metric lines/turn |
| `detect-bypass` | PostToolUse | **BUGS (low) + DEAD** | `exit 5` on corrupt state; check (1) `read_instead_of_skill` is dead in this repo |
| `skill-gate` | PreToolUse | **OK + DEAD** | Pass 1 & 2 structurally inert here (no `editGlobs`, empty `ruleGates`); only Pass 0 live |
| `token-guard` | PostToolUse | **OK** | +1-byte/call measurement drift (sub-token, harmless) |
| `lessons-nudge` | Stop | **OK** | None — clean |

**The big picture (what likely feels "not quite right"):** a large fraction of the guardrail *surface* is inert in this repo by configuration, not by bug — `skill-gate`'s two enforcement passes and `detect-bypass`'s read-on-skill-body check can never fire given the current `skills-routing.json` (all entries are `kind:"ref"` with no `files`, no skill has `editGlobs`, `ruleGates` is `{}`). On top of that, the two telemetry Stop hooks (`friction-log`, `log-skill-usage`) produce inflated/noisy counts, so the metrics they feed are not trustworthy as-is.

## High-severity findings (independently re-verified)

### H1 — `reset-turn-budget.sh`: opportunistic GC deletes the live session dir

- **Where:** line 11 `mkdir -p "$STATE_DIR"`, then line 19 `find "$STATE_BASE" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} +`, then lines 21–24 write into `$STATE_DIR`.
- **Cause:** `mkdir -p` on an **already-existing** directory is a no-op on macOS — it does **not** refresh the directory's mtime. The comment on line 15 ("the current session's dir was just created above (fresh mtime) so it is never collected") is **only true for a brand-new dir**. If a session's state dir is older than `GC_DAYS=7` (e.g. a session resumed after a week of idle), GC deletes it, and the writes on lines 21–24 then fail under `set -euo pipefail`.
- **Verified repro:**

```text
mkdir -p "$SANDBOX/.claude/state/racetest"
touch -t 202606010000 "$SANDBOX/.claude/state/racetest"   # stale (>7d before 2026-06-24)
echo '{"session_id":"racetest","prompt":"hello"}' | CLAUDE_PROJECT_DIR="$SANDBOX" bash reset-turn-budget.sh
# → line 21: .../racetest/turn-budget.json: No such file or directory
# → exit=1 ; the session dir was deleted
```

- **Impact:** on a resumed/long-idle session the per-turn state reset fails and the hook exits non-zero (a fail-open violation on the state-reset path). Trigger is narrow (session dir mtime older than 7 days — note that active sessions keep refreshing the dir mtime via other hooks' `.tmp` renames, so it bites idle-then-resumed sessions), but the failure mode is a crash + state loss, hence high.
- **Direction of fix (not applied):** `touch "$STATE_DIR"` immediately after `mkdir -p`, or run GC *before* creating the current session dir.

### H2 — `friction-log.sh`: multi-line error text is counted per line, not per result

- **Where:** lines 50–53. `TEXTS=$(jq -rc '…')` emits the text of each `is_error` result, but a result whose `.content` contains `\n` becomes multiple output lines. All three counters (`grep -ciE` denied, `grep -ciE` blocked, `grep -c .` total) then count **lines**, and `cur_error = cur_total - cur_denied - cur_blocked` over-counts.
- **Verified repro:** one `denied` result with 3-line content:

```text
content = "user doesn't want to proceed\nextra line one\nextra line two"
# emitted metrics:
{"event":"friction","class":"denied","count":1}
{"event":"friction","class":"error","count":2}   # phantom — there was no error result
```

- **Impact:** multi-line error content is the **common** case (command output, stack traces, tool error dumps). Counts are inflated and a single denied/blocked result manufactures phantom `error` events. The telemetry this hook exists to produce is unreliable on realistic input. High (accuracy of the headline friction KPI).
- **Direction of fix (not applied):** have `jq` emit exactly one line per `tool_result` (e.g. replace internal newlines, or `@json`-encode), then the line-count equals the result-count.

## Medium-severity findings

### M1 — `quality.sh`: backtick-skip regex hides a real broken link (line 54)

The "skip links shown inside inline backticks" guard is `grep -q '`[^`]*\]('`. Because grep scans from every position, a line with a *closed* inline-code span **before** a real link matches the pattern and the whole line is skipped.

```text
echo 'See `code` and then [missing](./gone.md)' | grep -q '`[^`]*\](' && echo SKIP
# → SKIP  (the broken ./gone.md reference is silently not reported)
```

The intended positive case (`` `[link](path)` `` fully inside backticks) still works; only "closed backticks earlier on the same line as a real link" is mis-classified. Impact: the link validator under-reports — false negatives, never false blocks (advisory hook, always exits 0).

### M2 — `log-skill-usage.sh`: not fail-open on malformed routing; metric-line volume

- **Fail-open gap (line 41):** under `set -euo pipefail`, the `jq -r '.skills | to_entries[] …'` pipeline exits 5 if `skills-routing.json` lacks a `skills` key (truncated/var write), and `pipefail` propagates it — the hook exits 5 instead of 0, and the `turn-skills-invoked.json` reset on line 68 never runs (stale state). Bounded (Stop hook, non-blocking) but violates the stated invariant. Fix: `jq -r '.skills // {} | …'` or guard `|| true`.
- **Noise:** the per-skill loop emits a line for **every** routing entry whose trigger union matches the prompt. A broad exploratory prompt produced 6 `bypass` lines in one Stop event; a "mentions everything" prompt up to ~28. The wide trigger phrases (`"brainstorm"`, `"I want to (add|build|implement|create)"`) make this easy to hit — analytics over `_metrics.jsonl` will see many low-meaning `bypass` rows.

## Low-severity findings

### L1 — `detect-bypass.sh`: `exit 5` on corrupt per-turn state (lines 77, 92)

Bare `INVOKED=$(jq -r … "$TURN_SKILLS_FILE")` under `set -euo pipefail`: if the state file is non-JSON, jq exits 5 and the hook aborts with 5 (fail-open violation). The same call inside check (2) is protected because it runs in a `$(… | while …)` subshell. Inconsistent guarding. Fix: `2>/dev/null || true` on those assignments.

### L2 — `\d` in the `resolving-requirements` trigger is non-portable (routing data, affects two hooks)

The routing trigger `[A-Z][A-Z0-9]+-\d+` uses `\d`, which is **not** POSIX ERE. It matches on this machine only because `grep` resolves to ugrep/PCRE2; on stock BSD or GNU grep `\d` matches a literal `d`, so ticket-ID prompts (`FLIBCO-1234`) would silently fail to trigger the bypass warn in both `detect-bypass.sh` and `log-skill-usage.sh`. This is a `skills-routing.json` data issue, not hook-code. Portable form: `[A-Z][A-Z0-9]+-[0-9]+`.

### L3 — `skill-gate.sh` cosmetics / edge (lines 21, 54)

- Header comment says "Two passes:" but there are three (Pass 0 memory-block was added later).
- A trailing slash in `CLAUDE_PROJECT_DIR` breaks `REL_PATH="${FILE_PATH#$PROJECT_DIR/}"` (double slash never strips), silently bypassing Pass 1/2 path matching. Dormant — the harness sets `CLAUDE_PROJECT_DIR` without a trailing slash. Pass 0 is unaffected (matches on `FILE_PATH` directly). Fix: `PROJECT_DIR="${PROJECT_DIR%/}"`.

### L4 — `token-guard.sh` +1 byte per measurement (line 35)

`jq -r … | wc -c` counts the trailing newline `jq -r` appends, so every tool_response is recorded 1 byte high. Effect on thresholds is 0.25 token — never trips a false threshold. Harmless; noted for completeness.

## Dead-in-this-repo (by configuration, not bugs)

These branches are correct code that simply cannot fire given the current `skills-routing.json` (schema v2: 26 entries, all `kind:"ref"`, no `files`; no `editGlobs`; `ruleGates: {}`). They would activate in a consumer repo that populates those fields.

- **`skill-gate.sh` Pass 1** (skill `editGlobs` gate) — no skill defines `editGlobs` → never fires.
- **`skill-gate.sh` Pass 2** (`ruleGates` barrier) — `ruleGates` is `{}` → never fires. Only **Pass 0** (block writes to a per-user `.claude/projects/**/memory/` path or `MEMORY.md`) is live.
- **`detect-bypass.sh` check (1)** (`read_instead_of_skill`) — matches a Read against a skill entry's `files`; no `ref` entry has `files` → can never match. Checks (1b) lessons-log direct-edit and (2) trigger-bypass are live and working.

This is consistent with CLAUDE.md ("`skill-gate.sh`'s `ruleGates` are currently empty … no `src/`"), but it means the PreToolUse **barrier** is effectively just a memory-write blocker here, and the read-on-skill-body nudge never runs. If the intent is enforcement, this repo isn't getting it from these branches.

## Cross-hook interactions

- **Duplicate bypass signal across two hooks/events.** A single missed-skill turn produces a `trigger_bypass_warn` line from `detect-bypass.sh` (PostToolUse, mid-turn) **and** a `bypass` line from `log-skill-usage.sh` (Stop, end-of-turn) for the same skill. Distinct event names (no key collision), but downstream analytics must dedupe by `(prompt_hash, skill)` across event types or it double-counts the same occurrence.
- **Shared metrics sink.** All telemetry hooks append to one `.claude/state/_metrics.jsonl`. Given H2 (phantom friction errors) + M2 (bypass-line volume), the file's aggregate counts are not currently trustworthy without post-processing.
- **SID keying is consistent** (verified): `reset-turn-budget`, `detect-bypass`, `skill-gate`, `token-guard`, `log-skill-usage`, `lessons-nudge`, `friction-log` all derive `SID` identically (`jq -r '.session_id // empty' | tr -cd 'A-Za-z0-9._-'`, fallback `default`) and key state under `.claude/state/$SID`. The `lessons-nudge` ← `detect-bypass` flag hand-off (`turn-bypass-warned.flag`) works: Stop fires after the PostToolUse flag is written. No cross-session leakage, no race there.

## How `friction-log.sh` works (you asked)

It is a **Stop** hook (fires when a turn ends) and is **pure telemetry** — it never warns and never blocks. On each turn end it:

1. Reads the turn's transcript (`transcript_path` from stdin) and extracts every `tool_result` whose `is_error == true`.
2. Classifies each by the **fixed shape of its error text** (not by guessing your intent):
   - `denied` — the user rejected the tool ("user doesn't want to proceed" / "user rejected" / "user declined").
   - `blocked` — a PreToolUse hook denied it ("hook error" / "BLOCKED:").
   - `error` — any other `is_error` (non-zero exit, tool failure).
3. **Delta-tracks** the running totals against `.claude/state/<sid>/friction-seen.json`, so a Stop hook that fires more than once never double-counts — it only appends the *new* deltas.
4. Appends `{event:"friction", class, count}` lines to `.claude/state/_metrics.jsonl`.

It deliberately does **not** attempt a semantic "wrong approach" label — that stays with offline analysis. It is fail-open: missing transcript, no `jq`, or garbage stdin all exit 0 with no output.

**Caveat from this audit (H2):** its per-class counts are computed by line-counting the extracted text, so multi-line error messages inflate the counts and fabricate phantom `error` events. Treat its current numbers as directional, not exact, until H2 is fixed.

## Ranked remediation backlog (fixes NOT applied — each should go through `writing-hooks` test-first)

1. **H1** — `reset-turn-budget` GC deletes live session dir (crash + state loss). `touch "$STATE_DIR"` after `mkdir -p`, or GC before create.
2. **H2** — `friction-log` multi-line over-count (telemetry wrong on common input). Make `jq` emit one line per result.
3. **M2** — `log-skill-usage` `exit 5` on malformed routing (fail-open gap) + line-volume noise. `jq '.skills // {}'`; consider tightening triggers.
4. **M1** — `quality` backtick-skip false negative. Tighten the inline-code detection so a closed span before a real link doesn't suppress it.
5. **L1** — `detect-bypass` `exit 5` on corrupt state. Guard the two bare jq assignments.
6. **L2** — `\d` → `[0-9]` in the `resolving-requirements` trigger (routing-data fix; restores ticket-ID detection on non-PCRE grep).
7. **L3 / L4** — `skill-gate` comment + trailing-slash hardening; `token-guard` +1-byte trim. Cosmetic/robustness.
8. **Config decision (not a code bug):** decide whether the dead branches (`skill-gate` Pass 1/2, `detect-bypass` check 1) should be activated here by populating `editGlobs` / `ruleGates` / `local` skill `files` in `skills-routing.json`, or whether the inert state is intended for this repo. This is the largest lever on "do the guardrails actually guard."

## Improvements — `.claude/state` folder & logging

This is forward-looking design (not bugs). Measured on the live tree at audit time.

### What's wrong with the current logs (measured)

- **`_metrics.jsonl` is 61% redundant.** Every `bypass` / `invoked_without_trigger` / `used_correctly` line embeds the **full trigger regex union** for the skill (avg line 272 bytes; `7348 / 12001` bytes = **61% of the whole file** is the `triggers` field). The triggers are fully derivable from `skills-routing.json` by skill key — storing them per line buys nothing and makes the file unreadable.
- **~30% of lines are non-signal.** `invoked_without_trigger` (13 of 44 lines) records "a skill ran whose trigger keywords weren't in the prompt" — which is *normal* (e.g. everything `sdd-lifecycle` dispatches), not a failure. It is pure noise.
- **`bypass` over-emits** (M2): one line per matched routing entry, so a broad prompt yields 6–28 lines for a single turn.
- **Session dirs pile up.** 13 dirs under `.claude/state/`, each 8 files. The only cleanup is `reset-turn-budget`'s `-mtime +7` GC, which (a) only runs when *some* session submits a prompt, so an ended session's dir lingers ≥7 days, and (b) can crash (H1).
- **Ephemeral and durable state are mixed.** Per-turn scratch (`turn-budget`, `turn-skills-invoked`, `turn-reads`, `turn-tool-count`, `last-prompt.txt`, the two `.flag`s) sits in the same dir as session-durable data (`session-budget`, `by-model-budget`, `friction-seen`). The turn-scratch is reset each turn but never removed at session end.
- **No rotation.** `_metrics.jsonl` is append-only and unbounded.
- `.claude/state` **is** gitignored (verified — not tracked), so this is hygiene/readability, not a git-leak risk.

### Proposed improvements (ranked, cheapest-highest-impact first)

1. **Drop the `triggers` field from every metric line.** Instant −61% file size; the analyzer re-derives triggers from routing by skill key. Target schema: `{ts, session, skill, event}` (+ `prompt_hash` only where dedup needs it). One-line change in `log-skill-usage.sh` and `detect-bypass.sh`.
2. **Stop logging non-signal events.** Remove `invoked_without_trigger` entirely. Keep only actionable events: `bypass`, `friction`, `direct_edit_lessons_log`, `read_instead_of_skill`.
3. **One writer per signal — kill the double-count.** `detect-bypass` (PostToolUse, mid-turn) and `log-skill-usage` (Stop) both record the same missed-skill (`trigger_bypass_warn` + `bypass`). Make **Stop the sole metric writer**; let `detect-bypass` only *warn* to stderr. Removes the systematic duplication and roughly halves bypass-related volume.
4. **Split ephemeral from durable; tear down at session end.** Put per-turn scratch under an OS temp dir keyed by session (e.g. `${TMPDIR}/guardrails-<sid>/`) so it never lands in `.claude/state`; keep only durable telemetry (`_metrics.jsonl`, per-session budget summary) under `.claude/state`. Add a `SessionEnd` hook (authored test-first via `writing-hooks`) that removes the session's scratch. This makes the dir-pileup impossible *by construction* rather than relying on age-based GC.
5. **Fix + tighten GC, add rotation.** Fix H1 regardless. Parameterize `GC_DAYS` lower for the durable tree, and rotate `_metrics.jsonl` (roll per day → `_metrics-YYYY-MM-DD.jsonl`, or cap by size) so it never grows unbounded.
6. **Document the state contract.** A short `state/README` or a `glossary` row stating which files are ephemeral (temp, per-turn) vs durable (telemetry, per-session), who writes each, and the retention policy — so future hook edits don't reintroduce scratch into the durable tree.

**Net effect:** the durable footprint becomes a single slim, rotated `_metrics.jsonl` of only actionable events; per-session scratch lives in temp and vanishes at session end; no unbounded growth, no 61%-redundant lines.

### Other hook improvements (beyond the state folder)

- **`token-guard` per-agent accounting is a coarse proxy.** It buckets only the subagent's *final-output* bytes by `subagent_type`/`model`, not the agent's true internal token consumption (the parent `PostToolUse` can't see it). If per-model cost is a real goal, this needs a different data source; otherwise label it explicitly as "final-output bytes only" so it isn't mistaken for true spend.
- **`friction-log` classification coverage.** The `denied`/`blocked` regexes target specific harness strings that aren't verified against what Claude Code actually emits; unmatched rejections silently fall to `error`. Pin the real strings (or treat the split as best-effort) once H2 is fixed.
- **Consolidate the two bypass detectors conceptually.** `detect-bypass` and `log-skill-usage` reimplement the same trigger-matching loop with the same regex-metacharacter fragility (L2). A shared helper (one trigger-match function, one routing read) would remove the divergence risk and the duplicated `grep -iE "$trigger_union"` portability bug.

## What to fix — consolidated (priority order)

Three buckets. Every code change goes through `writing-hooks` test-first (fixture RED → fix → GREEN); routing-data changes are validated by `skill-routing-sync` + `jq`.

1. **Correctness bugs (fix first):** H1 (`reset-turn-budget` GC crash + state loss) → H2 (`friction-log` multi-line over-count) → M2 (`log-skill-usage` fail-open gap) → M1 (`quality` hidden broken link) → L1 (`detect-bypass` `exit 5` on corrupt state).
2. **Logging/state hygiene (the noise you flagged):** improvements 1–3 above are quick wins (drop `triggers`, drop `invoked_without_trigger`, single writer); 4–6 are the structural cleanup (temp-scratch + `SessionEnd` teardown + rotation).
3. **Data/config decisions (not code bugs):** L2 (`\d` → `[0-9]` in the `resolving-requirements` trigger); and the big one — decide whether to activate the dead enforcement branches (`skill-gate` Pass 1/2, `detect-bypass` check 1) by populating `editGlobs`/`ruleGates`/`local`-skill `files`, or accept them as intentionally inert here.

## Proposed logging architecture (approved design)

Forward-looking design for a templated logging format that supports later analysis and adds a durable **prompt-input corpus** for auditing prompt quality. Approved decisions: **retention ≤ 14 days**; each prompt record is **text + outcome**; corpus scope is **only the user's own `UserPromptSubmit` prompts** (not subagent dispatches); the analysis layer is a **separate user-invoked skill** (a narrow, prompt-quality sibling of a global "Insights"-style command). No code here — hooks/skill are built separately, test-first via `writing-hooks` / `writing-skills`.

### What `_metrics.jsonl` is today (and the per-session gap)

`_metrics.jsonl` is a **single, shared, append-only file** at `.claude/state/_metrics.jsonl` — **not** per-session. The `session_id` keying (`SID`) governs only the *ephemeral turn-state dirs* (`.claude/state/<sid>/…`); it is **never stamped into a metric record**. Its purpose: a durable, cross-session telemetry trail for offline analysis of routing health — where a skill trigger fired but the skill wasn't invoked (`bypass` / `trigger_bypass_warn`), where a skill body was Read instead of invoked (`read_instead_of_skill`), where the lessons log was edited directly (`direct_edit_lessons_log`), and turn-end friction (`friction`). It feeds the lessons → rules loop, not the live turn.

The current records have three shapes, and **none carries a session field** (verified on the live file — keys are `{class,count,event}`, `{event,path,ts}`, `{event,prompt_hash,skill,triggers,ts}`):

- `friction-log` → `{event:"friction", class, count}` — no `ts`, no `session`.
- `detect-bypass` → `{ts, event, skill?, path?, tool_count?}` — no `session`.
- `log-skill-usage` → `{ts, prompt_hash, skill, event, triggers}` — no `session`, only a prompt hash.

So the intuition that it "collects from everywhere, not per session" is **correct**: every session's events are interleaved into one file with no way to slice by session — the per-session keying you see in the state dirs does not reach this file. (And `friction` lines have no timestamp either, so they can't even be ordered.) This is exactly what the slim schema below fixes.

### Two streams, both templated, gitignored, GC > 14 days

| Stream | File | Records | Retention |
| --- | --- | --- | --- |
| Telemetry | `.claude/state/_metrics.jsonl` (or `metrics/YYYY-MM-DD.jsonl`) | `skill_event`, `friction` | roll by day, GC > 14d |
| Prompt corpus | `.claude/state/prompts/YYYY-MM-DD.jsonl` | `prompt` (one per turn) | roll by day, GC > 14d |

Separate files (distinct consumers; the corpus is the analysis target), but **one template convention** — every record carries `v` (schema version) and `type` (discriminator), plus a `session` field so any stream can be sliced per session.

### Record templates

```json
{
  "v": 1, "type": "prompt",
  "ts": "2026-06-24T10:15:00Z", "session": "0052fd0a", "turn": 7,
  "prompt": "<full input text>", "chars": 412, "lang": "ru",
  "entrypoint": "grill",
  "triggers_matched": ["grilling"],
  "skills_invoked": ["grilling"],
  "outcome": { "tools_used": 14, "friction": {"denied":0,"blocked":0,"error":1}, "bypass": false }
}
```

```json
{ "v": 1, "type": "skill_event", "ts": "...", "session": "0052fd0a", "skill": "grilling", "event": "bypass" }
{ "v": 1, "type": "friction",    "ts": "...", "session": "0052fd0a", "class": "error", "count": 1 }
```

The `triggers` regex is **not** stored (−61% vs today); the analyzer re-derives it from `skills-routing.json` by skill key. `invoked_without_trigger` is dropped (not a signal).

### Capture mechanism

A `prompt` record is **opened at `UserPromptSubmit`** (text, `lang`, `entrypoint`, `triggers_matched`) and **finalized at `Stop`**, once the outcome is known. Make `Stop` the **single writer**: `log-skill-usage` already runs at `Stop` and sees the prompt (`last-prompt.txt`), the invoked skills, the turn tool-count, and the friction deltas — it assembles the full record and appends it to `prompts/`. One writer also removes the cross-hook double-count (improvement #3).

### Retention / rotation

Both streams roll by date; a single GC removes day-files older than **14 days** (corpus, metrics) and tears down per-session scratch at `SessionEnd` (scratch moves to `${TMPDIR}/guardrails-<sid>/`, so `.claude/state` holds only the dated telemetry + corpus). This replaces the current lax, crash-prone 7-day session-dir GC (H1).

### Analysis layer (separate future branch)

A new user-invoked skill in `learning-kit` (working name `prompt-coach` / `prompt-insights`): reads `prompts/*.jsonl` over a window, correlates *how a prompt was phrased* with *what it produced* (rework, bypass, iteration count, vagueness), and returns a precise audit of prompting — which phrasings drive friction, how to approach a prompt better. A narrow, prompt-quality sibling to a global "Insights"-style command. Designed once the format settles.
