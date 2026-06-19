# Spec: relocate domain rules to `.claude/rules/domains/`

## Goal

Restructure the foundational "domain rules": (a) move `domains-glossary.md` and `framework.md` out of `.claude/rules/common/` into a new `.claude/rules/domains/` folder, and (b) rename the glossary `domains-glossary.md` → `glossary.md`. Update every live reference (rule cross-links, both CLAUDE.md files, the domain-rules skills, the claude-md templates, plus comment/example mentions of the glossary filename) so nothing dangles and the framework's taught convention points at the new home.

> **Extension (R1–R3):** the glossary rename was folded into this same uncommitted change after the move was implemented. One commit covers relocate + rename.
>
> **Extension (S1–S3):** also rename the two skills `bootstrapping-domain-rules` → `bootstrapping-glossary` and `auditing-domain-rules` → `auditing-glossary` (they keep covering both the glossary and the framework charter; the name foregrounds the glossary). Structural rename: dir + `name:` + flat symlink + routing key/path + H1 title + every live mention of the skill name. Commit-splitting (one combined vs relocate-vs-skill-rename) decided at commit time.

## Scope

- `git mv` exactly `domains-glossary.md` and `framework.md` from `.claude/rules/common/` to `.claude/rules/domains/`.
- Rewrite the 3 forced relative links broken by the move (1 inside a moved file, 2 inside staying files).
- Update the ~8 live path references in `.claude/CLAUDE.md`, root `CLAUDE.md`, `bootstrapping-domain-rules`, `auditing-domain-rules`, and the two `bootstrapping-claude-md` templates — including the **taught convention** (`rules/common/` → `rules/domains/` as the home for domain rules).
- **(R1) `git mv` `domains-glossary.md` → `glossary.md`** within `.claude/rules/domains/`, and update all 6 live references to the glossary filename: the link in `domains/framework.md`, both CLAUDE.md pointers, the two `skill-gate.sh` comments, and the `audit-report-example.md` report title (R3).
- **(S1) Rename the two skills** `bootstrapping-domain-rules` → `bootstrapping-glossary`, `auditing-domain-rules` → `auditing-glossary`: directory, `name:` frontmatter, flat symlink, routing key + `files` path, H1 title, and every live mention of the old skill name (~14 sites).

## Out of scope

- The other six rules in `common/` (`agnostic-skill-authoring`, `scoping-skill-value`, `skill-routing-sync`, `git-conventions`, `markdown-style`, `phase-task-visualization`) — they stay; only their *links to the movers* are touched, not their location.
- `docs/specs/**` and `docs/plans/**` references (D3 — historical point-in-time records, left as-is).
- The pre-existing `framework.md` line 44 oddity `[lessons-learned.md](./lessons-learned.md)` (should be `../../`) — same-depth, the move neither fixes nor worsens it; not folded in.
- `skill-gate.sh` and `audit-report-example.md` were no-ops for the *move* (bare filename unchanged) — but the *rename* (R3) DOES touch them; see Files touched.
- **Renaming the reference template file** `bootstrapping-glossary/references/domain-glossary-template.md` → `glossary-template.md` (S2/optional). It moves with the dir and does not break; not renamed in this change. Concept-prose ("domain glossary", "foundational/domain rules" as terms) is left intact — only skill *names*, titles, and references change.
- All `rules/common/phase-task-visualization.md` references in apply-chain skills (file not moving). No-op.

## Contracts

Exact before → after for every edit. Paths verified by discovery this session.

> **Implementation status (this is a partially-applied, in-flight change):** §1 (moves), §2 (relative links), §3 (live path links), and most of §4 (taught convention) are **already applied on disk** — re-running them is a no-op; verify idempotent, do not chase a missing "before" string. The **remaining work** is §4b (the 4 missed concept references + table split), §5 (glossary rename), and §6 (skill renames).

### 1. File moves (git mv — preserves history)

```text
.claude/rules/common/domains-glossary.md  →  .claude/rules/domains/domains-glossary.md
.claude/rules/common/framework.md         →  .claude/rules/domains/framework.md
```

`domains-glossary.md` needs **no internal edit**: its only links are `../../../CLAUDE.md` (line 32) and `../../lessons-learned.md` (line 33) — both same-depth from `domains/`, unchanged.

### 2. Forced relative-link rewrites (3)

`.claude/rules/domains/framework.md` line 10 — link to a rule that stays in `common/`:

```text
- (see [skill-routing-sync.md](./skill-routing-sync.md)).
+ (see [skill-routing-sync.md](../common/skill-routing-sync.md)).
```

(Line 3 `[domains-glossary.md](./domains-glossary.md)` stays `./` — both files move together.)

`.claude/rules/common/agnostic-skill-authoring.md` line 15 — link to a now-moved file:

```text
- enforced as a check in [framework.md](./framework.md) → "Suspicion Protocol" #2
+ enforced as a check in [framework.md](../domains/framework.md) → "Suspicion Protocol" #2
```

`.claude/rules/common/scoping-skill-value.md` line 50:

```text
- inherits the vault's operating manual ([framework.md](./framework.md): the Iron Law,
+ inherits the vault's operating manual ([framework.md](../domains/framework.md): the Iron Law,
```

### 3. Live path references (`common/` → `domains/`)

`.claude/CLAUDE.md` lines 114-115:

```text
- Process basics (...): [rules/common/framework.md](./rules/common/framework.md)
- Domain glossary: [rules/common/domains-glossary.md](./rules/common/domains-glossary.md)
+ Process basics (...): [rules/domains/framework.md](./rules/domains/framework.md)
+ Domain glossary: [rules/domains/domains-glossary.md](./rules/domains/domains-glossary.md)
```

root `CLAUDE.md` line 59 — both occurrences of `.claude/rules/common/framework.md` and `.claude/rules/common/domains-glossary.md` (text + link target) → `.claude/rules/domains/...`.

### 4. Taught-convention edits (D2)

`bootstrapping-domain-rules/SKILL.md` line 24:

```text
- A new or unruled project: there is no `.claude/rules/common/` glossary or framework yet.
+ A new or unruled project: there is no `.claude/rules/domains/` glossary or framework yet.
```

`auditing-domain-rules/SKILL.md` — frontmatter `description` (line 5) `charter under .claude/rules/common/` → `.claude/rules/domains/`; and When-to-use (line 21) `` `.claude/rules/common/` (glossary, framework) `` → `` `.claude/rules/domains/` ``.

`bootstrapping-claude-md/references/operating-manual-template.md`:
- line 67: `[rules/common/framework.md](./rules/common/framework.md)` → `rules/domains/framework.md`
- line 124: `[rules/common/framework.md](./rules/common/framework.md)` → `rules/domains/framework.md`
- line 125: `[rules/common/<glossary>.md](./rules/common/)` → `rules/domains/<glossary>.md` (text + `./rules/domains/` target)

`bootstrapping-claude-md/references/root-claude-md-template.md` line 84: `[.claude/rules/common/framework.md](./.claude/rules/common/framework.md)` → `.claude/rules/domains/framework.md`.

### 4b. Concept-level references missed in the first relocate pass (CORRECTION)

The first pass scoped to path-*links* and a too-narrow audit grep, so it falsely reported "zero drift" while these **bare-directory / concept** references still pointed at `common/`. Completing the relocate (lesson `relocate-reference-undercount`):

- `skills/foundation/bootstrapping-domain-rules/SKILL.md` line 13 (taught convention): `by default under \`.claude/rules/common/\`:` → `\`.claude/rules/domains/\`:`
- root `CLAUDE.md` line 19 (prose): `…\`.claude/rules/common/\` (framework + domain glossary), \`.claude/skills-routing.json\`…` → `\`.claude/rules/domains/\` (framework + domain glossary), \`.claude/rules/common/\` (cross-cutting rules), \`.claude/skills-routing.json\`…`
- root `CLAUDE.md` line 51 ("Where rules live" table) — split the one conflated row into two:

  ```text
  | Domain rules (glossary, framework charter) | .claude/rules/domains/ |
  | Cross-cutting process & policy (framework charter excluded; code style, routing-sync, file org, …) | .claude/rules/common/ |
  ```

- `root-claude-md-template.md` line 75 (agnostic GENERATOR row — dogfood-generator-sync: instance `CLAUDE.md:51` + generator must move together) — split likewise into a `domains/` domain-rules row and a `common/` cross-cutting row, kept agnostic.

> **Table-split is a representation decision** surfaced for approval at the spec gate; alternative is a single repointed row, rejected because `common/` legitimately still holds the six cross-cutting rules.

### 5. Glossary rename (R1) + filename references (R3)

```text
.claude/rules/domains/domains-glossary.md  →  .claude/rules/domains/glossary.md   (git mv)
```

The H1 is `# Vault Glossary` — no filename self-reference, no internal edit. The agnostic `<glossary>.md` placeholder in `bootstrapping-domain-rules` / `operating-manual-template` is generic, NOT `domains-glossary` — untouched.

The 6 references (post-relocation state):
- `.claude/rules/domains/framework.md` line 3: `[domains-glossary.md](./domains-glossary.md)` → `[glossary.md](./glossary.md)`
- `.claude/CLAUDE.md` line 115: `[rules/domains/domains-glossary.md](./rules/domains/domains-glossary.md)` → `glossary.md` (label "Domain glossary:" stays)
- root `CLAUDE.md` line 59: `[.claude/rules/domains/domains-glossary.md](...)` → `glossary.md`
- `hooks/routing/skill-gate.sh` line 26 (comment): `(e.g. domains-glossary.md)` → `(e.g. glossary.md)`
- `hooks/routing/skill-gate.sh` line 99 (comment): `domains-glossary.md carry no skill body` → `glossary.md carry no skill body`
- `skills/foundation/auditing-domain-rules/references/audit-report-example.md` line 6 (title): `# Domain-Rules Audit — domains-glossary.md` → `# Domain-Rules Audit — glossary.md`

### 6. Skill renames (S1) — structural + name references

**Per skill, the structural rename (4 parts each):**

```text
git mv skills/foundation/bootstrapping-domain-rules  skills/foundation/bootstrapping-glossary
git mv skills/foundation/auditing-domain-rules       skills/foundation/auditing-glossary
# flat symlinks (remove old, create new):
rm .claude/skills/bootstrapping-domain-rules .claude/skills/auditing-domain-rules
ln -s ../../skills/foundation/bootstrapping-glossary .claude/skills/bootstrapping-glossary
ln -s ../../skills/foundation/auditing-glossary      .claude/skills/auditing-glossary
```

- `name:` frontmatter: `bootstrapping-domain-rules` → `bootstrapping-glossary`; `auditing-domain-rules` → `auditing-glossary`.
- H1 title: `# Bootstrapping Domain Rules` → `# Bootstrapping Glossary`; `# Auditing Domain Rules` → `# Auditing Glossary`.
- `skills-routing.json`: rename keys (line 232, 246) and fix `files` paths (line 244, 259) → `.claude/skills/bootstrapping-glossary/SKILL.md` / `.claude/skills/auditing-glossary/SKILL.md`. Invariant: key === dir === `name:`.

**Name-reference edits (`bootstrapping-domain-rules`→`bootstrapping-glossary`, `auditing-domain-rules`→`auditing-glossary`):**

| File | Line(s) |
| --- | --- |
| `CLAUDE.md` (root) | 40, 53 |
| `.claude/rules/domains/glossary.md` (post-R1 path) | 19 (`auditing-domain-rules`) |
| `skills/design/improve-codebase-architecture/SKILL.md` | 63, 64 |
| `bootstrapping-glossary/SKILL.md` (post-rename path) | 30 (`auditing-domain-rules`) |
| `bootstrapping-glossary/references/domain-glossary-template.md` | 57 (`auditing-domain-rules`) |
| `auditing-glossary/SKILL.md` (post-rename path) | 17, 27 (`bootstrapping-domain-rules`) |
| `skills/foundation/bootstrapping-claude-md/SKILL.md` | 20, 30 |
| `skills/foundation/bootstrapping-claude-md/references/intake-questions.md` | 19 |
| `skills/foundation/auditing-claude-md/SKILL.md` | 17, 27 |
| `skills/authoring/writing-rules/SKILL.md` | 28 |

**Sequencing:** do the skill-dir `git mv` FIRST; the reference files inside (`domain-glossary-template.md`, `audit-report-example.md`) move with it, so their content edits (R3 title, S1 mention) apply at the NEW path. The `audit-report-example.md` R3 edit and its S1 (none) land at `skills/foundation/auditing-glossary/references/`.

## Files touched

| File | Change | Why |
| --- | --- | --- |
| `.claude/rules/domains/glossary.md` | MOVE + RENAME (from `common/domains-glossary.md`) | relocate then rename (R1); no internal edit |
| `hooks/routing/skill-gate.sh` | EDIT ×2 (comments) | glossary filename mention → `glossary.md` (R3) |
| `skills/foundation/{bootstrapping,auditing}-domain-rules/` | RENAME dir → `…/{bootstrapping,auditing}-glossary/` | S1 skill rename (carries `references/`) |
| `.claude/skills/{bootstrapping,auditing}-domain-rules` | RE-SYMLINK → `…-glossary` | flat symlink retarget |
| `.claude/skills-routing.json` | EDIT (keys + files ×2) | S1 routing sync |
| `…-glossary/SKILL.md` ×2 | EDIT (`name:`, H1, cross-mention) | S1 name + title + sibling ref |
| `…-glossary/references/audit-report-example.md` | EDIT (title) | report title → `glossary.md` (R3), at post-rename path |
| `bootstrapping-glossary/references/domain-glossary-template.md` | EDIT (line 57) | `auditing-domain-rules` → `auditing-glossary` |
| root `CLAUDE.md`, `improve-codebase-architecture`, `bootstrapping-claude-md` (SKILL + `intake-questions.md`), `auditing-claude-md`, `writing-rules` | EDIT (name mentions) | S1 reference updates |
| `.claude/rules/domains/framework.md` | MOVE (from `common/`) | relocate; edit line-10 cross-link |
| `.claude/rules/common/agnostic-skill-authoring.md` | EDIT | link to `framework.md` → `../domains/` |
| `.claude/rules/common/scoping-skill-value.md` | EDIT | link to `framework.md` → `../domains/` |
| `.claude/CLAUDE.md` | EDIT | Pointers ×2 |
| `CLAUDE.md` | EDIT | Pointers line, ×2 refs |
| `skills/foundation/bootstrapping-domain-rules/SKILL.md` | EDIT | taught path → `domains/` |
| `skills/foundation/auditing-domain-rules/SKILL.md` | EDIT | description + when-to-use ×2 → `domains/` |
| `skills/foundation/bootstrapping-claude-md/references/operating-manual-template.md` | EDIT | ×3 (lines 67, 124, 125) |
| `skills/foundation/bootstrapping-claude-md/references/root-claude-md-template.md` | EDIT | line 84 |

## Edge cases

- **New folder creation:** `git mv` to a non-existent `domains/` creates the path; no manual `mkdir` needed (git mv handles it). Confirm `.claude/rules/domains/` holds exactly 2 files after.
- **Empty result of the dangling-ref grep:** the verification grep must return zero lines over live files — a non-empty result means a reference was missed.
- **Frontmatter edit (`auditing-domain-rules` description):** must stay valid YAML and ≤1024 chars after the path swap (it is — swapping `common`→`domains` is length-neutral).
- **Same-depth links untouched:** any `../../` / `../../../` link in the moved files is depth-invariant; editing them would *introduce* breakage. Leave them.
- **No symlink involved:** `.claude/rules/` is a real directory (not a flat symlink like `.claude/skills/`), so no symlink retargeting.

## Verification

This vault has no build/test pipeline; verification = validators + grep, run and pasted.

```bash
# 1. Move done, folder holds exactly the two files
ls -1 .claude/rules/domains/        # expect: domains-glossary.md, framework.md
ls .claude/rules/common/framework.md 2>&1   # expect: No such file

# 2. BROAD gate (lesson relocate-reference-undercount): every bare `rules/common/` mention,
#    minus the six rules that legitimately stay. Catches prose/tables, not just dir/file links.
grep -rn "rules/common/" --include="*.md" --include="*.sh" \
  skills/ CLAUDE.md .claude/CLAUDE.md hooks/ .claude/rules/ \
  | grep -vE "phase-task-visualization|skill-routing-sync|git-conventions|markdown-style|agnostic-skill-authoring|scoping-skill-value|dogfood-generator-sync" \
  | grep -vE "audit-report-example\.md.*\| path"   # the illustrative example row (out of scope)
# expect: no output — any hit is a framework/glossary home still pointing at common/

# 2b. Zero references to the OLD glossary filename in LIVE files (R1 rename)
grep -rn "domains-glossary" --include="*.md" --include="*.sh" \
  skills/ CLAUDE.md .claude/CLAUDE.md hooks/ .claude/rules/   # expect: no output
ls .claude/rules/domains/glossary.md   # expect: exists; domains-glossary.md gone

# 2c. Skill rename (S1): no old skill name anywhere live; new dirs/symlinks/keys exist
grep -rn "domain-rules" --include="*.md" --include="*.json" --include="*.sh" \
  skills/ CLAUDE.md .claude/CLAUDE.md hooks/ .claude/skills-routing.json   # expect: no output
find skills/foundation -maxdepth 1 -name "*-glossary" -type d   # expect: bootstrapping-glossary, auditing-glossary
test -L .claude/skills/bootstrapping-glossary && readlink .claude/skills/bootstrapping-glossary  # resolves
test -L .claude/skills/auditing-glossary && readlink .claude/skills/auditing-glossary            # resolves
jq -e '.skills["bootstrapping-glossary"] and .skills["auditing-glossary"]' .claude/skills-routing.json
jq . .claude/skills-routing.json > /dev/null && echo "valid JSON"
# invariant key === dir === name:
for s in bootstrapping-glossary auditing-glossary; do grep -q "^name: $s$" skills/foundation/$s/SKILL.md && echo "OK name $s"; done

# 3. Every relative link in the moved + edited rule files resolves
#    (manual: for each ](path) in domains/*.md, agnostic-skill-authoring.md,
#     scoping-skill-value.md — test -f the resolved target)

# 4. Fence balance / frontmatter unchanged on edited files (length-neutral swaps)
```

GREEN subagent check: a fresh agent told "read the framework charter / domain glossary for this repo" lands on `.claude/rules/domains/` via the updated CLAUDE.md Pointers, with no broken-link detour.

## Risks

- **Missed live reference** → dangling link. Mitigation: verification grep #2 over the full live tree is the gate; it must be empty.
- **D2 over-reach** — changing the agnostic templates/skills alters what every future consumer repo is taught. Accepted: D2 was chosen explicitly with that framing; `domains/` is now the promoted canonical pattern.
- **git mv vs Edit ordering** — the line-10 edit to `framework.md` must happen *after* the move (edit the file at its new path), or the working-tree edit races the move. Plan sequences move-then-edit. Same for the skill-dir rename: `git mv` the dir first, then edit `SKILL.md` / `references/*` at the new path.
- **Routing/symlink desync (S1)** — if the routing key, dir name, `name:`, and symlink target diverge, the skill becomes unroutable/bypass-undetectable (`skill-routing-sync` rule). Mitigation: verification 2c asserts key === dir === `name:` and that both symlinks resolve, plus `jq` validity.
- **Self-reference in this spec/plan** — `docs/specs|plans/relocate-domain-rules.md` mention the old skill names in prose; per D3 they are this change's own artifacts and may keep historical names, but the live-tree grep (2c) excludes `docs/` so it stays green regardless.
