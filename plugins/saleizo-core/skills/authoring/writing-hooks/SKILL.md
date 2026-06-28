---
name: writing-hooks
description: >-
  Use when authoring or editing a Claude Code hook — a PreToolUse/PostToolUse/
  Stop/UserPromptSubmit gate or logger wired in settings.json — test-first.
  Triggers on: "write a hook", "add a hook", "PreToolUse hook", "PostToolUse
  hook", "gate this tool", "блокировать инструмент", "написать хук", "добавить хук".
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Skill
---

# Writing Hooks

A hook is **deterministic executable code** wired to a harness event — not an instruction the model interprets. So unlike a skill, you do not pressure-test it with a subagent: you **run it against crafted stdin and assert the decision**. Predictability is still the virtue, and here you get it for free *if* you pin two things a capable author otherwise gets subtly wrong: **which decision contract** the hook speaks, and **fail-open** as an invariant rather than a judgment call.

This skill is the hook-specific specialization of `writing-skills` — the RED→GREEN→VALIDATE loop is the same; the "test" is a fixture run.

## The two non-negotiables (discipline core)

Everything else here is a recipe. These two are not negotiable:

1. **Fail-open is an invariant, not a tradeoff.** On its OWN error — missing dependency (`jq`), unparseable stdin, an empty target field — a hook MUST NOT disrupt real work: a **guard allows** (`exit 0`), a **logger silently does nothing**. A guard that blocks because *its own* `jq` was missing is a worse failure than the gap it guarded: it breaks every unrelated tool call. Never "fail-closed for safety" — that is the one rationalization that turns a guard into an outage.
2. **No hook without a failing fixture first (the Iron Law, hook form).** Write the fixture, run it, watch it give the wrong/absent decision BEFORE you write the logic. Wrote the logic first? Delete it, start from the fixture.

| Rationalization | Reality |
| --- | --- |
| "If jq is missing, fail-closed is safer." | It is not safer — it blocks ALL gated tool calls on your machine because of your bug. Fail-open; the gap is narrower than the outage. |
| "I'll emit both JSON deny AND exit 2 to be safe across versions." | Hedging both forms is the variance this skill exists to kill. Pick the one form the event needs (below) and commit to it. |
| "`exit 1` means warn." | No — `exit 1` is a generic non-blocking error. A warn is `exit 0` + a stderr message. `exit 2` blocks. |
| "I'll wire it after I write it." | An unwired hook never fires — the wiring IS part of the deliverable, and a wrong matcher fires on the wrong tool. |
| "It's deterministic code, the fixture is overkill." | The fixture is the whole test. Without it you are shipping an unrun guard into the tool-call path. |

## Block 1 — Pick the event, then the decision contract

**Event** — what fires when (full field/shape catalog: [`references/hook-events.md`](./references/hook-events.md)):

- `PreToolUse` — before a tool runs; the ONLY event that can block it. `PostToolUse` is too late.
- `PostToolUse` — after a tool ran; observe/validate, cannot prevent.
- `UserPromptSubmit` — on prompt submit (no `tool_input`); gate or annotate a prompt.
- `Stop` — at turn end; nudges/logging.

**Contract — choose ONE form, do not hedge both** (this is the convergence the skill enforces):

```text
FORM A — exit-code (DEFAULT; simple guards). The vault majority.
  BLOCK  = message on stderr + `exit 2`   (stderr is fed back to the model)
  allow  = `exit 0`
FORM B — JSON-stdout (ONLY when a PreToolUse deny needs a model-visible REASON
         the harness renders structurally). Print to stdout, then `exit 0`:
  {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"<shown to the model>"}}
WARN is NOT a third exit code: it is `exit 0` + a stderr message (advisory, non-blocking).
  FORBIDDEN: `exit 1` as a "warn" — the harness treats it as a generic non-blocking error.
```

## Block 2 — Fail-open, concretely

Guard every parse; every path ends at `exit 0` unless a real, matched condition fires. The three own-error exits — missing dep (`jq`), unreadable stdin, empty target field — are the opening guards of [`assets/hook-template.sh`](./assets/hook-template.sh); copy them rather than re-deriving. A logger's fail-open is the same shape, with "do nothing" instead of "allow".

## Block 3 — Test-first: the fixture loop

RED a crafted stdin, run the script, assert the decision — per contract form. Full worked oracle: [`assets/fixture-example.md`](./assets/fixture-example.md).

```bash
# Form A (exit-code): assert the code
echo '{"tool_input":{"file_path":".env"}}' | ./hook.sh; echo $?    # RED (no logic): 0  → GREEN: 2
# Form B (JSON-stdout): parse the decision
echo '<deny-case>' | ./hook.sh | jq -r '.hookSpecificOutput.permissionDecision'   # RED: ""/null → GREEN: "deny"
# warn: exit 0 AND the message on stderr
out=$(echo '<case>' | ./hook.sh 2>err); echo $?; grep -q 'warn:' err              # 0 + message present
# fail-open (DISTINCT from RED-0): garbage/empty stdin
printf 'not json' | ./hook.sh; echo $?                                             # MUST be 0
```

Keep the RED-0 (logic not yet written) and the fail-open-0 (garbage input) as **separate fixtures** — a garbage→0 assertion must never be mistaken for "not implemented yet".

## Block 4 — Wire it (or it never runs)

Three moves, all required; a hook that exists but is unwired (or mis-matched) silently never fires:

1. **Source** — the script lives in the repo's hook tree (in this vault, `hooks/<area>/<name>.sh`; the buckets `guards/`, `quality/`, `routing/`, `session/` are _illustrative — your repo may differ_).
2. **Discovery** — whatever the harness reads (in this vault, a flat symlink `.claude/hooks/<name>.sh` → the source); `chmod +x`.
3. **Register** in `settings.json` under the **correct event** with the **correct matcher**: a tool-name regex like `"Bash"` or `"Edit|Write|MultiEdit"`, or `".*"`; `UserPromptSubmit` and `Stop` take **no** matcher. A wrong matcher fires on the wrong tool — or never. Verify the wiring, not just that an entry exists.

### Authoring-time fixtures vs the persisted CI suite

The fixture loop above is authoring-time scaffolding — run it to prove the decision logic, then discard it. Separately, hooks are deterministic code with a **persisted regression suite** the CI runs: each hook has a `tests/<hook>.sh.cases` file (declarative cases) executed by the repo's hook-fixture runner (`scripts/run-hook-fixtures.sh`). When you add or change a hook's decision logic, update its `.cases` file in the same change so the committed suite stays green — an edited hook with a stale suite is the leaked hand-off this note prevents.

## VALIDATE

The hook fixture run (Block 3) is the behavioral test. Plus: the script is executable, the discovery path resolves, and `settings.json` is valid and registers the right event + matcher.

## Red Flags — STOP

- You wrote the hook logic before a failing fixture existed.
- You chose "fail-closed" / blocked on a missing dependency or unparseable input.
- You emitted both a JSON deny and `exit 2`, or used `exit 1` as a warn.
- The hook is written but not wired, or the matcher doesn't match the tool you meant.
- You asserted "it works" without running it against a crafted stdin fixture.
