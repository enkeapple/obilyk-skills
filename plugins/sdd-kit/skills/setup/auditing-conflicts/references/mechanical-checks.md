# Mechanical Checks — deterministic recipes & reproducible shortlist

The grep/jq recipes for the mechanical classes (1, 6, 8, 9) and the **reproducible** shortlist that narrows candidate pairs for the judgment layer. Two runs over the same working tree must produce the same findings and the same shortlist — that is what "mechanical" buys.

All searches obey `search-scope-verification.md`: use `grep -rE` (never BRE `\|`), **no** `-maxdepth`, **no** `--include` allowlist for a reference sweep. Run against the **working tree**.

## Class 1 — trigger collision

List every entry's triggers, then test each pair against the fixed sample-prompt set; a collision = both entries match ≥1 sample prompt (or share a literal trigger token).

```bash
jq -r '.skills | to_entries[] | "\(.key)\t\(.value.triggers | join("|"))"' .claude/skills-routing.json
```

(For each pair, compile each side's `triggers` as an alternation and test against the sample set below.)

## Class 8 — routing/invocation invariant

```bash
# (a) every routed ref key must equal a real skill directory name:
comm -23 <(jq -r '.skills|keys[]' .claude/skills-routing.json | sort) \
         <(find plugins -name SKILL.md | sed -E 's#.*/([^/]+)/SKILL.md#\1#' | sort)
# any key printed = a routing entry with no matching skill dir (invariant break)

# (b) name === dir === SKILL.md `name:` for every skill:
for f in $(find plugins -name SKILL.md); do
  dir=$(basename "$(dirname "$f")")
  nm=$(grep -m1 -E '^name:' "$f" | sed -E 's/^name:[[:space:]]*//')
  [ "$dir" = "$nm" ] || echo "MISMATCH: dir=$dir name=$nm ($f)"
done
```

- A **model-invocable** skill (no `disable-model-invocation: true`) with **no** routing entry → invariant break.
- A `disable-model-invocation: true` skill **with** a routing entry → invariant break (reference/alias skills must be absent from routing, per the glossary).
- An **alias** body delegating to a canonical name not in the dictionary → broken alias.

## Class 9 — orphan reference

Build the **dictionary of real names** = skill dir names ∪ routing keys. Then sweep every doc — all `SKILL.md` + `references/*.md` + `assets/*.md`, `.claude/rules/**/*.md`, both `CLAUDE.md`, `.claude/skills-routing.json`, hooks config / `*.yml` / `.github/` — whole repo:

```bash
grep -rEno '\[[^]]+\]\([^)]+\.md\)' . | sed -E 's/.*\(([^)]+)\)/\1/'   # link targets to existence-check
```

A **citation** (flag if its target is absent) is a *structural claim*, not prose:
- a markdown link to a path → the target file must exist;
- a backticked skill-name in a hand-off / `REQUIRED SUB-SKILL` / routing context → must be in the dictionary;
- a rule-file path → must exist.

A prose mention ("skills like `grilling`") is **not** a citation. The mechanical layer flags candidates; the judgment layer may downgrade an intentional one.

## Class 6 — duplicate canonical-source (detection)

Flag two artifacts that both assert ownership of one concern when **neither** carries a `canonical source is X` / `do not duplicate` cross-reference. Search for the cross-reference phrase to clear a candidate:

```bash
grep -rinE 'canonical source|do not duplicate|single source of truth' .claude/rules CLAUDE.md .claude/CLAUDE.md
```

Presence of such a deferral between the pair → **not** a class-6 conflict (this is the false-conflict guard).

## Shortlist signal computations (reproducible)

A skill/rule pair is shortlisted for the judgment layer iff **any** signal fires. Each is pinned so two runs agree:

| Signal | Concrete computation |
| --- | --- |
| Overlapping triggers | Both entries' `triggers` match ≥1 prompt in the **sample-prompt set** below, or share a literal trigger token |
| Shared description keyword | Lowercase both `description`s, strip the **stop-word list** below, then ≥2 shared remaining tokens |
| Same category | Same `skills/<category>/` path segment |
| Mutual hand-off ref | One body backtick-names the other in a `REQUIRED SUB-SKILL`/Upstream/Downstream/hand-off context |

**Stop-word list** (exact): `the a an to of and or use when this that is be it in on for with your you i as by from skill rule skills rules`

**Sample-prompt set** (exact, extend only by an explicit edit to this file): `audit the spec`, `write a skill`, `grill me`, `help me think this through`, `start coding`, `find conflicts`, `check the rules`, `hand off`, `write a plan`, `fix this bug`.

### Known bound (no silent caps)

The shortlist can **miss** a real conflict whose pair shares none of the four signals. The skill therefore `log`s the shortlist size and the dropped-pair count every run, so silent under-coverage is visible rather than read as "all pairs covered". Widening the signals or the sample set is an explicit edit here.
