#!/usr/bin/env bash
set -euo pipefail

# Regenerate flat discovery symlinks .claude/skills/<name> -> ../../plugins/<plugin>/skills/<category>/<name>
# for every plugins/*/skills/**/SKILL.md. Idempotent. Leaves _metrics.jsonl and non-skill entries alone.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/plugins"
DEST="$REPO/.claude/skills"

# Self-symlink guard: .claude/skills must be a real dir, not a symlink into this repo.
if [ -L "$DEST" ]; then
  echo "error: $DEST is a symlink; expected a real directory. Remove it and re-run." >&2
  exit 1
fi

mkdir -p "$DEST"

find "$SRC" -path '*/skills/*' -name SKILL.md -print0 |
while IFS= read -r -d '' skill_md; do
  src_dir="$(dirname "$skill_md")"          # $SRC/<plugin>/skills/<category>/<name>
  name="$(basename "$src_dir")"
  rel="../../plugins/${src_dir#"$SRC"/}"     # ../../plugins/<plugin>/skills/<category>/<name>
  target="$DEST/$name"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "error: $target exists and is not a symlink; refusing to clobber." >&2
    exit 1
  fi
  ln -sfn "$rel" "$target"
  echo "linked $name -> $rel"
done
