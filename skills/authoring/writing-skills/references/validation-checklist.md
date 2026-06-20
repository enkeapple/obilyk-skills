# Validation Checklist — Layer 1 (static pre-flight)

The cheap, fast checks the `validate` gate runs FIRST, before dispatching the validation subagent.
All of it is defined here, inside the skill — the gate depends on no external hook. The validation
subagent (Layer 2) also applies this list as its structural pass. Fail fast: a Layer-1 failure
stops the gate before the expensive subagent run.

This list is self-contained and agnostic — it names no repo-specific path or command. Run the checks
with whatever the host environment provides (illustrative shell shown; adapt to the runtime).

## Checks

1. **Frontmatter size** — the `---`…`---` block is ≤ 1024 bytes.
2. **`name` regex** — matches `^[a-z0-9-]+$` (lowercase, digits, hyphens only).
3. **`name === dir === symlink`** — `name:` equals the skill's directory name AND the flat-symlink name that surfaces it. A mismatch is a hard fail (invocation breaks).
4. **Code fences balanced** — an even count of ` ``` ` fence lines.
5. **Reference links resolve** — every `references/*.md` and `assets/*.md` (and other relative `.md`) link in `SKILL.md` and in each reference file points at a file that exists.
6. **Frontmatter keys legal** — every key is in the authoritative set (`frontmatter-reference.md`); an unknown key is a likely typo. When present, `allowed-tools`/`disallowed-tools` is a space/comma string or YAML list; `model` is `inherit`, a known alias, or a `claude-*` id.
7. **Routing invariant** — if `disable-model-invocation: true`, the skill has NO entry in the routing registry (`skills-routing.json`) and declares no triggers; otherwise it MUST have a routing entry whose key equals `name`.
8. **Word count** — measured on the `SKILL.md` body (excluding frontmatter and fenced code blocks). Key the bound off the (mechanically decidable) `disable-model-invocation` signal from check #7:
   - a **model-invoked** skill (no `disable-model-invocation`): target ≤ **500 words** — its description loads every turn, so keep the whole skill lean;
   - a **user-invoked** skill (`disable-model-invocation: true`): ≤ **~1500 words**.
   Past the bound, **warn** (a sprawl smell, see `vocabulary.md`) — not a hard fail. Under the bound is always fine.

## Illustrative runner

```bash
# Adapt paths to the runtime; this is illustrative, not a repo-pinned command.
SKILL="$1/SKILL.md"
# 1. frontmatter bytes
awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f{print}' "$SKILL" | wc -c
# 2/3. name regex + name==dir
nm=$(grep -m1 '^name:' "$SKILL" | sed 's/name:[[:space:]]*//' | tr -d "\"'")
printf '%s' "$nm" | grep -qE '^[a-z0-9-]+$' && [ "$nm" = "$(basename "$1")" ] && echo "name ok"
# 4. fences balanced
n=$(grep -c '^```' "$SKILL"); [ $((n%2)) -eq 0 ] && echo "fences ok"
# 8. body word count (strip frontmatter + fenced blocks)
awk 'NR==1&&/^---/{f=1;next} f&&/^---/{f=0;next} /^```/{c=!c;next} !c&&!f' "$SKILL" | wc -w
```

A green Layer 1 means the skill is structurally sound; it does NOT mean the skill *works* — that is
Layer 2 (`validation-subagent-prompt.md`).
