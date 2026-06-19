# Spec: lessons-learned as a transient candidate-rules backlog

> Mode: AUTHOR (vault skills + rules + CLAUDE.md). Source: approved `grilling` design (xhigh pass), Decisions 1–6 + refinements R1–R2. Follow-on to the (A)+(B) capture-bar change (orthogonal; stays).

## Goal

Convert `lessons-learned.md` from an append-only archive into a transient backlog of un-promoted candidate rules: a cause-tag's entry bodies are deleted when the tag is promoted to (or already covered by) a rule, leaving `## Promoted clusters` as the permanent "what is covered" index and git as the archive.

## Scope

- Replace the append-only invariant with the backlog-churn model across the 4 doc surfaces that assert it.
- Make `writing-lessons` capture a STRUCTURAL dedup step: check existing rules + the `## Promoted clusters` ledger before adding an entry (skip if covered; scale the rule if a promoted tag's rule is too narrow — R2).
- Change `writing-lessons` promotion: on a confirmed promotion, DELETE the contributing entry bodies and write the ledger line in the same commit (R1) — no standalone log-tidying deletes.
- One-time cleanup of `.claude/lessons-learned.md`: delete the 5 already-covered entry bodies; add the `markdown-fence-counting` ledger line (Decision 6).
- Keep the promotion-debt scan working under deletion (a tag in `## Entries` can no longer reach 3 without being live debt).

## Out of scope

- The (A)+(B) capture-bar change (shipped this session, uncommitted) — untouched except where the same `writing-lessons` sections are edited.
- Renaming `lessons-learned.md` or splitting it into multiple files.
- The foreign "phase-task-visualization" changes uncommitted in the tree (`skills/apply-chain/*`, `phase-task-visualization.md`, its lessons entry) — not ours.
- `writing-lessons` routing triggers; the lesson-entry template fields; `lessons-nudge.sh`; `detect-bypass.sh` (composition verified, no change needed).
- A periodic "stale 1×/2× backlog entry" review.

## Contracts

The change has no code; the contract is the **lifecycle procedure** + the **exact doc wording**. The ledger line format is canonical and reused by capture-dedup, promotion, and the scan.

**Backlog lifecycle (the model):**

```text
CAPTURE a candidate (after it passes the (A)+(B) bar):
  1. Derive its cause-tag.
  2. Is the tag in `## Promoted clusters`, OR is the class already covered by a rule under .claude/rules/?
       - covered, and the rule handles THIS instance      -> SKIP (no entry).
       - tag promoted but the rule is too NARROW for this variant
                                                           -> SCALE the rule now via writing-rules; no entry (R2).
       - not covered                                       -> add/increment an entry in `## Entries`.

PROMOTE (a tag in `## Entries` reaches 3×, promotion-reviewer returns Promote):
  In ONE commit (R1):
    a. author/extend the rule via writing-rules,
    b. DELETE the contributing entry bodies from `## Entries`,
    c. add a ledger line to `## Promoted clusters`.
  No delete is ever standalone (only exception: the one-time Decision-6 cleanup).

ARCHIVE / RECOVERY:
  - deleted bodies live in git (`git log -S '<cause-tag>' -- .claude/lessons-learned.md`).
  - a too-narrow rule is found via its ledger tag->rule pointer and scaled; bodies are never resurrected.
```

**Ledger line (canonical format, unchanged):**

```text
- <cause-tag> → rules/<path>.md (YYYY-MM-DD)
```

`## Promoted clusters` now indexes every cause-tag resolved into a rule — whether by 3× promotion or by direct codification into an existing rule (e.g. `markdown-fence-counting` → `markdown-style.md`).

**`.claude/lessons-learned.md` header — current (line 3):**

```text
Append-only — never rewrite or delete an entry; new entries go at the top of `## Entries`. When a `Cause-tag` reaches 3×, **invoke the `writing-lessons` skill** (do not hand-promote): it dispatches an independent promotion review and, on a Promote verdict, authors the rule under `.claude/rules/` via `writing-rules`, then records the cluster in `## Promoted clusters`.
```

Target: state the backlog model — `## Entries` is a transient backlog of un-promoted candidates (newest on top); on promotion the contributing bodies are DELETED and a `## Promoted clusters` line records the tag → rule (git keeps the history); deletion happens only via the `writing-lessons` skill as part of a confirmed promotion.

**`writing-lessons/SKILL.md` edits (anchors verified):**

- **Line 15** (append-only statement) → restate as backlog: bodies are deleted on promotion, not retained; `## Promoted clusters` is the permanent ledger; git is the archive.
- **New capture-dedup subsection** (before "Capture an entry", ~line 50): the CAPTURE branch of the lifecycle above — check rules + ledger; SKIP if covered; SCALE the rule (R2) if a promoted tag's rule is too narrow; else add/increment.
- **Promotion path, steps 2–4 (lines 79–81)** — current step 2 "Append a back-reference to each contributing entry: `→ promoted to rules/<...>.md`" → replace with "DELETE the contributing entry bodies from `## Entries`"; keep step 3 (ledger line) and step 4 (commit rule + deletion + ledger together). Add R1: deletion only inside this promotion commit, never standalone.
- **Promotion-debt scan note (lines 59–68)** — add: under the backlog model a tag in `## Entries` cannot reach 3 without being live debt (promoted tags are deleted), so any tag at ≥3 is always actionable.
- **Red Flag line 94** "Rewriting/overwriting the log instead of appending." → replace with the new hazard: "Deleting an entry body OUTSIDE a confirmed-promotion commit (the only standalone delete allowed was the one-time backlog cleanup)."
- **Verification (line 108)** — update the diff expectation: a capture shows an added entry; a promotion shows the new/extended rule + DELETED bodies + ledger line in one commit.

**`domains-glossary.md` line 33 (lessons row #7) — current:**

```text
| 7 | **lessons** | [lessons-learned.md](../../lessons-learned.md) | append-only log | captured bottleneck; 3× same cause-tag → promoted to a rule |
```

Target: surface = "transient candidate-rules backlog (un-promoted only); git = archive"; represents = "captured bottleneck; on promotion its bodies are deleted and `## Promoted clusters` records tag → rule". Line 42 ("a **lesson** is one entry … becomes a **rule** only after the same cause-tag recurs 3× and is promoted") gains: "on promotion the lesson's entries are removed from the backlog."

**`.claude/CLAUDE.md` line 109 (Lessons promotion path) — current:**

```text
A bottleneck/failure → an entry in [lessons-learned.md](./lessons-learned.md) (use `writing-lessons`). Same root cause 3+ times → an actionable rule under `.claude/rules/` (use `writing-rules`). Mark each contributing entry `→ promoted to rules/<file>.md`.
```

Target: "… Same root cause 3+ times → a rule (use `writing-rules`); promotion DELETES the contributing entries from the backlog and records the tag in `## Promoted clusters` (git keeps the history)."

## Files touched

| File | Kind | Why |
| --- | --- | --- |
| `.claude/lessons-learned.md` | EDIT | rewrite header (line 3); delete 5 covered entry bodies; add `markdown-fence-counting` ledger line |
| `.claude/skills/writing-lessons/SKILL.md` | EDIT | capture-dedup step + R2; promotion deletes bodies + R1; drop append-only (15); scan note; red flag (94); verification (108) |
| `.claude/rules/common/domains-glossary.md` | EDIT | lessons row #7 (33) + line 42 to backlog model |
| `.claude/CLAUDE.md` | EDIT | Lessons promotion path (109) to deletion + ledger |
| `hooks/routing/detect-bypass.sh` | NONE | composition verified: 1b warns only if `writing-lessons` not invoked; deletion via the invoked skill satisfies it |

Note: `writing-lessons` edited via its source `skills/authoring/writing-lessons/SKILL.md` (the `.claude/skills/writing-lessons` symlink). No routing/symlink change.

**Decision-6 cleanup — exact entries to DELETE (bodies) from `## Entries`:**

```text
skill-value-vs-noop (4th instance)  — "Render SDD phases as a task list…"
skill-value-vs-noop (3rd instance)  — "A discipline-gate skill had no observable RED…"
skill-value-vs-noop (2nd instance)  — "Add a verify/review phase defaults to a no-op…"
skill-value-vs-noop (1st instance)  — "A skill's principles are a no-op for a strong model…"
markdown-fence-counting             — "Naive fence-toggle corrupts markdown-in-markdown…"
```

KEEP every other entry, including both `wrong-assumption` (2×) and `self-check-format-drift` (2×) and `fix-instance-not-generator` (2×) — live un-promoted candidates. Ledger after cleanup must contain `skill-value-vs-noop → …scoping-skill-value.md` (exists) and a new `markdown-fence-counting → rules/common/markdown-style.md (2026-06-19)`.

## Edge cases

- **Promoted tag, new variant the rule misses (R2):** must SCALE the rule, not silently SKIP (loses the variant) and not add an entry under a promoted tag (the tag is resolved). This is the testable GREEN case (iii).
- **Covered by a rule but only 1× (codified, never a 3× cluster):** still SKIP at capture; its ledger line is legitimate (`markdown-fence-counting`). The ledger indexes "covered", not only "3×-promoted".
- **Wrongly-promoted cluster later reversed:** `git revert` restores the deleted bodies and the rule; no in-file resurrection path needed.
- **Direct edit without the skill:** `detect-bypass.sh` 1b still warns — the cleanup and all deletions must run with `writing-lessons` invoked this turn.
- **Scan false-zero:** the existing cause-tag scan regex (line ~60) must still match live entries after the wording change; re-run it post-cleanup and confirm no tag ≥3 untracked.

## Verification

Vault verification = validators + RED/GREEN subagent runs + grep (no app code).

- **Validators** on `writing-lessons`: frontmatter ≤1024, name regex, `references/*.md` links resolve, fences balanced, word count. Paste output.
- **RED/GREEN capture-dedup** (subagent given the new `writing-lessons` capture section + the post-cleanup ledger): (i) candidate whose tag is in `## Promoted clusters` / covered → **SKIP**; (ii) genuinely new uncovered candidate → **add to `## Entries`**; (iii) new instance of a promoted tag the rule does NOT cover → **SCALE the rule**, no new entry. All three correct = GREEN. These exercise behavior the prior discipline-RED could not.
- **Post-cleanup checks:**

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  echo "entry count:"; grep -c '^### ' .claude/lessons-learned.md            # 17 - 5 = 12
  echo "deleted cause-tags absent (anchor on Cause-tag body line, not header):"; grep -nE 'Cause-tag:\*\* .(skill-value-vs-noop|markdown-fence-counting)' .claude/lessons-learned.md && echo "FAIL: a deleted entry body remains" || echo "clean"
  echo "ledger lines:"; sed -n '/## Promoted clusters/,$p' .claude/lessons-learned.md
  echo "promotion-debt tally:"; grep -oE '^[[:space:]]*-[[:space:]]+\*\*Cause-tag[^[:alnum:]]+[a-z0-9-]+' .claude/lessons-learned.md | sed -E 's/.*Cause-tag[^[:alnum:]]+//' | sort | uniq -c | sort -rn
  ```

  Expected: entry count 12; bodies clean; ledger has both `skill-value-vs-noop` and `markdown-fence-counting`; tally shows no tag at ≥3 (the deleted cluster is gone; `wrong-assumption`/`self-check-format-drift`/`fix-instance-not-generator` sit at 2, not debt).

- **grep no leftover append-only language:**

  ```bash
  grep -niE "append-only|never rewrite or delete|nothing is rewritten" \
    .claude/lessons-learned.md .claude/skills/writing-lessons/SKILL.md \
    .claude/rules/common/domains-glossary.md .claude/CLAUDE.md && echo "FAIL leftover" || echo "GREEN clean"
  ```

## Risks

- **Delete operation reintroduces the loss risk append-only prevented.** Mitigation R1: deletion only inside a confirmed-promotion commit (rule + ledger in the same commit), never standalone; git revert restores. The one-time cleanup is the sole exception, justified by pre-existing rules.
- **Capture-dedup over-skips a genuine variant of a promoted tag.** Mitigation R2 + GREEN case (iii): the rule-too-narrow branch forces scaling the rule instead of dropping the lesson.
- **Scan regex breaks on the reworded header/entries.** Mitigation: the tally command above is run post-cleanup as a verification gate; the regex anchors on the entry list-item marker, not header prose (per the `self-check-format-drift` lesson still live in the log).
