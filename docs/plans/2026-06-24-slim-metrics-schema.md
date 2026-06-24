# Slim `_metrics.jsonl` Schema Implementation Plan

**Goal:** Reshape every `_metrics.jsonl` record to the v1 templated form (`v`/`type`/`ts`/`session`, drop `triggers` + `invoked_without_trigger`) across 3 emitters, and update the one consumer (`metrics-report.sh`) to the new schema.
**Architecture:** Four independent single-file edits, each tested by fixture-execution (crafted stdin → run hook → assert the appended JSON line with `jq -e`). The consumer is tested by feeding a crafted new-schema file and asserting the report output. No unit-test suite.
**Tech stack:** Bash + `jq`; verification = fixture-execution + `bash -n`.

## Global constraints

- **Test-first (Iron Law, hook form):** write the fixture, run it, watch RED, then edit. Fixture-execution IS the RED/GREEN.
- **Fail-open invariant:** every hook exits 0 on garbage stdin — asserted as a separate fixture per emitter task. The schema change adds fields only; it must not alter any fail-open path.
- **`grep` and `rg` are UNAVAILABLE in this shell** (a shim error). Assert with `jq -e '<predicate>'` and bash `[[ "$out" == *substr* ]]` — never `grep`.
- **Scope (verbatim from spec):** drop ONLY `triggers` + `invoked_without_trigger`; KEEP `bypass`, `used_correctly`, `trigger_bypass_warn`, `read_instead_of_skill`, `direct_edit_lessons_log`. `prompt_hash` is retained on `skill_event` records. No corpus / single-writer / rotation (those are #3).
- **Record templates:** `skill_event` = `{v:1,type:"skill_event",ts,session,event,…payload}`; `friction` = `{v:1,type:"friction",ts,session,class,count}` (no `event` field on friction).
- **`session`** = the hook's existing `SID`; **`ts`** = `date -u +%FT%TZ`. Use a fresh `SB=$(mktemp -d)` per run.
- **Git boundary:** human owns the commit; each task ends with a proposed Conventional Commit, not an autonomous `git commit`.
- Spec: [docs/specs/2026-06-24-slim-metrics-schema.md](../specs/2026-06-24-slim-metrics-schema.md).

---

## Task 1 — `friction-log.sh`: friction record → v1 template

**Files:** `plugins/guardrails-kit/hooks/friction-log.sh` (EDIT)
**Interfaces** — Consumes: none. Produces: `friction` record shape `{v,type,ts,session,class,count}` (consumed by Task 4's `.type=="friction"` select).

- [ ] **1.1 Failing fixture.**

```bash
HOOK=plugins/guardrails-kit/hooks/friction-log.sh
SB=$(mktemp -d); TR="$SB/t.jsonl"
cat > "$TR" <<'EOF'
{"message":{"content":[{"type":"tool_result","is_error":true,"content":"user rejected"}]}}
EOF
echo "{\"session_id\":\"ftest\",\"transcript_path\":\"$TR\"}" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
line=$(tail -1 "$SB/.claude/state/_metrics.jsonl")
echo "$line"
echo "$line" | jq -e '.v==1 and .type=="friction" and .session=="ftest" and (.ts|type=="string") and .class=="denied" and .count==1 and (has("event")|not)' >/dev/null && echo PASS || echo FAIL
rm -rf "$SB"
```

- [ ] **1.2 Confirm RED:** `FAIL` (the emitted line is `{"event":"friction","class":"denied","count":1}` — no `v`/`type`/`session`/`ts`, and it still has `event`).

- [ ] **1.3 Apply fix** — replace the single `jq -cn` emit inside the `emit()` function (≈ line 64):

```bash
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg c "$cls" --argjson n "$d" \
    '{v:1, type:"friction", ts:$ts, session:$sid, class:$c, count:$n}' >> "$METRICS" 2>/dev/null || true
```

- [ ] **1.4 Confirm GREEN:** re-run 1.1 → `PASS`.

- [ ] **1.5 Fail-open:** `SB2=$(mktemp -d); printf 'not json' | CLAUDE_PROJECT_DIR="$SB2" bash "$HOOK"; echo "exit=$?"; rm -rf "$SB2"` → `exit=0`.

- [ ] **1.6 Syntax + commit:** `bash -n "$HOOK"` → propose `refactor(hooks): emit friction records in the v1 {v,type,ts,session} template`.

---

## Task 2 — `log-skill-usage.sh`: drop triggers + invoked_without_trigger, add v/type/session

**Files:** `plugins/guardrails-kit/hooks/log-skill-usage.sh` (EDIT)
**Interfaces** — Consumes: none. Produces: `skill_event` records for `bypass`/`used_correctly` shaped `{v,type,ts,session,prompt_hash,skill,event}` (no `triggers`).

- [ ] **2.1 Failing fixture (bypass shape + no triggers).**

```bash
HOOK=plugins/guardrails-kit/hooks/log-skill-usage.sh
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/mtest"
cat > "$SB/.claude/skills-routing.json" <<'EOF'
{"version":2,"skills":{"demo":{"kind":"ref","plugin":"x","name":"demo","triggers":["deploy"]}}}
EOF
echo 'please deploy now' > "$SB/.claude/state/mtest/last-prompt.txt"
echo '[]' > "$SB/.claude/state/mtest/turn-skills-invoked.json"
echo '{"session_id":"mtest","transcript_path":""}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
line=$(tail -1 "$SB/.claude/state/_metrics.jsonl"); echo "$line"
echo "$line" | jq -e '.v==1 and .type=="skill_event" and .session=="mtest" and .event=="bypass" and .skill=="demo" and (.prompt_hash|type=="string") and (has("triggers")|not)' >/dev/null && echo PASS || echo FAIL
rm -rf "$SB"
```

- [ ] **2.2 Confirm RED:** `FAIL` (emitted line is `{ts,prompt_hash,skill,event:"bypass",triggers:"deploy"}` — no `v`/`type`/`session`, and it has `triggers`).

- [ ] **2.3 Apply fix — remove the `invoked_without_trigger` arm** (lines 53-54), leaving:

```bash
  if [[ "$MATCHED" == "yes" && "$INVOKED" == "null" ]]; then
    EVENT="bypass"
  elif [[ "$MATCHED" == "yes" && "$INVOKED" != "null" ]]; then
    EVENT="used_correctly"
  else
    continue
  fi
```

- [ ] **2.4 Apply fix — reshape the emit** (lines 59-64):

```bash
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg h "$PROMPT_HASH" --arg s "$skill" --arg e "$EVENT" \
         '{v:1, type:"skill_event", ts:$ts, session:$sid, prompt_hash:$h, skill:$s, event:$e}' >> "$METRICS"
```

- [ ] **2.5 Confirm GREEN (bypass shape):** re-run 2.1 → `PASS`.

- [ ] **2.6 Confirm `invoked_without_trigger` is gone.** Trigger NOT matched but skill invoked → must emit nothing:

```bash
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/mtest"
cat > "$SB/.claude/skills-routing.json" <<'EOF'
{"version":2,"skills":{"demo":{"kind":"ref","plugin":"x","name":"demo","triggers":["deploy"]}}}
EOF
echo 'hello there, nothing relevant' > "$SB/.claude/state/mtest/last-prompt.txt"
echo '["demo"]' > "$SB/.claude/state/mtest/turn-skills-invoked.json"
echo '{"session_id":"mtest","transcript_path":""}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
test -s "$SB/.claude/state/_metrics.jsonl" && echo "WROTE-LINE (RED)" || echo "NO-LINE (GREEN)"
rm -rf "$SB"
```

Expected after fix: `NO-LINE (GREEN)` (before fix: `WROTE-LINE (RED)` — an `invoked_without_trigger` record).

- [ ] **2.7 Fail-open:** garbage stdin → `exit=0`.

- [ ] **2.8 Syntax + commit:** `bash -n "$HOOK"` → propose `refactor(hooks): slim log-skill-usage records (drop triggers + invoked_without_trigger, add v/type/session)`.

---

## Task 3 — `detect-bypass.sh`: add v/type/session to all 3 skill_event emits

**Files:** `plugins/guardrails-kit/hooks/detect-bypass.sh` (EDIT)
**Interfaces** — Consumes: none. Produces: `skill_event` records for `read_instead_of_skill`, `direct_edit_lessons_log`, `trigger_bypass_warn`.

- [ ] **3.1 Failing fixture (read_instead_of_skill, site 1).** The routing entry MUST be `kind:"local"` with a `files` array — check 1 matches the Read path against `.value.files`, and a `ref` entry has no `files`, so it would never fire. Do not "simplify" it to `ref`.

```bash
HOOK=plugins/guardrails-kit/hooks/detect-bypass.sh
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/btest"
cat > "$SB/.claude/skills-routing.json" <<'EOF'
{"version":2,"skills":{"demo":{"kind":"local","triggers":["x"],"files":[".claude/skills/demo/SKILL.md"]}}}
EOF
echo '[]' > "$SB/.claude/state/btest/turn-skills-invoked.json"
echo '{"count":0}' > "$SB/.claude/state/btest/turn-tool-count.json"
echo "{\"session_id\":\"btest\",\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$SB/.claude/skills/demo/SKILL.md\"}}" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null
line=$(tail -1 "$SB/.claude/state/_metrics.jsonl"); echo "$line"
echo "$line" | jq -e '.v==1 and .type=="skill_event" and .session=="btest" and .event=="read_instead_of_skill" and .skill=="demo"' >/dev/null && echo PASS || echo FAIL
rm -rf "$SB"
```

- [ ] **3.2 Confirm RED:** `FAIL` (line is `{ts,event:"read_instead_of_skill",skill,path}` — no `v`/`type`/`session`).

- [ ] **3.3 Apply fix — site 1 (read_instead_of_skill, lines 80-81):**

```bash
        jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg s "$MATCHED_SKILL" --arg p "$REL_PATH" \
          '{v:1, type:"skill_event", ts:$ts, session:$sid, event:"read_instead_of_skill", skill:$s, path:$p}' >> "$METRICS"
```

- [ ] **3.4 Apply fix — site 2 (direct_edit_lessons_log, lines 95-96):**

```bash
      jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg p "$WRITE_PATH" \
        '{v:1, type:"skill_event", ts:$ts, session:$sid, event:"direct_edit_lessons_log", path:$p}' >> "$METRICS"
```

- [ ] **3.5 Apply fix — site 3 (trigger_bypass_warn, lines 126-127):**

```bash
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg s "$MATCHED_MISSED" --argjson c "$NEW_COUNT" \
    '{v:1, type:"skill_event", ts:$ts, session:$sid, event:"trigger_bypass_warn", skill:$s, tool_count:$c}' >> "$METRICS"
```

- [ ] **3.6 Confirm GREEN site 1:** re-run 3.1 → `PASS`.

- [ ] **3.7 Confirm GREEN site 2 (direct_edit_lessons_log):**

```bash
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/btest"
echo '{"version":2,"skills":{}}' > "$SB/.claude/skills-routing.json"
echo '[]' > "$SB/.claude/state/btest/turn-skills-invoked.json"; echo '{"count":0}' > "$SB/.claude/state/btest/turn-tool-count.json"
echo "{\"session_id\":\"btest\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$SB/lessons-learned.md\"}}" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null
tail -1 "$SB/.claude/state/_metrics.jsonl" | jq -e '.v==1 and .type=="skill_event" and .session=="btest" and .event=="direct_edit_lessons_log"' >/dev/null && echo PASS || echo FAIL
rm -rf "$SB"
```

- [ ] **3.8 Confirm GREEN site 3 (trigger_bypass_warn):** count starts at 2 so this call bumps to the threshold (3):

```bash
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/btest"
cat > "$SB/.claude/skills-routing.json" <<'EOF'
{"version":2,"skills":{"demo":{"kind":"ref","plugin":"x","name":"demo","triggers":["deploy"]}}}
EOF
echo '[]' > "$SB/.claude/state/btest/turn-skills-invoked.json"
echo '{"count":2}' > "$SB/.claude/state/btest/turn-tool-count.json"
echo 'please deploy' > "$SB/.claude/state/btest/last-prompt.txt"
echo '{"session_id":"btest","tool_name":"Bash","tool_input":{}}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null
tail -1 "$SB/.claude/state/_metrics.jsonl" | jq -e '.v==1 and .type=="skill_event" and .session=="btest" and .event=="trigger_bypass_warn" and .skill=="demo"' >/dev/null && echo PASS || echo FAIL
rm -rf "$SB"
```

- [ ] **3.9 Fail-open:** garbage stdin → `exit=0`.

- [ ] **3.10 Syntax + commit:** `bash -n "$HOOK"` → propose `refactor(hooks): stamp detect-bypass skill_event records with v/type/session`.

---

## Task 4 — `metrics-report.sh`: discriminate by `.type`, fix stale read path

**Files:** `scripts/metrics-report.sh` (EDIT)
**Interfaces** — Consumes: the `skill_event` / `friction` record shapes from Tasks 1-3 (fixture uses hand-crafted new-schema lines, so this task is independently testable). Produces: nothing.

- [ ] **4.1 Failing fixture (new-schema lines at the LIVE path).**

```bash
SCRIPT=scripts/metrics-report.sh
SB=$(mktemp -d); mkdir -p "$SB/.claude/state"
cat > "$SB/.claude/state/_metrics.jsonl" <<'EOF'
{"v":1,"type":"skill_event","ts":"2026-06-24T10:00:00Z","session":"s1","prompt_hash":"h","skill":"demo","event":"bypass"}
{"v":1,"type":"skill_event","ts":"2026-06-24T10:01:00Z","session":"s1","prompt_hash":"h","skill":"demo","event":"used_correctly"}
{"v":1,"type":"friction","ts":"2026-06-24T10:02:00Z","session":"s1","class":"error","count":1}
EOF
out=$(bash "$SCRIPT" "$SB"); printf '%s\n' "$out"
{ [[ "$out" == *"- bypass: 1"* ]] && [[ "$out" == *"Bypass rate: 1/2 = 50%"* ]] && [[ "$out" == *"- error: 1"* ]]; } && echo PASS || echo FAIL
rm -rf "$SB"
```

- [ ] **4.2 Confirm RED:** `FAIL` — the script reads the stale `.claude/skills/_metrics.jsonl` (absent here) → "no _metrics.jsonl data yet", so none of the substrings appear. (Separately, with the path fixed but the discriminators NOT updated, a new-schema friction record has no `.event`, so the routing `select(.event != "friction")` is `null != "friction"` → true → friction would leak into the routing group; step 4.4/4.5 fix that by switching to `.type`.)

- [ ] **4.3 Apply fix — read path (line 15):**

```bash
METRICS="$PROJECT_DIR/.claude/state/_metrics.jsonl"
```

- [ ] **4.4 Apply fix — routing discriminator (line 26):**

```bash
    map(select(.type == "skill_event"))
```

- [ ] **4.5 Apply fix — friction discriminator (line 47):**

```bash
    (map(select(.type == "friction"))) as $f
```

- [ ] **4.6 Apply fix — header comment (lines 6-8):** drop `invoked_without_trigger` from the event list and note the v1 template, e.g.:

```bash
#   - .claude/state/_metrics.jsonl   v1 records {v,type,ts,session,…}: type=="skill_event"
#                                     (event: bypass / used_correctly / read_instead_of_skill /
#                                      trigger_bypass_warn / direct_edit_lessons_log) and type=="friction"
```

- [ ] **4.7 Confirm GREEN:** re-run 4.1 → `PASS` (bypass:1, Bypass rate 1/2 = 50%, error:1).

- [ ] **4.8 Empty-input regression:** `out=$(bash "$SCRIPT" "$(mktemp -d)"); [[ "$out" == *"no _metrics.jsonl data yet"* ]] && echo PASS || echo FAIL` → `PASS` (absent file still handled).

- [ ] **4.9 Syntax + commit:** `bash -n "$SCRIPT"` → propose `fix(scripts): metrics-report reads .claude/state and discriminates records by type`.

---

## Final verification (after all tasks)

- [ ] `bash -n` on all 4 edited files → no output.
- [ ] Independent Layer-2 verdict: a fresh subagent re-runs all task fixtures, inverts each (confirms RED reproduces against the committed pre-edit version via `git show HEAD:`), and returns PASS with verbatim evidence.
- [ ] Spec-drift audit against the approved spec (incl. out-of-scope sweep: corpus / single-writer / used_correctly-removal / rotation NOT touched).
