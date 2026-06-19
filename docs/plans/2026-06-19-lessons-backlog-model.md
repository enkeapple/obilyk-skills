# Lessons-Backlog-Model Implementation Plan

**Goal:** Convert `lessons-learned.md` from an append-only archive into a transient candidate-rules backlog: capture dedups against rules + the ledger, promotion deletes the contributing entry bodies, and a one-time cleanup removes 5 already-covered entries.

**Architecture:** The lifecycle lives in `writing-lessons/SKILL.md` (Task 1 — the owning skill). The log file is migrated to the new header + cleaned (Task 2). The model wording is propagated to the glossary and `.claude/CLAUDE.md` (Task 3). git is the archive; `## Promoted clusters` is the permanent "covered" index.

**Tech stack:** Markdown only (one skill, two rule/manual docs, the log). No app code.

## Global constraints

- Mode AUTHOR on the vault. Verification = skill validators + RED/GREEN **subagent runs** + grep — never unit tests / `pnpm` / build.
- **R1:** an entry-body DELETE is only ever part of a confirmed-promotion change (rule + ledger in the same commit). The SOLE exception is the one-time cleanup in Task 2 (its rules already exist).
- **R2:** a new instance of an already-promoted cause-tag whose rule is too narrow → SCALE the rule via `writing-rules`; never re-add a backlog entry.
- All edits to `lessons-learned.md` run with the `writing-lessons` skill invoked this turn (satisfies `detect-bypass.sh` 1b — no hook change).
- `writing-lessons` is edited at its source `skills/authoring/writing-lessons/SKILL.md` (the `.claude/skills/writing-lessons` symlink). No routing/symlink change.
- The 5 lessons-bar files from earlier this session are uncommitted; this plan re-edits `writing-lessons`. Land the lessons-bar commits first so the two logical changes stay separate. Human owns commits.

---

## Task 1 — Rework `writing-lessons` to the backlog lifecycle

**Files:** `skills/authoring/writing-lessons/SKILL.md` — header (15), Two-levels bullet (48), NEW capture-dedup section (before "Capture an entry"), promotion steps (79–81), scan note (after 68), red flag (94), verification (108).

**Interfaces:**

- **Consumes:** nothing.
- **Produces — the lifecycle the other tasks rely on:** capture = dedup(rules + ledger) → SKIP / SCALE-rule / add; promote = author rule + DELETE bodies + ledger line, one commit; ledger line format `- <cause-tag> → rules/<path>.md (YYYY-MM-DD)`.

**Steps:**

- [ ] 1.1 RED (capture-dedup efficacy). Dispatch a subagent with ONLY the current `## When to use` / `## When NOT to use` text (no dedup step) + scenario: *"You just hit a no-op-skill mistake. A rule `scoping-skill-value.md` already covers that class and `## Promoted clusters` lists `skill-value-vs-noop`. Do you add a new lessons entry? CAPTURE or SKIP + why."* Expected RED: ambiguous/CAPTURE — nothing tells it to consult the ledger and skip. Record.

- [ ] 1.2 Edit header (line 15). Replace:

  ````text
  The log lives at `.claude/lessons-learned.md`. It is **append-only**: new entries go at the top of `## Entries`, nothing is rewritten or deleted. A `## Promoted clusters` ledger sits at the bottom. The promotion path turns a recurring lesson into an actionable rule under `.claude/rules/`.
  ````

  with:

  ````text
  The log lives at `.claude/lessons-learned.md`. It is a **transient backlog** of un-promoted candidate rules: new entries go at the top of `## Entries`; when a cause-tag is promoted to (or already covered by) a rule, its entry bodies are **deleted** and the tag is recorded in the `## Promoted clusters` ledger at the bottom — git keeps the history (`git log -S '<cause-tag>'`). Deletion happens only via this skill, inside a confirmed promotion. The promotion path turns a recurring lesson into an actionable rule under `.claude/rules/`.
  ````

- [ ] 1.3 Edit Two-levels bullet (line 48). Replace:

  ````text
  - **`.claude/lessons-learned.md` is an on-demand archive.** It is NOT loaded into every session. Read it only at capture time, or when you suspect you are repeating a past mistake. It can grow without polluting context.
  ````

  with:

  ````text
  - **`.claude/lessons-learned.md` is an on-demand backlog.** It is NOT loaded into every session. Read it only at capture time, or when you suspect you are repeating a past mistake. It stays small because promoted tags are deleted from it (git keeps the history).
  ````

- [ ] 1.4 Insert the capture-dedup section immediately before `## Capture an entry` (current line 53):

  ````text
  ## Before capturing: dedup against rules and the ledger

  The log holds only un-promoted candidates. Before appending, derive the cause-tag and check the `## Promoted clusters` ledger AND the rules under `.claude/rules/` for that class:

  - **Covered, and the rule handles this instance** → SKIP — do not add an entry; the rule already carries the guidance.
  - **Tag is in the ledger but the rule is too narrow for this variant** → SCALE the rule now via `writing-rules`; do NOT add a backlog entry (a promoted tag never re-enters `## Entries`).
  - **Not covered** → add/increment an entry in `## Entries` (below).

  ````

- [ ] 1.5 Edit promotion steps 2 and 4 (lines 79, 81). Replace line 79:

  ````text
  2. Append a back-reference to each contributing entry: `→ promoted to rules/<...>.md`.
  ````

  with:

  ````text
  2. **Delete the contributing entry bodies** from `## Entries` (git preserves them via `git log -S`). Deletion is allowed ONLY here, inside this confirmed-promotion change — never as a standalone log tidy.
  ````

  and replace line 81:

  ````text
  4. Commit the new rule and the back-references + ledger line together.
  ````

  with:

  ````text
  4. Commit the new/extended rule, the entry deletions, and the ledger line together (one commit).
  ````

- [ ] 1.6 Add the scan note. After line 68 (the `Any tag with **count ≥ 3** …` paragraph), append a sentence to that paragraph or a new line:

  ````text
  Under the backlog model promoted tags are deleted from `## Entries`, so any tag still at count ≥ 3 here is always live debt — promote it or add a ledger line justifying why it does not generalize.
  ````

- [ ] 1.7 Edit red flag (line 94). Replace:

  ````text
  - Rewriting/overwriting the log instead of appending.
  ````

  with:

  ````text
  - Deleting an entry body OUTSIDE a confirmed-promotion change (the only standalone deletion allowed was the one-time backlog cleanup).
  ````

- [ ] 1.8 Edit verification (line 108). Replace:

  ````text
  The diff shows the entry was appended (and, for a promotion, the new rule file + back-references + ledger line all changed). Then re-run the promotion-debt tally (above) — it must show no untracked cause-tag at count ≥ 3.
  ````

  with:

  ````text
  The diff shows a capture as one added entry; a promotion as the new/extended rule + the deleted entry bodies + the ledger line, all in one commit. Then re-run the promotion-debt tally (above) — it must show no untracked cause-tag at count ≥ 3.
  ````

- [ ] 1.9 Validators:

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  F=skills/authoring/writing-lessons/SKILL.md
  echo "name:"; grep -nE '^name: [a-z0-9-]+$' "$F"
  echo "frontmatter bytes:"; awk '/^---$/{n++; next} n==1{c+=length($0)+1} n==2{print c; exit}' "$F"
  echo "fences even:"; grep -c '^```' "$F"
  echo "ref links:"; grep -oE 'references/[a-zA-Z0-9_-]+\.md' "$F" | sort -u | while read r; do test -f "skills/authoring/writing-lessons/$r" && echo "OK $r" || echo "MISSING $r"; done
  echo "words:"; wc -w "$F"
  ```

  Expected: `name: writing-lessons`; frontmatter < 1024; fence count even; ref links OK; sane word count.

- [ ] 1.10 GREEN (capture-dedup). Dispatch a subagent with the NEW capture-dedup section + the three scenarios: (i) tag covered & in ledger → expected **SKIP**; (ii) genuinely new uncovered class → expected **ADD**; (iii) tag in ledger but the rule misses this variant → expected **SCALE the rule, no entry** (R2). All three correct = GREEN.

- [ ] 1.11 Commit:

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  git add skills/authoring/writing-lessons/SKILL.md
  git commit -m "feat(writing-lessons): make the lessons log a transient backlog"
  ```

---

## Task 2 — Migrate + clean `lessons-learned.md`

**Files:** `.claude/lessons-learned.md` — header (line 3); delete 5 entry bodies; add `markdown-fence-counting` ledger line.

**Interfaces:**

- **Consumes:** the lifecycle from Task 1 (header wording aligns with the skill).
- **Produces:** a cleaned backlog (12 entries) + a ledger with both covered tags.

**Steps:**

- [ ] 2.1 RED (state of the log). Run:

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  echo "entries:"; grep -c '^### ' .claude/lessons-learned.md
  echo "deleted-target tags present:"; grep -nE 'Cause-tag:\*\* .(skill-value-vs-noop|markdown-fence-counting)' .claude/lessons-learned.md
  ```

  Expected RED: 17 entries; 5 Cause-tag lines for the two target tags present (4× skill-value-vs-noop, 1× markdown-fence-counting).

- [ ] 2.2 Edit header (line 3). Replace:

  ````text
  Append-only — never rewrite or delete an entry; new entries go at the top of `## Entries`. When a `Cause-tag` reaches 3×, **invoke the `writing-lessons` skill** (do not hand-promote): it dispatches an independent promotion review and, on a Promote verdict, authors the rule under `.claude/rules/` via `writing-rules`, then records the cluster in `## Promoted clusters`.
  ````

  with:

  ````text
  Transient backlog of un-promoted candidate rules — newest at the top of `## Entries`. When a `Cause-tag` reaches 3×, **invoke the `writing-lessons` skill** (do not hand-promote): it dispatches an independent promotion review and, on a Promote verdict, authors the rule under `.claude/rules/` via `writing-rules`, **deletes the contributing entries**, and records the tag in `## Promoted clusters`. git keeps deleted entries (`git log -S '<cause-tag>'`); deletion happens only via the skill, inside a confirmed promotion (or this one-time cleanup).
  ````

- [ ] 2.3 Delete the 5 entry bodies (each from its `### ` header through the blank line before the next `### `). Targets, by header:

  ````text
  ### 2026-06-19 — "Render SDD phases as a task list" was a no-op for the lifecycle case …
  ### 2026-06-19 — A discipline-gate skill had no observable RED in-vault …
  ### 2026-06-19 — "Add a verify/review phase" defaults to a no-op …
  ### 2026-06-19 — A skill's "principles" are a no-op for a strong model …
  ### 2026-06-19 — Naive fence-toggle corrupts markdown-in-markdown when auto-fixing
  ````

  Each body includes its own `→ promoted to rules/...` back-reference line — that line is inside the body and is removed with it (no orphan). For the final target (`Naive fence-toggle…`), stop the deletion before the `## Promoted clusters` heading (delete the entry lines + the trailing blank). Keep every other entry (12 remain), including both `wrong-assumption` (2×), `self-check-format-drift` (2×), `fix-instance-not-generator` (2×).

- [ ] 2.4 Add the ledger line under `## Promoted clusters` (the `skill-value-vs-noop` line already exists). Append:

  ````text
  - markdown-fence-counting → rules/common/markdown-style.md (2026-06-19)
  ````

- [ ] 2.5 GREEN (post-cleanup):

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  echo "entry count (want 12):"; grep -c '^### ' .claude/lessons-learned.md
  echo "deleted cause-tags absent:"; grep -nE 'Cause-tag:\*\* .(skill-value-vs-noop|markdown-fence-counting)' .claude/lessons-learned.md && echo "FAIL: a body remains" || echo "clean"
  echo "ledger:"; sed -n '/## Promoted clusters/,$p' .claude/lessons-learned.md
  echo "promotion-debt tally (no tag >=3):"; grep -oE '^[[:space:]]*-[[:space:]]+\*\*Cause-tag[^[:alnum:]]+[a-z0-9-]+' .claude/lessons-learned.md | sed -E 's/.*Cause-tag[^[:alnum:]]+//' | sort | uniq -c | sort -rn
  ```

  Expected: count 12; `clean`; ledger lists `skill-value-vs-noop` AND `markdown-fence-counting`; tally shows max count 2 (no tag ≥ 3).

- [ ] 2.6 Commit:

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  git add .claude/lessons-learned.md
  git commit -m "chore(lessons): migrate log to backlog model and clean covered entries"
  ```

---

## Task 3 — Propagate the model to glossary + operating manual

**Files:** `.claude/rules/common/domains-glossary.md` (lines 33, 42); `.claude/CLAUDE.md` (line 109). `hooks/routing/detect-bypass.sh` — verify only (NONE).

**Interfaces:**

- **Consumes:** the lifecycle (Task 1) + the cleaned log (Task 2).
- **Produces:** nothing downstream (terminal task).

**Steps:**

- [ ] 3.1 Edit glossary lessons row (line 33). Replace:

  ````text
  | 7 | **lessons** | [lessons-learned.md](../../lessons-learned.md) | append-only log | captured bottleneck; 3× same cause-tag → promoted to a rule |
  ````

  with:

  ````text
  | 7 | **lessons** | [lessons-learned.md](../../lessons-learned.md) | transient candidate-rules backlog (un-promoted only); git = archive | captured bottleneck; on promotion (3×) its entries are deleted and the tag recorded in `## Promoted clusters` |
  ````

- [ ] 3.2 Edit glossary line 42. Replace:

  ````text
  - **"lesson" vs "rule"** — a **lesson** is one entry in `lessons-learned.md`; it becomes a **rule** only after the same cause-tag recurs 3× and is promoted via `writing-rules`.
  ````

  with:

  ````text
  - **"lesson" vs "rule"** — a **lesson** is one entry in `lessons-learned.md`; it becomes a **rule** only after the same cause-tag recurs 3× and is promoted via `writing-rules`, at which point its lesson entries are deleted from the backlog (git keeps them).
  ````

- [ ] 3.3 Edit `.claude/CLAUDE.md` Lessons promotion path (line 109). Replace:

  ````text
  A bottleneck/failure → an entry in [lessons-learned.md](./lessons-learned.md) (use `writing-lessons`). Same root cause 3+ times → an actionable rule under `.claude/rules/` (use `writing-rules`). Mark each contributing entry `→ promoted to rules/<file>.md`.
  ````

  with:

  ````text
  A qualifying lesson → an entry in [lessons-learned.md](./lessons-learned.md) (use `writing-lessons`). Same root cause 3+ times → an actionable rule under `.claude/rules/` (use `writing-rules`); promotion **deletes** the contributing entries from the backlog and records the tag in `## Promoted clusters` (git keeps the history).
  ````

- [ ] 3.4 GREEN — no leftover append-only language + composition check:

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  echo "leftover append-only (want none):"; grep -niE "append-only|never rewrite or delete|nothing is rewritten" .claude/lessons-learned.md skills/authoring/writing-lessons/SKILL.md .claude/rules/common/domains-glossary.md .claude/CLAUDE.md && echo "FAIL leftover" || echo "GREEN clean"
  echo "detect-bypass 1b still gates lessons (NONE expected, just confirm it references writing-lessons):"; grep -nE 'lessons-learned\.md|writing-lessons' hooks/routing/detect-bypass.sh
  ```

  Expected: `GREEN clean`; detect-bypass still shows its 1b branch referencing `writing-lessons` (unchanged, composes).

- [ ] 3.5 Commit:

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  git add .claude/rules/common/domains-glossary.md .claude/CLAUDE.md
  git commit -m "docs(rules): align glossary and manual with the lessons backlog model"
  ```

---

## Self-review

- **Spec coverage:** header→1.2/2.2; capture-dedup+R2→1.4/1.10; promotion-deletes+R1→1.5; scan note→1.6; red flag→1.7; verification→1.8; one-time cleanup→2.3/2.4; glossary→3.1/3.2; CLAUDE.md→3.3; detect-bypass NONE→3.4; leftover-append-only grep→3.4. All covered.
- **Show-don't-describe:** every edit step shows the actual old + new block; every test step is an exact subagent prompt + expected verdict or a shell command + expected output; every task commits.
- **Consistency:** the ledger-line format and the SKIP/SCALE/add three-way are identical in Task 1's section and the spec; R1 (delete only in promotion) stated in Global constraints + 1.5 + 1.7; R2 in 1.4 + 1.10.

## Execution handoff

Tasks are tightly coupled (one subsystem; Task 2/3 wording mirrors Task 1). Recommended: **`inline-driven-development`** solo. Before the first edit, run `pre-implementation-protocol` (confirm anchors, the verification commands above, clean git baseline — ideally after the lessons-bar commits land). Each task's "test" maps RED→GREEN to the subagent/grep steps shown.
