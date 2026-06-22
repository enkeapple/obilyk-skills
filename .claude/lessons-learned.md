# Lessons Learned

Transient backlog of un-promoted candidate rules — newest at the top of `## Entries`. When a `Cause-tag` reaches 3×, **invoke the `writing-lessons` skill** (do not hand-promote): it dispatches an independent promotion review and, on a Promote verdict, authors the rule under `.claude/rules/` via `writing-rules`, **deletes the contributing entries**, and records the tag in `## Promoted clusters`. git keeps deleted entries (`git log -S '<cause-tag>'`); deletion happens only via the skill, inside a confirmed promotion (or this one-time cleanup).

## Entries

## 2026-06-22 — Security guard matched short tokens as substrings → false-blocked benign commands

- **Cause-tag**: guard-substring-false-positive
- **Symptom**: `security-guard.sh` blocked legitimate read-only hook-test commands three times in one session ("Environment dump combined with network tool", "combines credential file access with network tool"). The commands contained no exfil — only words like "re**set**-turn-budget.sh", "sy**nc**ing", "**enc**oding", "meth**od**".
- **Root cause**: guard regexes matched short tokens as unanchored substrings. `EXFIL_TOOLS` "nc" matched "sync"/"encoding"; Rule 12's `set\b` had a word boundary only on the RIGHT, so it matched the "set" inside "re**set**"; `od` (ENCODE) matched "method"/"code". Combined with a `.claude/(settings|hooks)` path mention or another stray substring, two unrelated fragments on different lines satisfied an AND-rule.
- **Wrong approach**: assumed `(nc|set\b|od|...)` in `grep -E` matches those as commands; it matches them anywhere in the command string, across all lines (`grep -q` scans every line).
- **Correct approach**: word-anchor short tokens on BOTH sides — `(^|[^[:alnum:]_])(curl|nc|scp|…)([^[:alnum:]_]|$)` for EXFIL/ENCODE, same for `env|set|printenv`. Real exfil still matches because the tool appears as a whole command word (`nc evil 443`, `/usr/bin/nc …`); benign substrings no longer do.
- **Prevention**: when authoring or reviewing a guard regex containing short tokens (`nc`, `od`, `set`, `env`, `host`, `ssh`), word-anchor both sides and RED it against benign words that CONTAIN the token as a substring ("reset", "syncing", "method", "settings"), AND regression-test that real exfil (`nc host`, `/usr/bin/nc`, `set | curl`) still blocks. A one-sided `\b` is a red flag — `set\b` still matches "reset".

## 2026-06-22 — Added accounting state to a hook that shares one global state dir across sessions

- **Cause-tag**: hook-state-not-session-keyed
- **Symptom**: extended `token-guard.sh` with `by-model-budget.json` keyed only by model, into the shared `.claude/state` dir alongside `turn-budget`/`session-budget`/`last-prompt` — none keyed by session. Owner asked "what if I run several sessions in parallel"; under concurrent Claude Code sessions these files race and co-mingle.
- **Root cause**: hook state uses fixed global filenames in one `.claude/state` dir. Concurrent sessions interleave read-modify-write (lost increments), one session's `UserPromptSubmit` turn-reset clobbers another mid-turn, `last-prompt.txt` is overwritten so the Stop-hook bypass analysis misattributes the prompt, and session/by-model ceilings sum all sessions at once.
- **Wrong approach**: assumed a single active session when adding accounting state — the same assumption every existing vault hook makes.
- **Correct approach**: (tracked as task #11, not yet applied) key state by `session_id` from the hook stdin — `.claude/state/<session_id>/…` — so turn/session/by-model/last-prompt isolate per session and a new session gets a fresh dir (which also gives session-boundary reset for free).
- **Prevention**: when adding or reviewing any hook that writes to `.claude/state`, confirm the file path is namespaced by `session_id` from the hook input; a fixed global filename is a red flag — it corrupts under parallel sessions. Confirm `session_id` is actually present in that event's payload before keying on it (the vault's `hook-events.md` does not enumerate it).

## 2026-06-22 — Wrote a skill file to a fabricated `.claude/skills/<category>/` path

- **Cause-tag**: skill-path-source-vs-symlink
- **Symptom**: created `test-cases.md` at `.claude/skills/apply-chain/subagent-driven-development/references/…` — a non-existent nested path under the flat-symlink dir; the Layer-2 validation subagent's `find` could not locate it and returned INCONCLUSIVE.
- **Root cause**: spliced the source-tree category segment (`apply-chain/`) onto the symlink prefix (`.claude/skills/`). The two addressing schemes are distinct: source lives at `skills/<category>/<name>/…`; `.claude/skills/` holds only flat per-skill symlinks `.claude/skills/<name>` with NO `<category>/` level.
- **Wrong approach**: assumed `.claude/skills/<name>` generalizes to `.claude/skills/<category>/<name>`, and wrote without checking the symlink target.
- **Correct approach**: relocated the file to the source `skills/apply-chain/subagent-driven-development/references/test-cases.md` (reachable via the `.claude/skills/<name>` symlink) and removed the bogus `.claude/skills/apply-chain` tree.
- **Prevention**: author skill files in the SOURCE tree `skills/<category>/<name>/…`, never under `.claude/skills/<anything-but-the-flat-name>`. Before writing into a skill, run `ls -la .claude/skills/<name>` to read the symlink target and write into that resolved source dir; treat any path of shape `.claude/skills/<seg>/<name>/…` as a red flag.

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

- skill-value-vs-noop → rules/common/scoping-skill-value.md (2026-06-19)
- markdown-fence-counting → rules/common/markdown-style.md (2026-06-19)
