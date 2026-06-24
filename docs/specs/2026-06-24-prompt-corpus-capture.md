# Spec — prompt corpus capture + single-writer (build 3a)

Source of requirements: the approved logging architecture in [docs/audits/2026-06-24-guardrails-kit-hooks.md](../audits/2026-06-24-guardrails-kit-hooks.md) ("Proposed logging architecture", "Improvements" #2–#3) and this session's `grilling` design + readiness review for build 3a (the first decomposed slice of handoff item #3). No ticket, so the optional Source provenance block is omitted.

## Goal

Add a durable **prompt-input corpus** (`.claude/state/prompts/YYYY-MM-DD.jsonl`) — one record per user turn, opened at `UserPromptSubmit` and finalized at `Stop` by a single writer (`log-skill-usage`) — and consolidate the duplicated bypass signal so `Stop` is the sole writer of it. This is the data source the future `prompt-coach` skill (handoff #4) reads.

## Scope

- **New persisted shape:** a `prompt` record appended to `.claude/state/prompts/YYYY-MM-DD.jsonl` per turn.
- **`reset-turn-budget.sh`** (`UserPromptSubmit`): bump a monotone per-session `session-turn` counter, then write the **open** prompt record to `.claude/state/<sid>/pending-prompt.json` — in a NEW standalone block placed right after the existing `printf '%s' "$PROMPT" > "$STATE_DIR/last-prompt.txt"` line (there is no JSON block there today — `last-prompt.txt` is raw text), guarded so a failure cannot abort the turn reset.
- **`log-skill-usage.sh`** (`Stop`, the sole writer): finalize the pending record (add `triggers_matched`, `skills_invoked`, `lang`, `outcome`), append it to `prompts/YYYY-MM-DD.jsonl`, then clear `pending-prompt.json`.
- **`detect-bypass.sh`** (`PostToolUse`): stop emitting the `trigger_bypass_warn` **metric** line (keep the stderr warn + the `turn-bypass-warned.flag`).
- **`hooks.json`**: reorder the `Stop` array so `friction-log` runs before `log-skill-usage`.

## Out of scope

- **Rotation + 14-day GC** of `prompts/` and `_metrics.jsonl` (build 3b) — 3a writes dated files but adds no pruning.
- **`SessionEnd` teardown / TMPDIR scratch move** (build 3c, gated on verifying `SessionEnd` exists).
- **State-contract doc** (build 3d).
- **`entrypoint`** field — deferred (needs alias/skill resolution); not captured in 3a.
- Removing `read_instead_of_skill` / `direct_edit_lessons_log` / `used_correctly` from `detect-bypass`/`log-skill-usage` — only the `trigger_bypass_warn` duplicate is removed.
- The `prompt-coach` analysis skill (handoff #4).
- Changing `friction-log`'s classification or `lessons-nudge` (untouched beyond the Stop-array reorder).

## Contracts

### New persisted shape — a `prompt` record (one JSONL line per turn) in `.claude/state/prompts/YYYY-MM-DD.jsonl`

```json
{
  "v": 1, "type": "prompt", "ts": "2026-06-24T10:15:00Z", "session": "0052fd0a", "turn": 7,
  "prompt": "<full user prompt text>", "chars": 412, "lang": "ru",
  "triggers_matched": ["grilling"],
  "skills_invoked": ["grilling"],
  "outcome": { "tools_used": 14, "friction": {"denied":0,"blocked":0,"error":1}, "bypass": false }
}
```

### Open record (written at `UserPromptSubmit`, `pending-prompt.json`)

```json
{ "v": 1, "type": "prompt", "ts": "...", "session": "<sid>", "turn": 7, "prompt": "<text>", "chars": 412 }
```

### Field derivations (all computable in-bash with jq)

- `turn` — monotone per-session counter in `.claude/state/<sid>/session-turn.json` (`{"n":N}`), incremented at `UserPromptSubmit` **before** the pending write; never reset (unlike `turn-tool-count.json`).
- `chars` — `($prompt | length)` (jq).
- `lang` — `if (.prompt | test("[Ѐ-ӿ]")) then "ru" else "en" end` (jq `test()`, Cyrillic range → `ru`, else `en`; note the required `end`).
- `triggers_matched` — the routing skill keys whose trigger union matches the prompt (the loop `log-skill-usage` already runs over `.skills`).
- `skills_invoked` — `turn-skills-invoked.json` contents.
- `outcome.tools_used` — `.count` from `turn-tool-count.json` (this is the **non-Skill** tool count: `detect-bypass` bumps it for every tool except `Skill`, which it exits early on — same semantics the audit used).
- `outcome.friction` — `{denied,blocked,error}` from `friction-seen.json` (current only because of the Stop reorder below).
- `outcome.bypass` — `true` iff `log-skill-usage`'s own end-of-turn loop found ≥1 skill with trigger-matched-but-not-invoked (the authoritative, threshold-independent signal — **not** the `turn-bypass-warned.flag`, which is gated on `TRIGGER_BYPASS_THRESHOLD=3` and would undercount).

### Single-writer edit — `detect-bypass.sh`

Remove the metric emit at the `trigger_bypass_warn` site (the `jq -cn … '{… event:"trigger_bypass_warn" …}' >> "$METRICS"` line); KEEP the `echo "SKILL-BYPASS warn:" >&2` and `touch "$BYPASS_WARNED_FILE"`. The `read_instead_of_skill` and `direct_edit_lessons_log` metric emits are unchanged (unique mid-turn signals).

### Stop-array reorder — `hooks.json`

```text
current order:  log-skill-usage  →  lessons-nudge  →  friction-log
target  order:  friction-log     →  log-skill-usage  →  lessons-nudge
```

`friction-log` must run first so `friction-seen.json` reflects this turn before `log-skill-usage` reads it for `outcome.friction`. `lessons-nudge` stays last (it depends only on `turn-bypass-warned.flag`, set by `detect-bypass` at `PostToolUse`, not on `log-skill-usage`).

## Files touched

| File | Change | Why |
| --- | --- | --- |
| `plugins/guardrails-kit/hooks/reset-turn-budget.sh` | EDIT | bump `session-turn`; write `pending-prompt.json` (open record) in the existing valid-JSON block |
| `plugins/guardrails-kit/hooks/log-skill-usage.sh` | EDIT | finalize pending record → append to `prompts/YYYY-MM-DD.jsonl`; clear pending |
| `plugins/guardrails-kit/hooks/detect-bypass.sh` | EDIT | drop the `trigger_bypass_warn` metric emit (keep warn + flag) |
| `plugins/guardrails-kit/hooks/hooks.json` | EDIT | reorder the `Stop` array (`friction-log` first) |

No NEW/DELETE source files (`prompts/` and `pending-prompt.json` are runtime state under gitignored `.claude/state/`). `common.sh`, `friction-log.sh`, `lessons-nudge.sh`, `quality.sh` untouched.

## Edge cases

- **Empty / non-JSON prompt stdin** — `reset-turn-budget` already early-exits the prompt-cache block on invalid JSON; `pending-prompt.json` is written only when a prompt is present, so no corpus record is produced that turn (correct — there was no user prompt).
- **No `pending-prompt.json` at `Stop`** — `log-skill-usage` skips the corpus step (no open record → nothing to finalize); the metric path is unaffected. Fail-open.
- **Double `Stop`** — `log-skill-usage` clears `pending-prompt.json` immediately after appending; a re-fired `Stop` finds no pending file → no second append (idempotent).
- **Empty turn (prompt but zero tools)** — `outcome.tools_used:0`, `bypass:false`; record still written.
- **`session-turn.json` absent** (first turn) — initialize to `{"n":0}` then bump → `turn:1`.
- **Garbage stdin / missing `jq` / missing lib** — every hook fail-opens (`common.sh` readability guard + `hook_require_json`); no corpus record, no crash.
- **`prompts/` dir absent** — `mkdir -p` it before the first append.

## Verification

Skills vault — no `pnpm`/build/test pipeline. Verification = fixture-execution + `bash -n`:

- **Open (`reset-turn-budget`):** stdin `{"session_id":"s1","prompt":"привет мир"}` → assert `pending-prompt.json` exists with `.v==1 and .type=="prompt" and .session=="s1" and .turn==1 and .prompt=="привет мир" and .chars==10`; second prompt → `.turn==2` (monotone).
- **Finalize (`log-skill-usage`):** seed `pending-prompt.json`, `turn-skills-invoked.json`, `turn-tool-count.json`, `friction-seen.json`, routing; run → assert the appended `prompts/$(date +%F).jsonl` line has `.type=="prompt"`, `.lang=="ru"` for a Cyrillic prompt (`"en"` for Latin), `.outcome.tools_used`, `.outcome.friction.error`, `.outcome.bypass` (bool), `.triggers_matched`, `.skills_invoked`; and `pending-prompt.json` is gone after. Re-run (double-Stop) → no second line appended.
- **Single-writer (`detect-bypass`):** the `trigger_bypass_warn` fixture (count→threshold, matched trigger, skill not invoked) → assert stderr still warns AND `turn-bypass-warned.flag` is set, but **no** `trigger_bypass_warn` line in `_metrics.jsonl`. The `read_instead_of_skill` fixture still emits its metric (regression).
- **Reorder (`hooks.json`):** `jq -e '.hooks.Stop[0].hooks[0].command | test("friction-log")'` → true; file stays valid JSON.
- **Fail-open:** garbage stdin → each edited hook `exit 0`, no corpus record.
- **`bash -n`** on the 3 edited hooks; authored test-first via `writing-hooks`.

## Risks

- **Stop-order regression** — reordering the `Stop` array could perturb another hook. Mitigation: only `log-skill-usage`'s `outcome.friction` depends on the order; `lessons-nudge` depends on the `PostToolUse` flag, not on `log-skill-usage` (confirmed in readiness review). A fixture asserts `friction-log` is `Stop[0]`.
- **`outcome.friction` still one turn stale if the reorder is wrong** — the fixture seeds `friction-seen.json` to the current turn's values and asserts the record reflects them, catching a missed reorder.
- **`jq test()` Cyrillic range portability** — ONIG (jq's regex) supports `\uXXXX`; asserted directly by the `lang` fixture (ru vs en), not assumed.
- **Full prompt text stored** — the corpus stores the verbatim prompt (approved: "text + outcome"). `.claude/state` is gitignored (verified in the audit), so this is local-only runtime data; retention/GC lands in 3b.
- **`reset-turn-budget` under `set -euo pipefail`** — the new `session-turn` bump + pending write form a NEW standalone block after the `last-prompt.txt` `printf` (no JSON block exists there today); a `jq`/write failure there must not abort the turn reset (already completed above it). Guard the new writes with `|| true` / tmp-file+mv as the hook already does.
