# Prompt Corpus Capture (3a) — Implementation Plan

**Goal:** Capture a per-turn prompt-corpus record (open at `UserPromptSubmit`, finalize at `Stop` by the sole writer `log-skill-usage`) into `.claude/state/prompts/YYYY-MM-DD.jsonl`, and remove the duplicated `trigger_bypass_warn` metric.
**Architecture:** Reorder the `Stop` array first (so `friction-seen.json` is current), then add the open-record write to `reset-turn-budget`, the finalize+append to `log-skill-usage`, and drop one metric emit in `detect-bypass`. Each hook is tested by fixture-execution.
**Tech stack:** Bash + `jq`; verification = fixture-execution + `bash -n` + `jq` on `hooks.json`.

## Global constraints

- **Test-first (writing-hooks):** craft the fixture, run RED/baseline, edit, run GREEN. Each edited hook keeps its fail-open behavior (`common.sh` readability guard already in place).
- **`grep`/`rg` unavailable in THIS shell for direct calls** — fixture ASSERTIONS use `jq -e`, `[[ ]]`, `tail`. (Hooks' own internal `grep` runs fine when the hook executes.)
- **No behavior change outside scope:** `read_instead_of_skill` / `direct_edit_lessons_log` / `bypass` / `used_correctly` / `friction` metrics stay; only the `trigger_bypass_warn` metric emit is removed.
- **Fresh `SB=$(mktemp -d)` per fixture; guard new writes** with tmp-file+`mv` / `|| true` (the hooks run under `set -euo pipefail`).
- **Full prompt text is stored** (approved); `.claude/state` is gitignored. Rotation/GC is build 3b (out of scope).
- **Git boundary:** human owns the commit; each task proposes a Conventional Commit.
- Spec: [docs/specs/2026-06-24-prompt-corpus-capture.md](../specs/2026-06-24-prompt-corpus-capture.md).

---

## Task 1 — Reorder the `Stop` hooks so `friction-log` runs first

**Files:** `plugins/guardrails-kit/hooks/hooks.json` (EDIT)
**Interfaces** — Consumes: none. Produces: `Stop` order `friction-log → log-skill-usage → lessons-nudge` (Task 3 relies on `friction-seen.json` being current).

- [ ] **1.1 Failing fixture (current order is wrong for our need).**

```bash
jq -r '.hooks.Stop[0].hooks[0].command' plugins/guardrails-kit/hooks/hooks.json
# RED: prints "...log-skill-usage.sh" (friction-log is currently last)
```

- [ ] **1.2 Confirm RED:** the command shown is `log-skill-usage.sh`, not `friction-log.sh`.

- [ ] **1.3 Apply fix.** Reorder the three `Stop` entries so `friction-log` is first, then `log-skill-usage`, then `lessons-nudge`:

```json
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/friction-log.sh" },
          { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/log-skill-usage.sh" },
          { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/lessons-nudge.sh" }
        ]
      }
    ]
```

- [ ] **1.4 Confirm GREEN.**

```bash
jq -e '(.hooks.Stop[0].hooks[0].command|test("friction-log")) and (.hooks.Stop[0].hooks[1].command|test("log-skill-usage")) and (.hooks.Stop[0].hooks[2].command|test("lessons-nudge"))' plugins/guardrails-kit/hooks/hooks.json && echo "ORDER OK"
jq -e . plugins/guardrails-kit/hooks/hooks.json >/dev/null && echo "VALID JSON"
```

Expected: `ORDER OK` + `VALID JSON`.

- [ ] **1.5 Commit.** Propose `chore(hooks): run friction-log before log-skill-usage at Stop (corpus needs current friction)`.

---

## Task 2 — `reset-turn-budget`: open the prompt record + monotone turn counter

**Files:** `plugins/guardrails-kit/hooks/reset-turn-budget.sh` (EDIT)
**Interfaces** — Consumes: `hook_sid`/`hook_state_dir` (lib). Produces: `.claude/state/<sid>/pending-prompt.json` = `{v:1,type:"prompt",ts,session,turn,prompt,chars}`; `.claude/state/<sid>/session-turn.json` = `{"n":N}` (monotone, NOT reset per turn).

- [ ] **2.1 Failing fixture.**

```bash
HOOK=plugins/guardrails-kit/hooks/reset-turn-budget.sh
SB=$(mktemp -d)
echo '{"session_id":"s1","prompt":"привет мир"}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
P="$SB/.claude/state/s1/pending-prompt.json"
test -f "$P" && jq -e '.v==1 and .type=="prompt" and .session=="s1" and .turn==1 and .prompt=="привет мир" and .chars==10' "$P" >/dev/null && echo "OPEN OK" || echo "RED"
rm -rf "$SB"
```

- [ ] **2.2 Confirm RED:** `RED` (no `pending-prompt.json` written yet).

- [ ] **2.3 Apply fix.** Insert a new block immediately after the `last-prompt.txt` write (current line 34, `printf '%s' "$PROMPT" > "$STATE_DIR/last-prompt.txt"`) — inside the post-`jq -e`-guard region so it only runs for a valid-JSON prompt:

```bash
# Open the prompt-corpus record (finalized at Stop by log-skill-usage). Monotone session-turn
# counter (NOT among the per-turn files reset above). Guarded: a failure must not abort the reset.
TURN_N_FILE="$STATE_DIR/session-turn.json"
[ -f "$TURN_N_FILE" ] || echo '{"n":0}' > "$TURN_N_FILE"
TURN_N=$(( $(jq -r '.n // 0' "$TURN_N_FILE" 2>/dev/null || echo 0) + 1 ))
jq -cn --argjson n "$TURN_N" '{n:$n}' > "$TURN_N_FILE.tmp" 2>/dev/null && mv "$TURN_N_FILE.tmp" "$TURN_N_FILE" || true
jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --argjson turn "$TURN_N" --arg p "$PROMPT" \
  '{v:1, type:"prompt", ts:$ts, session:$sid, turn:$turn, prompt:$p, chars:($p|length)}' \
  > "$STATE_DIR/pending-prompt.json.tmp" 2>/dev/null \
  && mv "$STATE_DIR/pending-prompt.json.tmp" "$STATE_DIR/pending-prompt.json" || true
```

- [ ] **2.4 Confirm GREEN:** re-run 2.1 → `OPEN OK`.

- [ ] **2.5 Confirm monotone turn.** Second prompt in the same session → `turn==2`:

```bash
SB=$(mktemp -d)
echo '{"session_id":"s1","prompt":"first"}'  | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
echo '{"session_id":"s1","prompt":"second"}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
jq -e '.turn==2 and .prompt=="second"' "$SB/.claude/state/s1/pending-prompt.json" >/dev/null && echo "MONOTONE OK"; rm -rf "$SB"
```

- [ ] **2.6 Confirm no record on non-JSON stdin** (the existing early-exit holds):

```bash
SB=$(mktemp -d); printf 'not json' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; echo "exit=$?"
test -f "$SB/.claude/state/default/pending-prompt.json" && echo "LEAK (FAIL)" || echo "no-record OK"; rm -rf "$SB"
```

Expected: `exit=0` + `no-record OK`.

- [ ] **2.7 Fail-open + syntax.** `printf 'x' | CLAUDE_PROJECT_DIR=$(mktemp -d) bash "$HOOK"; echo $?` → 0; `bash -n "$HOOK"`. Propose `feat(hooks): open a prompt-corpus record at UserPromptSubmit (+ monotone session-turn)`.

---

## Task 3 — `log-skill-usage`: finalize the record + append to the corpus

**Files:** `plugins/guardrails-kit/hooks/log-skill-usage.sh` (EDIT)
**Interfaces** — Consumes: `pending-prompt.json` (Task 2), `turn-tool-count.json`, `friction-seen.json`, `turn-skills-invoked.json`, routing. Produces: appended record in `.claude/state/prompts/YYYY-MM-DD.jsonl`.

- [ ] **3.1 Failing fixture.**

```bash
HOOK=plugins/guardrails-kit/hooks/log-skill-usage.sh
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/s1"
cat > "$SB/.claude/skills-routing.json" <<'EOF'
{"version":2,"skills":{"grilling":{"kind":"ref","plugin":"sdd-kit","name":"grilling","triggers":["давай подумаем"]}}}
EOF
echo 'давай подумаем' > "$SB/.claude/state/s1/last-prompt.txt"
echo '[]' > "$SB/.claude/state/s1/turn-skills-invoked.json"
echo '{"count":14}' > "$SB/.claude/state/s1/turn-tool-count.json"
echo '{"denied":0,"blocked":0,"error":1}' > "$SB/.claude/state/s1/friction-seen.json"
echo '{"v":1,"type":"prompt","ts":"2026-06-24T10:00:00Z","session":"s1","turn":7,"prompt":"давай подумаем","chars":14}' > "$SB/.claude/state/s1/pending-prompt.json"
echo '{"session_id":"s1","transcript_path":""}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
F="$SB/.claude/state/prompts/$(date -u +%F).jsonl"
test -f "$F" && tail -1 "$F" | jq -e '.type=="prompt" and .turn==7 and .lang=="ru" and .triggers_matched==["grilling"] and .outcome.tools_used==14 and .outcome.friction.error==1 and .outcome.bypass==true' >/dev/null && echo "FINALIZE OK" || echo "RED"
test -f "$SB/.claude/state/s1/pending-prompt.json" && echo "pending NOT cleared (FAIL)" || echo "pending cleared OK"
rm -rf "$SB"
```

(Trigger matched + skill not invoked → `outcome.bypass==true`; Cyrillic prompt → `lang=="ru"`.)

- [ ] **3.2 Confirm RED:** `RED` (no `prompts/` file written yet).

- [ ] **3.3 Apply fix.** Insert the finalize block after the metric loop's `done` (current line 63) and before `echo '[]' > "$TURN_SKILLS_FILE"` (line 66):

```bash
# --- Prompt-corpus finalize (single writer). Only if reset-turn-budget opened a record. ---
PENDING="$STATE_DIR/pending-prompt.json"
if [[ -f "$PENDING" ]]; then
  PROMPTS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/state/prompts"
  mkdir -p "$PROMPTS_DIR"
  # skills whose trigger union matches the prompt (same match as the metric loop above)
  TRIGGERS_MATCHED=$(jq -r '.skills // {} | to_entries[] | "\(.key)\t\(.value.triggers // [] | join("|"))"' "$ROUTING" \
    | while IFS=$'\t' read -r skill trig; do
        [[ -n "$trig" ]] || continue
        echo "$USER_PROMPT" | grep -qiE "$trig" && printf '%s\n' "$skill"
      done | jq -R . | jq -cs .)
  TOOLS_USED=$(jq -r '.count // 0' "$STATE_DIR/turn-tool-count.json" 2>/dev/null || echo 0)
  FRICTION=$(cat "$STATE_DIR/friction-seen.json" 2>/dev/null || echo '{"denied":0,"blocked":0,"error":0}')
  BYPASS=$(printf '%s' "$TRIGGERS_MATCHED" | jq --argjson inv "$INVOKED_SKILLS" 'map(select(($inv | index(.)) | not)) | length > 0')
  jq -cn --slurpfile pend "$PENDING" \
        --argjson tm "$TRIGGERS_MATCHED" --argjson inv "$INVOKED_SKILLS" \
        --argjson tu "$TOOLS_USED" --argjson fr "$FRICTION" --argjson bp "$BYPASS" \
        '$pend[0] + {triggers_matched:$tm, skills_invoked:$inv,
                     lang:(if ($pend[0].prompt|test("[Ѐ-ӿ]")) then "ru" else "en" end),
                     outcome:{tools_used:$tu, friction:$fr, bypass:$bp}}' \
    >> "$PROMPTS_DIR/$(date -u +%F).jsonl" 2>/dev/null || true
  rm -f "$PENDING"
fi
```

- [ ] **3.4 Confirm GREEN:** re-run 3.1 → `FINALIZE OK` + `pending cleared OK`.

- [ ] **3.5 Confirm `lang=="en"` for a Latin prompt + `bypass==false` when invoked.**

```bash
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/s2"
cat > "$SB/.claude/skills-routing.json" <<'EOF'
{"version":2,"skills":{"grilling":{"kind":"ref","plugin":"sdd-kit","name":"grilling","triggers":["brainstorm"]}}}
EOF
echo 'brainstorm this' > "$SB/.claude/state/s2/last-prompt.txt"
echo '["grilling"]' > "$SB/.claude/state/s2/turn-skills-invoked.json"
echo '{"count":3}' > "$SB/.claude/state/s2/turn-tool-count.json"
echo '{"denied":0,"blocked":0,"error":0}' > "$SB/.claude/state/s2/friction-seen.json"
echo '{"v":1,"type":"prompt","ts":"t","session":"s2","turn":1,"prompt":"brainstorm this","chars":15}' > "$SB/.claude/state/s2/pending-prompt.json"
echo '{"session_id":"s2","transcript_path":""}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
tail -1 "$SB/.claude/state/prompts/$(date -u +%F).jsonl" | jq -e '.lang=="en" and .outcome.bypass==false and .skills_invoked==["grilling"]' >/dev/null && echo "EN/INVOKED OK"; rm -rf "$SB"
```

- [ ] **3.6 Confirm double-Stop idempotency** (pending cleared → second Stop no-ops): re-run the 3.1 hook a SECOND time on the same `SB` (after the first cleared `pending-prompt.json`) and assert the corpus file still has exactly 1 line.

```bash
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/s1"
cat > "$SB/.claude/skills-routing.json" <<'EOF'
{"version":2,"skills":{}}
EOF
echo 'hi' > "$SB/.claude/state/s1/last-prompt.txt"; echo '[]' > "$SB/.claude/state/s1/turn-skills-invoked.json"
echo '{"count":0}' > "$SB/.claude/state/s1/turn-tool-count.json"; echo '{"denied":0,"blocked":0,"error":0}' > "$SB/.claude/state/s1/friction-seen.json"
echo '{"v":1,"type":"prompt","ts":"t","session":"s1","turn":1,"prompt":"hi","chars":2}' > "$SB/.claude/state/s1/pending-prompt.json"
echo '{"session_id":"s1"}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
echo '{"session_id":"s1"}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
N=$(wc -l < "$SB/.claude/state/prompts/$(date -u +%F).jsonl" | tr -d ' '); [ "$N" = "1" ] && echo "IDEMPOTENT OK ($N line)" || echo "DOUBLE-APPEND (FAIL: $N)"; rm -rf "$SB"
```

- [ ] **3.7 Fail-open + syntax.** garbage stdin → `exit 0`; missing `pending-prompt.json` → metric path unaffected, no corpus write; `bash -n "$HOOK"`. Propose `feat(hooks): finalize the prompt-corpus record at Stop (sole writer)`.

---

## Task 4 — `detect-bypass`: drop the duplicated `trigger_bypass_warn` metric

**Files:** `plugins/guardrails-kit/hooks/detect-bypass.sh` (EDIT)
**Interfaces** — Consumes: none new. Produces: still warns + sets `turn-bypass-warned.flag`; no longer writes the `trigger_bypass_warn` metric line.

- [ ] **4.1 Baseline (current emits the metric).** Self-contained; assert the `trigger_bypass_warn` line IS present before the fix:

```bash
HOOK=plugins/guardrails-kit/hooks/detect-bypass.sh
run_tbw() {  # re-usable: seed a sandbox that fires trigger_bypass_warn; echoes the SB path
  local SB; SB=$(mktemp -d); mkdir -p "$SB/.claude/state/b1"
  cat > "$SB/.claude/skills-routing.json" <<'EOF'
{"version":2,"skills":{"demo":{"kind":"ref","plugin":"x","name":"demo","triggers":["deploy"]}}}
EOF
  echo '[]' > "$SB/.claude/state/b1/turn-skills-invoked.json"
  echo '{"count":2}' > "$SB/.claude/state/b1/turn-tool-count.json"
  echo 'please deploy' > "$SB/.claude/state/b1/last-prompt.txt"
  echo '{"session_id":"b1","tool_name":"Bash","tool_input":{}}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>"$SB/err"
  printf '%s' "$SB"
}
SB=$(run_tbw)
jq -es 'map(select(.event=="trigger_bypass_warn")) | length' "$SB/.claude/state/_metrics.jsonl" 2>/dev/null   # RED: 1
rm -rf "$SB"
```

- [ ] **4.2 Apply fix.** Remove only the metric emit at the `trigger_bypass_warn` site (keep the `echo … >&2` warn and `touch "$BYPASS_WARNED_FILE"`):

```bash
# before:
  echo "SKILL-BYPASS warn: user prompt matched trigger for Skill '$MATCHED_MISSED' ..." >&2
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg s "$MATCHED_MISSED" --argjson c "$NEW_COUNT" \
    '{v:1, type:"skill_event", ts:$ts, session:$sid, event:"trigger_bypass_warn", skill:$s, tool_count:$c}' >> "$METRICS"
  touch "$BYPASS_WARNED_FILE"

# after (metric emit deleted; bypass is now recorded solely by log-skill-usage at Stop):
  echo "SKILL-BYPASS warn: user prompt matched trigger for Skill '$MATCHED_MISSED' ..." >&2
  touch "$BYPASS_WARNED_FILE"
```

(Keep the exact original `echo` text — shown abbreviated here; do not reword it.)

- [ ] **4.3 Confirm GREEN:** self-contained (reuse `run_tbw` from 4.1). Stderr still warns, `turn-bypass-warned.flag` exists, but **zero** `trigger_bypass_warn` lines. The `jq -es … length==0` slurp is true even when the metrics file is absent (no metric emitted in that path), so it cannot false-GREEN:

```bash
SB=$(run_tbw)
# zero trigger_bypass_warn lines (absent file → treat as zero):
if [ -f "$SB/.claude/state/_metrics.jsonl" ]; then
  jq -es 'map(select(.event=="trigger_bypass_warn")) | length == 0' "$SB/.claude/state/_metrics.jsonl" >/dev/null && echo "no trigger_bypass_warn OK" || echo "STILL EMITS (FAIL)"
else
  echo "no trigger_bypass_warn OK (no metrics file)"
fi
test -f "$SB/.claude/state/b1/turn-bypass-warned.flag" && echo "flag set OK" || echo "flag MISSING (FAIL)"
[[ "$(cat "$SB/err")" == *"SKILL-BYPASS warn"* ]] && echo "warn OK" || echo "warn MISSING (FAIL)"
rm -rf "$SB"
```

Expected: `no trigger_bypass_warn OK` + `flag set OK` + `warn OK`.

- [ ] **4.4 Regression: `read_instead_of_skill` metric still emits.**

```bash
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/b2"
cat > "$SB/.claude/skills-routing.json" <<'EOF'
{"version":2,"skills":{"demo":{"kind":"local","triggers":["x"],"files":[".claude/skills/demo/SKILL.md"]}}}
EOF
echo '[]' > "$SB/.claude/state/b2/turn-skills-invoked.json"; echo '{"count":0}' > "$SB/.claude/state/b2/turn-tool-count.json"
echo "{\"session_id\":\"b2\",\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$SB/.claude/skills/demo/SKILL.md\"}}" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null
tail -1 "$SB/.claude/state/_metrics.jsonl" | jq -e '.event=="read_instead_of_skill"' >/dev/null && echo "read_instead regression OK"; rm -rf "$SB"
```

- [ ] **4.5 Fail-open + syntax.** garbage stdin → `exit 0`; `bash -n "$HOOK"`. Propose `refactor(hooks): drop duplicated trigger_bypass_warn metric (log-skill-usage is sole writer)`.

---

## Final verification (after all tasks)

- [ ] `bash -n` on the 3 edited hooks; `jq -e . hooks.json`.
- [ ] End-to-end: run `reset-turn-budget` (open) then `log-skill-usage` (finalize) in one `SB` with a real routing file → assert one well-formed record in `prompts/YYYY-MM-DD.jsonl`.
- [ ] Independent Layer-2 verdict: a fresh subagent re-runs all task fixtures on the working tree (GREEN) and confirms each RED/baseline reproduces against the pre-edit `git stash`/copy; returns PASS with verbatim evidence.
- [ ] Spec-drift audit (out-of-scope sweep: no rotation/GC, no SessionEnd, no entrypoint, `common.sh`/`friction-log`/`lessons-nudge`/`quality` untouched beyond the Stop-array reorder).
