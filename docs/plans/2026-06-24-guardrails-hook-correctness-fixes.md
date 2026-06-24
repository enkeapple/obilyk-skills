# Guardrails-kit Hook Correctness Fixes — Implementation Plan

**Goal:** Fix five confirmed correctness defects (H1, H2, M2, M1, L1) in `plugins/guardrails-kit/hooks/`, each the narrowest change, verified by a `writing-hooks` fixture RED → fix → GREEN.
**Architecture:** Five independent single-file edits; each hook is tested by fixture-execution (crafted stdin in an isolated `CLAUDE_PROJECT_DIR` sandbox → run script → assert exit code / metric line / stderr), never a unit-test suite. Tasks are independent (different files) → subagent-driven execution is viable.
**Tech stack:** Bash hooks + `jq`; no node/build/test pipeline. Verification = fixture-execution + `bash -n`.

## Global constraints

- **Test-first (Iron Law, hook form):** write the fixture, run it, watch it give the wrong/absent decision BEFORE editing the hook. The fixture-execution IS the RED/GREEN.
- **Fail-open is an invariant:** every hook must `exit 0` on garbage/non-JSON stdin — asserted as a SEPARATE fixture per task, distinct from the RED case.
- **Scope = correctness only.** No logging-redesign work (slim schema, drop `triggers`/`invoked_without_trigger`, corpus). No L2/L3/L4. Spec out-of-scope list is binding.
- **Git boundary:** the human owns the commit. Each task ends with a proposed one-line Conventional Commit; the executor does NOT run `git commit` autonomously.
- Run every fixture in a fresh `SB=$(mktemp -d)` so delta-state files (`friction-seen.json`) never carry across runs.
- Spec: [docs/specs/2026-06-24-guardrails-hook-correctness-fixes.md](../specs/2026-06-24-guardrails-hook-correctness-fixes.md).

---

## Task 1 — H1: `reset-turn-budget.sh` GC no longer deletes the live session dir

**Files:** `plugins/guardrails-kit/hooks/reset-turn-budget.sh` (EDIT)
**Interfaces** — Consumes: none. Produces: none (behavior-only fix).

- [ ] **1.1 Write the failing fixture.** Save as a temp script and run:

```bash
HOOK=plugins/guardrails-kit/hooks/reset-turn-budget.sh
SB=$(mktemp -d)
mkdir -p "$SB/.claude/state/racetest"
touch -t 202606010000 "$SB/.claude/state/racetest"   # stale: 2026-06-01, >7d before today
echo '{"session_id":"racetest","prompt":"hello"}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; echo "exit=$?"
test -f "$SB/.claude/state/racetest/turn-budget.json" && echo DIR-SURVIVED || echo DIR-GONE
```

- [ ] **1.2 Confirm RED.** Expected before the fix:

```text
exit=1
DIR-GONE
```

(GC deletes the stale live dir; the write on line 21 then fails under `set -euo pipefail`.)

- [ ] **1.3 Apply the fix.** Insert `touch "$STATE_DIR"` right after `mkdir -p "$STATE_DIR"` (line 11):

```bash
STATE_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/state/$SID"
mkdir -p "$STATE_DIR"
touch "$STATE_DIR"   # refresh mtime: mkdir -p is a no-op (no mtime bump) on an existing dir, so a
                     # resumed >GC_DAYS-old session dir would otherwise be deleted by the GC below.
```

- [ ] **1.4 Confirm GREEN.** Re-run 1.1. Expected:

```text
exit=0
DIR-SURVIVED
```

- [ ] **1.5 Assert fail-open (separate fixture).**

```bash
SB2=$(mktemp -d); printf 'not json' | CLAUDE_PROJECT_DIR="$SB2" bash "$HOOK"; echo "exit=$?"   # → exit=0
```

- [ ] **1.6 Syntax check + commit.** `bash -n "$HOOK"` (no output) → propose: `fix(hooks): refresh reset-turn-budget state-dir mtime so GC keeps the live session (H1)`.

---

## Task 2 — H2: `friction-log.sh` counts one line per result, not per text line

**Files:** `plugins/guardrails-kit/hooks/friction-log.sh` (EDIT)
**Interfaces** — Consumes: none. Produces: none.

- [ ] **2.1 Write the failing fixture.** A transcript with one `denied`-class `is_error` result whose content is 3 lines:

```bash
HOOK=plugins/guardrails-kit/hooks/friction-log.sh
SB=$(mktemp -d); TR="$SB/transcript.jsonl"
cat > "$TR" <<'EOF'
{"message":{"content":[{"type":"tool_result","is_error":true,"content":"user rejected\nextra line one\nextra line two"}]}}
EOF
echo "{\"session_id\":\"ftest\",\"transcript_path\":\"$TR\"}" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; echo "exit=$?"
cat "$SB/.claude/state/_metrics.jsonl"
```

(The heredoc is quoted, so `\n` stays a literal two-char JSON escape that `jq` decodes to a real newline.)

- [ ] **2.2 Confirm RED.** Expected before the fix:

```text
exit=0
{"event":"friction","class":"denied","count":1}
{"event":"friction","class":"error","count":2}
```

(The 3-line text is counted as 3 lines: 1 denied + 2 phantom errors.)

- [ ] **2.3 Apply the fix.** Append `| gsub("[\r\n]+"; " ")` as the last step of the `jq` expression in the `TEXTS=$(...)` block (after the `if … then … else … end` line, line 43):

```bash
TEXTS=$(jq -rc '
  select((.message.content // empty) | type == "array")
  | .message.content[]
  | select((type == "object") and (.type == "tool_result") and (.is_error == true))
  | (if (.content | type) == "array" then (.content | map(.text? // "") | join(" ")) else (.content | tostring) end)
  | gsub("[\r\n]+"; " ")
' "$TRANSCRIPT" 2>/dev/null) || exit 0
```

- [ ] **2.4 Confirm GREEN.** Re-run 2.1 with a fresh `SB`. Expected:

```text
exit=0
{"event":"friction","class":"denied","count":1}
```

(No phantom `error` line.)

- [ ] **2.5 Assert fail-open (separate fixture).**

```bash
SB2=$(mktemp -d); printf 'not json' | CLAUDE_PROJECT_DIR="$SB2" bash "$HOOK"; echo "exit=$?"   # → exit=0
```

- [ ] **2.6 Syntax check + commit.** `bash -n "$HOOK"` → propose: `fix(hooks): count one friction result per tool_result, not per line (H2)`.

---

## Task 3 — M2: `log-skill-usage.sh` fails open when routing lacks a `skills` key

**Files:** `plugins/guardrails-kit/hooks/log-skill-usage.sh` (EDIT)
**Interfaces** — Consumes: none. Produces: none.

- [ ] **3.1 Write the failing fixture.** Routing JSON with NO `skills` key, a recoverable prompt, and a pre-existing turn-skills file to detect whether the line-68 reset runs:

```bash
HOOK=plugins/guardrails-kit/hooks/log-skill-usage.sh
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/mtest"
echo '{"version":2}' > "$SB/.claude/skills-routing.json"          # no "skills" key
echo 'hello world' > "$SB/.claude/state/mtest/last-prompt.txt"   # REQUIRED: non-empty prompt gets past the line-34 early-exit so the hook reaches the line-41 crash
echo '["foo"]' > "$SB/.claude/state/mtest/turn-skills-invoked.json"
echo '{"session_id":"mtest","transcript_path":""}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; echo "exit=$?"
cat "$SB/.claude/state/mtest/turn-skills-invoked.json"
```

- [ ] **3.2 Confirm RED.** Expected before the fix:

```text
exit=5
["foo"]
```

(`jq '.skills | to_entries[]'` on a null `.skills` exits 5; `pipefail` + `set -e` abort the hook, so the line-68 reset never runs.)

- [ ] **3.3 Apply the fix.** Default `.skills` to an empty object on line 41:

```bash
jq -r '.skills // {} | to_entries[] | "\(.key)\t\(.value.triggers // [] | join("|"))"' "$ROUTING" | while IFS=$'\t' read -r skill trigger_union; do
```

- [ ] **3.4 Confirm GREEN.** Re-run 3.1 with a fresh `SB`. Expected:

```text
exit=0
[]
```

(Empty skills map → zero loop rows → hook reaches line 68 and resets the file.)

- [ ] **3.5 Assert fail-open (separate fixture).**

```bash
SB2=$(mktemp -d); printf 'not json' | CLAUDE_PROJECT_DIR="$SB2" bash "$HOOK"; echo "exit=$?"   # → exit=0 (line 9 jq -e guard)
```

- [ ] **3.6 Syntax check + commit.** `bash -n "$HOOK"` → propose: `fix(hooks): fail open in log-skill-usage when routing has no skills key (M2)`.

---

## Task 4 — M1: `quality.sh` reports a real broken link even after a closed inline-code span

**Files:** `plugins/guardrails-kit/hooks/quality.sh` (EDIT)
**Interfaces** — Consumes: none. Produces: none. Note: this hook always `exit 0` (advisory); the RED/GREEN decision is the **presence/absence of the stderr warn**, not the exit code.

- [ ] **4.1 Write the failing fixture.** A `.claude/rules/` markdown file with a closed backtick span before a broken link:

```bash
HOOK=plugins/guardrails-kit/hooks/quality.sh
SB=$(mktemp -d); mkdir -p "$SB/.claude/rules"; F="$SB/.claude/rules/test.md"
printf 'See `code` and then [missing](./gone.md)\n' > "$F"
echo "{\"tool_input\":{\"file_path\":\"$F\"}}" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>err; echo "exit=$?"; cat err
```

- [ ] **4.2 Confirm RED.** Expected before the fix:

```text
exit=0
```

(No warn — the closed `` `code` `` span makes the line match the skip pattern, so the broken `./gone.md` is silently not reported.)

- [ ] **4.3 Apply the fix.** Replace the line-53–60 link loop: strip closed inline-code spans first, then detect/validate the link on the cleaned line:

```bash
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

- [ ] **4.4 Confirm GREEN.** Re-run 4.1 (fresh `SB`). Expected:

```text
exit=0
QUALITY warn: <path>/test.md references missing path './gone.md'.
```

- [ ] **4.5 Confirm the genuine-skip control still holds.** A link fully inside backticks with no real link on the line must NOT warn:

```bash
SB3=$(mktemp -d); mkdir -p "$SB3/.claude/rules"; G="$SB3/.claude/rules/c.md"
printf 'Example: `[x](./y.md)` only\n' > "$G"
echo "{\"tool_input\":{\"file_path\":\"$G\"}}" | CLAUDE_PROJECT_DIR="$SB3" bash "$HOOK" 2>err3; cat err3   # → no output
```

- [ ] **4.6 Assert fail-open (separate fixture).**

```bash
SB2=$(mktemp -d); printf 'not json' | CLAUDE_PROJECT_DIR="$SB2" bash "$HOOK"; echo "exit=$?"   # → exit=0
```

- [ ] **4.7 Syntax check + commit.** `bash -n "$HOOK"` → propose: `fix(hooks): strip closed inline-code spans before quality link check (M1)`.

---

## Task 5 — L1: `detect-bypass.sh` fails open on corrupt per-turn state

**Files:** `plugins/guardrails-kit/hooks/detect-bypass.sh` (EDIT)
**Interfaces** — Consumes: none. Produces: none.

> Fixture note (from spec review): this fixture uses a synthetic routing entry WITH a `files` field so check 1 reaches the bare `jq` read. No real `ref` entry in this repo has `files`, so check 1 is dead in-repo — the fixture exercises the fail-open **invariant**, not a path live here. Add this as a comment in the temp fixture.

- [ ] **5.1 Write the failing fixture.** Corrupt `turn-skills-invoked.json` + a Read of a skill-body path that matches a routing entry's `files`:

```bash
HOOK=plugins/guardrails-kit/hooks/detect-bypass.sh
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/btest"
cat > "$SB/.claude/skills-routing.json" <<'EOF'
{"version":2,"skills":{"demo":{"kind":"local","triggers":["x"],"files":[".claude/skills/demo/SKILL.md"]}}}
EOF
printf 'not json{{{' > "$SB/.claude/state/btest/turn-skills-invoked.json"   # corrupt (non-JSON)
echo '{"count":0}' > "$SB/.claude/state/btest/turn-tool-count.json"
echo "{\"session_id\":\"btest\",\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$SB/.claude/skills/demo/SKILL.md\"}}" \
  | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; echo "exit=$?"
```

- [ ] **5.2 Confirm RED.** Expected before the fix:

```text
exit=5
```

(Line 77 `INVOKED=$(jq -r … "$TURN_SKILLS_FILE")` on the corrupt file exits 5; `set -euo pipefail` aborts the hook.)

- [ ] **5.3 Apply the fix.** Guard both bare `jq` reads of the per-turn skills file (line 77 in check 1, line 92 in check 1b):

```bash
INVOKED=$(jq -r --arg s "$MATCHED_SKILL" 'index($s) // empty' "$TURN_SKILLS_FILE" 2>/dev/null || true)
```

```bash
INVOKED=$(jq -r 'index("writing-lessons") // empty' "$TURN_SKILLS_FILE" 2>/dev/null || true)
```

- [ ] **5.4 Confirm GREEN.** Re-run 5.1 (fresh `SB`). Expected:

```text
exit=0
```

(Corrupt state → `INVOKED` empty → treated as "not invoked" → advisory warn to stderr, hook exits 0.)

- [ ] **5.5 Confirm the line-92 read is also guarded (check 1b coverage).** The 5.1 fixture only exercises line 77 (check 1, `Read`); cover line 92 (check 1b, `Write` on `lessons-learned.md`) with corrupt state:

```bash
SBb=$(mktemp -d); mkdir -p "$SBb/.claude/state/btest"
echo '{"version":2,"skills":{}}' > "$SBb/.claude/skills-routing.json"
printf 'not json{{{' > "$SBb/.claude/state/btest/turn-skills-invoked.json"   # corrupt
echo '{"count":0}' > "$SBb/.claude/state/btest/turn-tool-count.json"
echo "{\"session_id\":\"btest\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$SBb/lessons-learned.md\"}}" \
  | CLAUDE_PROJECT_DIR="$SBb" bash "$HOOK"; echo "exit=$?"   # RED before line-92 fix: exit=5 ; GREEN: exit=0
```

- [ ] **5.6 Assert fail-open (separate fixture).**

```bash
SB2=$(mktemp -d); printf 'not json' | CLAUDE_PROJECT_DIR="$SB2" bash "$HOOK"; echo "exit=$?"   # → exit=0 (line 12 jq -e guard)
```

- [ ] **5.7 Syntax check + commit.** `bash -n "$HOOK"` → propose: `fix(hooks): guard detect-bypass jq reads of corrupt turn state (L1)`.

---

## Final verification (after all tasks)

- [ ] `bash -n` on all five edited hooks → no output.
- [ ] `jq . plugins/guardrails-kit/hooks.json` → valid (untouched, sanity check).
- [ ] Independent Layer-2 verdict: a fresh subagent re-runs all five fixtures, inverts each (confirms RED reproduces without the edit), and returns PASS with verbatim evidence.
- [ ] Spec-drift audit (chain terminal phase) against the approved spec.
