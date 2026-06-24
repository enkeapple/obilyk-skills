# Lessons Learned

Transient backlog of un-promoted candidate rules — newest at the top of `## Entries`. When a `Cause-tag` reaches 3×, **invoke the `writing-lessons` skill** (do not hand-promote): it dispatches an independent promotion review and, on a Promote verdict, authors the rule under `.claude/rules/` via `writing-rules`, **deletes the contributing entries**, and records the tag in `## Promoted clusters`. git keeps deleted entries (`git log -S '<cause-tag>'`); deletion happens only via the skill, inside a confirmed promotion (or this one-time cleanup).

## Entries

## 2026-06-24 — Happy-path-only hook fixtures false-greened a corpus-finalize branch that crashed on every real Stop

- **Cause-tag**: untested-empty-branch
- **Symptom**: `log-skill-usage.sh` Stop hook errored live ("Failed with non-blocking status code"); the prompt corpus (`prompts/YYYY-MM-DD.jsonl`) had NEVER been written since 3a and `pending-prompt.json` was never cleared — yet every 3a/3b fixture passed GREEN.
- **Root cause**: `TRIGGERS_MATCHED=$(jq ... | while read skill trig; do ...; echo "$P" | grep -qiE "$trig" && printf '%s\n' "$skill"; done | jq ...)` — under `set -euo pipefail` the loop's last command is the `grep -q` for the LAST routing entry; on no-match it exits 1, the while inherits 1, pipefail raises it to the `$()`, and set -e kills the hook right after the assignment. Fires for almost any prompt (the last routing skill rarely matches).
- **Wrong approach**: fixtured only the happy path — 3b's GREEN runs omitted `pending-prompt.json` entirely (so the corpus block never executed), and 3a's matched cases never hit a non-matching LAST entry. Both false-greened the broken branch.
- **Correct approach**: `if echo "$P" | grep -qiE "$trig"; then printf '%s\n' "$skill"; fi` so the loop's last command is always exit 0; added a fixture with `pending-prompt.json` present AND a prompt whose LAST routing trigger does not match.
- **Prevention**: fixture a hook's NON-happy path, not just the populated/matching case — for a per-entry loop, a prompt where the LAST entry's trigger misses; and never end a loop body (inside `$()` under set -e+pipefail) with a bare `cmd && action` whose left side can exit non-zero — use `if/then/fi` so the loop's last command is exit 0. (Same class as the grep -c "0\n0" entry: a path the happy-path fixture never exercises ships broken.)

## 2026-06-24 — `nullglob` does NOT drop an explicit absent path listed in a bash array

- **Cause-tag**: shell-glob-assumption
- **Symptom**: build 3b consumer `metrics-report.sh` built `METRICS_FILES=("$DIR"/metrics/*.jsonl "$DIR"/_metrics.jsonl)` under `shopt -s nullglob`; the cold-reviewer (plan gate) showed that on empty-state / post-rotation the array keeps the literal non-existent `_metrics.jsonl`, so `(( ${#arr[@]} > 0 ))` is true and `jq -rs "${arr[@]}"` crashes `No such file or directory` — the very empty-state the spec must handle.
- **Root cause**: assumed `nullglob` suppresses any absent entry. It only removes a GLOB that matches nothing; an EXPLICIT literal path (no wildcard) is never expanded, so it stays in the array verbatim whether or not the file exists.
- **Wrong approach**: listed the optional legacy file as a literal element inside the nullglob array, trusting nullglob to drop it when missing — and put the same wrong contract in both spec and plan.
- **Correct approach**: glob-only array `("$DIR"/metrics/*.jsonl)`, then append the optional explicit file conditionally: `[[ -f "$DIR/_metrics.jsonl" ]] && arr+=("$DIR/_metrics.jsonl")`.
- **Prevention**: never list an OPTIONAL explicit path inside a nullglob array — nullglob only suppresses wildcard patterns, not literals; append optional files via `[[ -f ]] && arr+=(...)`. Always execute the empty-state path (zero files) and confirm no non-existent literal reaches the downstream consumer. (Reviewer-diversity caught this — see model-selection.md: a different-model cold reviewer found the author's own wrong assumption.)

## 2026-06-24 — `. lib || exit 0` fails CLOSED under set -e (`.` is a POSIX special builtin)

- **Cause-tag**: errexit-failopen-idiom
- **Symptom**: extracting a shared `hooks/lib/common.sh`, the 4 hooks under `set -euo pipefail` exited **1** (not 0) when the lib was absent — a fail-open violation — while the 3 `set -uo` hooks exited 0. The missing-lib fixture (Task 5) caught it; the design, spec, plan, and an independent readiness review had all blessed the wrong idiom.
- **Root cause**: `.`/`source` is a POSIX **special builtin**; under `set -e` its open-failure (missing/unreadable file) terminates the shell with status 1 BEFORE the trailing `|| exit 0` — even `if ! . lib` — can run. So `. lib 2>/dev/null || exit 0` fails CLOSED under errexit.
- **Wrong approach**: used `. lib 2>/dev/null || exit 0` as the uniform "fail-open" source idiom; it reads as obviously-fail-open and survived four reasoning passes (design/spec/plan/readiness) because none of them executed the missing-lib case.
- **Correct approach**: guard readability with an ordinary builtin first — `L="${BASH_SOURCE[0]%/*}/lib/common.sh"; [ -r "$L" ] || exit 0; . "$L"`. `[ -r ]`'s `|| exit 0` runs normally; the unconditional `.` then only runs on a readable file.
- **Prevention**: never rely on `<special-builtin> || exit 0` for fail-open under `set -e` (`.`/`source`, `eval`, `exec`, `:`); guard the precondition with an ordinary `test`/`[ ]` first. And ALWAYS prove fail-open by EXECUTING the failure (run the hook with the file missing → assert exit 0), never by eyeballing the `||` — a missing-input fixture per fail-open path is mandatory.

## 2026-06-24 — Placed a new writing-* skill in a kit by topical surface, not its naming-family

- **Cause-tag**: skill-kit-placement
- **Symptom**: authored `writing-adrs` under `craft-kit/skills/design/` (next to `codebase-design`/`improve-codebase-architecture`) because ADRs are "architectural"; owner corrected — "why craft-kit if it should be sdd-kit?".
- **Root cause**: chose the kit by topical resemblance instead of the established naming-family. Every `writing-*` artifact-authoring skill (writing-specs/plans/rules/lessons/hooks/skills) lives in sdd-kit; a new `writing-<artifact>` is their sibling and belongs in `sdd-kit/skills/authoring`.
- **Wrong approach**: matched on the word "architecture" → craft-kit (vocabulary/review/prose), ignoring that the `writing-*` family is the load-bearing placement signal.
- **Correct approach**: moved to `sdd-kit/skills/authoring/writing-adrs`; updated both plugin.json manifests + the routing `plugin` field.
- **Prevention**: before choosing a kit/dir for a new skill, grep the existing skill names for a naming-family the new name joins (`find plugins/*/skills -name SKILL.md`); place by that family first, fall back to topical/register grouping only when no family applies.

## 2026-06-23 — Classified discipline skills as "technical docs" and assumed their prose punch was load-bearing

- **Cause-tag**: discipline-binding-is-structural
- **Symptom**: asked to run `humanizing-prose` over the learning-kit skills, I classified the SKILL.md bodies as "technical docs", nearly refused the edit, and warned that cutting the punchy rhetoric (dramatic fragments "Kill it."/"Suppress it.", binary-contrast openers) would break binding. Owner corrected: "те скиллы не должны быть техническими".
- **Root cause**: conflated a discipline skill's *voice* (punchy imperative prose) with its *binding mechanism*. Assumed the dramatic fragments and contrast openers were load-bearing, when the binding actually lives in the structural prohibitions + rationalization table + red flags. Treated a register question as settled by taste rather than by test.
- **Wrong approach**: argued from the `humanizing-prose` "technical doc → use tightening-prose" carve-out that the skills were off-limits, without testing whether a humanized version still binds.
- **Correct approach**: ran it test-first — per-skill pressure RED + Layer-2 inversion across all 9 skills. Every humanized version still complied under pressure while the no-skill control failed; the loud fragments were removable with no regression, so all 9 were kept.
- **Prevention**: a voice/register/de-slop edit to a `SKILL.md` is still a skill edit → Iron Law, RED-first. Decide whether a stylistic element is load-bearing with a binding pressure-test (RED + would-comply-WITHOUT inversion), never by assertion; expect the structural prohibition set (prohibitions + rationalization table + red flags), not the prose punch, to carry the discipline.

## 2026-06-23 — Linked a skill from a rule via a deep in-tree plugin path instead of its canonical name

- **Cause-tag**: dev-source-vs-consumer-routing
- **Symptom**: authored `.claude/rules/common/resolving-requirements-flibco-source.md` with a markdown link `[…](../../../plugins/sdd-kit/skills/chain/resolving-requirements/SKILL.md)`; owner flagged it — "вот такого не должно существовать, на крайняк референс просто на скилл без путей".
- **Root cause**: same conflation as the routing variant — treated the dev repo's in-tree plugin source path as a stable address. A plugin skill's body ships in the install cache, not under `plugins/` for a consumer; a deep relative path to `plugins/*/skills/**/SKILL.md` resolves only in THIS dev tree and is a dead reference everywhere else. The canonical address of a skill is its NAME (the routing key), not a filesystem path.
- **Wrong approach**: reached for the habitual markdown file-link to "let the reader open the skill", deep-linking into the plugin tree.
- **Correct approach**: cite the skill by bare backtick name (`resolving-requirements`); dropped the link and the `../../../plugins/...` path entirely — the rule reads fine without it.
- **Prevention**: in any rule/doc, reference a skill by its canonical name, never via a path into `plugins/*/skills/**` (or `SKILL.md`). Grep the body: `grep -nE '\]\([^)]*plugins/[^)]*skills|\.\./\.\./' <file>` must be empty. (Same class as the routing variant: dev source tree vs the address another layer/consumer expects.)

## 2026-06-23 — Modeled plugin-provided skills as kind:local with in-repo files paths in a consumer routing file

- **Cause-tag**: dev-source-vs-consumer-routing
- **Symptom**: in the consumer-side `.claude/skills-routing.json` (read by hooks from `$CLAUDE_PROJECT_DIR`) all 25 plugin skills were set `kind:"local"` with `files: ["plugins/<kit>/skills/.../SKILL.md"]`; owner flagged it — that path won't exist when the file is a real consumer's config.
- **Root cause**: conflated "this dev repo contains the plugin source in-tree" with "the consumer routing should point at it." A plugin skill's body lives in the install cache, not under `plugins/` in a consumer; an in-repo `files` path is a dead reference and mis-models a plugin skill as locally-authored.
- **Wrong approach**: approved design D4 as "local with real plugin paths" and wrote spec+plan on it; the in-repo paths even resolved in THIS dev repo, masking the error until the concrete file made it visible.
- **Correct approach**: plugin-provided ⇒ `kind:"ref"` (`plugin`+`name`+`triggers`, NO `files`); `local` only for skills authored in the consumer's own `.claude/skills/<name>/`. Reverted via a spec+plan loop-back and a redone task.
- **Prevention**: for each routing entry ask "does the body ship in an installed plugin, or is it authored in THIS repo?" Plugin ⇒ `ref`, no `files`. Local ⇒ `files` must resolve from the CONSUMER root, never a dev-tree-only path. (Kin to `skill-path-source-vs-symlink`: dev source tree vs the addressing another layer expects.)

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

## 2026-06-21 — RED baseline subagent wrote README.md (default agent type carries Write/Edit)

- **Cause-tag**: subagent-worktree-mutation
- **Symptom**: a RED baseline `claude` subagent (dispatched read-only in intent) wrote `README.md` — the exact artifact `bootstrapping-readme` produces — leaving an unrequested working-tree change.
- **Root cause**: the default `claude`/general-purpose agent type carries Write/Edit; a baseline prompt that says "generate a README" gets taken literally and the file is written.
- **Wrong approach**: trusted that a "baseline" framing keeps the subagent read-only; it did not.
- **Correct approach**: `git checkout -- README.md` to restore; re-dispatched the Layer-2 run with an explicit "do NOT write files, output as text" instruction.
- **Prevention**: dispatch baseline/RED & Layer-2 subagents read-only (`Explore` agent, or forbid writes in the prompt + "output as text"); assert `git status --short` is clean after a baseline run.

## Promoted clusters

- contaminated-red-baseline → rules/common/fair-red-baseline.md (2026-06-24)
- broken-grep-false-verification → rules/common/search-scope-verification.md (2026-06-23)
- skill-value-vs-noop → rules/common/scoping-skill-value.md (2026-06-19)
- markdown-fence-counting → rules/common/markdown-style.md (2026-06-19)
