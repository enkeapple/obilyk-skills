# Lessons Learned

Transient backlog of un-promoted candidate rules — newest at the top of `## Entries`. When a `Cause-tag` reaches 3×, **invoke the `writing-lessons` skill** (do not hand-promote): it dispatches an independent promotion review and, on a Promote verdict, authors the rule under `.claude/rules/` via `writing-rules`, **deletes the contributing entries**, and records the tag in `## Promoted clusters`. git keeps deleted entries (`git log -S '<cause-tag>'`); deletion happens only via the skill, inside a confirmed promotion (or this one-time cleanup).

## Entries

## 2026-06-21 — RED baseline subagent overwrote the artifact under test

- **Cause-tag**: subagent-worktree-mutation
- **Symptom**: a RED baseline `claude` subagent (dispatched read-only in intent) wrote `README.md` — the exact artifact `bootstrapping-readme` produces — leaving an unrequested working-tree change.
- **Root cause**: the default `claude`/general-purpose agent type carries Write/Edit; a baseline prompt that says "generate a README" gets taken literally and the file is written.
- **Wrong approach**: trusted that a "baseline" framing keeps the subagent read-only; it did not.
- **Correct approach**: `git checkout -- README.md` to restore; re-dispatched the Layer-2 run with an explicit "do NOT write files, output as text" instruction.
- **Prevention**: dispatch baseline/RED & Layer-2 subagents read-only (`Explore` agent, or forbid writes in the prompt + "output as text"); assert `git status --short` is clean after a baseline run.

## Promoted clusters
