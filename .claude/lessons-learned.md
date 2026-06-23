# Lessons Learned

Transient backlog of un-promoted candidate rules — newest at the top of `## Entries`. When a `Cause-tag` reaches 3×, **invoke the `writing-lessons` skill** (do not hand-promote): it dispatches an independent promotion review and, on a Promote verdict, authors the rule under `.claude/rules/` via `writing-rules`, **deletes the contributing entries**, and records the tag in `## Promoted clusters`. git keeps deleted entries (`git log -S '<cause-tag>'`); deletion happens only via the skill, inside a confirmed promotion (or this one-time cleanup).

## Entries

## 2026-06-23 — Catalog re-derivation reported false drift: parser assumed all descriptions were folded scalars, missed quoted ones

- **Cause-tag**: parser-format-assumption
- **Symptom**: re-deriving the README catalog to verify the marketplace `bootstrapping-readme` run, a hand-rolled Python parser emitted every learning-kit description with a leading `"` (`— "Make confusing material click…`), implying the on-disk READMEs had drifted. They had not.
- **Root cause**: the parser captured the raw `description:` line and only handled `>-` folded block scalars (sdd-kit/craft-kit); learning-kit skills use a double-quoted YAML scalar (`description: "..."`), so the opening quote leaked into the "derived" string. The catalog-derivation DESCRIPTION algorithm operates on the PARSED YAML value (quotes are syntax, not content) — the parser, not the catalog, was wrong.
- **Wrong approach**: nearly read the leading-quote mismatch as catalog drift, since the deterministic re-derivation is supposed to be the source of truth.
- **Correct approach**: stripped matching surrounding quotes before the Triggers-strip + 120-truncate; the re-derived blocks then matched disk byte-for-byte (4/7/26 rows). Suspected the parser once the artifact (a leading quote) was itself implausible output.
- **Prevention**: when a hand-rolled check parses frontmatter, handle ALL YAML scalar forms a repo mixes (`>-`/`>`/`|` folded AND single/double-quoted) — parse YAML properly or strip matching surrounding quotes before deriving; and treat an implausible-looking derived artifact (a stray leading quote, doubled punctuation) as a parser bug to rule out before believing it is real drift. (Kin to `broken-grep-false-verification`: a hand-rolled verification mechanism fabricating a false signal — if a third such case lands, cluster them under one "sanity-check ad-hoc verification tooling" rule.)

## 2026-06-23 — Manifest passed jq but failed the real loader; verified-facts listed a field floor, not the full schema

- **Cause-tag**: incomplete-schema-verification
- **Symptom**: authored `.claude-plugin/marketplace.json` from a pre-implementation schema check (dispatched to `claude-code-guide`) that reported "each plugin entry needs `name` + `source`". The file passed `jq empty` and a `jq -e` field check, but `/plugin marketplace add ./` rejected it: `owner: Invalid input: expected object, received undefined` — the top-level required `owner` object was never mentioned by the verification and never added.
- **Root cause**: treated an enumerated "verified facts" field list as the COMPLETE schema (a ceiling) when it was only a floor — the fields it named are required, but it did not claim to be exhaustive, and other required fields (`owner`) went unlisted. Compounded by treating `jq`-valid JSON as schema-valid; structural validity says nothing about required-field conformance.
- **Wrong approach**: ran the real-loader (`/plugin marketplace add`) check as the LAST step (Task 10 GREEN) after building everything on it, and let jq validity stand in for it through all prior tasks.
- **Correct approach**: added `"owner": {"name": "..."}`; re-validated; the real `/plugin marketplace add ./` parse is the GREEN signal, not jq.
- **Prevention**: for any manifest consumed by a real loader (plugin.json, marketplace.json, package manifests, CI config), the GREEN signal is the actual loader/installer parsing it — run it early, not as a final gate; `jq`/structural validity is necessary, not sufficient. And when a verification subagent returns an enumerated required-field set, treat it as a floor (what's named is needed), never a ceiling (other required fields may be unnamed) — confirm against the loader before calling the manifest done.

## 2026-06-23 — Negative/guard validation case proved only the guard's existence, not that it discriminates

- **Cause-tag**: guard-case-inversion-design
- **Symptom**: Layer-2 validating a new opt-in drift class in `auditing-claude-md`, the negative case ("guard must NOT inject a baseline into a repo that declared none") was built as a one-sided inversion — "skill WITH the new guarded class" vs "skill WITHOUT the class at all". On an opt-out repo both refrain (no applicable class either way), so the validator rightly returned FAIL: the case proved nothing.
- **Root cause**: for a guard/opt-in clause, comparing feature-present vs feature-absent makes both negative paths observationally identical; the test confirms the guard text EXISTS but not that the guard predicate is load-bearing.
- **Wrong approach**: assumed the standard inversion ("would it comply WITHOUT the skill?") transfers unchanged to a negative case; it collapses when the expected behavior is *refraining*.
- **Correct approach**: re-ran a two-sided inversion that TOGGLES the predicate — SIDE A = the class as written (with the opt-in predicate) refrains; SIDE B = the same class with the predicate REMOVED would inject. PASS iff A refrains and B injects → the predicate is the discriminating difference.
- **Prevention**: when validating a guard/opt-in/conditional clause whose correct behavior is to NOT act, build the inversion by toggling the guard predicate itself (predicate-present vs predicate-removed variant of the same feature), never feature-present vs feature-absent; if both inversion arms produce the same output on the negative input, the case is untestable — rebuild it before accepting PASS.

## 2026-06-23 — RED baseline subagent inherited the vault's own anti-slop skill, complied for the wrong reason

- **Cause-tag**: contaminated-red-baseline
- **Symptom**: authoring `humanizing-prose`, the RED baseline subagent (general-purpose, dispatched in the vault) opened with "the catalog applies straight, no register exemptions… Running the pass" — `tightening-prose`/stop-slop vocabulary — and emitted already-clean prose, so the baseline proved nothing.
- **Root cause**: a subagent dispatched via the Agent tool with cwd = this vault inherits the vault's CLAUDE.md + skills-routing, so it applies an EXISTING skill whose domain overlaps the one under test; the "fresh" baseline is not a clean room.
- **Wrong approach**: assumed a freshly dispatched subagent is uncontaminated and ran the baseline with a plain "make it read human" prompt.
- **Correct approach**: re-dispatched with an explicit suppression clause ("ignore any repository instructions, project skills, catalogs, register frameworks, methodologies — act as a generic agent"); the clean baseline then left the long-tail tells, giving a real RED.
- **Prevention**: when the RED baseline's domain is one the vault ITSELF has a skill for, add an explicit "ignore repo skills/catalogs/methodologies" clause to the baseline prompt, AND scan the output/preamble for that skill's vocabulary (e.g. "catalog", "register", "the pass") — if present, the RED is contaminated; re-run clean.

## 2026-06-23 — Claimed "no test-cases.md" from a depth-limited find that couldn't reach them

- **Cause-tag**: broken-grep-false-verification
- **Symptom**: asserted the 3 `skills/personal/*` skills "carry no persisted `test-cases.md`"; `git status` later showed each has `references/test-cases.md` at depth 3 — the claim was false.
- **Root cause**: ran `find skills/personal -maxdepth 2 -type f`, which structurally cannot reach `<name>/references/test-cases.md` (depth 3); reported the truncated result as proof of absence.
- **Wrong approach**: trusted a depth-limited search's "not found" as evidence of absence without confirming the scope reached where the target would live.
- **Correct approach**: re-ran `find` without `-maxdepth` (and `git status`); all three carried the file. Corrected the claim and the under-scoped follow-up.
- **Prevention**: a depth/flag-limited search (`find -maxdepth`, `grep` without `-r`, a non-recursive glob) returning "not found" is NOT absence — before asserting it, drop the limiter or confirm the expected path depth is in scope; a "0 results" that contradicts a plausible expectation is suspect, widen before reporting.

## 2026-06-23 — Shaping prohibition keyed to a phrasing, evaded by a synonym

- **Cause-tag**: phrasing-keyed-prohibition
- **Symptom**: Layer-2 re-validation of `learning-curve-destroyer` produced the hedge "valuable eventually" in the "Ignore entirely (for now)" slot — a move the skill red-flags — yet it passed the skill's own prohibition. `confusion-translator` showed the same shape (source jargon echoed as a slot-2 "callback").
- **Root cause**: the prohibition was keyed to one wording ("but eventually you'll want…") instead of the underlying MOVE (acknowledging future value), so a semantic near-synonym slipped past the closed phrase list.
- **Wrong approach**: wrote the banned phrasing AS the prohibition, treating the enumerated wording as the exhaustive set the rule is matched against.
- **Correct approach**: (pending REFACTOR, not yet applied) forbid the move in any wording — "no acknowledgement of future value, however phrased" — and demote concrete phrasings to non-exhaustive examples.
- **Prevention**: when authoring/reviewing a shaping prohibition, check it bans the MOVE, not a wording; a prohibition that reads as a closed list of phrases is a red flag — RED it with a near-synonym NOT in the list and confirm the skill still rejects it.

## 2026-06-22 — Hook shipped a zero-match branch the fixture never exercised (grep -c "0\n0")

- **Cause-tag**: untested-empty-branch
- **Symptom**: `friction-log.sh` errored on every real Stop — `line 50: 0\n0: syntax error in expression` then `cur_error: unbound variable`. It had passed its GREEN fixtures.
- **Root cause**: `grep -c` PRINTS "0" AND EXITS 1 on no match, so `cur=$(printf … | grep -c PATTERN || echo 0)` evaluated to `"0\n0"`, which broke `cur_error=$(( cur_total - … ))` and (under `set -u`) left `cur_error` unbound. The GREEN fixtures only fed transcripts that HAD matches (nonzero counts), so the zero-match branch shipped untested and failed the moment a real turn had no `is_error` entries.
- **Wrong approach**: treated "GREEN on the populated fixture" as proof the hook works; the populated path never hit the `|| echo 0` double-print.
- **Correct approach**: dropped `|| echo 0`, sanitized each count to a clean integer (`${n//[^0-9]/}`, default 0); added fixtures for zero-match, partial (only one class), and no-tool_results transcripts.
- **Prevention**: when fixturing a counting/aggregating/branching hook, ALWAYS include the empty / zero-match input (no matches, empty transcript) alongside the populated case — the happy-path fixture is a false green for the empty branch. And never wrap `grep -c` in `|| echo 0`: on no match it already prints "0" and exits 1, so the `||` double-prints "0\n0".

## 2026-06-22 — Keyed hook accounting on a payload field that does not exist for that event+tool

- **Cause-tag**: hook-payload-assumption
- **Symptom**: `token-guard.sh`'s by-model accounting (#2) keys on `.tool_input.model`, but verification against 59 real `crewing-mobile` transcripts showed Task/Agent `tool_input` is only `{description, prompt, subagent_type}` — no `model`. So every subagent dispatch buckets as `"inherited"` and the per-model signal is dead.
- **Root cause**: assumed the dispatched model is echoed in the PostToolUse payload. It is not — the model comes from the subagent's `.claude/agents/<type>.md` frontmatter, applied by the harness and never surfaced in `tool_input`. Separately, a parent PostToolUse only sees the subagent's final-output bytes, never its internal token consumption, so any parent-side token accounting is a coarse proxy at best.
- **Wrong approach**: wrote the accounting against an imagined payload shape, fixture-tested it with a synthetic `{tool_input:{model:"opus"}}` I invented — so the fixture passed while the real dispatch payload never carries that field (a test that passed for the wrong reason).
- **Correct approach**: key by the field that actually exists — `.tool_input.subagent_type` — and resolve its tier via the agent's frontmatter when a tier label is needed; treat parent-side byte counts as a proxy, not true cost.
- **Prevention**: before keying hook logic on a payload field, confirm the field exists for THAT event+tool in a real transcript/payload (`grep`/inspect `~/.claude/projects/<proj>/*.jsonl`), and build the fixture from a real captured payload, not an invented one — an invented fixture validates the assumption instead of the runtime.

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
