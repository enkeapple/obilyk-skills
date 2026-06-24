# ADR-0001 — Share the guardrail-hook session/state preamble via a sourced lib

Date: 2026-06-24
Status: Accepted

## Context

The guardrails-kit ships 8 bash hooks (`plugins/guardrails-kit/hooks/`). Seven of them re-derived the same session id and per-session state dir inline — an identical ~6-line preamble (`jq -r '.session_id // empty' | tr -cd …`, `default` fallback, `${CLAUDE_PROJECT_DIR:-.}/.claude/state/$SID`) copied 7×, plus the strict `jq -e . || exit 0` fail-open guard copied in 3. Every hook is launched as a fresh child process (`"${CLAUDE_PLUGIN_ROOT}"/hooks/<name>.sh`), and **fail-open is a hard invariant** — a guard must never disrupt real work on its own error. The duplication was a maintenance and drift risk; the constraint was that any de-duplication must not weaken fail-open.

## Decision

Extract the shared preamble into a sourced function library `plugins/guardrails-kit/hooks/lib/common.sh` exposing three pure functions — `hook_sid` (`common.sh:15`), `hook_state_dir` (`common.sh:23`), `hook_require_json` (`common.sh:31`) — and migrate the 7 SID-deriving hooks to source it. `quality.sh` is excluded (it derives no session id). Hooks locate and load the lib with a **readability-guarded** source, the idiom documented at `common.sh:6-11`:

```bash
GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0
. "$GUARDRAILS_LIB"
```

Two hooks (`friction-log`, `lessons-nudge`) derive a second path from a local `PROJECT_DIR` var, so they keep `PROJECT_DIR` inline and call `hook_sid` only; the other five also use `hook_state_dir`.

## Options considered

- **Option A (chosen) — small sourced function library.** Captures the real duplication with minimal coupling; each hook keeps its own control flow and path vars. Cost: a shared dependency + a new failure mode (missing lib).
- **Option B — monolithic `hook_init` preamble** that sets `INPUT`/`SID`/`STATE_DIR` as globals. Rejected: the hooks have three distinct shapes (strict fail-open / run-on-empty / file-path), so one mold would force-fit them and set vars some hooks never use.
- **Option C — no abstraction (accept the duplication).** Rejected: the owner asked to de-duplicate; the SID derivation alone was 7 identical copies. Self-containment is a real benefit, but the duplication's drift risk outweighed it given a fail-open-preserving source guard exists.

## Consequences

- **Positive:** one place for the session/state preamble; a future change (e.g. SID sanitization) edits one file, not seven. The fail-open and JSON-guard contracts are now named functions, not re-derived idioms.
- **Negative (the cost accepted):** the hooks are no longer fully self-contained — a missing/corrupt `lib/common.sh` affects all 7 at once. Mitigated by the readability-guarded source (every hook fail-opens to `exit 0` when the lib is absent — verified by a per-hook missing-lib fixture).
- **Negative:** the source idiom is non-obvious. `. lib || exit 0` **fails closed** under `set -e` (`.` is a POSIX special builtin; its open-failure exits the shell before `|| exit 0` runs). The readability guard is mandatory, not stylistic — see lessons-learned `errexit-failopen-idiom`.
- **Follow-ups:** any new guardrail hook that needs the session/state preamble sources `common.sh` with the readability-guarded idiom and must prove fail-open by executing the missing-lib case, not by reading the `||`. A future "consolidate the two bypass detectors' trigger-match loop" refactor (audit's "Other hook improvements") could extend this lib.
