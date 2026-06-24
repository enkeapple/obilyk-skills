#!/usr/bin/env bash
# Metrics report — skill-routing health + token spend by model, from the hook-emitted state.
# Read-only and side-effect-free; safe to run anytime.
#
# Sources (all produced by the vault's hooks; absent → that section says "no data yet"):
#   - .claude/state/_metrics.jsonl   v1 records {v,type,ts,session,…}: type=="skill_event"
#                                    (event: bypass / used_correctly / read_instead_of_skill /
#                                     trigger_bypass_warn / direct_edit_lessons_log) and type=="friction"
#   - .claude/state/<session_id>/by-model-budget.json   per-session token accounting (token-guard.sh)
#
# Usage: bash scripts/metrics-report.sh [PROJECT_DIR]   (defaults to $CLAUDE_PROJECT_DIR or .)
set -uo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-.}}"
METRICS="$PROJECT_DIR/.claude/state/_metrics.jsonl"
STATE_DIR="$PROJECT_DIR/.claude/state"

command -v jq >/dev/null 2>&1 || { echo "metrics-report: jq is required" >&2; exit 1; }

echo "# Metrics report"
echo

echo "## Skill routing"
if [[ -s "$METRICS" ]]; then
  jq -rs '
    map(select(.type == "skill_event"))
    | group_by(.event)
    | map({event: (.[0].event // "unknown"), count: length})
    | sort_by(-.count)[]
    | "- \(.event): \(.count)"
  ' "$METRICS" 2>/dev/null || echo "- (could not parse $METRICS)"
  jq -rs '
    (map(select(.event=="bypass")) | length) as $b
    | (map(select(.event=="used_correctly")) | length) as $u
    | if ($b + $u) > 0
      then "\nBypass rate: \($b)/\($b + $u) = \((100 * $b / ($b + $u)) | floor)%"
      else "\nBypass rate: n/a (no triggered events yet)" end
  ' "$METRICS" 2>/dev/null
else
  echo "- no _metrics.jsonl data yet"
fi
echo

echo "## Friction (deterministic is_error, by class)"
if [[ -s "$METRICS" ]]; then
  jq -rs '
    (map(select(.type == "friction"))) as $f
    | if ($f | length) == 0 then "- none logged yet"
      else ($f | group_by(.class) | map("- \(.[0].class // "?"): \(map(.count // 0) | add)") | .[]) end
  ' "$METRICS" 2>/dev/null || echo "- (could not parse friction events)"
else
  echo "- no _metrics.jsonl data yet"
fi
echo

echo "## Token spend by model (≈ bytes / 4)"
shopt -s nullglob
files=("$STATE_DIR"/*/by-model-budget.json)
if (( ${#files[@]} > 0 )); then
  jq -rs '
    reduce .[] as $f ({};
      reduce ($f | to_entries[]) as $kv (.; .[$kv.key] = ((.[$kv.key] // 0) + $kv.value)))
    | to_entries | sort_by(-.value)[]
    | "- \(.key): \((.value / 4) | floor) tokens"
  ' "${files[@]}" 2>/dev/null || echo "- (could not parse by-model files)"
  echo
  echo "Sessions tracked: ${#files[@]}"
else
  echo "- no by-model-budget data yet (run some tool calls first)"
fi
