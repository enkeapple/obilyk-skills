#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit): BARRIER, not a warning.
# Blocks an edit/write inside a skill-owned domain (a path matching a skill's editGlobs in
# skills-routing.json) until the routed Skill has been invoked this turn. This is the enforcement that the
# PostToolUse detect-bypass.sh could never be: detect-bypass fires AFTER the tool ran and
# only writes to stderr; this fires BEFORE and can deny, so rule-following no longer depends
# on how willingly a given model reads stderr warnings -- it is model-agnostic.
#
# Contract (verified against official Claude Code hook docs):
#   stdin JSON: tool_name, tool_input{file_path,...}, source fields.
#   To DENY: stdout {"hookSpecificOutput":{"hookEventName":"PreToolUse",
#       "permissionDecision":"deny","permissionDecisionReason":<shown to the model>}}.
#   $CLAUDE_PROJECT_DIR available. Matcher matches the TOOL NAME.
#
# Fail-open: any error / missing routing / unparseable input exits 0 (allow). A buggy
# guard must never block real work -- it only blocks the one specific, verified condition.
# Domains gated: only path-deterministic ones (a directory-prefix editGlob). A domain whose
# files are interleaved with others (no clean path glob) would false-positive here; it stays
# on the trigger-based detect-bypass.sh nudge instead.
#
# Two passes:
#   1. Skill-gate (original): edit in a skill-owned editGlob with the Skill not yet invoked -> deny.
#   2. Rule-gate (ruleGates in skills-routing.json): edit matches a gate by path OR the user
#      prompt matches its promptTriggers, and the gate's rule file was not Read this turn
#      (turn-reads.json) -> deny until it is. Covers rule files that carry no skill body
#      (e.g. glossary.md) and so were never enforced before an edit.
set -uo pipefail

# Fail open if prerequisites missing.
GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib → fail open (`.` is a special builtin: under set -e its open-failure exits the shell before `|| exit 0` can run, so guard readability first)
. "$GUARDRAILS_LIB"
command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat 2>/dev/null) || exit 0
SID=$(hook_sid "$INPUT")
STATE_DIR=$(hook_state_dir "$SID")
ROUTING="${CLAUDE_PROJECT_DIR:-.}/.claude/skills-routing.json"
TURN_SKILLS_FILE="$STATE_DIR/turn-skills-invoked.json"
TURN_READS_FILE="$STATE_DIR/turn-reads.json"
LAST_PROMPT_FILE="$STATE_DIR/last-prompt.txt"
mkdir -p "$STATE_DIR" 2>/dev/null || true
[[ -f "$ROUTING" ]] || exit 0
TOOL=$(hook_field "$INPUT" '.tool_name // ""')
case "$TOOL" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

FILE_PATH=$(hook_field "$INPUT" '.tool_input.file_path // ""')
[[ -n "$FILE_PATH" ]] || exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
REL_PATH="${FILE_PATH#$PROJECT_DIR/}"

# Pass 0: NO local-memory writes. The per-user memory dir (~/.claude/projects/.../memory/)
# is not in git and invisible to the rest of the team. Several people work on this repo, so
# project facts, feedback and incidents must live in git-tracked stores (.claude/lessons-learned.md,
# .claude/rules/*) -- never a local profile. Deny any write whose path
# contains a /memory/ segment under a .claude/projects tree, or ends in MEMORY.md there.
case "$FILE_PATH" in
  */.claude/projects/*/memory/*|*/.claude/projects/*/MEMORY.md)
    MREASON="Write blocked: local Claude memory is forbidden in this project. The memory dir is per-user and not in git, so several teammates never see it. Persist the fact where the team can: an incident/learned fact -> append to .claude/lessons-learned.md; a recurring rule -> .claude/rules/<area>/<topic>.md. This barrier is intentional and model-agnostic."
    jq -cn --arg r "$MREASON" \
      '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}' \
      2>/dev/null || exit 0
    exit 0
    ;;
esac

# Skills invoked so far this turn (reset each UserPromptSubmit by reset-turn-budget.sh).
[[ -f "$TURN_SKILLS_FILE" ]] || echo '[]' > "$TURN_SKILLS_FILE"

# Find a skill whose editGlobs prefix matches this path AND which was NOT invoked this turn.
MISSED_SKILL=""
MISSED_GLOB=""
while IFS=$'\t' read -r skill glob; do
  [[ -n "$skill" && -n "$glob" ]] || continue
  # Prefix match: editGlobs are directory prefixes (e.g. "src/shared/api/").
  if [[ "$REL_PATH" == "$glob"* ]]; then
    INVOKED=$(jq -r --arg s "$skill" 'index($s) // "null"' "$TURN_SKILLS_FILE" 2>/dev/null || echo "null")
    if [[ "$INVOKED" == "null" ]]; then
      MISSED_SKILL="$skill"
      MISSED_GLOB="$glob"
      break
    fi
  fi
done < <(jq -r '.skills | to_entries[] | .key as $k | (.value.editGlobs // [])[] | "\($k)\t\(.)"' "$ROUTING" 2>/dev/null)

# Skill-domain hit and skill not invoked -> deny on the skill (original behavior).
if [[ -n "$MISSED_SKILL" ]]; then
  REASON="Edit blocked by skill-gate: '${REL_PATH}' is in the '${MISSED_GLOB}' domain owned by Skill '${MISSED_SKILL}', which carries that domain's rules. Invoke Skill('${MISSED_SKILL}') first to load those rules, then retry this edit. This barrier is intentional and model-agnostic — it keeps rule-following stable across model versions."
  jq -cn --arg r "$REASON" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}' \
    2>/dev/null || exit 0
  exit 0
fi

# Second pass: ruleGates barrier. A gate fires when EITHER the edited path matches one of its
# editGlobs OR the last user prompt matches one of its promptTriggers. If it fires and the
# gate's rule file was NOT Read this turn (turn-reads.json, written by detect-bypass.sh), DENY
# until the rule is loaded into context. This closes the gap where rule files like
# glossary.md carry no skill body and so were never enforced before any edit.
[[ -f "$TURN_READS_FILE" ]] || echo '[]' > "$TURN_READS_FILE"
PROMPT=""
[[ -f "$LAST_PROMPT_FILE" ]] && PROMPT=$(cat "$LAST_PROMPT_FILE" 2>/dev/null || echo "")

GATE_RULE=""
GATE_WHY=""
while IFS=$'\t' read -r gate rule; do
  [[ -n "$gate" && -n "$rule" ]] || continue

  # Already loaded this turn -> this gate is satisfied, skip it.
  LOADED=$(jq -r --arg r "$rule" 'index($r) // "null"' "$TURN_READS_FILE" 2>/dev/null || echo "null")
  [[ "$LOADED" == "null" ]] || continue

  FIRED=""
  # Path match against this gate's editGlobs (directory prefixes).
  while IFS= read -r glob; do
    [[ -n "$glob" ]] || continue
    if [[ "$REL_PATH" == "$glob"* ]]; then FIRED="path"; break; fi
  done < <(jq -r --arg g "$gate" '.ruleGates[$g].editGlobs // [] | .[]' "$ROUTING" 2>/dev/null)

  # Prompt match against this gate's promptTriggers (case-insensitive regex union).
  if [[ -z "$FIRED" && -n "$PROMPT" ]]; then
    TRIG=$(jq -r --arg g "$gate" '.ruleGates[$g].promptTriggers // [] | join("|")' "$ROUTING" 2>/dev/null)
    if [[ -n "$TRIG" ]] && printf '%s' "$PROMPT" | grep -qiE "$TRIG"; then FIRED="prompt"; fi
  fi

  if [[ -n "$FIRED" ]]; then
    GATE_RULE="$rule"
    GATE_WHY="$FIRED"
    break
  fi
done < <(jq -r '.ruleGates // {} | to_entries[] | select(.key != "_comment") | "\(.key)\t\(.value.rule)"' "$ROUTING" 2>/dev/null)

# No gate fired, or the rule is already loaded -> allow.
[[ -n "$GATE_RULE" ]] || exit 0

if [[ "$GATE_WHY" == "path" ]]; then
  WHY="'${REL_PATH}' is in a gated domain"
else
  WHY="your task matches a gated domain by keyword"
fi
REASON="Edit blocked by rule-gate: ${WHY}, which requires '${GATE_RULE}' to be loaded into context first. Read('${GATE_RULE}') this turn, then retry this edit. This file pins which rule owns this domain — editing without it is the recurring cross-domain bug this barrier exists to prevent. Intentional and model-agnostic."
jq -cn --arg r "$REASON" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}' \
  2>/dev/null || exit 0

exit 0
