# Spec: Raise the lessons-capture bar (stop over-capture)

> Mode: AUTHOR (vault's own CLAUDE.md files + skills). Source: approved `grilling` design + Decisions 1–11.

## Goal

Replace the floor-level "capture on **any** friction" lessons mandate with an operational bar — capture a lesson only when it (A) yields a concrete reusable check and (B) is a recurring/non-obvious error *class* — so the log stops accumulating one-off noise (16 entries in one day), while genuine failures still capture every time.

## Scope

- Rewrite `.claude/CLAUDE.md` non-negotiable #6 to carry an inline (A)+(B) bar, the "most turns produce no lesson" norm, the genuine-failure MUST-capture invariant, and delegation to `writing-lessons`.
- Soften `.claude/CLAUDE.md` Checklist #8 and the status-block `Pending lessons` line so "none" / "N/A" is the expected default.
- Merge the operational (A)+(B) bar into `writing-lessons` `## When to use` / `## When NOT to use` (single criterion, sole owner).
- Align root `./CLAUDE.md` capture wording; grep both CLAUDE.md for leftover "any friction / always" phrasing.
- Bring the generator template (`bootstrapping-claude-md/references/operating-manual-template.md`) up to the new bar + none-default.
- Add an "over-broad capture criterion" drift class to `auditing-claude-md`.

## Out of scope

- Re-judging / editing the 16 existing log entries — `lessons-learned.md` is append-only (`.claude/skills/writing-lessons/SKILL.md:15`). Decision 9.
- The missing `## Promoted clusters` ledger line for `skill-value-vs-noop` (3×) — separate bookkeeping follow-up.
- `lessons-nudge.sh` hook (already narrow — fires only on the skill-bypass flag). Decision 5.
- `writing-lessons` routing triggers in `skills-routing.json`; the lesson-entry template/format; the promotion-debt scan and `writing-rules` path.

## Contracts

The load-bearing artifact is the **wording contract** (Decision 7). All six edits use the same operational bar; the auditor (edit 6) checks for its absence.

**The operational bar (canonical wording, reused across edits):**

```text
Capture a lesson only when BOTH hold:
  (A) you can name a concrete check / Prevention a future session will actually run, AND
  (B) it is an error *class* a competent future agent would repeat (non-obvious; plausibly recurs).
Negative test: if all you'd write is "today I did X" with no reusable check — do not capture.
Most turns produce no lesson; that is normal, not a skipped step.
MUST-capture invariant: a turn that exposed a hallucinated symbol/API/skill-name, a wrong
assumption, a test that passed for the wrong reason, or an owner correction of a non-obvious
choice still captures the same turn — the bar raises the floor, it does not make these optional.
```

**Edit 1 — `.claude/CLAUDE.md:16` non-negotiable #6.** Current:

```text
6. **Capture the bottleneck, same turn.** When a turn exposes friction in a skill or a hand-off between skills (a misfire, a leak, an over-rigid step), or the owner corrects a non-obvious choice, capture it the SAME turn by invoking the `writing-lessons` skill (the `Skill` tool) — deferring loses it, and editing [lessons-learned.md](./lessons-learned.md) directly bypasses the cause-tag discipline and promotion-debt scan the skill owns. `lessons-nudge.sh` (Stop) backstops; every status block carries a `Pending lessons` line.
```

Target #6 must, in this order: (a) state capture is gated by the (A)+(B) bar with the negative test inline; (b) state "most turns produce no lesson — normal"; (c) carry the MUST-capture invariant for genuine failures; (d) keep "same turn" *for lessons passing the bar*; (e) keep "capture by invoking the `writing-lessons` skill, not a direct edit to `lessons-learned.md`" (preserve the existing bypass-discipline clause); (f) keep the `lessons-nudge.sh` backstop note. Drop the words "any friction", "the bottleneck", and any framing that reads as "every turn".

**Edit 2a — `.claude/CLAUDE.md:58` Checklist #8.** Current:

```text
| 8 | Bottleneck captured | Any friction found this turn captured via the `writing-lessons` skill (the `Skill` tool), not a direct edit to `lessons-learned.md` |
```

Target: rename the Item from "Bottleneck captured" to "Lesson captured (if any)"; Done-when text → a lesson that **met the (A)+(B) bar** was captured via the `writing-lessons` skill (not a direct edit to `lessons-learned.md`), **or `[N/A]` — no turn met the bar** (the expected default).

**Edit 2b — `.claude/CLAUDE.md:93` status-block `Pending lessons` line.** Current:

```text
- **Pending lessons** — <captured this turn via writing-lessons, or none>
```

Target: make "none" the expected default, e.g. `- **Pending lessons** — <captured this turn via writing-lessons if a turn met the bar, else "none" (typical)>`.

**Edit 3 — `.claude/skills/writing-lessons/SKILL.md` `## When to use` (21–24) / `## When NOT to use` (28–29).** MERGE the bar into these existing sections (Decision 8 — no parallel section). `## When to use` must lead with the (A)+(B) gate (both conditions required) before the example list; the existing examples (non-obvious bug, hallucinated symbol/API, test-passed-wrong-reason, library pitfall, recurrence) stay as instances that pass the bar. `## When NOT to use` must include the negative test ("if all you'd write is 'today I did X' with no reusable check") and "most turns produce no lesson" alongside the existing two bullets (routine typos/changelog; already-encoded-in-rules). No second criterion introduced anywhere in the file.

**Edit 4 — `./CLAUDE.md:13` (root) Hard-rules capture bullet.** Current:

```text
- **Capture bottlenecks the same turn.** Friction in a skill or a hand-off → a `writing-lessons` entry now; recurring (3×) → `writing-rules`.
```

Target: align to the bar — capture a *qualifying* lesson (passes the bar) the same turn via `writing-lessons`; recurring (3×) → `writing-rules`. Drop the unconditional "Friction → entry now".

**Edit 5a — `bootstrapping-claude-md/references/operating-manual-template.md:32`.** Already uses "non-obvious failure" (closer to target). Light touch: add the (A)+(B) gate phrasing + "most turns produce no lesson — normal" so a bootstrapped consumer repo inherits the bar, not a per-turn reflex.

**Edit 5b — same file, line 103** (`- **Pending lessons** — <captured this turn via the lessons skill, or none>`): make "none" the expected default, mirroring Edit 2b.

**Edit 6 — `auditing-claude-md/SKILL.md`.** Add a drift class mirroring the existing bypass-wording class at lines 32 / 61 / 71: flag a non-negotiable or pointer that mandates capture on "any friction" / makes the `Pending lessons` line mandatory (no "none"/N/A default) / lacks the (A)+(B) bar. The check must reference the **same** operational wording as Edit 1 so auditor and generated CLAUDE.md cannot disagree on "over-broad". Add one Step bullet, one Red-flag bullet, and one Rationalization-table row (matching the file's existing structure).

## Files touched

| File | Kind | Why |
| --- | --- | --- |
| `.claude/CLAUDE.md` | EDIT | #6 (line 16), Checklist #8 (58), status-block Pending line (93) — Edits 1, 2a, 2b |
| `.claude/skills/writing-lessons/SKILL.md` | EDIT | merge (A)+(B) bar into When-to-use / When-NOT — Edit 3 |
| `CLAUDE.md` (root) | EDIT | align capture bullet (line 13) — Edit 4 |
| `skills/foundation/bootstrapping-claude-md/references/operating-manual-template.md` | EDIT | bar + none-default in template (lines 32, 103) — Edits 5a, 5b |
| `skills/foundation/auditing-claude-md/SKILL.md` | EDIT | new over-broad-criterion drift class — Edit 6 |

Note: `writing-lessons`, `bootstrapping-claude-md`, `auditing-claude-md` are reached via their flat symlinks under `.claude/skills/`; edits land in the `skills/<category>/...` source. No NEW/DELETE files; no routing/symlink change (names/locations/triggers unchanged → no `skill-routing-sync` work).

## Edge cases

- **Empty turn (typical):** a turn with no qualifying failure → no lesson, Checklist #8 `[N/A]`, status-block `Pending lessons: none`. Must read as normal, not a skipped gate.
- **Genuine failure under the relaxed framing:** a hallucinated symbol / wrong assumption / wrong-reason pass / owner-correction still MUST capture — the MUST-capture invariant prevents the relaxation from becoming under-capture (Decision 11). This is the inversion to test in RED/GREEN.
- **#6 read without `writing-lessons` loaded:** the bar must be applicable from #6 alone (it is on-demand; not loaded at decision time) — #6 carries the inline bar, delegates only the *full discipline* (cause-tag, promotion scan) to the skill (Decision 10).
- **Two-criteria drift:** `writing-lessons` must hold exactly one criterion after the merge; a parallel "new bar" section beside the old When-text would re-create the divergence this fixes (Decision 8).
- **Auditor vs generator agreement:** Edit 6's "over-broad" definition must be the same wording as Edit 1/Edit 5a, or the auditor flags freshly-bootstrapped CLAUDE.md as drift.

## Verification

Vault verification = skill validators + RED/GREEN subagent runs (no app code, no unit tests). Per changed surface:

- **Validators** (root `CLAUDE.md` → "Common commands"): frontmatter ≤1024, `name` regex, every `references/*.md` link resolves, fences balanced, word count sane — run on `writing-lessons`, `bootstrapping-claude-md`, `auditing-claude-md`. Paste output.
- **RED (baseline):** subagent given the OLD #6 / old When-text + a turn that contains only trivial friction (a routine rename, a typo) → confirm it captures a noise lesson (reproduces over-capture). Separately, a turn with a hallucinated-symbol failure → confirm it captures (control).
- **GREEN (with edits):** same noise turn → no lesson captured (`Pending lessons: none`, #8 `[N/A]`); same hallucinated-symbol turn → still captures (MUST-capture invariant holds). This double check proves the bar rejects noise *without* suppressing genuine failures.
- **Auditor check (Edit 6):** hand `auditing-claude-md` a CLAUDE.md still carrying "capture on any friction" → it flags the over-broad-criterion drift; hand it the post-edit #6 → it does not flag.
- **Grep:** `grep -niE "any friction|capture the bottleneck|bottleneck.*same turn" CLAUDE.md .claude/CLAUDE.md` returns nothing after edits.

## Risks

- **Under-capture over-correction:** relaxing #6 could read as "capture is optional" and suppress genuine failures. Mitigation: the MUST-capture invariant (Decision 11) + the GREEN control run that asserts genuine-failure capture still fires.
- **Subjective (B) at capture time:** "plausibly recurs / non-obvious" is judgment, the precedent failure `unfollowable-literal-criterion`. Mitigation: the concrete **negative test** anchors it ("only 'today I did X' with no reusable check → skip"), turning judgment into a runnable check (Decision 7).
- **Bar drift between the 5 prose surfaces:** five files restating one bar can diverge. Mitigation: one canonical wording block (Contracts) copied verbatim; Edit 6's auditor enforces it going forward.
