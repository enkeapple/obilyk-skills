# `writing-hooks` Authoring Skill — Implementation Plan

**Goal:** Author the `writing-hooks` skill test-first and land the coordinated routing + foundational-rule edits, so authoring a vault hook has a `writing-X` skill and a hook fixture-test is a legitimate RED kind.

**Architecture:** AUTHOR mode, RED→GREEN→REFACTOR→VALIDATE per `writing-skills`. "Test" here is NOT a unit test: it is a subagent pressure run (for the SKILL.md discipline/shaping) plus — new in this change — a hook fixture-execution (pipe crafted stdin to a script, assert the decision). The skill is one coordinated unit; tasks are sequenced by dependency, RED before any authoring (Iron Law).

**Tech stack:** Markdown `SKILL.md` + `references/` + `assets/`; bash hook scripts; `jq`; `.claude/skills-routing.json` (JSON); flat dir symlinks; vault validators.

## Global constraints

- Iron Law: no skill/skill-edit without a failing test first — Task 1 (RED) MUST precede Task 2 (authoring). Wrote it first → delete, restart.
- Agnostic: the SKILL.md teaches the Claude Code hook mechanism, never a consumer stack; the `hooks/{guards,quality,routing,session}` buckets are marked `(illustrative — your repo may differ)`.
- Source-of-truth: every contract/shape is copied verbatim from the spec (`docs/specs/2026-06-21-writing-hooks-authoring-skill.md` §2–§8). Do not re-derive.
- Skill names are structural claims: `name` === dir === routing key === symlink name = `writing-hooks`.
- Flat symlink points at the **directory** (`.claude/skills/writing-hooks -> ../../skills/authoring/writing-hooks`), mirroring `writing-rules` — NOT at `SKILL.md`.
- No AI attribution in commit messages; the human runs each commit.
- dogfood-generator-sync = N/A (verified: no `bootstrapping-*` template ships the retracted "validators+subagent only" absolute).

## Interfaces summary (cross-task names)

- **Produces** (Task 2): `skills/authoring/writing-hooks/SKILL.md` with `name: writing-hooks`, sections: discipline core, Block 1–4, Rationalizations, Red Flags.
- **Produces** (Task 3): `references/hook-events.md`, `assets/hook-template.sh`, `assets/fixture-example.md` — linked from SKILL.md by relative path.
- **Produces** (Task 4): symlink `.claude/skills/writing-hooks`.
- **Produces** (Task 5): routing key `"writing-hooks"` with `files: [".claude/skills/writing-hooks/SKILL.md"]`.

---

## Task 1 — RED: baseline failure for hook authoring

**Files:** none (observation only; record verbatim output in the plan/turn log).

**Steps:**

- [ ] 1.1 Dispatch a cold subagent (NOT in-vault if testing the *discipline* — a vault subagent inherits `framework.md` and may falsely comply, per scoping-skill-value). Prompt: *"Author a Claude Code PreToolUse hook that blocks reading `.env` files. Give me the bash script and how to wire it."* Capture the output verbatim.
- [ ] 1.2 Classify the failure against the spec's target behaviors. Expected RED observations (at least one must reproduce):
  - picks a contract form arbitrarily / conflates `exit 1` with a deny or a warn;
  - omits fail-open (no `jq`-absent / unparseable-stdin guard; crashes instead of `exit 0`);
  - gives no wiring (no settings.json event+matcher) or a wrong matcher;
  - writes no fixture test / no way to assert the decision.
- [ ] 1.3 Decide the form (writing-skills "match the form to the failure"): if the discipline failure (fail-open, RED-first) does NOT reproduce on a clean baseline, **re-aim** GREEN to the reproducible **shaping** failure — decision-form variance across reps — and keep the discipline core minimal. Record the verdict.
- [ ] 1.4 Gate: if NOTHING reproduces even as a shaping failure, STOP — do not write the skill (no test, nothing to fix). Otherwise proceed to Task 2 scoped to the reproduced failure.

**Done when:** verbatim baseline failure captured and classified (discipline vs shaping); the target the skill must fix is named.

---

## Task 2 — GREEN: write `SKILL.md`

**Files:** `skills/authoring/writing-hooks/SKILL.md` (NEW).

**Interfaces — Produces:** the skill body. **Consumes:** Task 1's failure classification.

**Steps:**

- [ ] 2.1 Create the frontmatter verbatim from spec §1:

```yaml
---
name: writing-hooks
description: >-
  Use when authoring or editing a Claude Code hook — a PreToolUse/PostToolUse/
  Stop/UserPromptSubmit gate or logger wired in settings.json — test-first.
  Triggers on: "write a hook", "add a hook", "PreToolUse hook", "PostToolUse
  hook", "gate this tool", "блокировать инструмент", "написать хук", "добавить хук".
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Skill
---
```

- [ ] 2.2 Write the **discipline core** (the ONLY two non-negotiables, prohibition form): fail-open is mandatory; RED-before-writing is the Iron Law for a hook. Keep it small (spec §2, D5).
- [ ] 2.3 Write **Block 1 — event + contract** with the two forms as a *decision rule* (spec §3), both shapes shown:

```text
FORM A — exit-code (default; simple guards): BLOCK = stderr message + `exit 2`; allow = `exit 0`.
FORM B — JSON-stdout (PreToolUse deny needing a model-visible reason): stdout then `exit 0`:
  {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"<shown>"}}
WARN ≠ third exit code: `exit 0` + stderr message. FORBIDDEN: `exit 1` as a warn.
```

- [ ] 2.4 Write **Block 2 — fail-open** verbatim from spec §5 (guard MUST NOT block; logger silently does nothing; `2>/dev/null` + `// empty`/`// ""` + `exit 0`).
- [ ] 2.5 Write **Block 3 — test-first fixture loop**, embedding the per-form RED oracle from spec §4 (keep RED-0-no-logic distinct from fail-open-0). Link `assets/fixture-example.md`.
- [ ] 2.6 Write **Block 4 — wiring** from spec §6 (symlink-to-directory; settings.json correct EVENT + MATCHER; `UserPromptSubmit`/`Stop` take no matcher; buckets illustrative). Link `references/hook-events.md`.
- [ ] 2.7 Write **Rationalizations** table + **Red Flags** — for the discipline core only (e.g. "I'll add fail-open later", "`exit 1` is close enough to a warn", "I'll wire it after").
- [ ] 2.8 RED→GREEN check: re-run the Task 1 subagent scenario WITH the skill in context; confirm it now picks a form deliberately, fail-opens, wires with a matcher, and writes a fixture test. Record compliance.
- [ ] 2.9 Commit: `rtk git add skills/authoring/writing-hooks/SKILL.md && rtk git commit -m "feat(writing-hooks): add hook-authoring skill body"` (human runs).

**Done when:** the with-skill subagent run complies on the same scenario that failed in Task 1.

---

## Task 3 — references + assets

**Files:** `skills/authoring/writing-hooks/references/hook-events.md` (NEW), `assets/hook-template.sh` (NEW), `assets/fixture-example.md` (NEW).

**Interfaces — Consumes:** the relative links written in Task 2 (paths must match).

**Steps:**

- [ ] 3.1 `references/hook-events.md` — thin catalog: the 4 vault events (`UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`), each with its stdin fields used and decision form, plus a one-line link to the official Claude Code hooks doc. Do NOT reproduce the official docs.
- [ ] 3.2 `assets/hook-template.sh` — fail-open skeleton (single contract form, exit-code, per reviewer note 1):

```bash
#!/bin/bash
# <NAME> hook — <event>, matcher <matcher>. Exit: 0 = allow, 2 = block.
command -v jq >/dev/null 2>&1 || exit 0          # fail-open: missing dep
INPUT=$(cat 2>/dev/null) || exit 0               # fail-open: unreadable stdin
FIELD=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FIELD" ] && exit 0                         # fail-open: empty target
if printf '%s' "$FIELD" | grep -qiE '<pattern>'; then
  echo "BLOCKED: <reason>." >&2
  exit 2
fi
exit 0
```

- [ ] 3.3 `assets/fixture-example.md` — worked per-form RED oracle (spec §4), with THREE distinct fixtures kept separate: deny-case, allow-case, and garbage→fail-open. Show the runnable assertions:

```bash
echo '{"tool_input":{"file_path":".env"}}' | ./hook.sh; echo $?   # RED (no logic): 0 → GREEN: 2
echo '{"tool_input":{"file_path":"README.md"}}' | ./hook.sh; echo $?  # always: 0
printf 'not json' | ./hook.sh; echo $?                            # fail-open: 0 (NOT a missing-logic 0)
```

- [ ] 3.4 Fixture run (the new modality): make the template executable and run it against 3.3's fixtures, confirm the asserted codes.

```bash
chmod +x skills/authoring/writing-hooks/assets/hook-template.sh
# (fill <pattern> with \.env for this smoke run) then run the three lines above
```

- [ ] 3.5 Commit: `rtk git add skills/authoring/writing-hooks/references skills/authoring/writing-hooks/assets && rtk git commit -m "feat(writing-hooks): add event catalog, hook template, fixture example"` (human runs).

**Done when:** every relative link in SKILL.md resolves; the template runs against all 3 fixtures with the expected exit codes.

---

## Task 4 — flat symlink

**Files:** `.claude/skills/writing-hooks` (NEW symlink → `../../skills/authoring/writing-hooks`).

**Steps:**

- [ ] 4.1 Create the directory-level symlink (mirrors `writing-rules`):

```bash
ln -s ../../skills/authoring/writing-hooks .claude/skills/writing-hooks
```

- [ ] 4.2 Confirm it resolves and reaches the SKILL.md the routing will point at:

```bash
readlink .claude/skills/writing-hooks            # → ../../skills/authoring/writing-hooks
test -f .claude/skills/writing-hooks/SKILL.md && echo OK
```

- [ ] 4.3 Commit (note: creating files under `.claude/` is fine; `edit-write-guard` blocks `.claude/hooks`/settings, not `.claude/skills`). `rtk git add .claude/skills/writing-hooks && rtk git commit -m "feat(writing-hooks): add flat skill symlink"` (human runs).

**Done when:** `readlink` shows the dir target and `SKILL.md` is reachable through it.

---

## Task 5 — routing entry

**Files:** `.claude/skills-routing.json` (EDIT).

**Interfaces — Consumes:** the symlink from Task 4 (the `files` path resolves through it).

**Steps:**

- [ ] 5.1 Add the entry verbatim from spec §7 into the `skills` map (place near `writing-rules`):

```jsonc
"writing-hooks": {
  "triggers": [
    "write a hook", "add a hook", "create a hook", "make a hook",
    "PreToolUse hook", "PostToolUse hook", "gate (this )?tool",
    "написать хук", "добавить хук", "создать хук", "блокировать инструмент"
  ],
  "files": [".claude/skills/writing-hooks/SKILL.md"]
}
```

- [ ] 5.2 Validate JSON and that the `files` path resolves (skill-routing-sync checklist):

```bash
jq . .claude/skills-routing.json >/dev/null && echo "valid JSON"
test -f "$(jq -r '.skills["writing-hooks"].files[0]' .claude/skills-routing.json)" && echo "files path OK"
```

- [ ] 5.3 Reconcile disk ↔ routing (no missing/extra keys):

```bash
diff <(find skills -name SKILL.md | sed -E 's#skills/[^/]+/([^/]+)/SKILL.md#\1#' | sort) \
     <(jq -r '.skills|keys[]' .claude/skills-routing.json | sort) | head
# expected: only disable-model-invocation skills (writing-skills, improve-codebase-architecture, entrypoints/*) appear as routing-absent — verify each is intended
```

- [ ] 5.4 Commit: `rtk git add .claude/skills-routing.json && rtk git commit -m "chore(routing): register writing-hooks"` (human runs).

**Done when:** JSON valid, `files` resolves, reconcile shows only the expected `disable-model-invocation` skills as routing-absent.

---

## Task 6 — foundational-rule edits (own RED/GREEN)

**Files:** `.claude/rules/domains/glossary.md` (EDIT), `.claude/rules/domains/framework.md` (EDIT).

**Steps:**

- [ ] 6.1 RED: dispatch a cold subagent — *"In the sdd-workflow vault, how do you verify a hook change is correct?"* — BEFORE editing. Expect it to cite the current absolute ("validators + subagent runs only") and NOT mention fixture-execution. Capture verbatim.
- [ ] 6.2 Edit `glossary.md` — grep the quoted string (don't trust line numbers), replace the "only" absolute per spec §8:

```text
FIND:    Verification here = validators + subagent runs only.
REPLACE: Verification here = validators + subagent runs; a HOOK change additionally verifies by
         fixture-execution (crafted stdin → run the script → assert the decision), since a hook is
         deterministic executable code.
```

  Also extend the hooks row (#3) in the ownership table to note hook changes are RED-tested by fixture-execution; cross-link `writing-hooks`.
- [ ] 6.3 Edit `framework.md` — grep the quoted strings, amend line-3 intro and the `## Evidence-Based Verification` section per spec §8 (add the hook-fixture bullet; keep "no pnpm/build/suite/simulator").
- [ ] 6.4 GREEN: re-run the 6.1 subagent question WITH the edited rules; confirm it now cites fixture-execution as a legitimate RED kind and does NOT call it forbidden. Record compliance.
- [ ] 6.5 Validate the two rule docs (markdown-style + links/fences): see Task 7 validator block.
- [ ] 6.6 Commit: `rtk git add .claude/rules/domains/glossary.md .claude/rules/domains/framework.md && rtk git commit -m "docs(rules): admit hook fixture-execution as a RED kind"` (human runs).

**Done when:** the with-edit subagent cites fixture-execution; both docs validate.

---

## Task 7 — CLAUDE.md routing row + final VALIDATE

**Files:** `CLAUDE.md` (EDIT).

**Steps:**

- [ ] 7.1 Add the row after the `writing-skills` row in the Skill-routing table (grep `Author or change any skill`):

```text
| Author or change a Claude Code hook (test-first) | `writing-hooks` |
```

- [ ] 7.2 Run the full validator sweep and PASTE output (vault "Common commands"):

```bash
# frontmatter ≤1024 bytes
awk '/^---$/{c++; next} c==1{print}' skills/authoring/writing-hooks/SKILL.md | wc -c
# name regex + name == dir
grep -m1 '^name:' skills/authoring/writing-hooks/SKILL.md
# links resolve (every references/*.md + assets/* link)
grep -oE '\]\(([^)]+)\)' skills/authoring/writing-hooks/SKILL.md
# fences balanced (even count)
grep -c '^```' skills/authoring/writing-hooks/SKILL.md
# word count sane
wc -w skills/authoring/writing-hooks/SKILL.md
# unspaced markdown table delimiters (must be empty)
grep -nE '\|-{2,}\|' skills/authoring/writing-hooks/SKILL.md references/*.md 2>/dev/null || echo "no unspaced delimiters"
```

- [ ] 7.3 Re-run the quality.sh-equivalent on the new docs by editing them once (PostToolUse fires) OR run its checks manually; confirm no QUALITY warn.
- [ ] 7.4 Final GREEN: one consolidated subagent run — *author a real hook using the skill, then verify it* — confirm it produces a fail-open, wired, fixture-tested hook AND verifies it via fixture-execution. Paste compliance.
- [ ] 7.5 Commit: `rtk git add CLAUDE.md && rtk git commit -m "docs: route hook authoring to writing-hooks"` (human runs).

**Done when:** all validators pass (output pasted), final GREEN run complies, Completeness Checklist (`.claude/CLAUDE.md`) all `[x]`/`[N/A]`.

---

## Execution

Tasks are mostly sequential with a hard RED→authoring dependency and shared structural contracts (symlink ↔ routing ↔ SKILL.md). Recommended flow: **`inline-driven-development`** (coupled tasks, one coherent skill — execute solo in-session, verify + commit per task), gated first by **`pre-implementation-protocol`**. Each task's artifact is written test-first via `test-driven-development` adapted to AUTHOR mode (RED subagent/fixture before the artifact, GREEN after).
