#!/usr/bin/env bash
# Stop hook: analyze last turn's tool usage vs user prompt triggers.
# Emit per-turn metrics: bypass (triggered, no skill), unused (skill invoked, body not read),
# used_correctly (triggered + skill invoked).
set -euo pipefail

GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib → fail open (`.` is a special builtin: under set -e its open-failure exits the shell before `|| exit 0` can run, so guard readability first)
. "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || exit 0
hook_require_json "$INPUT"
SID=$(hook_sid "$INPUT")
STATE_DIR=$(hook_state_dir "$SID")
ROUTING="${CLAUDE_PROJECT_DIR:-.}/.claude/skills-routing.json"
METRICS="${CLAUDE_PROJECT_DIR:-.}/.claude/state/metrics/$(date -u +%F).jsonl"
TURN_SKILLS_FILE="$STATE_DIR/turn-skills-invoked.json"
LAST_PROMPT_FILE="$STATE_DIR/last-prompt.txt"

mkdir -p "$STATE_DIR" "$(dirname "$METRICS")"
[[ -f "$ROUTING" ]] || exit 0

# Stop hook receives session info. Read transcript_path if provided.
TRANSCRIPT=$(hook_field "$INPUT" '.transcript_path // ""')

# Recover last user prompt (stored by reset-turn-budget if we extend it; otherwise best-effort from transcript)
USER_PROMPT=""
if [[ -f "$LAST_PROMPT_FILE" ]]; then
  USER_PROMPT=$(cat "$LAST_PROMPT_FILE")
elif [[ -f "$TRANSCRIPT" ]]; then
  # Extract last user message text from JSONL transcript
  USER_PROMPT=$(tail -r "$TRANSCRIPT" 2>/dev/null | grep -m1 '"role":"user"' | jq -r '.message.content // .content // ""' 2>/dev/null || echo "")
fi

[[ -n "$USER_PROMPT" ]] || exit 0

PROMPT_HASH=$(printf '%s' "$USER_PROMPT" | shasum -a 256 | cut -c1-16)

INVOKED_SKILLS=$([[ -f "$TURN_SKILLS_FILE" ]] && cat "$TURN_SKILLS_FILE" || echo '[]')

# --- Session-level skill-routing reconciliation (replaces the old per-turn bypass/used_correctly) ---
# Real skill use is CROSS-turn: a trigger fires on one turn, the Skill is invoked on a later one
# (e.g. "go"/"next"), so a per-turn matched∩invoked intersection is structurally ~0 — the old logic
# made bypass-rate a constant 100% and used_correctly never fired. Instead keep a SESSION-scoped
# ledger of triggers that matched but whose skill is not yet invoked. Invoking that skill on any
# later turn resolves the pending trigger -> used_correctly. A trigger still pending when the session
# ends is a bypass, emitted by session-telemetry-digest.sh (SessionStart) — NOT here: emitting bypass
# per-turn would double-count a trigger that is invoked a turn later. The ledger deliberately survives
# the per-turn reset in reset-turn-budget.sh (which clears turn-skills-invoked.json, not this file).
PENDING_FILE="$STATE_DIR/pending-triggers.json"
[[ -f "$PENDING_FILE" ]] || echo '[]' > "$PENDING_FILE"
PENDING=$(jq -c . "$PENDING_FILE" 2>/dev/null || echo '[]')

# Skills whose trigger union matched THIS turn's prompt (case-insensitive, same match as detect-bypass).
# if/then/fi (not `grep -q && printf`): under pipefail a non-matching grep on the LAST routing entry
# would make the loop exit 1 -> the $() exits 1 -> set -e kills the hook. `if` keeps the exit 0.
MATCHED=$(jq -r '.skills // {} | to_entries[] | "\(.key)\t\(.value.triggers // [] | join("|"))"' "$ROUTING" \
  | while IFS=$'\t' read -r skill trig; do
      [[ -n "$trig" ]] || continue
      if echo "$USER_PROMPT" | grep -qiE "$trig"; then printf '%s\n' "$skill"; fi
    done | jq -R . | jq -cs 'map(select(length>0))')

# new pending = (old pending ∪ matched-this-turn)
PENDING=$(jq -cn --argjson a "$PENDING" --argjson b "$MATCHED" '($a + $b) | unique')

# resolved = pending ∩ invoked-this-turn  -> emit used_correctly, then drop from pending
RESOLVED=$(jq -cn --argjson pend "$PENDING" --argjson inv "$INVOKED_SKILLS" \
  '$pend | map(select(. as $s | $inv | index($s)))')
printf '%s' "$RESOLVED" | jq -r '.[]' | while IFS= read -r skill; do
  [[ -n "$skill" ]] || continue
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg h "$PROMPT_HASH" --arg s "$skill" \
    '{v:1, type:"skill_event", ts:$ts, session:$sid, prompt_hash:$h, skill:$s, event:"used_correctly"}' >> "$METRICS"
done
PENDING=$(jq -cn --argjson pend "$PENDING" --argjson res "$RESOLVED" '$pend - $res')
printf '%s' "$PENDING" > "$PENDING_FILE"

# --- Prompt-corpus finalize (single writer). Only if reset-turn-budget opened a record. ---
PENDING="$STATE_DIR/pending-prompt.json"
if [[ -f "$PENDING" ]]; then
  PROMPTS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/state/prompts"
  mkdir -p "$PROMPTS_DIR"
  # skills whose trigger union matches the prompt (same match as the metric loop above)
  TRIGGERS_MATCHED=$(jq -r '.skills // {} | to_entries[] | "\(.key)\t\(.value.triggers // [] | join("|"))"' "$ROUTING" \
    | while IFS=$'\t' read -r skill trig; do
        [[ -n "$trig" ]] || continue
        # if/then/fi (not `grep -q && printf`): under `set -euo pipefail` a non-matching grep on the
        # LAST routing entry would make the loop's last command exit 1 → pipefail → the $() exits 1 →
        # set -e kills the hook before the corpus is written. `if` keeps the loop's last command exit 0.
        if echo "$USER_PROMPT" | grep -qiE "$trig"; then printf '%s\n' "$skill"; fi
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

# Clear per-turn skill tracking
echo '[]' > "$TURN_SKILLS_FILE"
exit 0
