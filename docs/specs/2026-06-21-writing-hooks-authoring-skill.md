# Spec: `writing-hooks` authoring skill (+ coordinated rule edits)

> Status: draft for review. Source: approved grilling design + Decisions log (D1–D9), readiness review (all 5 findings resolved). Mode: AUTHOR.

## Goal

Add a single `writing-hooks` skill that teaches authoring a Claude Code hook **test-first** (fixture-led execution + wiring check), closing the authoring asymmetry — hooks are today the only first-class vault artifact with no `writing-X` skill. The same change retracts the "verification = validators + subagent runs **only**" absolute in the two foundational rules so a hook fixture-test is a legitimate third RED kind, not a contradiction.

## Scope

- New skill `skills/authoring/writing-hooks/SKILL.md` + flat symlink `.claude/skills/writing-hooks`.
- `skills/authoring/writing-hooks/references/hook-events.md` — thin event catalog (the 4 vault events + decision shapes; links to official Claude Code hook docs, does not reproduce them).
- `skills/authoring/writing-hooks/assets/hook-template.sh` — fail-open hook skeleton (shebang, stdin read, jq-guarded parse, exit-0 default).
- `skills/authoring/writing-hooks/assets/fixture-example.md` — worked fixture-test (the per-form RED oracle, runnable).
- `.claude/skills-routing.json` — one trigger-routed entry for `writing-hooks`.
- `.claude/rules/domains/glossary.md` — add hook verification note + retract the line-44 "only" absolute.
- `.claude/rules/domains/framework.md` — amend line 3 + the `## Evidence-Based Verification` section (l.34–40) to admit fixture-execution.
- `CLAUDE.md` (root) — add a routing-table row "Author or change a hook → `writing-hooks`".

## Out of scope

- A separate `auditing-hooks` skill (D1 — authored artifacts get a single `writing-X`).
- Extending `quality.sh` with leak / word-count validators (vault-expansion candidates H1/H2 — separate change).
- `SessionStart` / `SubagentStop` / `PreCompact` / `Notification` support beyond a one-line catalog mention (vault wires none today).
- Rewriting or refactoring any existing hook under `hooks/**`.
- Editing `auditing-glossary` / `auditing-claude-md` mirrors — confirmed no generator ships the retracted absolute (see Risks); dogfood-generator-sync is N/A.
- Any other vault-expansion-audit candidate (S2–S5, R1/R2, A1, H1–H7).

## Contracts

### 1. SKILL.md frontmatter (trigger-routed — NOT `disable-model-invocation`)

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

### 2. Body structure — 4 recipe blocks + a small discipline core (D4, D5)

```text
# Writing Hooks
<intro: a hook is deterministic executable code wired to a harness event; predictability is the virtue>
## The discipline core (the ONLY two non-negotiables — prohibition + table + red flags)
   - fail-open is mandatory; RED-before-writing is the Iron Law for a hook.
## Block 1 — Pick the event and the decision contract   (references/hook-events.md)
## Block 2 — Fail-open invariant
## Block 3 — Test-first: the fixture loop (RED oracle per contract form)
## Block 4 — Wire it (source → flat symlink → settings.json entry, right event + matcher)
## Rationalizations  (table — discipline core only)
## Red Flags — STOP
```

### 3. Two decision-contract forms + warn (D5b) — taught as a choice, both quoted

```text
FORM A — exit-code (default; simple guards). BLOCK = stderr message + `exit 2`; allow = `exit 0`.
FORM B — JSON-stdout (PreToolUse deny needing a model-visible reason): print to stdout then `exit 0`:
  {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"<shown to model>"}}
WARN is NOT a third exit code: it is `exit 0` + a message on stderr (advisory, non-blocking).
  Forbidden: `exit 1` as a warn (Claude Code treats it as a generic non-blocking error, not a clean warn).
```

### 4. Per-form RED oracle (D6) — the assertion mechanism, runnable

```bash
# exit-code form:   craft stdin, run, assert the code
echo '{"tool_input":{"file_path":"~/.ssh/id_rsa"}}' | ./hook.sh; echo $?   # RED (no logic): 0  → GREEN: 2
#   NB: this RED-0 (logic not written) is distinct from the fail-open 0 below — keep them
#   as separate fixtures so a garbage→0 assertion is never read as "not yet implemented".
# JSON-stdout form: parse stdout for the decision
echo '<deny-case-json>' | ./hook.sh | jq -r '.hookSpecificOutput.permissionDecision'   # RED: "" / null  → GREEN: "deny"
# warn form:        assert exit 0 AND stderr carries the message
out=$(echo '<case>' | ./hook.sh 2>err.txt); echo $?; grep -q 'warn:' err.txt   # exit 0 + message present
# fail-open:        feed garbage / empty, assert exit 0 and no block
printf 'not json' | ./hook.sh; echo $?     # MUST be 0
```

### 5. Fail-open definition (D7) — universal invariant

```text
On its OWN error / missing dependency (jq absent) / unparseable stdin / empty target field, a hook
never disrupts real work: a guard MUST NOT block, a logger silently does nothing.
Concretely: errors suppressed (`2>/dev/null`), defaulted (`// empty` / `// ""`), and the path ends `exit 0`.
A buggy guard that blocks real work is a worse defect than the gap it was guarding.
```

### 6. Wiring + matcher check (D8)

```text
Verify THREE things, not just "an entry exists":
  (a) flat symlink .claude/hooks/<name>.sh → ../../hooks/<area>/<name>.sh resolves (`readlink -f`);
  (b) settings.json registers it under the CORRECT event;
  (c) the matcher is right — "Bash", "Edit|Write|MultiEdit", ".*"; UserPromptSubmit/Stop take NO matcher.
A wrong matcher fires on the wrong tool (or never) — an unwired/mis-wired hook silently never runs.
The hooks/{guards,quality,routing,session} buckets are illustrative (vault-specific taxonomy, D2).
```

### 7. `skills-routing.json` entry (mirror the `writing-rules` shape)

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

### 8. Foundational-rule edits (D9) — their OWN RED/GREEN sub-item

> Line numbers below are as-of this spec; files shift. The implementer **greps the quoted string**, not the digit, to locate each edit.

```text
glossary.md:44  "Verification here = validators + subagent runs only."
  → "Verification here = validators + subagent runs; a HOOK change additionally verifies by
     fixture-execution (crafted stdin → run the script → assert the decision), since a hook is
     deterministic executable code." (still NO consumer pnpm/Vitest/simulator).
  + Implementation table: hooks row already exists (#3) — add that a hook change is RED-tested by
    fixture-execution, cross-link writing-hooks.
framework.md:3   "...the skill validators + RED/GREEN subagent runs — never pnpm/Vitest/simulator"
  → add ", plus fixture-execution of a hook against crafted stdin for a hook change".
framework.md:34  ## Evidence-Based Verification → add a bullet:
  "- Hook fixture run — for a hook change, pipe crafted stdin to the script and assert the exit
     code / stdout decision / stderr message; this is the hook's RED/GREEN. Still no pnpm/build/suite."
```

## Files touched

| File | Change | Why |
| --- | --- | --- |
| `skills/authoring/writing-hooks/SKILL.md` | NEW | The skill body (4 blocks + discipline core) |
| `skills/authoring/writing-hooks/references/hook-events.md` | NEW | Thin event/contract catalog, links official docs |
| `skills/authoring/writing-hooks/assets/hook-template.sh` | NEW | Fail-open hook skeleton |
| `skills/authoring/writing-hooks/assets/fixture-example.md` | NEW | Worked per-form RED oracle |
| `.claude/skills/writing-hooks` | NEW (symlink) | Discovery — flat symlink → `../../skills/authoring/writing-hooks/SKILL.md` |
| `.claude/skills-routing.json` | EDIT | Register the trigger-routed entry (skill-routing-sync) |
| `.claude/rules/domains/glossary.md` | EDIT | Retract the "only" absolute; admit fixture-execution |
| `.claude/rules/domains/framework.md` | EDIT | l.3 + Evidence-Based Verification: admit hook fixture run |
| `CLAUDE.md` | EDIT | Routing-table row "Author or change a hook → writing-hooks" |

## Edge cases

- **Event with no matcher** (`UserPromptSubmit`, `Stop`) — the wiring check must NOT require a matcher key for these; requiring one is a false negative.
- **Logger vs guard fail-open** — a logger failing open means "log nothing"; a guard failing open means "allow". Block 2 must state both so the garbage-fixture asserts the right thing per kind.
- **`jq` absent** — the canonical fail-open trigger; `hook-template.sh` must `command -v jq >/dev/null 2>&1 || exit 0` before any parse.
- **`warn` mistaken for `deny`** — author writes `exit 1` expecting a warning; the recipe + an explicit red flag must catch this.
- **Term boundary** — "validator" (structural markdown checks) must NOT be stretched to cover a hook fixture (behavioral); the glossary edit keeps them distinct kinds (rejected reframe option C from grilling).
- **Discipline core is a no-op** — if a cold agent already fail-opens by reflex, the prohibition guards nothing (scoping-skill-value); the RED phase must reproduce the failure or the core is re-aimed to shaping. Handled at authoring time, flagged in Risks.

## Verification

Real checks (vault has no build/test pipeline — validators + subagent runs + the new hook fixture run):

- **Validators** (per root CLAUDE.md → Common commands): frontmatter ≤1024 bytes; `name` matches `^[a-z0-9-]+$` and `name == dir`; every `references/*.md` + `assets/*.md` link resolves; fences balanced; word count sane. Paste output.
- **Routing**: `jq . .claude/skills-routing.json` valid; `find skills -name SKILL.md` ↔ `jq '.skills|keys'` reconcile (skill-routing-sync checklist).
- **Symlink**: `readlink -f .claude/skills/writing-hooks` resolves to the new SKILL.md.
- **Hook fixture run** (the new modality): run `assets/hook-template.sh` against the `fixture-example.md` fixtures; assert exit-code / stdout `permissionDecision` / stderr per oracle (§4); garbage stdin → exit 0.
- **GREEN subagent run**: re-run the RED authoring scenarios WITH the skill; paste compliance. The foundational-rule edits get their OWN RED/GREEN (a subagent told "verify a hook change in this vault" should cite fixture-execution, not reject it as forbidden).

## Risks

- **Term-stretch / `auditing-glossary` later flags the edit.** Mitigation: the glossary edit keeps "validator" and "fixture run" as distinct kinds (no stretch); `auditing-glossary` checks glossary-vs-disk, and disk will now contain `writing-hooks` teaching fixtures, so the rule matches the new truth — no conflict. Confirmed no `bootstrapping-*` template ships the retracted absolute (`framework-charter-template` verification is fully parameterized), so **dogfood-generator-sync is N/A**.
- **Discipline core absorbed by a strong baseline** (no-op risk). Mitigation: writing-skills RED phase reproduces the failure on a clean (non-vault-injected) baseline per scoping-skill-value; if it absorbs, re-aim GREEN to the shaping failure (decision-form variance) and keep only the reproduced part.
- **Coupling the rule retraction with the skill in one change** could enlarge the diff. Mitigation: the rule edit is scoped as its own RED/GREEN sub-item with consistent cross-references; the spec lists exact lines so the edit is mechanical, not exploratory.
