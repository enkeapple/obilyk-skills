---
name: auditing-hooks
description: >-
  Use to find drift between hook scripts on disk and their wiring in the
  harness hook configuration (each settings.json hooks block and each plugin
  hooks.json) — orphan scripts, dangling wiring, broken symlink indirection,
  event/matcher mismatch, missing fixtures. The single-domain auditor that
  pairs with writing-hooks; not hook-logic review. Triggers on: "audit the
  hooks", "are the hooks wired correctly", "hook wiring drift", "check hook
  config", "orphan hook", "проверь хуки", "аудит хуков", "дрейф хуков".
allowed-tools: Read, Grep, Glob, Bash
---

# Auditing Hooks

A read-only **structural** audit of one repo's hooks: does every hook **script on disk** correspond to its **wiring** in the harness configuration, and vice versa? It reports the drift per class in a locked shape and ends in a single decision picker. **It edits nothing during the audit.**

This is the single-domain auditor that pairs with `writing-hooks` (which authors one hook test-first) — the missing half of the author/audit symmetry. The drift taxonomy (the 5 classes, their layer, detection method, and fix lane), the locked finding shape, and the deterministic recipes live in [references/drift-catalog.md](./references/drift-catalog.md) and [references/mechanical-checks.md](./references/mechanical-checks.md). A filled report is in [assets/audit-report-example.md](./assets/audit-report-example.md).

**Progress:** before your first artifact, reflect this phase in the harness task list (one item `in_progress`; an item turns `completed` only on the user's explicit approval; a skipped phase stays listed, marked skipped) — under `sdd-lifecycle` update the existing item; run standalone, seed a single item.

## What this audit is NOT (the boundary — keep findings structural)

A strong agent, asked to "check the hooks", drifts into reviewing hook *behaviour*. Each of these is **out of scope** — do not raise it as a drift finding (note it out-of-scope at most, and name the right owner):

- **Hook-script logic / correctness** (a guard that matches too broadly, a missing deny branch, a no-op body, fail-open on garbage stdin) → `writing-hooks` owns this via fixture-execution RED/GREEN; code review owns quality. This audit never judges what a script *does*.
- **Fixture content / pass-fail** — whether a fixture's assertions are right or the suite is green → `writing-hooks` and the consumer's fixture runner own execution. This audit checks only that a fixture **exists** (class D5), never runs one.
- **Conflicts between skills, rules, or routing** → `auditing-conflicts`. This audit stays within the hook layer.

The unit of every finding here is a **correspondence** (script ↔ wiring ↔ symlink ↔ fixture-existence), never a line of hook behaviour.

## When to use

- Before a release / periodically — confirm every hook script is wired and every wiring entry resolves.
- After adding, renaming, moving, or deleting a hook script or a wiring entry — catch the half-done change the JSON validators and the fixture runner miss.

## When NOT to use

- Authoring or fixing a single hook (use `writing-hooks`).
- Cross-artifact skill/rule/routing conflicts (use `auditing-conflicts`).
- A pure JSON-validity check the CI already runs (`jq empty` on the config) — this audit assumes valid JSON and checks correspondence.

## Process

1. **Inventory** the **working tree** (not HEAD — catch drift pre-commit), per [references/mechanical-checks.md](./references/mechanical-checks.md):
   - every hook **script** on disk (the repo's hook script dirs);
   - every **wiring entry** — each `settings.json` `hooks` block AND each plugin `hooks.json`: event → matcher → `command` path;
   - the **symlink indirection** layer, where the repo surfaces hooks through symlinks;
   - every fixture/test file beside the scripts.
2. **Mechanical layer** — classes **D1, D2, D3, D5** (orphan script, dangling wiring, broken symlink, fixture gap): deterministic set-difference / existence / resolve checks. Emit a precise finding with `file:line` evidence for each instance.
3. **Judgment layer** — class **D4** (event/matcher mismatch): does the event + matcher a script is wired under match what the script's body reads/does? Light read, owner-action fix — never auto-edit a matcher.
4. **Report** — group findings by class then severity, in the locked finding shape. Emit an explicit `D{n}: no drift found` line for **every** clean class — never a silently omitted class.
5. **Disposition** — present exactly **one** C-drift batched picker (below). The audit itself still edits nothing.

## Required decision after the report

End with **one** picker (archetype C-drift; markdown-list fallback), never one picker per finding — which is why the report records a recommended disposition per finding:

- `Apply recommended` → run each finding's recommended disposition in its fix lane (mechanical edits sequential, stop-on-first-failure; a fixture gap routes through `writing-hooks`; a D4 matcher change is owner-action).
- `Adjust per-finding` → walk findings one by one.
- `Stop` → take no action now.

## Integration

- **Upstream:** invoked standalone, or after a hook/wiring change, against the repo in place.
- **Terminal:** a verify-style audit — it never feeds another phase. After the disposition is chosen, the human owns the commit; a fixture or logic fix runs its own `writing-hooks` cycle.

## Red Flags — if you catch yourself here, STOP

- Raising a hook-script **logic** defect (broad match, missing deny path, no-op, fail-open) as a drift finding — that is `writing-hooks` / code review, out of scope.
- **Executing** a fixture to judge it, instead of only checking it exists.
- Reporting only the obvious dangling/missing script and skipping the orphan, broken symlink, or fixture-gap sweep.
- Omitting a clean class instead of emitting its `D{n}: no drift found` line.
- Reporting in prose instead of the locked finding shape, or ending without the single C-drift picker.
- Editing a script, wiring entry, or symlink **during** the audit — it is read-only; fixes happen only after the picker.

## Rationalizations

| Excuse | Reality |
| --- | --- |
| "This guard's logic is clearly buggy — I'll flag it." | Script behaviour is out of scope. This audit checks correspondence; `writing-hooks` owns logic via fixtures. |
| "I'll run the fixture to be sure it works." | This audit checks a fixture *exists* (D5), never runs it — the consumer's runner / `writing-hooks` own execution. |
| "The dangling script is the real problem; the orphan is harmless." | Each class is swept in full. An orphan script and a fixture gap are findings, not details to skip. |
| "No instances of class D3 — I'll just leave it out." | Every clean class gets a `no drift found` line; a silently omitted class reads as 'not checked'. |
| "I'm here, I'll just fix the wiring." | The audit is read-only. Report it; the user authorizes the fix at the picker. |
