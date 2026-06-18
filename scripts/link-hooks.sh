#!/usr/bin/env bash
set -euo pipefail

# Regenerate flat discovery symlinks .claude/hooks/<name>.sh -> ../../hooks/<category>/<name>.sh
# for every hooks/**/*.sh. Idempotent. Self-symlink + clobber guards.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/hooks"
DEST="$REPO/.claude/hooks"

# Self-symlink guard: .claude/hooks must be a real dir, not a symlink into this repo.
if [ -L "$DEST" ]; then
  echo "error: $DEST is a symlink; expected a real directory. Remove it and re-run." >&2
  exit 1
fi

mkdir -p "$DEST"

find "$SRC" -name '*.sh' -print0 |
while IFS= read -r -d '' f; do
  name="$(basename "$f")"                 # <name>.sh  (file target)
  rel="../../hooks/${f#"$SRC"/}"          # ../../hooks/<category>/<name>.sh
  target="$DEST/$name"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "error: $target exists and is not a symlink; refusing to clobber." >&2
    exit 1
  fi
  ln -sfn "$rel" "$target"
  echo "linked $name -> $rel"
done
