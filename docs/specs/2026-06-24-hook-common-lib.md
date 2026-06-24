# Spec — shared hook preamble library (`hooks/lib/common.sh`)

Source of requirements: the approved design from this session's `grilling` phase (Decisions D1–D5) + the independent readiness review. No ticket, so the optional Source provenance block is omitted.

## Goal

Extract the duplicated session/state boilerplate in the guardrails-kit hooks into a small sourced bash function library, so the 7 SID-deriving hooks call shared functions instead of repeating ~6 identical lines each — without weakening the fail-open invariant.

## Scope

- **NEW** `plugins/guardrails-kit/hooks/lib/common.sh` — pure functions, zero side effects at source time: `hook_sid`, `hook_state_dir`, `hook_require_json`.
- **Migrate 7 hooks** to source the lib and call its functions (per the D5 mapping below): `detect-bypass.sh`, `log-skill-usage.sh`, `token-guard.sh`, `friction-log.sh`, `reset-turn-budget.sh`, `lessons-nudge.sh`, `skill-gate.sh`.
- Each migrated hook keeps its own stdin-read style, its `set` line, and its per-hook path vars (`ROUTING`, `METRICS`, `TURN_*`, etc.) inline.

## Out of scope

- `quality.sh` — derives no SID (operates on `tool_input.file_path`); not migrated.
- The per-hook path-var declarations (`TURN_SKILLS_FILE`, `METRICS`, `ROUTING`, `BY_MODEL_FILE`, …) — each is a per-hook subset, left inline.
- `reset-turn-budget.sh`'s GC block (its `find … -mtime` + writes) — per-hook logic, stays inline.
- A `hook_read_stdin` helper — `cat 2>/dev/null` is trivial and the callers vary (`|| exit 0` vs `|| INPUT=""`); not abstracted.
- The trigger-matching loop shared by `detect-bypass`/`log-skill-usage` (audit's "consolidate the two bypass detectors") — a different, larger refactor; not here.
- Any behavior change to any hook — this is a pure refactor; every existing fixture must stay GREEN.
- `hooks.json` wiring — unchanged (hooks still launched as `"${CLAUDE_PLUGIN_ROOT}"/hooks/<name>.sh`).

## Contracts

### `hooks/lib/common.sh` (NEW — sourced only; no shebang execution, no `chmod +x`, no `set`)

```bash
# Shared hook preamble helpers. Sourced by guardrail hooks; defines functions only —
# no side effects at source time (never reads stdin / touches the fs on source).

# hook_sid <raw-stdin-json> -> echoes the sanitized session id, or "default".
# Safe on empty/garbage input and when jq is absent (→ "default").
hook_sid() {
  local sid
  sid=$(printf '%s' "${1:-}" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9._-') || sid=""
  [ -z "$sid" ] && sid=default
  printf '%s' "$sid"
}

# hook_state_dir <sanitized-sid> -> echoes the per-session state dir.
hook_state_dir() {
  printf '%s' "${CLAUDE_PROJECT_DIR:-.}/.claude/state/${1:-default}"
}

# hook_require_json <raw-stdin-json> -> EXITS the calling hook 0 (fail-open) if not valid JSON.
# MUST be called as a bare statement (not in $(...)) so its exit terminates the hook, not a subshell.
# `exit` in bash always terminates the shell regardless of `set -e`, so this works under both
# `set -euo pipefail` and `set -uo pipefail`.
hook_require_json() {
  printf '%s' "${1:-}" | jq -e . >/dev/null 2>&1 || exit 0
}
```

### Canonical "after" preambles (the migration contract)

Strict fail-open (`detect-bypass`, `log-skill-usage`, `token-guard` — the 3 hooks that currently do `jq -e . || exit 0`):

```bash
set -euo pipefail
GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"; [ -r "$GUARDRAILS_LIB" ] || exit 0; . "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || exit 0
hook_require_json "$INPUT"
SID=$(hook_sid "$INPUT")
STATE_DIR=$(hook_state_dir "$SID")
# … per-hook path vars (ROUTING/METRICS/TURN_*) stay inline below …
```

Run-on-empty + `hook_state_dir` (`reset-turn-budget` only — must still run on empty stdin, NO `require_json`; `lessons-nudge` is run-on-empty too but is `hook_sid`-only, shown below):

```bash
set -euo pipefail
GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"; [ -r "$GUARDRAILS_LIB" ] || exit 0; . "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || INPUT=""
SID=$(hook_sid "$INPUT")
STATE_DIR=$(hook_state_dir "$SID")
# … STATE_BASE="${CLAUDE_PROJECT_DIR:-.}/.claude/state" + the GC block stay inline …
```

`skill-gate` (jq-guarded — keeps `command -v jq`, uses `hook_state_dir`; its `STATE_DIR`/`ROUTING` already use `${CLAUDE_PROJECT_DIR:-.}`):

```bash
set -uo pipefail
GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"; [ -r "$GUARDRAILS_LIB" ] || exit 0; . "$GUARDRAILS_LIB"
command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat 2>/dev/null) || exit 0
SID=$(hook_sid "$INPUT")
STATE_DIR=$(hook_state_dir "$SID")
# … ROUTING inline; the later PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}" (for REL_PATH) stays …
```

`hook_sid`-ONLY hooks (`friction-log`, `lessons-nudge`) — these derive a SECOND path from a `PROJECT_DIR` variable (`METRICS` and `LESSONS` respectively), so `PROJECT_DIR` is load-bearing and is KEPT inline verbatim; `STATE_DIR` is derived from it inline (NOT `hook_state_dir`), so there is zero `${CLAUDE_PROJECT_DIR}` drift and `lessons-nudge`'s `:-$(pwd)` is preserved exactly:

```bash
# friction-log.sh (set -uo pipefail, keeps command -v jq):
GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"; [ -r "$GUARDRAILS_LIB" ] || exit 0; . "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"          # KEPT — METRICS derives from it
SID=$(hook_sid "$INPUT")
STATE_DIR="$PROJECT_DIR/.claude/state/$SID"      # inline (PROJECT_DIR-derived), not hook_state_dir
METRICS="$PROJECT_DIR/.claude/state/_metrics.jsonl"
SEEN_FILE="$STATE_DIR/friction-seen.json"

# lessons-nudge.sh (set -uo pipefail, run-on-empty):
GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"; [ -r "$GUARDRAILS_LIB" ] || exit 0; . "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || INPUT=""
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"       # KEPT verbatim (:-$(pwd)) — LESSONS derives from it
SID=$(hook_sid "$INPUT")
STATE_DIR="$PROJECT_DIR/.claude/state/$SID"      # inline, not hook_state_dir
BYPASS_FLAG="$STATE_DIR/turn-bypass-warned.flag"
LESSONS="$PROJECT_DIR/.claude/lessons-learned.md"
```

(`skill-gate` reads `INPUT` then proceeds to its `TOOL`/`FILE_PATH` parsing; `friction-log` to its transcript read; `reset-turn-budget` to its GC block. Order within each hook is preserved except the SID line — and, for the `hook_state_dir` hooks, the `STATE_DIR` line — now come from the lib.)

### D5 — per-hook function mapping

`hook_sid` is called by all 7. `hook_state_dir` is used only by hooks whose `STATE_DIR` already uses `${CLAUDE_PROJECT_DIR:-.}` with no other `PROJECT_DIR`-derived path; `friction-log`/`lessons-nudge` keep `PROJECT_DIR` inline instead (zero drift). `hook_require_json` only by the 3 hooks that currently do `jq -e . || exit 0`.

| Hook | Shape | `require_json` | `state_dir` | Surviving inline vars |
| --- | --- | --- | --- | --- |
| `detect-bypass.sh` | strict | yes | yes | `ROUTING`, `METRICS` (`${CLAUDE_PROJECT_DIR:-.}`), `TURN_*`, later `PROJECT_DIR` (REL_PATH) |
| `log-skill-usage.sh` | strict | yes | yes | `ROUTING`, `METRICS`, `TURN_*`, `LAST_PROMPT_FILE` |
| `token-guard.sh` | strict | yes | yes | `TURN_FILE`/`SESSION_FILE`/`BY_MODEL_FILE` (from `$STATE_DIR`) |
| `skill-gate.sh` | jq-guarded | no | yes | `ROUTING`, `TURN_*`, later `PROJECT_DIR` (REL_PATH) |
| `reset-turn-budget.sh` | run-on-empty | no | yes | `STATE_BASE` (`${CLAUDE_PROJECT_DIR:-.}`), GC block |
| `friction-log.sh` | jq-guarded | no | **no — `hook_sid` only** | **`PROJECT_DIR` (`:-.`) KEPT**, `METRICS`, `SEEN_FILE` |
| `lessons-nudge.sh` | run-on-empty | no | **no — `hook_sid` only** | **`PROJECT_DIR` (`:-$(pwd)`) KEPT**, `LESSONS`, flags |
| `quality.sh` | — | no | no | not migrated (out of scope) |

## Files touched

| File | Change | Why |
| --- | --- | --- |
| `plugins/guardrails-kit/hooks/lib/common.sh` | NEW | the 3 shared functions |
| `plugins/guardrails-kit/hooks/detect-bypass.sh` | EDIT | strict preamble → lib |
| `plugins/guardrails-kit/hooks/log-skill-usage.sh` | EDIT | strict preamble → lib |
| `plugins/guardrails-kit/hooks/token-guard.sh` | EDIT | strict preamble → lib |
| `plugins/guardrails-kit/hooks/friction-log.sh` | EDIT | jq-guarded preamble → lib (`sid`/`state_dir`) |
| `plugins/guardrails-kit/hooks/skill-gate.sh` | EDIT | jq-guarded preamble → lib (`sid`/`state_dir`) |
| `plugins/guardrails-kit/hooks/reset-turn-budget.sh` | EDIT | run-on-empty preamble → lib |
| `plugins/guardrails-kit/hooks/lessons-nudge.sh` | EDIT | run-on-empty preamble → lib |

No DELETE. `quality.sh`, `hooks.json` untouched.

## Edge cases

- **Empty stdin** — `hook_sid ""` → `default`; run-on-empty hooks proceed (unchanged behavior).
- **Garbage/non-JSON stdin** — strict hooks: `hook_require_json` exits 0 (fail-open). Non-strict: `hook_sid` → `default`, hook proceeds exactly as before its own guards dictate.
- **Missing/unreadable lib** — `. … || exit 0` → hook exits 0 (fail-open). For run-on-empty hooks this skips that turn's reset; accepted (a missing lib means the whole plugin is down).
- **Missing `jq`** — strict: `hook_require_json` (jq absent → non-zero → exit 0). Non-strict: their own `command -v jq` guard, or `hook_sid` → `default`.
- **`hook_require_json` called in `$(…)`** — would only exit a subshell, NOT the hook (latent bug). Pinned as a bare-statement contract; a fixture asserts a strict hook with garbage stdin exits 0.
- **`PROJECT_DIR` fallback preserved, NOT standardized** — `friction-log` keeps `:-.` and `lessons-nudge` keeps `:-$(pwd)` exactly, because each derives a second path (`METRICS`/`LESSONS`) from `PROJECT_DIR`; these 2 hooks use `hook_sid` only and keep `STATE_DIR` inline so there is zero `${CLAUDE_PROJECT_DIR}` behavior drift. The 5 `hook_state_dir` hooks already used `${CLAUDE_PROJECT_DIR:-.}` for `STATE_DIR`, which `hook_state_dir` reproduces verbatim.

## Verification

Skills vault — no `pnpm`/build/unit-test pipeline. Verification = fixture-execution + `bash -n`:

- **Lib unit fixtures** (source `common.sh` in a test shell): `hook_sid '{"session_id":"a/b c"}'` → `abc` (the `tr -cd 'A-Za-z0-9._-'` strips `/` and the space); `hook_sid ''` → `default`; `hook_sid 'garbage'` → `default`; `hook_state_dir s1` with `CLAUDE_PROJECT_DIR=/x` → `/x/.claude/state/s1`; and a sub-hook that calls `hook_require_json 'garbage'` as a bare statement → exits 0, one that calls it on valid JSON → continues past it.
- **Regression — all 7 migrated hooks re-run their EXISTING fixtures → GREEN** (the prior builds' fixtures for friction-log/log-skill-usage/detect-bypass, plus crafted fixtures for token-guard/skill-gate/reset-turn-budget/lessons-nudge). Behavior must be byte-identical to pre-refactor.
- **Missing-lib fail-open** — run a migrated hook with the lib temporarily absent (e.g. copy the hook to a temp dir without `lib/`, or move the lib) → assert `exit 0`, no crash.
- **Structural** — `bash -n` on `common.sh` and all 7 edited hooks.
- Authored test-first via `writing-hooks`; the new lib gets its own fixture, each migration is a fixture RED (point at lib / assert new call) → edit → GREEN (existing fixture still passes).

## Risks

- **Behavior drift during a "pure refactor"** — the real risk. Mitigation: every hook's existing fixture must stay GREEN, byte-identical output; the independent Layer-2 re-runs them inverted against the pre-refactor `git show HEAD:` version.
- **`hook_require_json` mis-call in `$(…)`** — pinned by contract + a garbage-stdin fixture per strict hook (would exit non-zero / proceed if mis-called).
- **`BASH_SOURCE[0]` unset** — only if a hook were `source`d rather than executed; the harness executes hooks as child processes (`#!/usr/bin/env bash`), so `BASH_SOURCE[0]` is the hook's own path. Confirmed by the readiness review.
- **Sourcing fail-open under `set -e` (FOUND during execution — load-bearing):** `.` is a POSIX special builtin; under `set -euo pipefail` its open-failure (missing lib) exits the shell with status 1 *before* a trailing `|| exit 0` runs — so `. lib 2>/dev/null || exit 0` fails CLOSED (exit 1), violating fail-open. The only correct form is to guard readability first: `GUARDRAILS_LIB=…; [ -r "$GUARDRAILS_LIB" ] || exit 0; . "$GUARDRAILS_LIB"`. All 7 hooks use this; the Task-5 missing-lib fixture asserts `exit 0` for every hook (it would have caught the wrong idiom — and did).
- **`set -e` interaction with `SID=$(hook_sid …)`** — `hook_sid` always returns 0 (its `|| sid=""` and final `printf` succeed), so the assignment never trips `set -e`. `hook_require_json`'s only non-zero path is the `exit 0` itself.
