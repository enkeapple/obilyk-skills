# Spec — Split instantiated artifacts into per-skill `assets/`

## Goal

Separate each skill's bundled resources by **role**: `references/` keeps files the agent *reads for guidance*; a new sibling `assets/` holds files the skill *instantiates/copies* (templates, examples, reviewer/subagent prompts). Aligns the vault with the Claude Code skill-spec `assets/` concept. Benefit is organizational only — every file still loads into context.

## Scope

- Move **22 instantiated-artifact files** from their current `references/` dir (or, for `subagent-driven-development`, the skill root) into a new `<skill>/assets/` dir, filenames unchanged.
- Delete the **5** `references/` dirs that become empty after the move.
- Repoint **every** `SKILL.md` link/label that names a moved file (`references/<f>` and `./<f>`) to `assets/<f>`.
- Repoint the one non-`SKILL.md` path reference to a moved file: `dogfood-generator-sync.md:48`.
- Update the **structural docs** that describe the bundled-resource layout as `references/*.md` so they also cover `assets/*.md` (7 docs, see Files touched).
- Add `skills/**/assets/*.md` to the `dogfood-generator-sync.md` glob (and its prose).
- Teach the **`writing-skills`** methodology the `assets/` vs `references/` criterion (`SKILL.md` + `vocabulary.md`) — this is a skill edit, gated by a RED→GREEN subagent run.
- **(Amended mid-implementation, owner-approved):** normalize the link-prefix of **every** bundled-resource link (`references/<f>.md`, `assets/<f>.md`) across all `SKILL.md` to the `./folder/path` form. The repo was split 13 bare / 10 `./`; this converges it. Out of the original spec, added on owner decision during execution.

## Out of scope

- No `scripts/` dir introduced.
- `.claude/skills/<name>` flat symlinks are NOT touched — they point at the skill root, not sub-dirs; `assets/` is reached through the unchanged root.
- No file renames; no edits to the *content* of any moved template/example/prompt (only their location + inbound pointers).
- `codebase-design` / `improve-codebase-architecture` root methodology docs (`DEEPENING.md`, `DESIGN-IT-TWICE.md`, `HTML-REPORT.md`) — these are read-for-guidance, stay in root, untouched.
- `placeholder-keys.md` (×4), `intake-questions.md`, `design-principles.md`, `interview-playbook.md`, TDD `mocking/refactoring/tests.md`, `frontmatter-reference.md`, `test-cases.md`, `testing-with-subagents.md`, `validation-checklist.md`, `vocabulary.md` — read-for-guidance, stay in `references/`.
- `skills-routing.json` — unaffected: `files` point at `SKILL.md`, not bundled resources.
- `.claude/settings.local.json` (`:12`, `:14` name `references/operating-manual-template.md`) — these are **permission-allowlist entries for past commands**, not functional pointers: no future command uses that path (it targets `assets/`), so the stale entry is dead-but-harmless, and the `edit-write-guard` hook blocks editing settings files autonomously anyway. Left as-is by decision. (Verification grep step 2 is scoped to `skills/.claude/rules/.claude/CLAUDE.md` and does not touch this file.)

## Contracts

### The role criterion (the rule `writing-skills` must encode)

```text
assets/    — a file the skill INSTANTIATES or COPIES verbatim: a template it
             fills, an example it emulates, a prompt it injects into a subagent.
references/ — a file the agent READS to inform its own judgment: methodology,
             playbooks, a key/lookup registry, a checklist.
Test: "Does the skill copy/fill/inject this file, or read it for guidance?"
      copy/fill/inject -> assets/ ; read-for-guidance -> references/.
```

### The 22 moved files (source → destination)

```text
grilling/references/decisions-template.md            -> grilling/assets/
grilling/references/readiness-reviewer-prompt.md     -> grilling/assets/
spec-drift-audit/references/report-example.md        -> spec-drift-audit/assets/
writing-plans/references/plan-template.md            -> writing-plans/assets/
writing-plans/references/plan-reviewer-prompt.md     -> writing-plans/assets/
writing-specs/references/spec-template.md            -> writing-specs/assets/
writing-specs/references/spec-reviewer-prompt.md     -> writing-specs/assets/
subagent-driven-development/implementer-prompt.md           -> subagent-driven-development/assets/
subagent-driven-development/spec-reviewer-prompt.md         -> subagent-driven-development/assets/
subagent-driven-development/code-quality-reviewer-prompt.md -> subagent-driven-development/assets/
writing-lessons/references/lessons-template.md       -> writing-lessons/assets/
writing-lessons/references/promotion-reviewer-prompt.md -> writing-lessons/assets/
writing-rules/references/rule-template.md            -> writing-rules/assets/
writing-rules/references/rule-reviewer-prompt.md     -> writing-rules/assets/
writing-rules/references/rule-efficacy-test-prompt.md -> writing-rules/assets/
writing-skills/references/validation-subagent-prompt.md -> writing-skills/assets/
auditing-claude-md/references/audit-report-example.md   -> auditing-claude-md/assets/
auditing-glossary/references/audit-report-example.md    -> auditing-glossary/assets/
bootstrapping-claude-md/references/operating-manual-template.md -> bootstrapping-claude-md/assets/
bootstrapping-claude-md/references/root-claude-md-template.md   -> bootstrapping-claude-md/assets/
bootstrapping-glossary/references/domain-glossary-template.md   -> bootstrapping-glossary/assets/
bootstrapping-glossary/references/framework-charter-template.md -> bootstrapping-glossary/assets/
```

(All paths relative to `skills/<group>/<skill>/`. Move with `git mv` to preserve history.)

### The 5 emptied `references/` dirs (delete after move)

```text
spec-drift-audit/references/   writing-plans/references/   writing-specs/references/
writing-lessons/references/    writing-rules/references/
```

Skills whose `references/` survives (assets/ added alongside): grilling, writing-skills, auditing-claude-md, auditing-glossary, bootstrapping-claude-md, bootstrapping-glossary.

### SKILL.md pointer edits (`references/<f>` and `./<f>` → `assets/<f>`)

```text
grilling/SKILL.md            :35 :48                         (2)
writing-plans/SKILL.md       :59 :97                         (2)
writing-specs/SKILL.md       :52 :90                         (2)
spec-drift-audit/SKILL.md    :56                             (1)
writing-lessons/SKILL.md     :17 :63 :97 :80                 (4)
writing-rules/SKILL.md       :16 :83 :97                     (3)
writing-skills/SKILL.md      :59 :102                        (2)
auditing-claude-md/SKILL.md  :39                             (1)
auditing-glossary/SKILL.md   :43                             (1)
bootstrapping-claude-md/SKILL.md :49 :50                     (2)
bootstrapping-glossary/SKILL.md  :46 :54                     (2)
subagent-driven-development/SKILL.md :56 :60 :63 :71 :72 :74 :76 :77 :79 :80 :81 :83 (DOT labels) + :118 :119 :120 (links)
```

Verification is by grep (below), not by line number — lines shift as edits land.

### Structural-doc edits (describe layout as `references/*.md` → also cover `assets/*.md`)

```text
.claude/rules/domains/glossary.md:27          (+ references/*.md) -> (+ references/*.md, assets/*.md)
.claude/rules/domains/framework.md:10         layers list: add assets/*.md beside references/*.md
.claude/rules/domains/framework.md:23         "references/*.md link" -> "references/*.md / assets/*.md link"
.claude/rules/domains/framework.md:38         validators line: link-resolution covers assets/ too
.claude/CLAUDE.md:56                           checklist item 6 wording
skills/authoring/writing-skills/references/validation-checklist.md:17  link-resolution wording
.claude/rules/common/agnostic-skill-authoring.md:11   "or its references/*.md" -> add assets/*.md
.claude/rules/common/skill-routing-sync.md:18 :55     "body or references/*.md" wording (assets/ same treatment)
.claude/rules/common/dogfood-generator-sync.md:14     glob: add 'skills/**/assets/*.md'
.claude/rules/common/dogfood-generator-sync.md:48     references/operating-manual-template.md -> assets/...
.claude/rules/common/dogfood-generator-sync.md:42     bare filename, no path — review only (likely no change)
```

### `writing-skills` methodology edit (RED/GREEN-gated)

- `skills/authoring/writing-skills/SKILL.md` — add the role criterion (the Contract block above) where bundled-resource disclosure is discussed, so a new file is placed correctly the first time.
- `skills/authoring/writing-skills/references/vocabulary.md` — add an entry defining `assets/` vs `references/` (current `vocabulary.md:28` defines only the generic "external reference").

## Files touched

| File(s) | Change | Why |
| --- | --- | --- |
| 22 artifact files (Contracts) | MOVE (`git mv` → `assets/`) | the core reorg |
| 5 emptied `references/` dirs | DELETE | no files left after move |
| 11 `SKILL.md` bodies (grilling, writing-plans, writing-specs, spec-drift-audit, writing-lessons, writing-rules, writing-skills, auditing-claude-md, auditing-glossary, bootstrapping-claude-md, bootstrapping-glossary) + subagent-driven-development/SKILL.md | EDIT | repoint links/labels to `assets/<f>` |
| `glossary.md`, `framework.md`, `.claude/CLAUDE.md`, `validation-checklist.md`, `agnostic-skill-authoring.md`, `skill-routing-sync.md`, `dogfood-generator-sync.md` | EDIT | structural layout now includes `assets/` |
| `writing-skills/SKILL.md`, `writing-skills/.../vocabulary.md` | EDIT | encode the role criterion (RED/GREEN-gated) |

## Edge cases

- **Empty `references/` removal** — `git mv` of the last file leaves the dir empty; `git` drops empty dirs automatically on commit, but explicitly `rmdir` to keep the working tree clean. No hook glob, symlink, or `settings.json` entry targets these dirs (verified: `quality.sh` uses generic `.md` matching; `.claude/skills` symlinks point at skill roots).
- **Cross-links inside moved files** — a moved file may link a sibling that stayed in `references/`, or vice-versa; after the move every such relative link must still resolve (validator item "cross-links inside refs resolve"). Re-check each moved file's outbound links.
- **DOT-graph labels in subagent-dd** — the `./x.md` strings on lines :56–:83 are graphviz node labels, not markdown links, but they name the path and must be updated for accuracy (they will not break a link validator, but a stale path is a structural lie).
- **`assets/` created only where ≥1 artifact lands** — no empty `assets/` dirs.
- **No skill gains/loses a trigger, name, or location** — `skills-routing.json` stays byte-identical; the routing-sync rule does not fire (sub-resource move only).

## Verification

No build/test pipeline exists; verification = the vault's real checks.

1. **All moved files exist at destination, none at source:**
   `find skills -path '*/assets/*.md' | wc -l` ⇒ 22; `git status` shows 22 renames.
2. **No stale pointer remains** — must return nothing:
   `grep -rnE '(references/|\./)(decisions-template|plan-template|spec-template|lessons-template|rule-template|operating-manual-template|root-claude-md-template|domain-glossary-template|framework-charter-template|report-example|audit-report-example|readiness-reviewer-prompt|plan-reviewer-prompt|spec-reviewer-prompt|promotion-reviewer-prompt|rule-reviewer-prompt|rule-efficacy-test-prompt|validation-subagent-prompt|implementer-prompt|code-quality-reviewer-prompt)\.md' skills .claude/rules .claude/CLAUDE.md`
3. **Link-resolution validator** (per `validation-checklist.md`) — every `SKILL.md` and reference/asset link points at an existing file. Run the validators on each edited skill doc; paste output.
4. **5 `references/` dirs gone:** `for d in spec-drift-audit writing-plans writing-specs writing-lessons writing-rules; do test ! -e skills/*/$d/references && echo "$d ok"; done`.
5. **Structural docs:** no remaining bare `references/*.md` that should read `references/*.md` + `assets/*.md` — manual re-read of the 7 docs against the edit list.
6. **`writing-skills` RED→GREEN** — baseline subagent scenario "where do I put a new reviewer prompt / template?" fails WITHOUT the criterion (places it in `references/` or guesses); re-run WITH the edited skill confirms it places artifacts in `assets/` and reads-for-guidance in `references/`. Paste both runs.

## Risks

- **Missed inbound pointer** → a dangling link or a stale path that the validator may not flag if it is a DOT label, not a markdown link. *Mitigation:* the grep in Verification step 2 is path-pattern based and catches both link and label forms.
- **`writing-skills` test passes for the wrong reason** — the baseline might already place prompts correctly by luck. *Mitigation:* invert per Suspicion Protocol — confirm the control (no criterion) genuinely guesses wrong before claiming GREEN.
- **Structural-doc wording drift** — editing 7 docs risks inconsistent phrasing of the same concept. *Mitigation:* reuse one canonical phrase ("`references/*.md` and `assets/*.md`") across all of them.
