# ADR-0002 — Hooks get a persisted CI fixture suite, not ephemeral test cases

Date: 2026-06-27
Status: Accepted

## Context

The vault's authoring discipline treats test cases as **ephemeral**: `writing-skills` stages a skill's RED/GREEN cases in a temp file and **deletes them after the gate** ("never persist `test-cases.md`"), because a skill's cases are prose behavioral pressure runs that rot as committed clutter. Hooks were verified the same ad-hoc way — fixture-execution at authoring time, nothing persisted. Yet `lessons-learned.md` records a recurring class of hook bugs that shipped green and broke on a real event (false-green empty branches, `nullglob`, `set -e` fail-closed source, `grep -c "0\n0"`, substring false-positives). CI ran only structural JSON/manifest checks, so none of that class was caught after authoring. Wave 0 (0.3) had to decide whether hook fixtures stay ephemeral like skill cases, or become a persisted suite.

## Decision

Hooks get a **persisted** regression suite, deliberately departing from the ephemeral-cases rule. Each hook has a declarative `tests/<hook>.sh.cases` file run by a repo-root runner in CI. The split rests on a kind distinction: a **hook is deterministic executable code**, so a persisted suite is a genuine regression net; a **skill's cases are non-deterministic prose pressure runs**, which is why they stay ephemeral. `writing-hooks` now instructs updating a hook's `.cases` in the same change as its decision logic, so the committed suite cannot silently drift from the hook.

## Options considered

- **Option A (chosen) — persisted per-hook `.cases` suite + CI runner.** Catches the documented recurring hook-bug class on every push. Cost: a new sanctioned artifact class that contradicts the ephemeral-cases rule, so the distinction must be explained (this ADR) and maintained (the `writing-hooks` note).
- **Option B — keep hook fixtures ephemeral (uniform with skills).** Rejected: CI then cannot re-run them, and the exact bug class in `lessons-learned` keeps shipping green — the ephemeral rule's rationale (prose cases rot) does not apply to deterministic code.
- **Option C — write hook fixtures ad-hoc in CI from the hook's contract.** Rejected: CI cannot author fixtures; the cases must be committed artifacts to be re-runnable.

## Consequences

- **Positive:** the recurring hook-bug class is now a CI regression gate; a hook edit that breaks a contract fails the suite before merge. The fixture format is declarative data, not executable shell, so a case cannot itself introduce a bug.
- **Negative (the cost accepted):** two test-persistence philosophies now coexist in one vault (ephemeral for skills, persisted for hooks). Without this record a future reader would read the persisted `.cases` as a violation of the ephemeral rule. Mitigated by the kind distinction above and the `writing-hooks` reconciling note.
- **Negative:** the suite can drift from a hook if an author edits hook logic without updating its `.cases`. Mitigated by the `writing-hooks` instruction; a future `auditing-hooks` skill could enforce it.
- **Scope — the gate is vault-only by design.** The runner and the CI step live at the vault root (not in the plugin) and the runner also covers the vault-local `hooks/guards/`, so it runs only in this vault against the in-tree hooks. The `.cases` co-located under `plugins/saleizo-controls/hooks/tests/` ride along in a consumer's plugin install cache but are **inert there** — no runner, no CI. This is correct, not a gap: the vault authors and edits these hooks; a consumer installs the plugin read-only and never edits them, so the regression net belongs where the edits happen. The records therefore do not claim consumer-side regression value.
- **Follow-ups:** new hooks ship with a `.cases` file (happy + the empty/no-match branch + a distinct garbage→fail-open case); guard hooks additionally get one case per distinct blocking rule plus a benign-substring non-block.

## Related files

- `scripts/run-hook-fixtures.sh` — the runner (derives the hook path from each `tests/<hook>.sh.cases`, asserts exit/stdout/stderr).
- `plugins/saleizo-controls/hooks/tests/` and `hooks/guards/tests/` — the per-hook `.cases` suites.
- `.github/workflows/validate.yml` — the "Hook fixtures" step that runs the suite in CI.
- `plugins/saleizo-core/skills/authoring/writing-hooks/SKILL.md` — the authoring-time-vs-persisted reconciling note.
