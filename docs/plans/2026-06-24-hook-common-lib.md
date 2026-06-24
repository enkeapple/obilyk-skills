# Shared Hook Preamble Library — Implementation Plan

**Goal:** Extract the duplicated session/state boilerplate into `hooks/lib/common.sh` (3 pure functions) and migrate the 7 SID-deriving hooks to use it, with zero behavior change.
**Architecture:** Build the lib + its unit fixtures first; then migrate hooks in shape-groups (strict / state_dir-non-strict / sid-only). Each hook's *existing* behavior is the test — its fixture must stay GREEN byte-for-byte. Verification is fixture-execution + `bash -n`; no unit-test suite.
**Tech stack:** Bash + `jq`.

## Global constraints

- **Pure refactor — no behavior change.** Every migrated hook must produce byte-identical output to its pre-refactor version on the same fixture. The regression fixture is the gate.
- **Test-first (writing-hooks):** for the lib, write the unit fixture first (RED: function undefined) → create lib → GREEN. For each hook, run its regression fixture against the current version (baseline GREEN), apply the migration, re-run (still GREEN).
- **Fail-open preserved + missing-lib fail-open:** sourcing is `GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"; [ -r "$GUARDRAILS_LIB" ] || exit 0; . "$GUARDRAILS_LIB"`; a separate fixture proves a hook with the lib absent exits 0.
- **`grep`/`rg` unavailable in this shell** — assert with `jq -e` and bash `[[ ]]`.
- **`friction-log` + `lessons-nudge` keep their exact `PROJECT_DIR` line inline** (they use `hook_sid` only; `METRICS`/`LESSONS` derive from `PROJECT_DIR`; `lessons-nudge` keeps `:-$(pwd)`).
- **`hook_require_json` is called as a BARE statement**, never in `$(…)`.
- **Git boundary:** human owns the commit; each task ends with a proposed Conventional Commit.
- Fresh `SB=$(mktemp -d)` per fixture run. Spec: [docs/specs/2026-06-24-hook-common-lib.md](../specs/2026-06-24-hook-common-lib.md).

---

## Task 1 — Create `hooks/lib/common.sh` + lib unit fixtures

**Files:** `plugins/guardrails-kit/hooks/lib/common.sh` (NEW)
**Interfaces** — Produces: `hook_sid <json> -> sanitized-sid|default`, `hook_state_dir <sid> -> path`, `hook_require_json <json>` (exits caller 0 if invalid JSON). Consumes: none.

- [ ] **1.1 Failing fixture (lib absent → functions undefined).**

```bash
LIB=plugins/guardrails-kit/hooks/lib/common.sh
bash -c ". $LIB 2>/dev/null; type hook_sid" >/dev/null 2>&1 && echo "DEFINED" || echo "UNDEFINED"
```

- [ ] **1.2 Confirm RED:** `UNDEFINED` (file doesn't exist yet).

- [ ] **1.3 Create the lib.**

```bash
# plugins/guardrails-kit/hooks/lib/common.sh
# Shared hook preamble helpers. Sourced by guardrail hooks; defines functions only —
# no side effects at source time (never reads stdin / touches the fs on source).

hook_sid() {
  local sid
  sid=$(printf '%s' "${1:-}" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9._-') || sid=""
  [ -z "$sid" ] && sid=default
  printf '%s' "$sid"
}

hook_state_dir() {
  printf '%s' "${CLAUDE_PROJECT_DIR:-.}/.claude/state/${1:-default}"
}

hook_require_json() {
  printf '%s' "${1:-}" | jq -e . >/dev/null 2>&1 || exit 0
}
```

- [ ] **1.4 Confirm GREEN — the unit fixtures.**

```bash
LIB=plugins/guardrails-kit/hooks/lib/common.sh
[ "$(bash -c ". $LIB; hook_sid '{\"session_id\":\"a/b c\"}'")" = "abc" ] && echo "sid-sanitize OK"   # / and space stripped
[ "$(bash -c ". $LIB; hook_sid ''")" = "default" ] && echo "sid-empty OK"
[ "$(bash -c ". $LIB; hook_sid 'garbage'")" = "default" ] && echo "sid-garbage OK"
[ "$(bash -c ". $LIB; CLAUDE_PROJECT_DIR=/x hook_state_dir s1")" = "/x/.claude/state/s1" ] && echo "state_dir OK"
# require_json exits the CALLER on bad json (bare statement) → REACHED must NOT print:
out=$(bash -c ". $LIB; hook_require_json 'garbage'; echo REACHED"); [ -z "$out" ] && echo "require_json-bad OK (exited)"
out=$(bash -c ". $LIB; hook_require_json '{\"a\":1}'; echo REACHED"); [ "$out" = "REACHED" ] && echo "require_json-good OK"
```

Expected: all six `… OK` lines print.

- [ ] **1.5 Syntax + commit.** `bash -n "$LIB"` → propose `feat(hooks): add hooks/lib/common.sh (hook_sid/state_dir/require_json)`.

---

## Task 2 — Migrate the 3 strict hooks (require_json + sid + state_dir)

**Files:** `detect-bypass.sh`, `log-skill-usage.sh`, `token-guard.sh` (EDIT)
**Interfaces** — Consumes: `hook_require_json`, `hook_sid`, `hook_state_dir` (Task 1).

- [ ] **2.1 Baseline GREEN (record pre-refactor behavior).** Run each hook's regression fixture against the CURRENT version, capture the expected line:

```bash
# detect-bypass: read_instead_of_skill emits a v1 skill_event line
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/btest"
cat > "$SB/.claude/skills-routing.json" <<'EOF'
{"version":2,"skills":{"demo":{"kind":"local","triggers":["x"],"files":[".claude/skills/demo/SKILL.md"]}}}
EOF
echo '[]' > "$SB/.claude/state/btest/turn-skills-invoked.json"; echo '{"count":0}' > "$SB/.claude/state/btest/turn-tool-count.json"
echo "{\"session_id\":\"btest\",\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$SB/.claude/skills/demo/SKILL.md\"}}" | CLAUDE_PROJECT_DIR="$SB" bash plugins/guardrails-kit/hooks/detect-bypass.sh 2>/dev/null
tail -1 "$SB/.claude/state/_metrics.jsonl" | jq -e '.type=="skill_event" and .event=="read_instead_of_skill" and .session=="btest"' >/dev/null && echo "detect-bypass baseline OK"; rm -rf "$SB"
# log-skill-usage: bypass emits a v1 skill_event line
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/mtest"
cat > "$SB/.claude/skills-routing.json" <<'EOF'
{"version":2,"skills":{"demo":{"kind":"ref","plugin":"x","name":"demo","triggers":["deploy"]}}}
EOF
echo 'please deploy now' > "$SB/.claude/state/mtest/last-prompt.txt"; echo '[]' > "$SB/.claude/state/mtest/turn-skills-invoked.json"
echo '{"session_id":"mtest","transcript_path":""}' | CLAUDE_PROJECT_DIR="$SB" bash plugins/guardrails-kit/hooks/log-skill-usage.sh
tail -1 "$SB/.claude/state/_metrics.jsonl" | jq -e '.type=="skill_event" and .event=="bypass" and .session=="mtest"' >/dev/null && echo "log-skill-usage baseline OK"; rm -rf "$SB"
# token-guard: records bytes to by-model-budget.json under STATE_DIR, exit 0
SB=$(mktemp -d)
echo '{"session_id":"tg","tool_name":"Read","tool_response":"abcdefgh","tool_input":{}}' | CLAUDE_PROJECT_DIR="$SB" bash plugins/guardrails-kit/hooks/token-guard.sh; echo "tg exit=$?"
test -f "$SB/.claude/state/tg/by-model-budget.json" && echo "token-guard baseline OK"; rm -rf "$SB"
```

- [ ] **2.2 Apply the strict preamble to each** (replace each hook's `INPUT=$(cat)…SID=…STATE_DIR=…` block, after the `set -euo pipefail` line):

```bash
GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"; [ -r "$GUARDRAILS_LIB" ] || exit 0; . "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || exit 0
hook_require_json "$INPUT"
SID=$(hook_sid "$INPUT")
STATE_DIR=$(hook_state_dir "$SID")
```

Leave each hook's `ROUTING`/`METRICS`/`TURN_*` path vars inline exactly as-is (they use `${CLAUDE_PROJECT_DIR:-.}` or `$STATE_DIR`). Remove only the now-duplicated stdin/jq-e/SID/STATE_DIR lines. (`detect-bypass`/`skill-gate`'s separate later `PROJECT_DIR` for `REL_PATH` is untouched.)

- [ ] **2.3 Confirm GREEN — re-run all three fixtures from 2.1.** Each prints its `… baseline OK` line unchanged.

- [ ] **2.4 Fail-open (garbage stdin) per hook.**

```bash
for h in detect-bypass log-skill-usage token-guard; do
  printf 'not json' | CLAUDE_PROJECT_DIR="$(mktemp -d)" bash "plugins/guardrails-kit/hooks/$h.sh" 2>/dev/null; echo "$h failopen exit=$?"
done   # all exit=0
```

- [ ] **2.5 Syntax + commit.** `bash -n` on the three → propose `refactor(hooks): migrate strict hooks to lib (require_json/sid/state_dir)`.

---

## Task 3 — Migrate `skill-gate` + `reset-turn-budget` (sid + state_dir, no require_json)

**Files:** `skill-gate.sh`, `reset-turn-budget.sh` (EDIT)
**Interfaces** — Consumes: `hook_sid`, `hook_state_dir`.

- [ ] **3.1 Baseline GREEN.**

```bash
# skill-gate: Pass-0 memory-write block → deny JSON
SB=$(mktemp -d)
echo "{\"session_id\":\"sg\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$SB/.claude/projects/x/memory/note.md\"}}" | CLAUDE_PROJECT_DIR="$SB" bash plugins/guardrails-kit/hooks/skill-gate.sh | jq -e '.hookSpecificOutput.permissionDecision=="deny"' >/dev/null && echo "skill-gate baseline OK"; rm -rf "$SB"
# reset-turn-budget: writes turn-budget.json into STATE_DIR
SB=$(mktemp -d)
echo '{"session_id":"rt","prompt":"hi"}' | CLAUDE_PROJECT_DIR="$SB" bash plugins/guardrails-kit/hooks/reset-turn-budget.sh; echo "rt exit=$?"
test -f "$SB/.claude/state/rt/turn-budget.json" && echo "reset-turn-budget baseline OK"; rm -rf "$SB"
```

- [ ] **3.2 Apply — `skill-gate.sh`** (jq-guarded; keeps `command -v jq`):

```bash
GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"; [ -r "$GUARDRAILS_LIB" ] || exit 0; . "$GUARDRAILS_LIB"
command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat 2>/dev/null) || exit 0
SID=$(hook_sid "$INPUT")
STATE_DIR=$(hook_state_dir "$SID")
```

Leave `ROUTING`, `TURN_*`, the `mkdir -p`, and the later `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"` (REL_PATH) inline.

- [ ] **3.3 Apply — `reset-turn-budget.sh`** (run-on-empty; keeps GC):

```bash
GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"; [ -r "$GUARDRAILS_LIB" ] || exit 0; . "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || INPUT=""
SID=$(hook_sid "$INPUT")
STATE_DIR=$(hook_state_dir "$SID")
```

Leave the `mkdir -p`/`touch "$STATE_DIR"` (H1 fix), `STATE_BASE="${CLAUDE_PROJECT_DIR:-.}/.claude/state"`, the GC block, the state-file writes, and the prompt-cache tail inline.

- [ ] **3.4 Confirm GREEN — re-run both fixtures from 3.1** → both `… baseline OK`.

- [ ] **3.5 Fail-open.** `for h in skill-gate reset-turn-budget; do printf 'x' | CLAUDE_PROJECT_DIR="$(mktemp -d)" bash "plugins/guardrails-kit/hooks/$h.sh" >/dev/null 2>&1; echo "$h exit=$?"; done` → both `exit=0`.

- [ ] **3.6 Syntax + commit.** `bash -n` → propose `refactor(hooks): migrate skill-gate + reset-turn-budget to lib (sid/state_dir)`.

---

## Task 4 — Migrate `friction-log` + `lessons-nudge` (sid only; KEEP PROJECT_DIR)

**Files:** `friction-log.sh`, `lessons-nudge.sh` (EDIT)
**Interfaces** — Consumes: `hook_sid` only. These KEEP their inline `PROJECT_DIR` (so `METRICS`/`LESSONS` and `lessons-nudge`'s `:-$(pwd)` are byte-identical).

- [ ] **4.1 Baseline GREEN.**

```bash
# friction-log: a denied is_error result → one v1 friction line at the correct METRICS path
SB=$(mktemp -d); TR="$SB/t.jsonl"
cat > "$TR" <<'EOF'
{"message":{"content":[{"type":"tool_result","is_error":true,"content":"user rejected"}]}}
EOF
echo "{\"session_id\":\"fl\",\"transcript_path\":\"$TR\"}" | CLAUDE_PROJECT_DIR="$SB" bash plugins/guardrails-kit/hooks/friction-log.sh
tail -1 "$SB/.claude/state/_metrics.jsonl" | jq -e '.type=="friction" and .class=="denied" and .session=="fl"' >/dev/null && echo "friction-log baseline OK"; rm -rf "$SB"
# lessons-nudge: bypass flag present, no recent LESSONS edit → stderr nudge
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/ln"
touch "$SB/.claude/state/ln/turn-bypass-warned.flag"
echo '{"session_id":"ln"}' | CLAUDE_PROJECT_DIR="$SB" bash plugins/guardrails-kit/hooks/lessons-nudge.sh 2>ln.err; echo "ln exit=$?"
[[ "$(cat ln.err)" == *"LESSONS-NUDGE"* ]] && echo "lessons-nudge baseline OK"; rm -rf "$SB" ln.err
```

- [ ] **4.2 Apply — `friction-log.sh`** (KEEP `PROJECT_DIR`, derive STATE_DIR/METRICS inline; `hook_sid` only):

```bash
GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"; [ -r "$GUARDRAILS_LIB" ] || exit 0; . "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
SID=$(hook_sid "$INPUT")
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STATE_DIR="$PROJECT_DIR/.claude/state/$SID"
METRICS="$PROJECT_DIR/.claude/state/_metrics.jsonl"
SEEN_FILE="$STATE_DIR/friction-seen.json"
```

(Removes only the old inline SID-derivation lines; the rest of friction-log — transcript read, classification, emit — is untouched.)

- [ ] **4.3 Apply — `lessons-nudge.sh`** (KEEP `PROJECT_DIR` with `:-$(pwd)`; `hook_sid` only):

```bash
GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"; [ -r "$GUARDRAILS_LIB" ] || exit 0; . "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || INPUT=""
SID=$(hook_sid "$INPUT")
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_DIR="$PROJECT_DIR/.claude/state/$SID"
BYPASS_FLAG="$STATE_DIR/turn-bypass-warned.flag"
NUDGED_FLAG="$STATE_DIR/turn-lessons-nudged.flag"
LESSONS="$PROJECT_DIR/.claude/lessons-learned.md"
```

- [ ] **4.4 Confirm GREEN — re-run both fixtures from 4.1** → both `… baseline OK`.

- [ ] **4.5 Fail-open.** `for h in friction-log lessons-nudge; do printf 'x' | CLAUDE_PROJECT_DIR="$(mktemp -d)" bash "plugins/guardrails-kit/hooks/$h.sh" >/dev/null 2>&1; echo "$h exit=$?"; done` → both `exit=0`.

- [ ] **4.6 Syntax + commit.** `bash -n` → propose `refactor(hooks): migrate friction-log + lessons-nudge to hook_sid (keep PROJECT_DIR)`.

---

## Task 5 — Missing-lib fail-open (the new failure mode)

**Files:** none (verification only).
**Interfaces** — Consumes: all migrated hooks.

- [ ] **5.1 Verify every migrated hook fails open when the lib is absent.** Copy each hook alone into a temp dir (no `lib/` sibling) and run with stdin:

```bash
for h in detect-bypass log-skill-usage token-guard skill-gate reset-turn-budget friction-log lessons-nudge; do
  T=$(mktemp -d); cp "plugins/guardrails-kit/hooks/$h.sh" "$T/"   # no lib/ alongside → source fails
  echo '{"session_id":"x"}' | CLAUDE_PROJECT_DIR="$(mktemp -d)" bash "$T/$h.sh" >/dev/null 2>&1; echo "$h missing-lib exit=$?"
  rm -rf "$T"
done   # every line must be exit=0
```

- [ ] **5.2 Distinctly prove the source-guard fires for the two hooks that early-exit for other reasons.** `friction-log`/`lessons-nudge` would also exit 0 with no transcript / no flag, so give each a triggering condition and assert that with the lib absent the hook exits 0 AND produces NO side-effect (the work never ran — the `|| exit 0` short-circuited before it):

```bash
# friction-log: triggering transcript present, lib absent → exit 0 AND no _metrics line written
T=$(mktemp -d); cp plugins/guardrails-kit/hooks/friction-log.sh "$T/"
SB=$(mktemp -d); TR="$SB/t.jsonl"
cat > "$TR" <<'EOF'
{"message":{"content":[{"type":"tool_result","is_error":true,"content":"user rejected"}]}}
EOF
echo "{\"session_id\":\"x\",\"transcript_path\":\"$TR\"}" | CLAUDE_PROJECT_DIR="$SB" bash "$T/friction-log.sh" >/dev/null 2>&1; echo "fl missing-lib exit=$?"
test -f "$SB/.claude/state/_metrics.jsonl" && echo "fl LEAK (FAIL)" || echo "fl no-side-effect OK"; rm -rf "$T" "$SB"
# lessons-nudge: bypass flag set, lib absent → exit 0 AND no nudge on stderr
T=$(mktemp -d); cp plugins/guardrails-kit/hooks/lessons-nudge.sh "$T/"
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/x"; touch "$SB/.claude/state/x/turn-bypass-warned.flag"
echo '{"session_id":"x"}' | CLAUDE_PROJECT_DIR="$SB" bash "$T/lessons-nudge.sh" 2>ln2.err; echo "ln missing-lib exit=$?"
[[ "$(cat ln2.err)" == *"LESSONS-NUDGE"* ]] && echo "ln LEAK (FAIL)" || echo "ln no-side-effect OK"; rm -rf "$T" "$SB" ln2.err
```

- [ ] **5.3 Confirm:** all 7 `exit=0` (5.1); and 5.2 prints `fl no-side-effect OK` + `ln no-side-effect OK` — proving the `GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"; [ -r "$GUARDRAILS_LIB" ] || exit 0; . "$GUARDRAILS_LIB"` guard short-circuited before any work.

---

## Final verification (after all tasks)

- [ ] `bash -n` on `lib/common.sh` + all 7 migrated hooks → no output.
- [ ] Independent Layer-2 verdict: a fresh subagent re-runs every baseline/regression fixture on the working tree (GREEN) AND against the pre-refactor `git show HEAD:` version (also GREEN — proving the refactor changed nothing observable), runs the lib unit fixtures and the missing-lib fixtures, returns PASS with verbatim evidence.
- [ ] Spec-drift audit against the approved spec (incl. out-of-scope sweep: `quality.sh` untouched, GC block intact, no behavior change, `PROJECT_DIR` preserved in friction-log/lessons-nudge).
