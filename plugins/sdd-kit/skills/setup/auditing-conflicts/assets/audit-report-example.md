# Audit Report — filled example

A neutral reference for the shape `auditing-conflicts` produces: findings grouped by class then severity, every finding in the locked shape, an explicit zero-findings line per clean class, and the C-drift picker at the end. Three cases are shown — a real conflict, a clean class, and a *false* conflict the judgment layer downgrades.

## Findings

### Class 7 — rule-vs-skill contradiction

```text
F-001 · Class 7 · Severity Low
Title:    "Prefer multiple-choice" reads as the picker, but the rule reserves the picker for gates
Evidence: plugins/sdd-kit/skills/chain/grilling/SKILL.md:33 "Ask ONE question. Prefer multiple-choice."
          .claude/rules/common/interactive-gates.md:23 "Do NOT add a picker where the choice is ... already conversational (a one-question recommended-answer interview)."
Why:      "multiple-choice" (content framing) and "picker" (the tool, gates only) are not distinguished,
          so a reader applies the picker tool to a conversational interview question — inconsistent UX.
Disposition: amend grilling:33 to split "multiple-choice framing (prose)" from "the picker tool (gates only,
             per interactive-gates)" → writing-skills (behavioral lane, test-first)
```

### Class 6 — duplicate canonical-source

```text
F-002 · Class 6 · Severity Info  (downgraded by judgment — see rationale)
Title:    git-conventions and CLAUDE.md both speak to the git boundary
Evidence: .claude/rules/common/git-conventions.md "Canonical Source — Do Not Duplicate"
          .claude/CLAUDE.md → "Git boundary"
Why:      Both touch the same concern (git autonomy / commit rules), which the mechanical layer flags as a
          duplicate-ownership candidate.
Judgment annotation (downgrade → Info): NOT a real conflict — git-conventions.md carries an explicit
          "Canonical Source — Do Not Duplicate" cross-reference deferring the boundary to CLAUDE.md and
          owning only the *format* conventions. The deferral resolves the ownership; this is the
          false-positive guard working as intended. Mechanical finding retained, visible, severity Info.
Disposition: accept (cross-reference already present)
```

### Other classes

```text
Class 1 (trigger collision): no conflicts found
Class 2 (responsibility overlap): no conflicts found
Class 3 (broken hand-off): no conflicts found
Class 4 (contradictory instructions): no conflicts found
Class 5 (rule-vs-rule): no conflicts found
Class 8 (routing/invocation invariant): no conflicts found
Class 9 (orphan reference): no conflicts found
```

## Summary

| Severity | Count |
| --- | --- |
| High | 0 |
| Medium | 0 |
| Low | 1 |
| Info | 1 |

## Decision (archetype C-drift — one batched picker)

- `Apply recommended` → run each finding's disposition in its lane: F-001 via `writing-skills` (behavioral, test-first); F-002 `accept` (no-op, the cross-reference already resolves it).
- `Adjust per-finding` → walk F-001, F-002 one by one.
- `Stop` → take no action now.
