---
name: reviewing-telemetry
description: >-
  Use to review the SDD framework's own routing/telemetry health — read the
  guardrails hooks' emitted metrics (skill bypasses, friction, hand-off leaks)
  and produce a fixed-shape triage digest: prioritized findings with evidence
  and a recommended action for each. Triggers on: "review telemetry",
  "telemetry digest", "routing health", "what's misfiring", "bypass rate",
  "noisy triggers", "проверь телеметрию", "здоровье роутинга", "что мисфайрит",
  "шумные триггеры", "дайджест телеметрии".
---

# Reviewing Telemetry

Turn the guardrails hooks' raw event log into a **fixed-shape triage digest** a human can act on: what is misfiring, how badly, and the one recommended action per finding. The value is the *shape* — same sections, same finding taxonomy, same action vocabulary every run — so two runs over the same data converge instead of producing two ad-hoc essays with different counts.

**Reuse the counts, don't recompute them.** The repo already ships an aggregation script that produces canonical top-line numbers (bypass rate, friction by class, token spend). Run it; do not re-derive those totals by hand — hand-counting is exactly where two reviews diverge. This skill adds the layer the script does *not*: the per-skill breakdown, the triage classification, and the recommended action.

Project-agnostic: the metric **schema** and **locations** below are the framework's own convention (the guardrails hooks emit them identically in any consumer). Concrete paths are illustrative — if the consumer's layout differs, fill its real ones.

## Source (where the data is)

- **Canonical aggregates** — the repo's metrics-report script (illustratively `scripts/metrics-report.sh`); run it for the top-line. If the repo has no such script, aggregate the JSONL directly.
- **Raw events** — the guardrails hooks' day-files (illustratively `.claude/state/metrics/*.jsonl`), one JSON object per line. The fields this skill reads:
  - `type:"skill_event"`, `event:"bypass"` — a prompt matched skill `<skill>`'s triggers but the skill was not invoked.
  - `event:"used_correctly"` — matched AND invoked (the bypass-rate denominator).
  - `event:"direct_edit_lessons_log"` / `read_instead_of_skill` — a routed skill was sidestepped.
  - `type:"friction"`, `class` ∈ {`error`,`denied`,`blocked`}, with `count`.
- **Routing** — `.claude/skills-routing.json` to name the trigger set behind a noisy skill.

Exclude obvious fixture/test sessions (e.g. session ids like `fixture*`) from the production picture — note that you excluded them.

## Process

1. **Run the aggregation script** for the canonical top-line (bypass rate, friction by class, tokens). Quote its output; do not recompute these totals.
2. **Per-skill bypass breakdown** — group `event:"bypass"` by `skill`, sort descending. This is the breakdown the script omits and the core of the digest.
3. **Classify** each signal into the taxonomy below; attach the evidence (counts) and the one recommended action. Nothing crosses a threshold → say so; do not invent findings.

## The digest — REQUIRED fixed shape

Emit exactly these three sections, in order:

```text
## Telemetry digest — <date range>, <N> events (<excluded> fixture excluded)

### Health top-line   (from the aggregation script — quoted, not recomputed)
- Bypass rate: <b>/<b+u> = <pct>%
- Friction: error <n> · denied <n> · blocked <n>
- Token spend by model: <…>

### Findings   (prioritized; each: type · evidence · recommended action)
1. <type> — <skill/where>: <evidence counts>. → <recommended action>
2. …
(If none cross a threshold: "No findings — routing health within normal range.")

### Recommended next step
<one line: the single highest-value action, or "none">
```

## Finding taxonomy + recommended action

Three finding types only; map each to ONE action from the fixed vocabulary:

| Type | Fires when | Recommended action (pick one) |
| --- | --- | --- |
| **noisy-trigger** | a skill's bypass count dominates, or it fires alongside many others on the same prompt, or bypass with ~zero `used_correctly` | **tune trigger** — narrow/fix the skill's `triggers` in `.claude/skills-routing.json` |
| **leaked-handoff** | a routed skill sidestepped (`direct_edit_lessons_log` / `read_instead_of_skill`), or a chain hand-off that should have routed but didn't | **capture lesson** (`writing-lessons`) — record the bypass class; if it recurs 3×, **promote rule** (`writing-rules`) |
| **friction-hotspot** | a friction `class` concentrates in a session/skill, or `blocked`/`denied` cluster in a window | **investigate** the named session/gate; **accept** if it is expected (a guard doing its job) |

A finding whose evidence is below threshold or expected is **accept** (no action) — record it as accepted, do not omit it silently.

## Hand-off — surface, never auto-apply

This skill **reports**; it does not edit routing, write lessons, or promote rules. Each recommended action names the skill that owns it:

- **tune trigger** → the human edits `.claude/skills-routing.json` (the `skill-routing-sync` rule governs that edit).
- **capture lesson** → invoke `writing-lessons`; **promote rule** → `writing-rules`.

Present the findings; let the human pick which actions to run.

## Red Flags — STOP

- Re-counting the top-line by hand instead of quoting the aggregation script (the counts will diverge from every other run).
- Inventing findings when nothing crosses a threshold — an empty Findings list is a valid, honest result.
- A free-form essay instead of the three REQUIRED sections (the drift this skill exists to stop).
- A finding with no recommended action, or an action outside the fixed vocabulary (tune trigger / capture lesson / promote rule / investigate / accept).
- Editing routing / writing a lesson / promoting a rule from inside this skill — it surfaces; the human authorizes.
- Counting fixture/test sessions into the production picture without excluding and saying so.
