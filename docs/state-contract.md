# `.claude/state/` — runtime state contract

What the saleizo-controls hooks write under `.claude/state/`, who owns each file, and how long it lives. The **whole directory is gitignored** (`.gitignore` → `.claude/state`) — it is runtime scratch + telemetry, never committed. This doc is the durable record of that layout (build 3d); it is reference, not a rule or skill.

Source of truth is the hooks themselves in `plugins/saleizo-controls/hooks/`; if this doc and a hook disagree, the hook wins — fix this doc. Reconciled against the hooks as of build 3b/3c-gate (2026-06-24).

## Two layers

- **Durable telemetry + corpus** — dated day-files at the state root, append-only, pruned by a single 14-day mtime GC. Survive across sessions; the analysis layer (`scripts/metrics-report.sh`, future `prompt-coach`) reads these.
- **Per-session scratch** — everything under `.claude/state/<session_id>/`. Either reset every turn or session-durable; today pruned only by the same 14-day GC (build 3c will add prompt `SessionEnd` teardown — see Retention).

`<session_id>` is the sanitized `session_id` from hook stdin (`hook_sid`, fallback `default`); the dir is `hook_state_dir` = `${CLAUDE_PROJECT_DIR}/.claude/state/<session_id>`.

## Durable streams (state root)

| File | Writer hook(s) | Event | Records | Lifetime |
| --- | --- | --- | --- | --- |
| `metrics/YYYY-MM-DD.jsonl` | `log-skill-usage`, `friction-log`, `detect-bypass` | Stop / PostToolUse | `{v,type:"skill_event",…}` (bypass / used_correctly / read_instead_of_skill / direct_edit_lessons_log) and `{v,type:"friction",class,count}` | durable, GC > 14d |
| `prompts/YYYY-MM-DD.jsonl` | `log-skill-usage` (**sole writer**, at Stop) | Stop | `{v,type:"prompt",…}` — one finalized record per user turn (the corpus) | durable, GC > 14d |
| `_metrics.jsonl` | — (pre-3b legacy; **no longer written**) | — | old undated telemetry, fat schema | read by the consumer until its mtime ages past 14d, then GC-removed |

Every record carries `v` (schema version) + `type` (discriminator) + `session` + `ts`. The `triggers` regex is **not** stored (re-derived from `.claude/skills-routing.json` by skill key). Consumer `scripts/metrics-report.sh` reads `metrics/*.jsonl` plus the legacy `_metrics.jsonl` while it exists.

## Per-session scratch (`.claude/state/<session_id>/`)

**Per-turn** — written/reset by `reset-turn-budget` on every `UserPromptSubmit`, mutated mid-turn by `PostToolUse` hooks, consumed at `Stop`:

| File | Reset by | Mutated / read by | Holds |
| --- | --- | --- | --- |
| `turn-budget.json` | `reset-turn-budget` | `token-guard` (bytes/tools) | per-turn token budget |
| `turn-skills-invoked.json` | `reset-turn-budget` | `detect-bypass` (append Skill names), `skill-gate` (read), `log-skill-usage` (clear at Stop) | skills invoked this turn |
| `turn-reads.json` | `reset-turn-budget` | `detect-bypass` (append), `skill-gate` (read) | files Read this turn (rel paths) |
| `turn-tool-count.json` | `reset-turn-budget` | `detect-bypass` (bump), `log-skill-usage` (read) | non-Skill tool count |
| `last-prompt.txt` | `reset-turn-budget` | `detect-bypass` / `log-skill-usage` / `skill-gate` (read) | raw user prompt text |
| `pending-prompt.json` | `reset-turn-budget` (opens) | `log-skill-usage` (finalize → `prompts/`, then `rm`) | the in-flight corpus record |
| `turn-bypass-warned.flag` | `reset-turn-budget` (`rm`) | `detect-bypass` (touch), `lessons-nudge` (read) | once-per-turn bypass-warn guard |
| `turn-lessons-nudged.flag` | `reset-turn-budget` (`rm`) | `lessons-nudge` (touch) | once-per-turn lessons-nudge guard |

**Session-durable** — created once, accumulate across turns within a session (NOT reset per turn):

| File | Writer hook | Holds |
| --- | --- | --- |
| `session-turn.json` | `reset-turn-budget` | monotone per-session turn counter (`{n}`) |
| `session-budget.json` | `token-guard` | per-session token accounting |
| `by-model-budget.json` | `token-guard` | per-`subagent_type` output-byte accounting (coarse proxy, not true spend) |
| `friction-seen.json` | `friction-log` | running friction totals for Stop delta-tracking |

## Retention / GC

`reset-turn-budget` (`UserPromptSubmit`) runs a single **14-day mtime GC** after refreshing the live session dir's mtime (`touch "$STATE_DIR"`, so the active dir is never collected):

1. day-files in `metrics/` + `prompts/` and the legacy `_metrics.jsonl`, older than 14 days → deleted.
2. per-session scratch dirs older than 14 days → removed.

This is opportunistic (runs only when some session submits a prompt) and is the **only guaranteed cleanup** — it is the backstop a `SessionEnd` teardown cannot replace.

**Build 3c (planned, gate passed):** add a `SessionEnd` hook to tear down the current session's scratch dir promptly on normal exit (and optionally relocate scratch to `${TMPDIR}`). Caveat from the hook-events check: `SessionEnd` does **not** fire on `SIGKILL`/crash, so the 14-day GC above stays mandatory as the hard-kill backstop. 3c is a prompt-cleanup optimization, not a correctness requirement.

## Notes

- The directory is gitignored; nothing here is a git-tracked fact. Durable knowledge goes to git elsewhere (skills, rules, this doc).
- `hook-events.md` (in `writing-hooks/references/`) is the thin event catalog; it currently lists only the four in-use events — `SessionEnd`/`SessionStart` are added there when build 3c lands.
