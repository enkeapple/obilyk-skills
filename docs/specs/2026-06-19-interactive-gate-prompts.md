# Spec: interactive gate prompts for the SDD chain

## Goal

Replace the ad-hoc prose gate-prompt the agent emits at SDD-chain decision points (e.g. "Next — review the spec… I will not advance without your explicit approval") with one canonical **interactive picker of options-with-descriptions**, so every gate offers the user a clickable, recognizable choice instead of free-form prose that drifts run to run.

## Scope

- A new rule `.claude/rules/common/interactive-gates.md` (sibling to `phase-task-visualization.md`) owning: the picker mechanism (tool-agnostic, with the harness tool named), the four decision-point archetypes and their option templates, the inclusion criterion, the gate-honesty reconciliation, and the no-picker-tool fallback.
- Edit `skills/apply-chain/sdd-lifecycle/SKILL.md`: add the **execution-mode fork (B)** as an explicit presentation point and a pointer to `interactive-gates`. The gate *prohibition* prose ("present artifact, STOP, advance only on explicit approval") is **unchanged**.
- Edit `skills/apply-chain/pre-implementation-protocol/SKILL.md`: present the readiness verdict (C-readiness) via the picker; pointer to `interactive-gates`.
- Edit `skills/apply-chain/spec-drift-audit/SKILL.md`: **replace** the current per-finding question loop ("remove it, or document it — which?", one open either/or per finding) with the batched C-drift picker. This requires the audit to now produce a **recommended disposition per finding** in the report (it currently asks open either/or questions and pre-computes no recommendation); pointer to `interactive-gates`. This is the one edit that changes interaction *model*, not only presentation.

## Out of scope

- `.claude/CLAUDE.md` status-block template — **not edited**. The generic `Next` slot (`<next step, or handoff-doc path>`, [.claude/CLAUDE.md:94] / template line 104) already accommodates the gate-turn pointer text; the new rule documents the gate-turn fill. No structural change to the block.
- `operating-manual-template.md` (generator) and `auditing-claude-md` (auditor) — **not touched**. dogfood-generator-sync is `[N/A]`: `interactive-gates` is vault-only, no `bootstrapping-*` template emits a process rule, and the gate-turn `Next` behavior only exists where the (vault-only) rule is active — a generated consumer CLAUDE.md has no picker to point at.
- Archetype CUT points: entry-classification confirmation in `sdd-lifecycle` (agent-derivable) and approach-selection in `grilling` (already conversational). Excluded by the inclusion criterion, recorded in the rule.
- `skills-routing.json` — rules are not routed (skills-only map); no entry.
- Changing the *content* of any verdict/report — readiness logic, drift classification — beyond what each archetype requires. (Exception, in scope: C-drift adds a per-finding **recommended disposition** to the audit report, since the batched picker offers "apply recommended"; A/B/C-readiness are presentation-only.)

## Contracts

### Decision-point archetypes and option templates (the rule's core table)

The picker always auto-adds an "Other" free-text option, so it is never listed. Each list is 2–4 explicit options (harness limit).

```text
A — approval gate (after each phase, owned by sdd-lifecycle):
  1. Approve            → approve this artifact; advance to the next phase
  2. Request changes    → revise this same artifact (I say what)
  3. Redo a prev phase  → defect upstream; return and rework (I name the phase)

B — execution-mode fork (after plan approval, owned by sdd-lifecycle):
  1. Inline (solo)      → coupled tasks / small plan; execute in-session
  2. Subagents          → independent tasks; fresh subagent per task + review gates

C-readiness (pre-implementation-protocol):
  1. Proceed            → readiness confirmed; begin implementation
  2. Not ready          → gaps remain; I list them and return to the plan

C-drift (spec-drift-audit, after the report — ONE picker, batched):
  1. Apply recommended  → apply my per-finding recommended dispositions
  2. Adjust per-finding → walk findings one by one
  3. Stop               → take no action now
```

### Mechanism (tool-agnostic, harness-concrete)

The rule states the mechanism as a role, names the concrete tool, and pins the fallback:

```text
Present the choice as a numbered picker of options-with-descriptions.
In this harness that is the `AskUserQuestion` tool (1–4 questions; each 2–4
options; an "Other" free-text option is added automatically — verified against
the live tool schema this session).
Fallback: when no picker tool exists, render a markdown numbered list with
one-line descriptions and ask the user to reply with a number
(mirrors phase-task-visualization's "no task tooling → skip silently").
```

### Inclusion criterion (which points get a picker)

```text
Add a picker only where the gate needs an EXPLICIT, NON-DERIVABLE decision the
user owns. Do NOT add one where the choice is agent-derivable (entry
classification) or already collected conversationally (grilling's recommended-
answer interview).
```

### Gate-honesty reconciliation (rule prose, reconciling with sdd-lifecycle)

```text
The picker IS the stop: presenting options and waiting for a pick is the gate's
"STOP for explicit approval"; "never auto-advance" means "never advance without
a pick". An "Approve" pick IS the explicit approval, so advancing after it
honors the gate. sdd-lifecycle's gate prohibition is unchanged in meaning.
A gate-turn awaiting a pick is `Result: IN PROGRESS` (awaiting approval), never
`BLOCKED` (reserved for scope decisions / git-boundary actions).
```

### sdd-lifecycle edit anchor (fork B)

`sdd-lifecycle/SKILL.md` names the fork only in the phase chain `(inline-driven-development | subagent-driven-development)` and the controls; it has **no** prose telling the agent to present that choice. The edit adds, in "The gate" / "Controls" region, a sentence that the execution-mode fork is presented as archetype B per `interactive-gates` after plan approval.

## Files touched

| File | Kind | Why |
| --- | --- | --- |
| `.claude/rules/common/interactive-gates.md` | NEW | The convention: mechanism, archetypes A/B/C, option templates, inclusion criterion, gate-honesty, fallback. |
| `skills/apply-chain/sdd-lifecycle/SKILL.md` | EDIT | Add fork-B presentation point + pointer to `interactive-gates`; gate prohibition prose unchanged. |
| `skills/apply-chain/pre-implementation-protocol/SKILL.md` | EDIT | Present readiness verdict via C-readiness picker; pointer (anchor: "Output format" / "Hand-off", lines 49–75). |
| `skills/apply-chain/spec-drift-audit/SKILL.md` | EDIT | Replace per-finding question loop with C-drift batched picker + per-finding recommended disposition; pointer (anchor: "Required decision after the report", line 64). |
| `skills/apply-chain/spec-drift-audit/references/report-example.md` | EDIT | Bring the filled example into line: add recommended-disposition section, swap the open-question "Decisions" block for the batched picker. |

## Edge cases

- **No picker tool in the harness** → fallback to a markdown numbered list (rule pins this); never silently drop the choice.
- **Consumer repo without `interactive-gates`** → no picker; the chain skills' pointers degrade to their existing prose. The rule being vault-only is intentional, not a leak.
- **`Redo a previous phase` (A) / `Adjust per-finding` (C-drift)** → two-step: the pick is followed by a free-text/secondary prompt naming the phase / walking findings. The picker collects the branch, not the detail.
- **Large audit (many findings)** → C-drift stays ONE picker (`Apply recommended / Adjust per-finding / Stop`); never one picker per finding.
- **Standalone phase invocation (not under `sdd-lifecycle`)** → the phase skill still presents its own archetype picker at its gate; B is only meaningful post-plan and stays owned by `sdd-lifecycle`.

## Verification

This is a **shaping** change to vault docs (a rule + skill prose), not a discipline skill and not app code. Verification = the vault's real checks:

- **Validators** (per root `CLAUDE.md` → Common commands + `markdown-style.md`): frontmatter present, every `references`/relative link in the new rule and edited skills resolves, fenced blocks balanced and language-tagged, tables use the spaced delimiter row, word count sane. Paste output.
  - `grep -nE '\|-{2,}\|' .claude/rules/common/interactive-gates.md` → no unspaced delimiter rows.
  - Every relative link target exists (`interactive-gates` → `phase-task-visualization.md`, the three skills → `interactive-gates.md`).
- **RED → GREEN subagent run** (the shaping baseline — convergence, not discipline):
  - RED: a subagent driving a phase gate WITHOUT the rule presents an ad-hoc prose prompt / a varying or absent option set / no clickable choice.
  - GREEN: WITH the rule + the skill pointers, the same subagent presents the canonical archetype picker (right option set, descriptions, fallback when no picker tool).
- No `pnpm`/build/test pipeline exists; do not claim one.

## Risks

- **Risk: the RED is a tautology** — a capable agent may already produce *a* list, so "no list" is not the failure. Mitigation: the RED scenario must show *drift* (different option sets / labels / prose across runs, or no clickable choice), and GREEN must show *convergence* to the canonical set — mirroring `phase-task-visualization`'s convergence rationale, not "make a list".
- **Risk: `sdd-lifecycle` edit accidentally softens the gate prohibition.** Mitigation: the edit is additive (fork B + pointer); the prohibition sentence and red-flag list are left verbatim; spec-drift-audit-style re-read confirms no wording weakened.
- **Risk: dogfood-sync wrongly skipped.** Mitigation: the `[N/A]` is justified in Out-of-scope (vault-only rule, no generator emits process rules); if review disagrees, the template + auditor edits are added before GREEN.
- **Risk: AskUserQuestion contract assumption.** Mitigation: 2–4 options + auto-Other verified against the live tool schema this session; archetypes A=3, B=2, C-readiness=2, C-drift=3 all fit.
