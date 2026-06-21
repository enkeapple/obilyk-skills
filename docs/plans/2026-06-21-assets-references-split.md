# Split instantiated artifacts into per-skill `assets/` — Implementation Plan

**Goal:** Relocate the 22 instantiated-artifact files (templates, examples, reviewer/subagent prompts) from each skill's `references/` (or root) into a sibling `assets/`, repoint every inbound reference, and teach `writing-skills` the role criterion.
**Architecture:** Pure docs/structure refactor in a skills vault — no app code. "Test-first" maps to the vault's real checks: `git`/`find`/`grep` assertions and the skill link-validators for mechanical tasks, and a RED→GREEN subagent pressure run for the one methodology edit (Iron Law).
**Tech stack:** Markdown skills, `git mv`, shell (`find`/`grep`/`rmdir`), the vault validators (frontmatter ≤1024, name regex, link resolution, fence balance, word count).

## Global constraints

- **Source of truth:** `specs/2026-06-21-assets-references-split.md` — its Contracts (22-file table, pointer line list, 7 structural docs, criterion block) are copied verbatim here; do not re-derive.
- **Git boundary:** the human owns commits. Commit steps below show the exact command; in this vault they are *proposed* — the executor runs them only on explicit instruction.
- **No content edits** to any moved file — only its location and inbound pointers change.
- **Markdown-style rule** applies to every edited `.md` (spaced table delimiters, fenced langs, standard links) — see `.claude/rules/common/markdown-style.md`.
- **`git mv`** for all moves (preserve history); never copy+delete.
- Out of scope (do not touch): `.claude/skills/` symlinks, `skills-routing.json`, `.claude/settings.local.json`, the `codebase-design`/`improve-codebase-architecture` root docs.

---

## Task 1 — Relocate 22 files and repoint every pointer to a moved file

Atomic "move + repoint" so the tree never holds a broken-link commit. The deliverable is a consistent tree: every artifact under `assets/`, no inbound pointer still saying `references/<f>` or `./<f>`.

**Files**

- MOVE (22): exactly the source→dest table in the spec (Contracts → "The 22 moved files"). `git mv <src> <skill>/assets/<file>`.
- DELETE (5 empty dirs): `spec-drift-audit/references/`, `writing-plans/references/`, `writing-specs/references/`, `writing-lessons/references/`, `writing-rules/references/`.
- EDIT pointers (12 SKILL.md + 1 rule):
  - `grilling/SKILL.md`, `writing-plans/SKILL.md`, `writing-specs/SKILL.md`, `spec-drift-audit/SKILL.md`, `writing-lessons/SKILL.md`, `writing-rules/SKILL.md`, `writing-skills/SKILL.md`, `auditing-claude-md/SKILL.md`, `auditing-glossary/SKILL.md`, `bootstrapping-claude-md/SKILL.md`, `bootstrapping-glossary/SKILL.md`, `subagent-driven-development/SKILL.md` (DOT labels + links).
  - `.claude/rules/common/dogfood-generator-sync.md:48` — the `references/operating-manual-template.md` path (a pointer to a moved file; the `:14` glob is Task 2).

**Interfaces**

- Produces: a `<skill>/assets/` dir for each of the 12 skills with ≥1 artifact; the canonical pointer form `assets/<file>.md`.
- Consumes: nothing (first task).

**Pointer transformation rule** (uniform string substitution; apply to each occurrence):

```text
[text](references/<file>.md)  -> [text](assets/<file>.md)
[text](./references/<file>.md)-> [text](assets/<file>.md)
[`<file>.md`](./references/<file>.md) -> [`<file>.md`](assets/<file>.md)
./<file>.md  (subagent-dd links & DOT labels) -> assets/<file>.md
```

Exact targets to apply it to (from the spec's pointer list):

```text
grilling/SKILL.md            :35 :48
writing-plans/SKILL.md       :59 :97
writing-specs/SKILL.md       :52 :90
spec-drift-audit/SKILL.md    :56
writing-lessons/SKILL.md     :17 :63 :80 :97
writing-rules/SKILL.md       :16 :83 :97
writing-skills/SKILL.md      :59 :102
auditing-claude-md/SKILL.md  :39
auditing-glossary/SKILL.md   :43
bootstrapping-claude-md/SKILL.md :49 :50
bootstrapping-glossary/SKILL.md  :46 :54
subagent-driven-development/SKILL.md :56 :60 :63 :71 :72 :74 :76 :77 :79 :80 :81 :83 (DOT labels) :118 :119 :120 (links)
dogfood-generator-sync.md    :48
```

**Steps**

- [ ] **RED — write the assertions and watch them fail.** Run, capture the failing baseline:

```bash
find skills -path '*/assets/*.md' | wc -l        # expect 0 now (target: 22)
grep -rnE '(references/|\./)(decisions-template|plan-template|spec-template|lessons-template|rule-template|operating-manual-template|root-claude-md-template|domain-glossary-template|framework-charter-template|report-example|audit-report-example|readiness-reviewer-prompt|plan-reviewer-prompt|spec-reviewer-prompt|promotion-reviewer-prompt|rule-reviewer-prompt|rule-efficacy-test-prompt|validation-subagent-prompt|implementer-prompt|code-quality-reviewer-prompt)\.md' skills .claude/rules .claude/CLAUDE.md | wc -l   # expect >0 now (target: 0)
```

Expected failure: `assets` count `0`, stale-pointer count non-zero (≈30+).

- [ ] **Move the 22 files** with `git mv`, one per source→dest row, e.g.:

```bash
git mv skills/apply-chain/grilling/references/decisions-template.md skills/apply-chain/grilling/assets/decisions-template.md
git mv skills/apply-chain/subagent-driven-development/implementer-prompt.md skills/apply-chain/subagent-driven-development/assets/implementer-prompt.md
# ... all 22 rows from the spec table (git mv auto-creates the assets/ dir)
```

- [ ] **Remove the 5 emptied `references/` dirs:**

```bash
rmdir skills/apply-chain/spec-drift-audit/references skills/apply-chain/writing-plans/references skills/apply-chain/writing-specs/references skills/authoring/writing-lessons/references skills/authoring/writing-rules/references
```

(`rmdir` fails loudly if a dir is unexpectedly non-empty — that is the safety check.)

- [ ] **Repoint every pointer** per the transformation rule on each enumerated target. Example concrete edits:

```text
# grilling/SKILL.md:35
- ... Format: [references/decisions-template.md](references/decisions-template.md).
+ ... Format: [assets/decisions-template.md](assets/decisions-template.md).

# subagent-driven-development/SKILL.md:118 (link) and :56 (DOT label)
- - [./implementer-prompt.md](./implementer-prompt.md) — dispatch the implementer subagent.
+ - [assets/implementer-prompt.md](assets/implementer-prompt.md) — dispatch the implementer subagent.
- "Dispatch implementer subagent (./implementer-prompt.md)" [shape=box];
+ "Dispatch implementer subagent (assets/implementer-prompt.md)" [shape=box];

# dogfood-generator-sync.md:48
- fix to references/operating-manual-template.md, kept agnostic.
+ fix to assets/operating-manual-template.md, kept agnostic.
```

- [ ] **GREEN — re-run the assertions, confirm they pass:**

```bash
find skills -path '*/assets/*.md' | wc -l        # 22
# stale-pointer grep (command above)                # 0
git status --porcelain | grep -c '^R'              # 22 renames
for d in spec-drift-audit writing-plans writing-specs writing-lessons writing-rules; do test ! -e "$(echo skills/*/$d/references)" && echo "$d ok"; done   # 5 ok lines
```

- [ ] **Link-validator pass** — measured as a **delta against the recorded baseline**, not against zero. The repo has 12 pre-existing intentional "broken" links (template *content* links describing a consumer repo's paths — `operating-manual-template.md`/`root-claude-md-template.md` → `../CLAUDE.md`, `./lessons-learned.md`, `./rules/domains/framework.md`, `./.claude/...`; plus `writing-rules/SKILL.md → ./error-handling.md`, an illustrative example name). The two moved templates stay at the same directory depth (`references/` → sibling `assets/`), so these relative links resolve identically after the move — the move must add **0 new** broken links. Mechanism: (a) editing a `SKILL.md` fires the `quality.sh` PostToolUse hook (read its stderr); (b) run the whole-tree scan below before and after, and diff — the after-set must equal the before-set:

```bash
scan() { find skills -name '*.md' | while read -r f; do
  grep -oE '\]\(([^)]+\.md)\)' "$f" | sed -E 's/^\]\((.*)\)$/\1/' | while read -r l; do
    case "$l" in /*|http*) continue;; esac
    [ -e "$(dirname "$f")/$l" ] || echo "BROKEN: $f -> $l"
  done; done | sed 's#references/#<DIR>/#; s#assets/#<DIR>/#' | sort -u; }
# baseline captured at readiness: 12 lines (paths normalized so a references/→assets/ move is a no-op in the diff)
scan   # compare to the readiness baseline; expect identical count/set
```
- [ ] **Commit (proposed):**

```bash
git commit -am "refactor(skills): move instantiated artifacts to per-skill assets/"
```

---

## Task 2 — Update structural-layout docs and the dogfood glob

Independent reviewer gate: the layout *descriptions* and the operational glob, distinct from Task 1's pointers. A reviewer could accept the moves but reject wording here.

**Files** (EDIT)

- `.claude/rules/domains/glossary.md:27`, `.claude/rules/domains/framework.md:10 :23 :38`, `.claude/CLAUDE.md:56`, `skills/authoring/writing-skills/references/validation-checklist.md:17`, `.claude/rules/common/agnostic-skill-authoring.md:11`, `.claude/rules/common/skill-routing-sync.md:18 :55`, `.claude/rules/common/dogfood-generator-sync.md:14` (glob) + surrounding prose.

**Interfaces**

- Consumes: the `assets/` layout established in Task 1.
- Produces: one canonical phrase reused everywhere — `references/*.md` and `assets/*.md`.

**Steps**

- [ ] **RED — assert no structural doc yet mentions `assets/`:**

```bash
grep -rln 'assets/\*\.md\|assets/\*\*' .claude/rules .claude/CLAUDE.md skills/authoring/writing-skills/references/validation-checklist.md | wc -l   # expect 0
```

- [ ] **Edit each doc** to add `assets/*.md` beside `references/*.md`, using the one canonical phrase. Concrete edits:

```text
# glossary.md:27
- source `skills/*/<name>/SKILL.md` (+ `references/*.md`); discovered via flat symlink ...
+ source `skills/*/<name>/SKILL.md` (+ `references/*.md`, `assets/*.md`); discovered via flat symlink ...

# framework.md:10
- ... `SKILL.md` body → `references/*.md` → `skills-routing.json` (triggers) ...
+ ... `SKILL.md` body → `references/*.md` / `assets/*.md` → `skills-routing.json` (triggers) ...

# framework.md:23
- ... or `references/*.md` link is verified by a `Read`/`Grep`/`Glob` ...
+ ... or `references/*.md` / `assets/*.md` link is verified by a `Read`/`Grep`/`Glob` ...

# framework.md:38  and  .claude/CLAUDE.md:56  and  validation-checklist.md:17
- ... every `references/*.md` link resolves ...
+ ... every `references/*.md` and `assets/*.md` link resolves ...

# agnostic-skill-authoring.md:11
- ... `.claude/skills/<name>/SKILL.md` or its `references/*.md` ...
+ ... `.claude/skills/<name>/SKILL.md` or its `references/*.md` / `assets/*.md` ...

# skill-routing-sync.md:18 and :55
- ... only a skill's *body* or its `references/*.md` ...
+ ... only a skill's *body* or its `references/*.md` / `assets/*.md` ...

# dogfood-generator-sync.md — the glob is in the YAML frontmatter `paths:` list (line 14)
   paths:
     - '.claude/CLAUDE.md'
     - 'CLAUDE.md'
     - '.claude/rules/**/*.md'
     - 'skills/**/SKILL.md'
-    - 'skills/**/references/*.md'
+    - 'skills/**/references/*.md'
+    - 'skills/**/assets/*.md'
```

Note: `dogfood-generator-sync.md:48` (the `references/operating-manual-template.md` path inside the ✅-example block) is a pointer to a moved file and was already fixed in **Task 1**. Line `:42` is a bare filename with no path — it stays valid, no edit. The rule's body prose is generic ("a generator under `skills/**`") and needs no `assets/` mention beyond the glob.

- [ ] **GREEN — confirm coverage:**

```bash
grep -rln 'assets/\*\.md\|skills/\*\*/assets' .claude/rules .claude/CLAUDE.md skills/authoring/writing-skills/references/validation-checklist.md | wc -l   # ≥ 8
jq -e '.' .claude/rules/common/dogfood-generator-sync.md >/dev/null 2>&1 || true   # (only if any JSON touched — N/A here)
```

- [ ] **Manual re-read** of the 7 docs: every occurrence of the old bare `references/*.md` that should now include `assets/` is updated; the canonical phrase is consistent.
- [ ] **Commit (proposed):**

```bash
git commit -am "docs(rules): describe assets/ layout beside references/ in structural docs"
```

---

## Task 3 — Teach `writing-skills` the assets/ vs references/ criterion (Iron Law: RED→GREEN)

This is a **skill edit**, so it is gated by a subagent pressure run, not a grep. The criterion text is the spec's Contracts → "The role criterion" block.

**Files** (EDIT)

- `skills/authoring/writing-skills/SKILL.md` — add the role criterion where bundled-resource disclosure is discussed.
- `skills/authoring/writing-skills/references/vocabulary.md` — add an entry defining `assets/` vs `references/` (today `:28` defines only the generic "external reference").

**Interfaces**

- Consumes: the `assets/` convention now live in the tree (Tasks 1–2).
- Produces: the durable authoring rule a future skill author follows.

**Steps**

- [ ] **RED — baseline pressure run WITHOUT the edit.** Dispatch a fresh subagent (zero context) the scenario: *"You are adding a new reviewer-prompt file and a new fill-in template to an existing skill in this vault. Where on disk do each go, and why?"* Record the verbatim answer. Expected failure: it places both in `references/` (or guesses), with no role distinction — because the methodology does not yet name the criterion.
- [ ] **Confirm the test isn't trivially green (Suspicion Protocol):** verify the control genuinely lacks the distinction — `grep -ni 'assets' skills/authoring/writing-skills/SKILL.md skills/authoring/writing-skills/references/vocabulary.md` returns nothing.
- [ ] **GREEN — write the minimal criterion.** Add to `SKILL.md` (illustrative placement — match surrounding prose):

```text
**`assets/` vs `references/`** — a bundled file goes in `assets/` if the skill
*instantiates/copies* it (a template it fills, an example it emulates, a prompt it
injects into a subagent); it goes in `references/` if the agent *reads it for
guidance* (methodology, a playbook, a key registry, a checklist). Test: "copy/fill/
inject → `assets/`; read-for-guidance → `references/`."
```

And add the matching `vocabulary.md` entry distinguishing the two from the generic "external reference."

- [ ] **GREEN — re-run the same scenario WITH the edit.** Confirm the subagent now routes the prompt and template to `assets/` and a methodology doc to `references/`, citing the criterion. Paste both runs.
- [ ] **VALIDATE** — run the vault validators on `writing-skills/SKILL.md`. The `quality.sh` PostToolUse hook auto-runs them on the edit (read its stderr); to run manually, use the illustrative runner in `skills/authoring/writing-skills/references/validation-checklist.md:27-39` (frontmatter bytes ≤1024, `name` regex + `name==dir`, fences even, body word count) plus the link-resolution loop from Task 1. Note `writing-skills` is `disable-model-invocation: true`, so the word-count bound is ≤~1500 (user-invoked), not ≤500. Paste output.
- [ ] **Commit (proposed):**

```bash
git commit -am "feat(writing-skills): document assets/ vs references/ placement criterion"
```

---

## Final verification (whole-spec, after all tasks)

- [ ] `find skills -path '*/assets/*.md' | wc -l` → 22.
- [ ] Stale-pointer grep (Task 1) → 0, across `skills .claude/rules .claude/CLAUDE.md`.
- [ ] 5 `references/` dirs gone; no empty `assets/` dir created.
- [ ] Link-resolution validator clean on every edited skill doc.
- [ ] `writing-skills` RED→GREEN runs pasted; criterion present in `SKILL.md` + `vocabulary.md`.
- [ ] Then `spec-drift-audit` against `specs/2026-06-21-assets-references-split.md`.

## Execution mode

Tasks are **sequential and coupled** (Task 2's wording and Task 3's criterion both depend on Task 1's relocation; the grep/validator gates assume the prior task landed). Recommend **`inline-driven-development`** (solo, in-session) over subagents — though Task 3's RED/GREEN itself dispatches subagents for the pressure run. Confirm via `pre-implementation-protocol` first.
