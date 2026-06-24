# Spec — slim `_metrics.jsonl` schema (templated records)

Source of requirements: the approved logging design in [docs/audits/2026-06-24-guardrails-kit-hooks.md](../audits/2026-06-24-guardrails-kit-hooks.md) — "Improvements" #1–#2 and "Proposed logging architecture (approved design)" → record templates. Handoff work-item #2. No ticket / `resolving-requirements` bundle, so the optional Source provenance block is omitted.

## Goal

Make every `_metrics.jsonl` record self-describing and sliceable per session: drop the redundant `triggers` field (−61% file size) and the non-signal `invoked_without_trigger` event, and stamp every record with `v` (schema version), `type` (discriminator), `session`, and `ts`. Update the one consumer (`scripts/metrics-report.sh`) to the new schema so the contract ships intact.

## Scope

- **3 emitters** — reshape every record written to `.claude/state/_metrics.jsonl`:
  - `friction-log.sh`: `{event:"friction",class,count}` → `{v:1,type:"friction",ts,session,class,count}` (adds `ts` + `session`, replaces the `event:"friction"` discriminator with `type:"friction"`).
  - `detect-bypass.sh` (3 emit sites): add `v:1`, `type:"skill_event"`, `session` to each (`read_instead_of_skill`, `direct_edit_lessons_log`, `trigger_bypass_warn`); keep their existing `event` + payload.
  - `log-skill-usage.sh`: add `v:1`, `type:"skill_event"`, `session`; **drop the emitted `triggers` field**; **remove the `invoked_without_trigger` branch** entirely.
- **1 consumer** — `scripts/metrics-report.sh`: discriminate by `.type` (not `.event`); fix the stale read path `.claude/skills/` → `.claude/state/`; update the header doc comment (drop `invoked_without_trigger`, note the v1 template).

## Out of scope

- The **prompt corpus** (`prompts/YYYY-MM-DD.jsonl`, `UserPromptSubmit`→`Stop` capture) — handoff #3.
- **Single-writer consolidation** / killing the `detect-bypass` ↔ `log-skill-usage` double-count, and dropping the `used_correctly` / `trigger_bypass_warn` events — those are #3's restructure; this spec drops ONLY `invoked_without_trigger` (per handoff #2) and keeps `bypass`, `used_correctly`, `trigger_bypass_warn`, `read_instead_of_skill`, `direct_edit_lessons_log`.
- **Two-stream split**, daily rotation, 14-day GC, `SessionEnd` teardown — handoff #3.
- The **`prompt-coach` skill** — handoff #4.
- **Migrating existing old-schema lines** already in `_metrics.jsonl` — it is gitignored runtime state; pre-migration lines (no `.type`) are simply not matched by the updated consumer and age out.
- The dead-branch **config decision** (`skill-gate` Pass 1/2, `detect-bypass` check 1); L2/L3/L4.
- Keeping `prompt_hash` on `skill_event` records is **retained** (dedup key); only `triggers` is dropped.

## Contracts

New record templates (the v1 convention — every record carries `v`, `type`, `ts`, `session`):

```json
{ "v": 1, "type": "skill_event", "ts": "2026-06-24T10:15:00Z", "session": "0052fd0a", "prompt_hash": "ab12…", "skill": "grilling", "event": "bypass" }
{ "v": 1, "type": "skill_event", "ts": "…", "session": "0052fd0a", "event": "read_instead_of_skill", "skill": "grilling", "path": ".claude/skills/grilling/SKILL.md" }
{ "v": 1, "type": "skill_event", "ts": "…", "session": "0052fd0a", "event": "direct_edit_lessons_log", "path": "/…/lessons-learned.md" }
{ "v": 1, "type": "skill_event", "ts": "…", "session": "0052fd0a", "event": "trigger_bypass_warn", "skill": "grilling", "tool_count": 4 }
{ "v": 1, "type": "friction", "ts": "…", "session": "0052fd0a", "class": "error", "count": 1 }
```

`session` = the hook's existing `SID` (all three derive it identically: `jq -r '.session_id // empty' | tr -cd 'A-Za-z0-9._-'`, fallback `default` — verified `reset-turn-budget.sh:8`, `detect-bypass.sh:15`, `friction-log.sh:25`, `log-skill-usage.sh:11`). `ts` = `date -u +%FT%TZ` (already used by detect-bypass / log-skill-usage; newly added to friction).

Emitter edits (before → after):

```bash
# friction-log.sh line 63 (emit)
# before:
  jq -cn --arg c "$cls" --argjson n "$d" '{event:"friction", class:$c, count:$n}' >> "$METRICS" 2>/dev/null || true
# after (SID is in scope from line 25):
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg c "$cls" --argjson n "$d" \
    '{v:1, type:"friction", ts:$ts, session:$sid, class:$c, count:$n}' >> "$METRICS" 2>/dev/null || true
```

```bash
# log-skill-usage.sh lines 49-57 (branch) — remove the invoked_without_trigger arm.
# before (REAL current file — three arms):
  if [[ "$MATCHED" == "yes" && "$INVOKED" == "null" ]]; then
    EVENT="bypass"
  elif [[ "$MATCHED" == "yes" && "$INVOKED" != "null" ]]; then
    EVENT="used_correctly"
  elif [[ "$MATCHED" != "yes" && "$INVOKED" != "null" ]]; then
    EVENT="invoked_without_trigger"
  else
    continue
  fi
# after (two arms — the matched-without-invoke arm and its else both fall to continue):
  if [[ "$MATCHED" == "yes" && "$INVOKED" == "null" ]]; then
    EVENT="bypass"
  elif [[ "$MATCHED" == "yes" && "$INVOKED" != "null" ]]; then
    EVENT="used_correctly"
  else
    continue
  fi
# log-skill-usage.sh lines 59-64 (emit) — drop triggers, add v/type/session:
# before:
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg h "$PROMPT_HASH" --arg s "$skill" --arg e "$EVENT" --arg t "$trigger_union" \
         '{ts:$ts, prompt_hash:$h, skill:$s, event:$e, triggers:$t}' >> "$METRICS"
# after:
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg h "$PROMPT_HASH" --arg s "$skill" --arg e "$EVENT" \
         '{v:1, type:"skill_event", ts:$ts, session:$sid, prompt_hash:$h, skill:$s, event:$e}' >> "$METRICS"
# NOTE: $trigger_union is still computed and used for matching in the trigger-match loop (the
# grep -qiE on the prompt); only the emitted `triggers` field is dropped.
```

```bash
# detect-bypass.sh — add v/type/session to each of the 3 emit sites (SID in scope from line 15):
# line 80-81:
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg s "$MATCHED_SKILL" --arg p "$REL_PATH" \
    '{v:1, type:"skill_event", ts:$ts, session:$sid, event:"read_instead_of_skill", skill:$s, path:$p}' >> "$METRICS"
# line 95-96:
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg p "$WRITE_PATH" \
    '{v:1, type:"skill_event", ts:$ts, session:$sid, event:"direct_edit_lessons_log", path:$p}' >> "$METRICS"
# line 126-127:
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg s "$MATCHED_MISSED" --argjson c "$NEW_COUNT" \
    '{v:1, type:"skill_event", ts:$ts, session:$sid, event:"trigger_bypass_warn", skill:$s, tool_count:$c}' >> "$METRICS"
```

Consumer edits — `scripts/metrics-report.sh`:

```bash
# line 15 (path fix):
  METRICS="$PROJECT_DIR/.claude/state/_metrics.jsonl"     # was .claude/skills/
# line 26 (routing select by type):
    map(select(.type == "skill_event"))
# line 47 (friction select by type):
    (map(select(.type == "friction"))) as $f
# lines 33-34 keep .event sub-selects (bypass / used_correctly) — skill_event records still carry .event.
# header comment (lines 6-8): drop invoked_without_trigger from the event list; note "v1 records: {v,type,ts,session,…}".
```

## Files touched

| File | Change | Why |
| --- | --- | --- |
| `plugins/guardrails-kit/hooks/friction-log.sh` | EDIT | reshape friction emit → `type:"friction"` + ts + session |
| `plugins/guardrails-kit/hooks/log-skill-usage.sh` | EDIT | drop `triggers` + `invoked_without_trigger`; add v/type/session |
| `plugins/guardrails-kit/hooks/detect-bypass.sh` | EDIT | add v/type/session to 3 `skill_event` emits |
| `scripts/metrics-report.sh` | EDIT | discriminate by `.type`; fix stale read path; update comment |

No NEW/DELETE files. `hooks.json` untouched (no event/matcher change). `.claude/skills-routing.json` untouched (L2 deferred).

## Edge cases

- **Empty** — no events in a turn → no lines emitted (unchanged). `metrics-report.sh` on an absent/empty file → "no data yet" branch (unchanged).
- **friction `ts`** — friction records previously had no `ts`; now they do, so friction lines become orderable (a goal of the change).
- **Mixed old+new lines** during transition — pre-migration lines lack `.type`; the updated consumer's `select(.type=="skill_event")` / `select(.type=="friction")` simply exclude them (no crash — `select` on a null field is false). They are gitignored runtime state and age out. Documented as accepted, not migrated.
- **`session` fallback** — when `session_id` is absent/garbage, `SID=default`; records carry `"session":"default"` rather than omitting the field (every record has the key).
- **Fail-open preserved** — all emits keep their existing `>> "$METRICS"` (loggers: detect-bypass/log-skill-usage under `set -e` already guarded by upstream `jq -e` stdin check; friction-log keeps `2>/dev/null || true`). Garbage stdin → exit 0, no record. The schema change adds fields only; it does not change any fail-open path.

## Verification

Skills vault — no `pnpm`/build/unit-test pipeline. Verification = fixture-execution + the consumer run + `bash -n`:

- **Per emitter (fixture-execution):** craft stdin that triggers each emit, run the hook in an isolated `CLAUDE_PROJECT_DIR`, then assert the appended `_metrics.jsonl` line with `jq`:
  - `friction`: line has `.v==1 and .type=="friction" and .session and .ts and .class and .count`.
  - `log-skill-usage` bypass: line has `.v==1 and .type=="skill_event" and .session and (.triggers|not) and .event=="bypass"`; and assert **no** `invoked_without_trigger` line is ever emitted (matched-without-invoke now `continue`s).
  - `detect-bypass` read_instead_of_skill: line has `.v==1 and .type=="skill_event" and .session and .event=="read_instead_of_skill"`.
- **Consumer (`metrics-report.sh`):** feed a crafted `.claude/state/_metrics.jsonl` of new-schema lines (a `skill_event` bypass + a `used_correctly` + a `friction`), run the report, assert the "Skill routing" section counts the skill_events, the "Friction" section sums the friction class, AND the "Bypass rate" line computes from the bypass/used_correctly sub-select (e.g. `1/2 = 50%`) — proving `.type` discrimination + the path fix + the unchanged `.event` sub-select all work end-to-end.
- **Each emitter's fail-open:** garbage stdin → `exit 0`, no line written.
- **Structural:** `bash -n` on all 4 edited files; the RED→GREEN of each is authored via `writing-hooks`.

## Risks

- **`SID` not in scope at an emit site** — mitigated: confirmed each hook computes `SID` near the top before any emit (line refs in Contracts). The fixture asserts the `session` field is non-empty, catching a missed wiring.
- **Consumer `.event` sub-selects** (bypass/used_correctly rate) rely on `skill_event` records still carrying `.event` — they do; friction has no `.event`, so the `select(.event=="bypass")` lines already exclude friction. Low risk; the consumer fixture exercises the bypass-rate line.
- **`v:1` as a jq literal** — written as a bare `v:1` in the object (number), not `--argjson`; valid jq. Fixture asserts `.v==1` (numeric) to catch an accidental string.
- **Other readers** — discovery (Explore sweep + reads) found exactly one consumer (`metrics-report.sh`); no skill/JS/CI reads `_metrics.jsonl` or the `triggers`/`invoked_without_trigger` fields. If a future consumer assumed the old shape, the `v` field is the migration signal.
