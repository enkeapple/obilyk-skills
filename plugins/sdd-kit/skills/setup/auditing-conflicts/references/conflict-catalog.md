# Conflict Catalog — the detection contract

The 9 classes `auditing-conflicts` detects, their layer (how they are found), their fix lane (what `Apply recommended` does), and the detection method. This is the contract; the deterministic recipes are in [mechanical-checks.md](./mechanical-checks.md).

## The 9 classes

| # | Class | Layer | Fix lane | Detection |
| --- | --- | --- | --- | --- |
| 1 | Trigger collision | Mechanical (detect) | **Owner action** — report only | Two routing entries whose `triggers` regexes both match ≥1 prompt in the fixed sample set |
| 2 | Responsibility overlap | Judgment | Behavioral | Subagent reads both full bodies; the same job is claimed by two skills |
| 3 | Broken hand-off (semantic) | Judgment | Behavioral | Subagent: a `REQUIRED SUB-SKILL`/Upstream/Downstream target exists but does the wrong thing |
| 4 | Contradictory instructions | Judgment | Behavioral | Subagent: skill A mandates X, skill B forbids X in the same situation |
| 5 | Rule-vs-rule contradiction | Judgment | Behavioral | Subagent over a rule pair |
| 6 | Duplicate canonical-source | Mechanical (detect) | **split — see below** | Two artifacts assert ownership of one concern with **no** "canonical source is X / do not duplicate" cross-reference |
| 7 | Rule-vs-skill contradiction | Judgment | Behavioral | Subagent over a rule×skill pair (e.g. F-001) |
| 8 | Routing/invocation invariant | Mechanical | Mechanical | `name`≠dir≠routing-key; a model-invocable skill with no routing entry; a `disable-model-invocation:true` skill WITH an entry; an alias delegating to a nonexistent name |
| 9 | Orphan reference | Mechanical | Mechanical | A structural citation (link target / backticked skill-name in a hand-off context / rule-file path) whose target is absent on disk |

Class 10 (cross-plugin coupling — an agnostic skill hard-depending on another kit) is **deferred (YAGNI)**; it is not detected.

## Class-6 lane split

The mechanical layer **detects** every class-6 candidate; the judgment layer decides which sub-case each is and tags its lane:

- **Mechanical fix lane — the *missing-cross-reference* sub-case.** Two artifacts legitimately touch one concern but neither defers to the other. The fix is to **add** the `canonical source is X` line (mirroring how `git-conventions.md` defers to `CLAUDE.md`). Verified by re-running the class-6 check (red→green). No pressure-subagent.
- **Behavioral fix lane — the *genuine-duplication* sub-case.** The two artifacts actually say overlapping things and one must be cut or merged. Routes through `writing-rules`/`writing-skills` test-first, because it changes what an artifact says.

## Locked finding shape

Every finding — mechanical or judgment — uses exactly this shape:

```text
F-NNN · Class <1-9> · Severity <Info|Low|Medium|High>
Title:    <one line>
Evidence: <file:line> "<verbatim citation>"   (one or more)
Why:      <why these two artifacts conflict>
Disposition: <recommended action> → <delegate-target: writing-skills | writing-rules |
              mechanical re-check | "run auditing-readme" (reference-only) | owner action | accept>
```

A class with no findings gets an explicit line — never a silently omitted class:

```text
Class 5 (rule-vs-rule): no conflicts found
```

## Disagreement rule (mechanical vs judgment)

- The **mechanical layer is authoritative on existence** — deterministic: a collision/invariant-break/orphan either is present or is not.
- A **judgment subagent may only annotate** a mechanical finding — downgrade its severity to `Info` with a written rationale (e.g. "trigger overlap intentional; the skills are complementary"). It **never deletes** a mechanical finding. The finding stays visible; the user decides at the picker.
