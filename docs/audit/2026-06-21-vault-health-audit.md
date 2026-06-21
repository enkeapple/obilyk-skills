# Vault Health Audit & Improvement Roadmap — 2026-06-21

> **Mode:** read-only AUDIT artifact (not an implementation change).
> **Lens:** health first (defects present today), then expansion (coverage gaps). Each finding carries `file:line` evidence verified this session.
> **Relationship to the existing roadmap:** this complements [docs/plans/2026-06-21-vault-roadmap.md](../plans/2026-06-21-vault-roadmap.md), which is an *expansion* roadmap gated on a future dogfood RED. That roadmap asserts the vault is "structurally clean … no defects worth pre-empting" (line 8, 16). This audit's central finding is that the claim is **overstated**: a deeper read surfaced ~7 confirmed present defects. Crucially, the Iron-Law "no work without an observed RED" gate applies to *speculative expansion* — it does **not** apply to fixing a confirmed defect whose evidence is already in hand. Those are bugs, not hypotheses.

## Summary

A six-way fan-out audit (apply-chain · foundation+authoring · design+prose+entrypoints · rules · hooks+harness · cross-cutting coverage), each finder citing `file:line`, with the load-bearing findings re-verified directly this session.

**Verdict:** the vault is structurally sound (28 skills pass name/symlink/routing invariants), but it is **not** defect-free. There are concrete, fixable-now health defects — most notably a rule that may never fire, four hooks that fail *closed* instead of open, a routing-table omission, and a chain-threshold claim that is false. Separately, the single most consequential *expansion* gap (no "adopt the framework into a new repo" skill) is absent from the existing watchlist.

| Priority | Count | Class |
| --- | --- | --- |
| P0 | 1 (DONE) | Discipline-enforcing rule never loaded — `agnostic-skill-authoring` `paths` (F1, fixed) |
| P1 | 5 confirmed (ALL DONE) | Fail-closed hooks (F2), dangling lesson cite (F4), false threshold claim (F6), dropped provenance (F7), missing onboarding skill (F19) — all fixed |
| P2 | 11 | Consistency / polish / minor coverage |
| Withdrawn | 2 | F3 (routing row exists at CLAUDE.md:49) and F5 (unlinked test-cases.md is convention) — both false positives caught on re-verification |

The full prioritized list is in [Recommendations](#recommendations). Findings already parked on the existing watchlist (H1–H6, S1–S2, M1–M4) are **not** re-raised here — only cross-referenced.

> **Verification note (2026-06-21):** while executing the clean-up wave, two "verified" P1s proved false on re-check — F3 (a `grep` run with BSD-incompatible `\|` alternation reported a phantom "absent" row) and F5 (treating a convention as a defect). Both are now withdrawn above. The remaining findings were re-confirmed by direct read; the broken-grep class is captured as a lesson.

## Inventory (baseline, verified this session)

- **Skills — 28**, in 7 category folders: `apply-chain` (10), `foundation` (6), `authoring` (4), `design` (2), `prose` (1), `entrypoints` (4), plus the orchestrator/loop members of apply-chain. Discovered via flat symlinks under `.claude/skills/`.
- **Routing** — `.claude/skills-routing.json`: 23 trigger-routed keys; the 5 un-routed skills (`improve-codebase-architecture` + the 4 `/sdd /grill /spec /audit` aliases) are exactly the `disable-model-invocation: true` set — correct.
- **Rules — 11**: 2 domain (`glossary.md`, `framework.md`) + 9 common (`markdown-style`, `skill-routing-sync`, `git-conventions`, `interactive-gates`, `phase-task-visualization`, `agnostic-skill-authoring`, `rule-self-containment`, `scoping-skill-value`, and the WIP). (The existing roadmap's "8 common" count at line 13 is stale.)
- **Hooks — 11**, in `guards/ quality/ routing/ session/`, all symlinked into `.claude/hooks/` and wired in `settings.json`. `ruleGates` is `{}`.
- **Docs** — `docs/plans/2026-06-21-vault-roadmap.md` exists (untracked); `docs/specs/` is empty (specs deleted in commit `2a6304a`); this is the first `docs/audit/` artifact.

## Method

1. **Fan-out** — six independent subagent finders, one per area, each instructed to cite real `file:line`, classify HEALTH vs EXPANSION, and propose a direction. No finder saw another's output.
2. **Synthesis + dedup** — merged 30+ raw findings; dropped duplicates and anything already on the existing watchlist (cross-referenced instead of re-raised).
3. **Adversarial re-verification** — every P0/P1 finding was re-checked directly this session (grep/script-run/file-read), not trusted on the finder's word. Hook fail-open behavior was confirmed by piping garbage stdin and reading the exit code. Findings that survived are marked **verified**; finder-only `file:line` cites that were not independently re-run are marked **finder-cited**.
4. **Prioritization** — `P = severity × leverage ÷ effort`. P0 = breaks a stated discipline *now*; P1 = notable leak/gap, high leverage, cheap-to-fix; P2 = consistency/polish.

## Findings

### Health — confirmed defects

**F1 · `agnostic-skill-authoring` rule is scoped to a path real skill edits never match · P0 · verified · DONE (2026-06-21)**
- **Resolution (minimal):** body prose left exactly as it was (still references `.claude/skills/...`); the only change is `paths` gains a second glob so it actually fires. `paths` now lists **both** `skills/**/*.md` (the real source path edits use today — the previously-missing match) **and** `.claude/skills/**/*.md` (the original symlink glob, kept as a hedge for a future move to editing via `.claude/skills`). Net diff: +1 line. Verified: a real skill path (`skills/authoring/writing-skills/SKILL.md`) now matches the first glob.
- Evidence: `.claude/rules/common/agnostic-skill-authoring.md:4` → `paths: ['.claude/skills/**/*.md']`. Real skill files live at `skills/<cat>/<name>/SKILL.md`; `.claude/skills/<name>` is only a flat symlink. The sibling rule `.claude/rules/common/scoping-skill-value.md` correctly uses `paths: ['skills/**/SKILL.md']`, and `glossary.md:27` documents the migrated convention (`source skills/*/<name>/SKILL.md … discovered via flat symlink`).
- Impact: a path-scoped rule loads when the in-hand edited path matches its glob. An edit to `skills/authoring/.../SKILL.md` does not match `.claude/skills/**`, so the rule enforcing **non-negotiable #2 (agnostic-by-default)** likely never fires during the one activity it governs — skill authoring. Project leakage goes uncaught by the rule meant to catch it. (Severity assumes the loader matches the in-hand source path, not a symlink alias — the convention mismatch between the two sibling rules is confirmed regardless.)
- Direction: change `paths` to `['skills/**/SKILL.md']` (or `skills/**/*.md` to also cover `references/`); fix the 5 stale `.claude/skills/...` path references in the body (lines 2, 4, 11, 38, 45).

**F2 · Four session/routing hooks fail *closed* (exit 5) on malformed stdin · P1 · verified · DONE (2026-06-21)**
- **Resolution (test-first via `writing-hooks`):** RED confirmed all four exit 5 on garbage stdin; added a uniform fail-open guard right after each `INPUT=$(cat)` — `INPUT=$(cat 2>/dev/null) || exit 0` + `printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1 || exit 0`. GREEN: all four now exit 0 on garbage **and** empty stdin, valid stdin still behaves, and stderr is clean (no jq spam). `bash -n` clean on all four. Source files edited under `hooks/` (the `.claude/hooks/` symlinks already point at them; no wiring change). For `reset-turn-budget` the guard sits after the state-reset block, so a malformed prompt event still resets per-turn state.
- Evidence (re-run this session): `printf garbage | … token-guard.sh` → `exit=5`; same for `detect-bypass.sh`. `log-skill-usage.sh` and `reset-turn-budget.sh` share the pattern. Cause: `set -euo pipefail` (`hooks/session/token-guard.sh:6`, `hooks/routing/detect-bypass.sh:8`) + an unguarded `jq` on `$(cat)`. The guard hooks (`skill-gate.sh:39`, `lessons-nudge.sh:19`) correctly fail open with `2>/dev/null || exit 0` — the contract these four violate.
- Impact: on a malformed event the routing-bypass detector and the budget tracker die noisily (raw `jq: parse error` to the model) instead of no-op'ing. PostToolUse/Stop nonzero doesn't block work, but self-instrumentation silently stops and the model sees parser spam. `reset-turn-budget` failing means per-turn state may not reset, degrading every downstream routing hook that turn.
- Direction: guard the first parse (`INPUT=$(cat 2>/dev/null) || exit 0`) in all four; test-first via `writing-hooks` (garbage-stdin fixture → assert exit 0).

**F3 · ~~`tightening-prose` absent from the CLAUDE.md routing table~~ · WITHDRAWN — FALSE POSITIVE (2026-06-21)**
- **Correction:** the row exists at `CLAUDE.md:49` (`| De-slop an existing chunk of prose (remove the AI tells) | tightening-prose |`). The original "verified grep=0" was a **broken verification**: `grep -c "tightening-prose\|prose"` was run with BRE on macOS/BSD grep, where `\|` is a *literal* `|`, not alternation — so it searched for the literal string `tightening-prose|prose` and found nothing. Re-run with `grep -nE 'tightening-prose'` → matches line 49. No defect; no change made.
- **Lesson:** negative grep results on this platform must use `grep -E` for alternation; a "0 matches" that contradicts a plausible expectation gets re-run before being reported as verified.

**F4 · `scoping-skill-value` rule cites lesson entries that were deleted on promotion · P1 · verified · DONE (2026-06-21)**
- **Resolution:** the dangling parenthetical "(3 instances in [lessons-learned.md])" at `scoping-skill-value.md:17` was removed; the cause-tag is now restated self-contained as "the recurring `skill-value-vs-noop` failure class this rule was promoted from and now owns" — no pointer to deleted lesson entries, satisfying `rule-self-containment`.
- Evidence: `.claude/rules/common/scoping-skill-value.md:17` → "the recurring `skill-value-vs-noop` failure (3 instances in lessons-learned.md)". But `grep -c skill-value-vs-noop .claude/lessons-learned.md` → `0`; git shows the tag was promoted into this very rule on 2026-06-19 and its contributing entries deleted per the promotion discipline.
- Impact: a dangling self-justification — the pointer resolves to nothing. Exactly the rot `rule-self-containment.md` warns of; a promoted rule pointing back at its own now-deleted source lessons undermines itself.
- Direction: drop the count + lessons link; restate the cause-tag as promoted-and-owned-here ("the `skill-value-vs-noop` class this rule was promoted from").

**F5 · ~~Orphan `references/test-cases.md` in `bootstrapping-readme`~~ · WITHDRAWN — FALSE POSITIVE (2026-06-21)**
- **Correction:** an unlinked `test-cases.md` is the **convention**, not a defect. Four skills carry `references/test-cases.md` (`grilling`, `writing-skills`, `bootstrapping-readme`, `tightening-prose`); only `writing-skills` forward-links it — `grilling` and `tightening-prose` also leave theirs unlinked. `test-cases.md` is the *persisted Layer-2 validation artifact* (the cases a fresh validation subagent runs per the Completeness Checklist), deliberately not skill content the SKILL.md body points users at. The forward-link validator does not require it, and its absence is shared by 3 of 4 such skills. No defect; no change made.

**F6 · The small-change threshold is enumerated three different ways, and `grilling` falsely claims they are "the same" · P1 · verified · DONE (2026-06-21)**
- **Resolution (test-first via `writing-skills`):** converged all three skills on the canonical 4-part off-ramp predicate, **each stated self-contained** — `writing-specs` "When NOT to use" rewritten from the narrow one-line/cosmetic list to the full predicate (trivial cases kept as the floor); `pre-implementation-protocol` PATH B "Route" restated in the same terms; all three now define **a source file plus its own test as one test-first cycle, not "multi-file"** — the exact ambiguity that caused the mis-classification. **RED** (fresh subagent): the three disagreed on a borderline debounce change (grilling→TDD, writing-specs→"spec needed", pre-implementation→ambiguous), confidence "moderate". **GREEN** (fresh subagent): all three route to TDD for the same reason (the carve-out), confidence "high". **Post-GREEN correction (owner):** the first pass made grilling's false "same threshold as `writing-specs`/`pre-implementation`" claim *true* by cross-referencing them — but that couples the skills' content. Reverted to **no cross-references**: each skill states the identical predicate independently, so consistency holds by construction without any skill naming another's threshold.
- Evidence: `grilling/SKILL.md:63` claims its off-ramp predicate "is the same small-change threshold `writing-specs` ("When NOT to use") and `pre-implementation-protocol` (PATH B) already use". But `writing-specs/SKILL.md:30-31` "When NOT to use" lists only "One-line fixes, typo/format/rename" + "Cosmetic tweaks confined to a single file" — far narrower than grilling's 4-part off-ramp (single behavior · no shared contract · no new surface · one TDD cycle). `writing-specs` then states a *third*, different bar at `:90` ("beyond small = more than one surface/module, or a shared contract"). `pre-implementation-protocol:46` paraphrases it a fourth way.
- Impact: the "consistent across the chain" guarantee is false; a reader trusting it mis-routes borderline non-cosmetic single-behavior changes. (Distinct from watchlist S1/S2 — this is a concrete contradiction, not a coherence hypothesis.)
- Direction: factor the predicate into one canonical list (a shared rule or one owning skill) and cross-reference it from the other three.

**F7 · `resolving-requirements` provenance is dropped at the `writing-specs` boundary · P1 · verified · DONE (2026-06-21)**
- **Resolution (decided: add field + check):** added a **conditional `## Source` section** to the spec template (`source`/`revision`/`ticket`/`files`, copied verbatim from the `resolving-requirements` provenance block; omitted for a free-text idea) and a matching section-0 in `writing-specs`. `spec-drift-audit` gained: parse the Source block, a "Trace to source" process step, a **Source drift** classification (a source requirement absent from both spec and code), and a "Source trace" report item. `resolving-requirements:38`'s stale "no downstream slot exists" parenthetical was corrected to point at the new slot. **RED**: structural — the template had no slot and `resolving-requirements` itself documented the gap (read this session). **GREEN** (fresh subagent): provenance survives verbatim into the spec; a dropped acceptance criterion absent from both spec and code is caught as Source drift (a class spec↔code-only audit is blind to); free-text → Source omitted.
- Evidence: `resolving-requirements/SKILL.md:36-47` produces a provenance block, then `:38` itself notes "writing-specs defines no dedicated provenance field and spec-drift-audit traces code↔spec, not spec↔source". Confirmed: `writing-specs/SKILL.md:37-48` required sections have no provenance slot; `spec-drift-audit/SKILL.md:40` parses Goal/Scope/Contracts/Files/Verification — no source trace.
- Impact: the traceability this skill exists to protect evaporates one hop downstream — a leaky hand-off the skill flags but does not resolve. (Overlaps watchlist H1, but here it is a *confirmed present drop*, not a hypothesis to watch.)
- Direction: add an optional "Source / provenance" field to the spec template + a spec↔source check to `spec-drift-audit`; or explicitly scope provenance as chat-only and soften the "keeps every later artifact grounded" claim.

### Health — consistency / minor (P2)

| ID | Finding | Evidence | Direction |
| --- | --- | --- | --- |
| F8 | `grilling` off-ramp routes straight to TDD, bypassing `pre-implementation-protocol` PATH B (which exists for exactly the no-plan single-behavior case, with a baseline/layer-map pre-flight grilling skips) | `grilling/SKILL.md:57` vs `pre-implementation-protocol/SKILL.md:42-47` | route the off-ramp through PATH B, or document why it deliberately skips the pre-flight |
| F9 | `sdd-lifecycle` orchestrator has no branch for grilling's off-ramp — its fixed 7-phase set assumes spec+plan are mandatory | `sdd-lifecycle/SKILL.md:44,52-60` | add an off-ramp branch (mark spec/plan/readiness skipped → implement) |
| F10 | Asymmetric completion rigor: `subagent-driven-development` dispatches a whole-change final reviewer; `inline-driven-development` goes straight to the audit with no whole-change review | `subagent-driven-development/SKILL.md:87` vs `inline-driven-development/SKILL.md:48` | add a whole-change self-review to inline's Complete step, or note why it's subagent-only |
| F11 — **WON'T FIX (reverted)** | Authoring methodology drift: `writing-skills` mandates a persisted `test-cases.md` (Red Flag if absent), but `writing-rules`/`writing-hooks` (its specializations) waive it without saying so | `writing-skills/SKILL.md:42,100` | attempted fix added a note in each child referencing `writing-skills`' internal requirement — **owner rejected**: a skill must not couple to another skill's internal content/mandate to justify itself. Reverted. Each skill's own test approach stands alone; the mild inconsistency is accepted over a fragile cross-skill reference |
| F12 | Terminology collision: `writing-skills` "Layer 1/Layer 2" (validator passes) vs `writing-rules` "two-layer review" (self + cold reviewer) — same numbering, different referents | `writing-skills/SKILL.md:57-67` vs `writing-rules/SKILL.md:73-75` | rename one axis |
| F13 — **ACCEPTED (no action)** | `ruleGates` is `{}` — ~75 lines of `skill-gate.sh` barrier logic (pass 1 + pass 2) are dead; the only live PreToolUse deny is the `/memory/` block | `jq '.ruleGates'` → `{}`; `hooks/routing/skill-gate.sh:70-144` | decision: leave empty — already documented as intentional in `.claude/CLAUDE.md` ("ruleGates currently empty — no code-domain edit gates, no `src/`") and the roadmap. Wiring the barrier is a gated expansion, not a defect fix; the passes stand as consumer-repo scaffolding |
| F14 — **DONE (2026-06-22)** | `markdown-style` Review Checklist grep is not runnable as written (`**/*.md` needs globstar; matches its own ❌ example) | `markdown-style.md:70` | fixed: `grep -rnE '\|-{2,}\|' --include='*.md' .` + note fenced examples are expected hits |
| F15 — **DONE (2026-06-22)** | `test-driven-development` long TS example has no "illustrative" marker, unlike sibling skills that mark theirs | `test-driven-development/SKILL.md:66-90` | fixed: added "illustrative — use the consumer repo's real language/runner" note right above the block |
| F16 — **ACCEPTED (no action)** | `allowed-tools` inconsistency: `writing-rules`/`writing-lessons` declare none though they dispatch subagents / run bash, while `writing-skills`/`writing-hooks` declare the full set | `grep -L allowed-tools` over the authoring skills | decision: leave as inherit-all. `allowed-tools` is an optional restrictive lever; omitting it grants all tools, which is exactly what these two need (Bash + Skill + Task). Adding a restrictive set risks cutting a tool they use — absence is the safe default, not a defect |
| F17 — **DONE (2026-06-22)** | `spec-drift-audit` declares `allowed-tools: …, Bash` while promising read-only ("does not edit code") — `Bash` is write-capable | `spec-drift-audit/SKILL.md:9,14-16` | fixed: documented that `Bash` is only for running verification commands / read-only inspection, never edits |
| F18 — **DONE (2026-06-22)** | `edit-write-guard.sh` is a 7-line hook with no header/contract comment, unlike every sibling guard (behavior is correct) | `hooks/guards/edit-write-guard.sh` | fixed: added the standard header (purpose/event/exit codes/fail-open); behavior re-verified (block .env→2, allow→0, garbage→0) |

### Expansion — genuinely novel (not on the existing watchlist)

| ID | Gap | Why it matters | Direction |
| --- | --- | --- | --- |
| F19 · P1 · **DONE (2026-06-21)** | No "adopt the framework into a new consumer repo" meta-skill | The 3 `bootstrapping-*` skills exist but nothing sequenced them. **Resolved:** authored `skills/foundation/adopting-framework/SKILL.md` (ordered recipe: pre-flight → copy → symlinks+reconcile → wire hooks → glossary→claude-md→readme bootstraps → routing sync → GREEN-run verify), test-first via `writing-skills`. RED (fresh subagent, no skill): inferred/guessed the entire sequence, flagged the missing orchestrator. GREEN (fresh subagent, with skill): follows the pinned order, no inference, behavioral acceptance, guard-block escalated. Wired: flat symlink + `skills-routing.json` entry + CLAUDE.md routing row; Layer-1 validators pass (name===dir===symlink, frontmatter 520B, links resolve, 749 words). | done |
| F20 · P2 | No reusable agent definitions (`.claude/agents/` does not exist) | 10 reviewer/role personas live as duplicated `assets/*-prompt.md` prose (e.g. spec-reviewer duplicated across `writing-specs` and `subagent-driven-development`) — drift risk, no single place to harden a reviewer contract | introduce `.claude/agents/` types (`spec-reviewer`, `code-reviewer`) referenced by the prompt assets |
| F21 · P2 | `_metrics.jsonl` is write-only — no skill consumes it | `detect-bypass.sh`/`log-skill-usage.sh` write it; nothing reads it. The "surface bottlenecks" goal has a write-only telemetry channel; the roadmap assumes a manual read-out but plans no skill | a small `metrics-review` skill (or extend an auditor) summarizing bypass/unused/over-invoked skills |
| F22 · P2 | No standalone whole-change code-review skill | `spec-drift-audit` checks code↔spec only; `code-quality-reviewer-prompt.md` is scoped per-task inside `subagent-driven-development`. An inline-executed change, or any non-drift review, has no routable quality pass | promote the per-task reviewer into a `code-review` skill, or fold it into `spec-drift-audit`'s report |
| F23 · P2 | No deprecation/deletion authoring path | `writing-skills`/`writing-rules` cover create/edit/promote but neither owns "retire a skill/rule safely" (routing entry + symlink + cross-ref cleanup); `skill-routing-sync` handles only the routing mechanics | add a delete/deprecate branch to `writing-skills`/`writing-rules` |
| F24 · P2 | Asymmetric entrypoint aliases | `/sdd /grill /spec /audit` exist but not `/resolve` (front-door `resolving-requirements`) or `/plan` (`writing-plans`) | add `/resolve`, `/plan` if full alias parity is wanted (judgment call) |

## Recommendations

Prioritized, fix-now-eligible (these are confirmed defects, not watchlist hypotheses — they need no dogfood RED before action). Each row names the next chain skill that owns the fix.

| Rank | Item | Priority | Effort | Leverage | Owning skill for the fix |
| --- | --- | --- | --- | --- | --- |
| 1 | **F1** — repoint `agnostic-skill-authoring` `paths` to `skills/**` — **DONE (2026-06-21)** | P0 | XS | Restores enforcement of a core non-negotiable | `writing-rules` |
| 2 | **F2** — make the 4 hooks fail open on garbage stdin — **DONE (2026-06-21)** | P1 | S | Stops silent self-instrumentation loss + model spam | `writing-hooks` (fixture-first) |
| 3 | ~~**F3** — add `tightening-prose` to routing table~~ — **WITHDRAWN (false positive; row exists at CLAUDE.md:49)** | — | — | — | — |
| 4 | **F4** — de-dangle `scoping-skill-value`'s lessons cite — **DONE (2026-06-21)** | P1 | XS | Removes self-undermining pointer | `writing-rules` |
| 5 | ~~**F5** — wire or remove orphan `test-cases.md`~~ — **WITHDRAWN (false positive; unlinked test-cases.md is the convention)** | — | — | — | — |
| 6 | **F6** — unify the small-change threshold into one canonical predicate — **DONE (2026-06-21)** | P1 | M | Removes a false cross-chain guarantee | edits to 3 skills via `writing-skills` |
| 7 | **F7** — add `Source/Provenance` spec field + code↔source check — **DONE (2026-06-21)** | P1 | M | Closes the traceability leak `resolving-requirements` flags | `writing-specs` + `spec-drift-audit` |
| 8 | **F19** — author an `adopting-framework` onboarding skill — **DONE (2026-06-21)** | P1 | M | The framework's reusability goal | `writing-skills` (RED via a fresh-repo dogfood) |
| 9 | **F8–F18** — consistency/polish batch | P2 | S–M each | Incremental coherence | per-row owning skill |
| 10 | **F20–F24** — expansion candidates | P2 | M each | Consolidation / coverage | `writing-skills` / `writing-hooks`, gated on a RED where it's a new capability |

**Sequencing note:** F1–F5 are XS/S "clean-up wave" — independent, cheap, no RED needed; do them first. F6/F7 touch the chain contract and should each run through the normal `writing-specs`/`writing-rules` test-first loop. F19–F24 are the only items that should respect the existing roadmap's Iron-Law gate (a new *capability* wants an observed RED) — except F19, whose RED is trivially producible (try to onboard a fresh repo and watch it fail).

### Prioritized action plan (waves)

A concrete execution order. Each wave gates the next only where a dependency is noted; within a wave, items are independent and parallelizable.

| Wave | Items | Priority | Total effort | Gate to start | RED needed? | Rationale |
| --- | --- | --- | --- | --- | --- | --- |
| **A — Clean-up** | ~~F1~~ (done), ~~F4~~ (done), ~~F3~~ (withdrawn), ~~F5~~ (withdrawn) | P0–P1 | XS | none — defects with evidence in hand | No | **Complete.** F1 + F4 fixed; F3 and F5 were false positives on re-verification (F3: BSD-grep alternation bug; F5: unlinked test-cases.md is convention). |
| **B — Harness fail-open** | ~~F2~~ (done) | P1 | S | Wave A done | Fixture (garbage-stdin → exit 0) via `writing-hooks` | **Complete.** All four hooks fail open; verified by fixture run. |
| **C — Chain contract** | ~~F6~~ (done), ~~F7~~ (done) | P1 | M each | run each through the test-first loop | No (defects), but test-first loop applies | **Complete.** F6 (threshold unified) + F7 (provenance Source slot + Source-drift audit), both RED→GREEN. |
| **D — Onboarding** | ~~F19~~ (done) | P1 | M | Waves A–C | Yes — produced (RED: fresh subagent inferred the sequence) | **Complete.** `adopting-framework` authored + wired; RED→GREEN via `writing-skills`. README catalog regen pending (see follow-up). |
| **E — Polish** | F8–F18 | P2 | S–M each | none; opportunistic | No | **Partly done.** Fixed: F14, F15, F17, F18. Accepted (no action): F13, F16. Won't-fix: F11 (cross-skill reference rejected by owner — reverted). **Remaining: F8, F9, F10** (behavioral routing — need RED via `writing-skills`) and **F12** (cross-file terminology rename, do coherently). |
| **F — Expansion (gated)** | F20–F24 | P2 | M each | a dogfood RED per item (existing roadmap's Iron-Law gate) | Yes | New capabilities; do **not** pre-build. Promote only when Wave 0 of the existing roadmap surfaces a reproducible RED. |

**Critical path:** A → B → C → D. Waves E and F run off to the side (E opportunistic, F evidence-gated). The only hard ordering is F1 first (it re-arms the rule that guards every later skill edit) and F2 before any run that trusts hook telemetry.

**One-decision fork before Wave A:** resolve Open Q3 — run A–D as a dedicated clean-up wave **now**, or fold them into the existing dogfood roadmap as "Wave 0.5". Either way A–D need no dogfood RED (they are confirmed defects); the choice is only cadence.

## Open questions

1. **F1 severity** — does the on-demand rule loader match the *source* path (`skills/...`) or the *symlink* path (`.claude/skills/...`) of an edited file? If the latter, F1 drops to P2. This is the one assumption behind the P0 rating — worth confirming against Claude Code's loader behavior before acting.
2. **F13 ruleGates** — wire the dead barrier for the path-deterministic domains that exist, or formally document passes 1–2 as consumer-repo scaffolding and pass-0 as the intended sole vault behavior?
3. **Scope of this audit's follow-through** — should the confirmed P0/P1 health defects (F1–F7) be fixed in a dedicated clean-up wave *now*, or folded into the existing dogfood-first roadmap as a "Wave 0.5"? They are defects with evidence in hand, so the Iron-Law-RED gate does not bind them — but the owner decides the cadence.

**Resolved by owner (2026-06-21):**

- **F7 (was Q here)** → **add the field + the check**: an optional `Source / Provenance` section in the spec template and a code↔source step in `spec-drift-audit`. Carries traceability through the chain rather than dropping it.
- **F19** → **author it**: a new `foundation/adopting-framework` skill that sequences the three bootstraps + symlink/routing setup, test-first via `writing-skills` (RED = onboard a fresh repo and watch it fail).

## Rejected (recorded so they are not re-proposed)

- **Re-raising H1–H6 / S1–S2 / M1–M4** — already parked on [docs/plans/2026-06-21-vault-roadmap.md](../plans/2026-06-21-vault-roadmap.md) §4, gated on a dogfood RED. F7 (provenance) overlaps H1 but is escalated because it is a *confirmed present drop*, not a hypothesis. F6 is distinct from S1/S2 (a contradiction, not a coherence hypothesis).
- **A dedicated debugging skill / refactoring skill** — TDD's RED loop + `codebase-design` + the `refactoring.md` reference cover these; no observed RED justifies a new skill (respects the Iron Law).
- **A `summary:` frontmatter field across skills** — rejected earlier in the readme-catalog grilling as scope creep; not revived.
- **Forcing this audit into the strict spec template** — a spec describes one change; this is a survey of many. Audit/roadmap format chosen by design decision D1.
- **Whole-file README ownership / consumer-app README generator** — out of scope per the readme-catalog spec.
