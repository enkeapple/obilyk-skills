# Mechanical Checks

Deterministic recipes for the mechanical drift classes (D1, D2, D3, D5) and the inventory that feeds every class. Reproducible: the same repo yields the same findings. Recipes are **illustrative shell** — adapt paths and the fixture convention to the repo under audit; they name no command the consumer must have beyond `jq`/`find`/`grep`.

## Inventory (feeds all classes)

Discover the real locations first — do not assume the example paths. The four inventories:

1. **Scripts on disk** — the hook script files. Glob the repo's hook dirs for `*.sh` (or the repo's hook script extension):

   ```bash
   find . -path '*/hooks/*.sh' -not -path '*/tests/*' -not -path '*/lib/*'
   ```

2. **Wiring entries** — every `command` under every event/matcher, from each `settings.json` `hooks` block AND each plugin `hooks.json`. The harness wraps events under a top-level `hooks` object in both:

   ```bash
   # one row per wired command: event<TAB>matcher<TAB>command
   for cfg in .claude/settings.json plugins/*/hooks/hooks.json; do
     [ -f "$cfg" ] || continue
     jq -r '.hooks | to_entries[] | .key as $ev | .value[]
            | (.matcher // "*") as $m | .hooks[] | [$ev,$m,.command] | @tsv' "$cfg"
   done
   ```

   The `command` carries a harness variable (`$CLAUDE_PROJECT_DIR`, `${CLAUDE_PLUGIN_ROOT}`) — resolve it to the config's base dir to get the on-disk path.

3. **Symlink indirection** — where the repo surfaces hooks through a symlink dir (e.g. a `.claude/hooks/` layer pointing back at the real script dir). List the links and their targets.

4. **Fixtures** — the test files beside the scripts (e.g. a `tests/<script>.cases` convention, or whatever the repo uses).

## D1 — orphan script (set difference)

A script on disk that no wiring `command` names. The lib/common/helper files a hook *sources* are not orphans — exclude shared libs and test dirs from the script set first.

```bash
comm -23 <(printf '%s\n' "${scripts_on_disk[@]}" | sort -u) \
         <(printf '%s\n' "${scripts_named_by_wiring[@]}" | sort -u)
# anything only on the left is an orphan (D1)
```

## D2 — dangling wiring (existence)

For each wiring `command`, resolve its path and assert the target exists. A `command` that points through a symlink also fails here if the symlink's target is missing (overlaps D3 — report the more specific D3 when the symlink itself is the break).

```bash
# resolved_path = command with its harness var expanded to the config base dir
[ -e "$resolved_path" ] || echo "D2 dangling: $resolved_path  (wired at $cfg:$line)"
```

## D3 — broken symlink indirection (resolve)

For each symlink in the indirection dir, assert its target resolves. `test -e` on a broken symlink is false; `readlink` shows the intended target.

```bash
for l in .claude/hooks/*; do            # illustrative indirection dir
  [ -L "$l" ] || continue
  [ -e "$l" ] || echo "D3 broken symlink: $l -> $(readlink "$l")"
done
```

## D5 — fixture gap (existence)

For each **wired** script (not every script on disk — an orphan's missing fixture is subsumed by D1), assert a fixture exists by the repo's convention. This checks **existence only** — never run the fixture.

```bash
# for a tests/<script>.cases convention beside the script
test -f "$(dirname "$script")/tests/$(basename "$script").cases" \
  || echo "D5 fixture gap: $script has no fixture"
```

The repo's fixture runner iterating over *existing* fixtures does NOT cover D5 — it never asserts each wired hook *has* one. That gap is exactly why D5 is a mechanical class here, not a CI concern.

## Evidence rule

Every mechanical finding cites **both sides** of the correspondence verbatim: the on-disk path and the `file:line` of the wiring entry (or the symlink and its target). A finding that names only one side is incomplete — the reader cannot confirm the drift.
