# Lessons Learned

Transient backlog of un-promoted candidate rules — newest at the top of `## Entries`. When a `Cause-tag` reaches 3×, **invoke the `writing-lessons` skill** (do not hand-promote): it dispatches an independent promotion review and, on a Promote verdict, authors the rule under `.claude/rules/` via `writing-rules`, **deletes the contributing entries**, and records the tag in `## Promoted clusters`. git keeps deleted entries (`git log -S '<cause-tag>'`); deletion happens only via the skill, inside a confirmed promotion (or this one-time cleanup).

## Entries

## 2026-06-22 — Coupled skills by referencing another skill's internal content

- **Cause-tag**: cross-skill-content-coupling
- **Symptom**: owner rejected edits where one skill referenced another skill's internals — `writing-rules`/`writing-hooks` citing `writing-skills`' `test-cases.md` mandate (F11), and grilling/writing-specs/pre-implementation asserting "the same threshold as skill X" (F6).
- **Root cause**: treated cross-skill references as helpful consistency/DRY; they actually couple skills so one rots when another changes, breaking self-containment.
- **Wrong approach**: made grilling's "same threshold" claim true by naming the other skills; justified an absent `test-cases.md` by pointing at `writing-skills`' requirement.
- **Correct approach**: reverted both; each skill states its own contract/predicate independently, so consistency holds by construction (identical text), never by one skill naming another's.
- **Prevention**: before writing another skill's name in a SKILL.md, classify the reference — a HAND-OFF / data-flow ref ("next use writing-specs", "hand the bundle to grilling") is legitimate; a CONTENT/INTERNAL ref ("same threshold X uses", "X requires Y so this is N/A") is coupling — inline the standalone statement instead. Grep the edit for skill names; confirm each hit is a hand-off, not a content dependency.

## 2026-06-21 — Reported an audit finding as "verified" from a broken grep

- **Cause-tag**: broken-grep-false-verification
- **Symptom**: audit finding F3 ("`tightening-prose` absent from CLAUDE.md routing table") shipped as "verified grep=0", but the row exists at `CLAUDE.md:49` — a phantom finding.
- **Root cause**: `grep -c "tightening-prose\|prose"` ran as BRE on macOS/BSD grep, where `\|` is a literal pipe, not alternation — it searched for the literal string and matched nothing.
- **Wrong approach**: trusted a "0 matches" result as evidence of absence without confirming the pattern syntax matched the grep flavor in use.
- **Correct approach**: re-ran with `grep -nE 'tightening-prose'` (extended regex) → matched line 49; withdrew the finding.
- **Prevention**: on macOS use `grep -E` for any alternation; treat a surprising "0 matches" that contradicts a plausible expectation as suspect and re-run before reporting verified — a negative grep is not absence until the regex flavor is confirmed.

- **Cause-tag**: subagent-worktree-mutation
- **Symptom**: a RED baseline `claude` subagent (dispatched read-only in intent) wrote `README.md` — the exact artifact `bootstrapping-readme` produces — leaving an unrequested working-tree change.
- **Root cause**: the default `claude`/general-purpose agent type carries Write/Edit; a baseline prompt that says "generate a README" gets taken literally and the file is written.
- **Wrong approach**: trusted that a "baseline" framing keeps the subagent read-only; it did not.
- **Correct approach**: `git checkout -- README.md` to restore; re-dispatched the Layer-2 run with an explicit "do NOT write files, output as text" instruction.
- **Prevention**: dispatch baseline/RED & Layer-2 subagents read-only (`Explore` agent, or forbid writes in the prompt + "output as text"); assert `git status --short` is clean after a baseline run.

## Promoted clusters
