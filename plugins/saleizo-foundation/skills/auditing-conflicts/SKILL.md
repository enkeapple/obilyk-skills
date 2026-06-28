---
name: auditing-conflicts
description: >-
  Use to find conflicts and contradictions BETWEEN skills, rules, and routing
  in a framework repo — overlapping triggers, duplicated ownership, broken
  hand-offs, rule-vs-rule or rule-vs-skill contradictions, routing/invocation
  invariant breaks, orphan references — distinct from the one-pair drift
  auditors. Triggers on: "audit conflicts", "check for skill/rule conflicts",
  "find contradictions", "conflicting triggers", "проверь конфликты",
  "аудит конфликтов", "противоречия между скиллами/рулами".
allowed-tools: Read, Grep, Glob, Bash, Task
---

# Auditing Conflicts

A read-only **cross-artifact** coherence audit of a framework repo. It finds conflicts *between* skills, rules, and routing — overlapping triggers, duplicated ownership, broken hand-offs, contradictions, routing/invocation-invariant breaks, orphan references — and ends in a single decision picker. **It does not edit artifacts during the audit.**

This is **not** a one-pair drift auditor. `verifying-implementation`, `auditing-claude-md`, `auditing-glossary`, and `auditing-readme` each check one artifact against its own reality (code↔spec, README↔disk, …). This skill checks artifacts *against each other*. A drift-class observation is **never** re-checked here — it becomes a finding whose disposition *names* the right auditor to run (`→ run auditing-readme`), never a `Skill` invocation. (`Bash` runs read-only grep/jq inventory and the mechanical re-check on a fix; `Task` dispatches the judgment-layer fan-out. The read-only guarantee holds despite `Bash`.)

The detection contract — the 9 conflict classes, their layer, fix lane, and detection method, plus the class-6 split, the locked finding shape, and the disagreement rule — lives in [references/conflict-catalog.md](./references/conflict-catalog.md). The deterministic recipes (grep/jq for classes 1/6/8/9, the reproducible shortlist computations, the class-9 search rules) live in [references/mechanical-checks.md](./references/mechanical-checks.md). A filled report is in [assets/audit-report-example.md](./assets/audit-report-example.md).

**Progress:** before your first artifact, reflect this phase in the harness task list (one item `in_progress`; an item turns `completed` only on the user's explicit approval; a skipped phase stays listed, marked skipped) — under `sdd-lifecycle` update the existing item; run standalone, seed a single item.

## When to use

- Before a release / periodically — confirm the skill+rule+routing set is internally coherent.
- After adding or renaming a skill, rule, or trigger — catch a collision or a broken hand-off the single-artifact validators miss.
- When a routing change makes you unsure whether two skills now compete for the same prompt.

## When NOT to use

- A single-artifact drift check (use the matching `auditing-*` / `verifying-implementation`).
- A pure validator pass on one skill (`writing-skills` owns that).

## Process

1. **Inventory** (the **working tree**, not HEAD — conflicts must be caught pre-commit). Read every `SKILL.md`, every `.claude/rules/**/*.md`, both `CLAUDE.md`, and `.claude/skills-routing.json`. Build the dictionary of real names = skill directory names ∪ routing keys.
2. **Mechanical layer** — run the [references/mechanical-checks.md](./references/mechanical-checks.md) recipes. Emit (a) precise findings for classes **1, 6, 8, 9** with `file:line` evidence, and (b) a **shortlist** of candidate artifact-pairs for the judgment layer (only pairs with a structural signal — never all pairs). `log` the shortlist size and the dropped-pair count so under-coverage is visible.
3. **Judgment layer** — fan out one `Task` subagent **per shortlisted candidate**, each on a **different model + fresh context** (per `model-selection.md`: a reviewer that inherits the author's model inherits its blind spots). Each subagent receives the **full bodies** of the two artifacts and returns a finding in the locked shape for classes **2, 3, 4, 5, 7**.
4. **Report** — group findings by class then severity, in the locked finding shape. Emit an explicit `Class N: no conflicts found` line for every clean class — never a silently omitted class.
5. **Disposition** — present exactly **one** C-drift batched picker (below). The audit itself still edits nothing.

### Disagreement rule (mechanical vs judgment)

The mechanical layer is **authoritative on existence** — a trigger collision either matches the sample set or it does not. A judgment subagent may only **annotate** a mechanical finding: downgrade its severity to `Info` with a written rationale (e.g. "overlap is intentional, the skills are complementary"). It may **never delete** a mechanical finding — the finding stays visible so the user decides.

### Fix lanes (only after the user picks `Apply recommended`)

The audit finding itself is the RED. On `Apply recommended`, run each finding's fix **in its lane**, sequentially, **stop-on-first-failure** with a report of what applied and what did not. The picker is approval to **start** the fix work — not a promise of a one-shot patch.

- **Mechanical lane** — classes **8, 9**, and the *missing-cross-reference* sub-case of **6**: edit + re-run the same mechanical check (was red → now green). No pressure-subagent.
- **Behavioral lane** — classes **2, 3, 4, 5, 7**, and the *genuine-duplication* sub-case of **6**: route through `writing-skills` (skill bodies) / `writing-rules` (rules) with a real subagent RED→GREEN, because the artifact's behavior changes.
- **Owner action** — class **1** (trigger collision): which trigger to narrow is the owner's judgment call; the runner **skips** class-1 findings and lists them as "owner action" in its summary. It never auto-edits triggers.

## Required decision after the report

End with **one** picker (archetype C-drift; markdown-list fallback), never one picker per finding — which is why the report records a recommended disposition per finding:

- `Apply recommended` → run each finding's recommended disposition in its fix lane (sequential, stop-on-first-failure).
- `Adjust per-finding` → walk findings one by one.
- `Stop` → take no action now.

## Integration

- **Upstream:** invoked standalone, or after a routing/skill change, against the framework repo in place.
- **Terminal:** a verify-style audit — it never feeds another phase. After the disposition is chosen, the human owns the commit; a behavioral fix runs its own `writing-skills`/`writing-rules` cycle.

## Red Flags — if you catch yourself here, STOP

- Reaching to "just fix the overlap while I'm here" — the audit is read-only; report it.
- Marking the intentional overlap a hard conflict — annotate it down to `Info`, keep it visible.
- Scanning only the first orphan / first colliding pair — sweep the whole repo, every pair on the shortlist.
- Reporting in prose instead of the locked finding shape.
- Re-checking a drift-class issue here instead of delegating it as a disposition string.

## Rationalizations

| Excuse | Reality |
| --- | --- |
| "I'll just fix the overlap while I'm here." | The audit is read-only. Report it; the user authorizes the fix at the picker. |
| "The intentional overlap is a conflict — flag it High." | Judgment annotates it to `Info` with a rationale; the mechanical finding stays visible, not deleted. |
| "I'll check the obvious orphan and move on." | Class-9 is a whole-repo sweep (`grep -rE`, no `-maxdepth`, no allowlist). Agents miss the second hit. |
| "Prose is clearer than the finding shape." | Prose hides class and severity. Every finding gets the locked shape; every clean class gets a zero-findings line. |
| "This drift is right here, I'll just verify it too." | Drift is not this skill's job. Emit it as a finding whose disposition says `→ run auditing-readme`; never invoke it. |
