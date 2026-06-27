#!/usr/bin/env bash
# HARD: frontmatter <=1024 bytes, balanced fences, references/*+assets/* links resolve.
# WARN: body word-count > 1500 (flat ceiling; per-tier gating deferred). WARN never affects exit.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hard=0
while IFS= read -r f; do
  dir="$(dirname "$f")"; name="$(basename "$dir")"
  fm=$(awk 'NR==1&&/^---$/{a=1;next} a&&/^---$/{exit} a{print}' "$f")
  fb=$(printf '%s' "$fm" | wc -c | tr -d ' ')
  [ "$fb" -le 1024 ] || { echo "HARD frontmatter>$fb: $name"; hard=1; }
  fences=$(grep -cE '^```' "$f"); [ $((fences % 2)) -eq 0 ] || { echo "HARD odd-fences: $name"; hard=1; }
  for t in $(grep -oE '\((\./)?(references|assets)/[A-Za-z0-9._-]+\.md\)' "$f" | tr -d '()'); do
    [ -f "$dir/$t" ] || { echo "HARD broken-link $t: $name"; hard=1; }
  done
  wc_words=$(awk 'NR==1&&/^---$/{a=1;next} a&&/^---$/{a=0;next} !a{print}' "$f" | wc -w | tr -d ' ')
  [ "$wc_words" -le 1500 ] || echo "WARN word-count: $name = ${wc_words}w"
done < <(find "$ROOT"/plugins -path '*/skills/*' -name SKILL.md)
exit $hard
