# Spec — guardrails-kit hook correctness fixes

Source of requirements: the read-only audit [docs/audits/2026-06-24-guardrails-kit-hooks.md](../audits/2026-06-24-guardrails-kit-hooks.md) (findings H1, H2, M2, M1, L1) and the approved fix design from this session's `grilling` phase. No ticket / `resolving-requirements` bundle, so the optional Source provenance block is omitted.

## Goal

Fix five confirmed correctness defects in `plugins/guardrails-kit/hooks/` so the hooks stop crashing (`exit` non-zero on their own error — a fail-open violation) and stop producing inaccurate telemetry. Each fix is the narrowest change that resolves the defect, verified by a `writing-hooks` fixture RED → fix → GREEN.

## Scope

- **H1** — `reset-turn-budget.sh`: stop the opportunistic GC from deleting the live session dir on a resumed/long-idle session (crash + state loss).
- **H2** — `friction-log.sh`: stop counting multi-line error text per line (phantom `error` events, inflated counts).
- **M2** — `log-skill-usage.sh`: restore fail-open when `skills-routing.json` lacks a `skills` key (currently `exit 5`, and the per-turn reset never runs).
- **M1** — `quality.sh`: stop a closed inline-code span earlier on a line from suppressing a real broken-link report on the same line.
- **L1** — `detect-bypass.sh`: restore fail-open on corrupt per-turn state at the two bare `jq` reads (currently `exit 5`).

## Out of scope

- Logging redesign (deferred items): slimming `_metrics.jsonl`, dropping the `triggers` field, dropping `invoked_without_trigger`, single-writer consolidation, the `prompts/` corpus, the `prompt-coach` skill.
- **L2** (`\d` → `[0-9]` in the `resolving-requirements` trigger): a `skills-routing.json` *data* fix governed by `skill-routing-sync`, not hook code — left to the config bucket.
- **L3 / L4** cosmetics (`skill-gate` comment + trailing-slash hardening; `token-guard` +1-byte trim).
- The config decision on activating dead enforcement branches (`skill-gate` Pass 1/2, `detect-bypass` check 1).
- Any change to `M2`'s line-volume noise (`invoked_without_trigger`, per-entry emission) beyond the fail-open fix.

## Contracts

Each "contract" is the exact code edit (before → after) plus the fixture **decision contract** (exit code / stderr / metric line) the GREEN run must satisfy. All hooks are Form-A (exit-code) or pure loggers; none emits a JSON `permissionDecision`.

### H1 — `reset-turn-budget.sh` (UserPromptSubmit)

Insert a `touch` so the live dir's mtime is fresh and GC (line 19, `-mtime +"$GC_DAYS"`) can never collect it.

```bash
# before (lines 10-11)
STATE_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/state/$SID"
mkdir -p "$STATE_DIR"

# after
STATE_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/state/$SID"
mkdir -p "$STATE_DIR"
touch "$STATE_DIR"   # refresh mtime: mkdir -p is a no-op (no mtime bump) on an existing dir, so a
                     # resumed >GC_DAYS-old session dir would otherwise be deleted by the GC below.
```

Decision contract: stale session dir (mtime > 7d) → `exit 0`, `turn-budget.json` written, dir survives.

### H2 — `friction-log.sh` (Stop)

Collapse newlines inside each extracted result so one `is_error` result is exactly one physical line (the `grep -c` counters count lines).

```bash
# before (lines 39-44): the final string may still contain embedded \n
TEXTS=$(jq -rc '
  select((.message.content // empty) | type == "array")
  | .message.content[]
  | select((type == "object") and (.type == "tool_result") and (.is_error == true))
  | (if (.content | type) == "array" then (.content | map(.text? // "") | join(" ")) else (.content | tostring) end)
' "$TRANSCRIPT" 2>/dev/null) || exit 0

# after: collapse any CR/LF run to a single space → one line per result
TEXTS=$(jq -rc '
  select((.message.content // empty) | type == "array")
  | .message.content[]
  | select((type == "object") and (.type == "tool_result") and (.is_error == true))
  | (if (.content | type) == "array" then (.content | map(.text? // "") | join(" ")) else (.content | tostring) end)
  | gsub("[\r\n]+"; " ")
' "$TRANSCRIPT" 2>/dev/null) || exit 0
```

Decision contract: one `denied` result with 3-line content → metrics get exactly `{"event":"friction","class":"denied","count":1}` and **no** `error` line.

### M2 — `log-skill-usage.sh` (Stop)

Default the `.skills` lookup so a routing file missing the key yields an empty object (no rows) instead of a `jq` exit 5 that `pipefail` propagates as the hook's exit.

```bash
# before (line 41)
jq -r '.skills | to_entries[] | "\(.key)\t\(.value.triggers // [] | join("|"))"' "$ROUTING" | while IFS=$'\t' read -r skill trigger_union; do

# after
jq -r '.skills // {} | to_entries[] | "\(.key)\t\(.value.triggers // [] | join("|"))"' "$ROUTING" | while IFS=$'\t' read -r skill trigger_union; do
```

Decision contract: routing JSON with no `skills` key (but a recoverable prompt) → `exit 0` and the line-68 `echo '[]' > "$TURN_SKILLS_FILE"` reset runs.

### M1 — `quality.sh` (PostToolUse)

Strip closed inline-code spans from the line *before* link detection, so only links genuinely inside backticks are skipped — a closed span earlier on the line no longer suppresses a real link.

```bash
# before (lines 53-60)
grep -nE '\]\([^)]+\.md[^)]*\)' "$FILE" 2>/dev/null | while IFS= read -r line; do
  printf '%s' "$line" | grep -q '`[^`]*\](' && continue
  target=$(printf '%s' "$line" | sed -E 's/.*\]\(([^)#]+\.md)[^)]*\).*/\1/')
  case "$target" in
    http*|/*) continue ;;
  esac
  [ -e "$dirpath/$target" ] || echo "QUALITY warn: $FILE references missing path '$target'." >&2
done

# after: remove closed `...` spans first; detect/validate the link on the cleaned line
grep -nE '\]\([^)]+\.md[^)]*\)' "$FILE" 2>/dev/null | while IFS= read -r line; do
  cleaned=$(printf '%s' "$line" | sed 's/`[^`]*`//g')
  printf '%s' "$cleaned" | grep -qE '\]\([^)]+\.md[^)]*\)' || continue
  target=$(printf '%s' "$cleaned" | sed -E 's/.*\]\(([^)#]+\.md)[^)]*\).*/\1/')
  case "$target" in
    http*|/*) continue ;;
  esac
  [ -e "$dirpath/$target" ] || echo "QUALITY warn: $FILE references missing path '$target'." >&2
done
```

Decision contract: line `` See `code` and then [missing](./gone.md) `` → emits `QUALITY warn: ... references missing path './gone.md'`. Control: a link fully inside backticks (`` `[x](./y.md)` `` with no real link on the line) → still skipped (no warn). Hook always `exit 0`.

### L1 — `detect-bypass.sh` (PostToolUse)

Guard the two bare `jq` reads of the per-turn state file so a corrupt (non-JSON) file fails open instead of aborting under `set -euo pipefail`.

```bash
# before (line 77, inside check 1)
INVOKED=$(jq -r --arg s "$MATCHED_SKILL" 'index($s) // empty' "$TURN_SKILLS_FILE")
# before (line 92, inside check 1b)
INVOKED=$(jq -r 'index("writing-lessons") // empty' "$TURN_SKILLS_FILE")

# after
INVOKED=$(jq -r --arg s "$MATCHED_SKILL" 'index($s) // empty' "$TURN_SKILLS_FILE" 2>/dev/null || true)
INVOKED=$(jq -r 'index("writing-lessons") // empty' "$TURN_SKILLS_FILE" 2>/dev/null || true)
```

Decision contract: corrupt `turn-skills-invoked.json` (non-JSON) + a Read of a skill-body path (check 1) → `exit 0` (was `exit 5`).

## Files touched

| File | Change | Why |
| --- | --- | --- |
| `plugins/guardrails-kit/hooks/reset-turn-budget.sh` | EDIT | H1 — `touch "$STATE_DIR"` after `mkdir -p` |
| `plugins/guardrails-kit/hooks/friction-log.sh` | EDIT | H2 — `gsub` newlines so 1 result = 1 line |
| `plugins/guardrails-kit/hooks/log-skill-usage.sh` | EDIT | M2 — `.skills // {}` fail-open |
| `plugins/guardrails-kit/hooks/quality.sh` | EDIT | M1 — strip inline-code spans before link check |
| `plugins/guardrails-kit/hooks/detect-bypass.sh` | EDIT | L1 — guard two bare `jq` reads |

No NEW or DELETE files. The hooks are wired by `plugins/guardrails-kit/hooks.json` (unchanged — no event/matcher change).

## Edge cases

- **Garbage / non-JSON stdin** (every hook): must `exit 0` with no disruption — re-asserted as a separate fixture per hook, distinct from the RED-0 "logic not yet written" case.
- **H1 empty**: brand-new session dir (fresh mtime) — `touch` is harmless, GC still excludes it; no regression.
- **H2 empty**: transcript with zero `is_error` results → no metric lines, `exit 0`. Single-line error result → count still 1 (no regression from the `gsub`).
- **M2 empty**: routing present with a normal `skills` map → behaves exactly as today (the `// {}` is inert when the key exists). Missing prompt → `exit 0` at line 34 as today.
- **M1**: a line with a closed backtick span **and** a genuinely-inside-backticks link and **no** real link → still skipped (cleaned line has no `](`). A line with only a real link and no backticks → validated as today.
- **L1**: well-formed `turn-skills-invoked.json` → unchanged behavior (the guard is inert when `jq` succeeds).

## Verification

This is a skills vault — **no `pnpm` / build / unit-test pipeline and no simulator.** Verification per the framework charter is fixture-execution of each hook against crafted stdin plus the doc validators:

- **Per hook (the RED → GREEN):** pipe the crafted fixture stdin to the script in an isolated `CLAUDE_PROJECT_DIR` sandbox, assert the decision contract above (exit code / metric line / stderr), and assert the garbage-stdin → `exit 0` fail-open case. Each is authored test-first via `writing-hooks` (fixture RED before the edit, GREEN after).
- **Independent Layer-2 verdict:** a fresh subagent re-runs the staged fixture cases, inverts each (confirms RED without the fix), and returns PASS with verbatim evidence.
- **Doc/structural:** `bash -n <hook>.sh` (syntax) on each edited script; `jq . plugins/guardrails-kit/hooks.json` stays valid (untouched). The advisory `quality.sh` PostToolUse pass is markdown-only and does not gate shell edits.

## Risks

- **macOS vs GNU `touch`/`find` mtime semantics (H1):** the fix relies on `touch` bumping the dir mtime above the `-mtime +7` threshold; standard on both macOS (BSD) and GNU. Mitigation: the fixture asserts dir survival directly, not the mtime value.
- **`gsub` over-collapsing (H2):** collapsing CR/LF to a single space could merge two logically distinct errors that the transcript already delivered as separate array entries — but each array entry is already one result and emitted on its own line by `jq -rc`, so `gsub` only flattens *within* a result. No cross-result merge. Confirmed by the array-content branch already using `join(" ")`.
- **M1 `sed` greediness:** `s/\`[^\`]*\`//g` removes only *closed* spans (paired backticks); an unclosed backtick is left intact, so a real link after a lone backtick is still validated (no new false-skip). Lower risk than the status quo, which over-skips.
- **L1 `|| true` masking a real jq error:** intended — fail-open is the invariant; a corrupt state file must not abort the hook. The check simply treats "can't read state" as "not invoked", which is the safe default for an advisory warn.
