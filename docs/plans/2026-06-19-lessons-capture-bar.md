# Lessons-Capture Bar Implementation Plan

**Goal:** Replace the floor-level "capture on any friction" lessons mandate with an operational (A)+(B) bar across 5 files, so the log stops accumulating one-off noise while genuine failures still capture every time.

**Architecture:** One canonical "operational bar" wording block is authored once (Task 1, in `writing-lessons` — the sole owner) and reused verbatim across the four other surfaces. `.claude/CLAUDE.md` #6 carries an inline copy (the skill is on-demand, not loaded at decision time); the generator template seeds it into consumer repos; the auditor learns to flag its absence.

**Tech stack:** Markdown docs only (CLAUDE.md files + skill `SKILL.md` + a generator template). No app code.

## Global constraints

- Mode AUTHOR on the vault itself. Verification = skill validators + RED/GREEN **subagent pressure runs** + grep — NEVER unit tests / `pnpm` / build (no app code exists). Copied verbatim from the spec's Verification note.
- The canonical bar (Task 1, Interfaces → Produces) defines the (A)+(B)/negative-test/most-turns-none/MUST-capture **semantics**. Each surface adapts the phrasing to its slot (inline #6, one-bullet root, audit-criterion in the auditor) but must stay semantically identical — same conditions, same negative test, same invariant. Apply the literal block shown in each task's step; do not let a surface weaken or drop a clause.
- No NEW/DELETE files; no routing/symlink changes (no skill name/location/trigger changes → no `skill-routing-sync` work).
- Skills are edited at their source under `skills/<category>/<name>/`; `.claude/skills/<name>` is a flat symlink to that source — editing either path edits the same file.
- The human owns each commit; the plan shows the exact one-line Conventional Commit to propose, but does not run `git commit` autonomously.

---

## Task 1 — Author the canonical bar in `writing-lessons` (source of truth)

**Files:**

- `.claude/skills/writing-lessons/SKILL.md` (source: `skills/apply-chain/.../writing-lessons/SKILL.md` via symlink) — merge the bar into `## When to use` (21-24) and `## When NOT to use` (28-29). Single criterion (Decision 8 — no parallel section).

**Interfaces:**

- **Consumes:** nothing (this is the source).
- **Produces — the canonical bar wording** (reused verbatim downstream):
  - (A) Reusable check — you can name a concrete check / Prevention a future session will actually run.
  - (B) Recurring class — it is an error *class* a competent future agent would repeat (non-obvious; plausibly recurs), not a one-off tied to this exact spot.
  - Negative test — if all you'd write is "today I did X" with no reusable check, do not capture.
  - Norm — most turns produce no lesson; that is normal, not a skipped step.
  - MUST-capture invariant — a hallucinated symbol/API/skill-name, a wrong assumption, a test that passed for the wrong reason, or an owner correction of a non-obvious choice still captures the same turn.

**Steps:**

- [ ] 1.1 RED (efficacy baseline). Dispatch a subagent with ONLY the current `## When to use` / `## When NOT to use` text (lines 19-29) pasted in, and this scenario: *"This turn you renamed a local variable for clarity and fixed a typo in a comment. No bug, no surprise. Per these rules, do you capture a lesson? Answer CAPTURE or SKIP + one line."* Expected RED: it answers **CAPTURE** or is ambiguous (the current text has no negative test / no (A)+(B) gate — nothing forces SKIP). Record verbatim.

- [ ] 1.2 Edit `## When to use`. Replace lines 19-24:

  ````text
  ## When to use

  - A non-obvious bug got fixed, or a wrong assumption was caught mid-task ("I thought function X existed").
  - A hallucinated symbol/API, or a test that passed for the wrong reason.
  - A library/version pitfall bit you.
  - You notice you are hitting a problem you have seen before — check the log and the recurrence count.
  ````

  with:

  ````text
  ## When to use

  Capture a lesson only when **both** conditions hold (the bar):

  - **(A) Reusable check** — you can name a concrete check / Prevention a future session will actually run.
  - **(B) Recurring class** — it is an error *class* a competent future agent would repeat (non-obvious; plausibly recurs), not a one-off tied to this exact spot.

  Turns that pass the bar look like:

  - A non-obvious bug got fixed, or a wrong assumption was caught mid-task ("I thought function X existed").
  - A hallucinated symbol/API/skill-name, or a test that passed for the wrong reason.
  - A library/version pitfall bit you.
  - You notice you are hitting a problem you have seen before — check the log and the recurrence count.

  These genuine-failure classes are MUST-capture — do not let the bar talk you out of them.
  ````

- [ ] 1.3 Edit `## When NOT to use`. Replace lines 26-29:

  ````text
  ## When NOT to use

  - Routine typos or changelog-style notes ("today I fixed X") — the git log already does that.
  - A lesson already encoded in `.claude/rules/` — re-capturing wastes the log.
  ````

  with:

  ````text
  ## When NOT to use

  Most turns produce no lesson — that is normal, not a skipped step. Do not capture when:

  - The negative test fires: all you'd write is "today I did X" with no reusable check (fails (A)).
  - A one-off tied to this exact spot that a future agent would not repeat (fails (B)).
  - Routine typos or changelog-style notes — the git log already does that.
  - A lesson already encoded in `.claude/rules/` — re-capturing wastes the log.
  ````

- [ ] 1.4 Validators on `writing-lessons`. Run:

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  F=.claude/skills/writing-lessons/SKILL.md
  echo "name:"; grep -nE '^name: [a-z0-9-]+$' "$F"
  echo "frontmatter bytes:"; awk '/^---$/{n++; next} n==1{c+=length($0)+1} n==2{print c; exit}' "$F"
  echo "fences (must be even):"; grep -c '^```' "$F"
  echo "ref links resolve:"; grep -oE 'references/[a-zA-Z0-9_-]+\.md' "$F" | while read r; do test -f ".claude/skills/writing-lessons/$r" && echo "OK $r" || echo "MISSING $r"; done
  echo "words:"; wc -w "$F"
  ```

  Expected: `name: writing-lessons`; frontmatter bytes < 1024; fence count even; every ref link `OK`; word count in the low-hundreds (sane).

- [ ] 1.5 GREEN (efficacy). Re-dispatch the 1.1 subagent with the NEW `## When to use` + `## When NOT to use` text and the SAME typo/rename scenario. Expected: **SKIP** (negative test fires). Then a second scenario: *"This turn you discovered a function you called, `clearLayers()`, does not exist — you hallucinated it. CAPTURE or SKIP?"* Expected: **CAPTURE** (MUST-capture invariant). Both correct = GREEN.

- [ ] 1.6 Commit:

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  git add .claude/skills/writing-lessons/SKILL.md
  git commit -m "feat(writing-lessons): gate capture on the (A)+(B) bar"
  ```

---

## Task 2 — Apply the bar to `.claude/CLAUDE.md` (live operating manual)

**Files:**

- `.claude/CLAUDE.md` — non-negotiable #6 (line 16), Checklist row #8 (line 58), status-block `Pending lessons` line (line 93).

**Interfaces:**

- **Consumes:** the canonical bar wording from Task 1 (Produces).
- **Produces:** an inline #6 bar that is self-contained (applies without `writing-lessons` loaded — Decision 10).

**Steps:**

- [ ] 2.1 RED (behavioral, the live manual). Dispatch a subagent given the CURRENT #6 (line 16) text + scenario: *"This turn you renamed a variable and fixed a comment typo — no bug, no surprise. Per non-negotiable #6, must you capture a lesson this turn? YES/NO + one line."* Expected RED: **YES** ("any friction" + "capture the bottleneck, same turn" forces it). Record.

- [ ] 2.2 Edit #6. Replace line 16 (the whole `6. **Capture the bottleneck, same turn.** …` paragraph) with:

  ````text
  6. **Capture a qualifying lesson, same turn.** Capture only when BOTH hold: (A) you can name a concrete check/Prevention a future session will actually run, AND (B) it is an error *class* a competent future agent would repeat (non-obvious; plausibly recurs). Negative test: if all you'd write is "today I did X" with no reusable check, do not capture — **most turns produce no lesson, and that is normal, not a skipped step.** MUST-capture invariant: a turn that exposed a hallucinated symbol/API/skill-name, a wrong assumption, a test that passed for the wrong reason, or an owner correction of a non-obvious choice still captures the same turn. When a turn qualifies, capture it the SAME turn by invoking the `writing-lessons` skill (the `Skill` tool) — deferring loses it, and editing [lessons-learned.md](./lessons-learned.md) directly bypasses the cause-tag discipline and promotion-debt scan the skill owns. `writing-lessons` owns the full bar; `lessons-nudge.sh` (Stop) backstops.
  ````

- [ ] 2.3 Edit Checklist #8. Replace line 58:

  ````text
  | 8 | Bottleneck captured | Any friction found this turn captured via the `writing-lessons` skill (the `Skill` tool), not a direct edit to `lessons-learned.md` |
  ````

  with:

  ````text
  | 8 | Lesson captured (if any) | A lesson that met the (A)+(B) bar was captured via the `writing-lessons` skill (the `Skill` tool), not a direct edit to `lessons-learned.md` — or `[N/A]` when no turn met the bar (the expected default) |
  ````

- [ ] 2.4 Edit status-block `Pending lessons` line. Replace line 93:

  ````text
  - **Pending lessons** — <captured this turn via writing-lessons, or none>
  ````

  with:

  ````text
  - **Pending lessons** — <captured this turn via writing-lessons if a turn met the (A)+(B) bar, else "none" (typical)>
  ````

- [ ] 2.5 Structural check (CLAUDE.md is not a skill — no frontmatter validator; check fences + links):

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  echo "fences even:"; grep -c '^```' .claude/CLAUDE.md
  echo "lessons link resolves:"; test -f .claude/lessons-learned.md && echo OK || echo MISSING
  ```

  Expected: fence count even; `OK`.

- [ ] 2.6 GREEN (behavioral). Re-dispatch the 2.1 subagent with the NEW #6 + the SAME typo/rename scenario → expected **NO** (negative test, most-turns-none). Second scenario: hallucinated `clearLayers()` → expected **YES** (MUST-capture invariant). Both correct = GREEN; proves the relaxation rejects noise without suppressing genuine failures.

- [ ] 2.7 Commit:

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  git add .claude/CLAUDE.md
  git commit -m "docs(claude-md): gate lessons capture on the (A)+(B) bar"
  ```

---

## Task 3 — Align root `./CLAUDE.md` + grep sweep

**Files:**

- `CLAUDE.md` (root) — the Hard-rules capture bullet (line 13).

**Interfaces:**

- **Consumes:** the canonical bar (Task 1) — compressed to one bullet.
- **Produces:** nothing downstream.

**Steps:**

- [ ] 3.1 Edit line 13. Replace:

  ````text
  - **Capture bottlenecks the same turn.** Friction in a skill or a hand-off → a `writing-lessons` entry now; recurring (3×) → `writing-rules`.
  ````

  with:

  ````text
  - **Capture a qualifying lesson the same turn.** Only when it passes the (A)+(B) bar — a concrete reusable check AND a recurring/non-obvious class (most turns produce none); `writing-lessons` owns the bar. Recurring (3×) → `writing-rules`.
  ````

- [ ] 3.2 RED→GREEN grep sweep (the test for this task). Run:

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  grep -niE "any friction|capture the bottleneck|bottleneck.*same turn|capture bottlenecks" CLAUDE.md .claude/CLAUDE.md
  ```

  Expected after Tasks 2 + 3: **no output** (exit 1). Before this edit the same grep matched root line 13 — confirming the sweep is live. If any line prints, fix it before committing.

- [ ] 3.3 Commit:

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  git add CLAUDE.md
  git commit -m "docs(claude-md): align root capture bullet with the (A)+(B) bar"
  ```

---

## Task 4 — Bring the generator template up to the bar

**Files:**

- `skills/foundation/bootstrapping-claude-md/references/operating-manual-template.md` — lesson-capture clause (line 32), `Pending lessons` line (line 103).

**Interfaces:**

- **Consumes:** the canonical bar (Task 1). Template stays agnostic ("if the repo has a lessons-capture skill").
- **Produces:** the seed a freshly-bootstrapped consumer repo inherits — must match what the auditor (Task 5) accepts.

**Steps:**

- [ ] 4.1 Edit line 32. Replace:

  ````text
  5. **Capture the lesson, in git, same turn.** When a turn exposes a non-obvious failure (hallucinated symbol, missed duplication, wrong-domain edit, contract contradicting an assumption) or the owner corrects/confirms a non-obvious choice, capture it the SAME turn — deferring loses it. If the repo has a lessons-capture skill (e.g. `writing-lessons`), capture by **invoking that skill (the `Skill` tool)**, not by editing [lessons-learned.md](./lessons-learned.md) directly — a direct edit bypasses the skill's cause-tag/promotion discipline; absent such a skill, append to the log. Every status block carries a `Pending lessons` line.
  ````

  with:

  ````text
  5. **Capture a qualifying lesson, in git, same turn.** Capture only when BOTH hold: (A) you can name a concrete check/Prevention a future session will run, AND (B) it is a non-obvious failure *class* that would recur (hallucinated symbol, missed duplication, wrong-domain edit, contract contradicting an assumption) or the owner corrects/confirms a non-obvious choice. If all you'd write is "today I did X" with no reusable check, do not capture — **most turns produce no lesson, and that is normal.** When a turn qualifies, capture it the SAME turn — deferring loses it. If the repo has a lessons-capture skill (e.g. `writing-lessons`), capture by **invoking that skill (the `Skill` tool)**, not by editing [lessons-learned.md](./lessons-learned.md) directly — a direct edit bypasses the skill's cause-tag/promotion discipline; absent such a skill, append to the log.
  ````

- [ ] 4.2 Edit line 103. Replace:

  ````text
  - **Pending lessons** — <captured this turn via the lessons skill, or none>
  ````

  with:

  ````text
  - **Pending lessons** — <captured this turn via the lessons skill if a turn met the bar, else "none" (typical)>
  ````

- [ ] 4.3 Validators on `bootstrapping-claude-md` (the ref link from its SKILL.md must still resolve; fences even in template):

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  T=skills/foundation/bootstrapping-claude-md/references/operating-manual-template.md
  echo "fences even:"; grep -c '^```' "$T"
  echo "template referenced by SKILL.md:"; grep -c 'operating-manual-template.md' skills/foundation/bootstrapping-claude-md/SKILL.md
  ```

  Expected: fence count even; SKILL.md reference count ≥ 1.

- [ ] 4.4 GREEN (agnostic-seed check). Dispatch a subagent: *"Here is a CLAUDE.md operating-manual template clause [paste new line 32]. A consumer repo is bootstrapped from it. On a turn that only fixed a comment typo, does the manual require capturing a lesson? YES/NO."* Expected **NO**. Confirms the consumer repo no longer inherits a per-turn reflex.

- [ ] 4.5 Commit:

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  git add skills/foundation/bootstrapping-claude-md/references/operating-manual-template.md
  git commit -m "feat(bootstrapping-claude-md): seed the (A)+(B) capture bar into the template"
  ```

---

## Task 5 — Teach the auditor the over-broad-criterion drift class

**Files:**

- `skills/foundation/auditing-claude-md/SKILL.md` — Process step 2 (line 32), Red Flags (line 61), Rationalizations table (line 71). Mirror the existing bypass-wording class's three-part shape.

**Interfaces:**

- **Consumes:** the canonical bar (Task 1) — the auditor's "over-broad" definition must equal it, so auditor and generated CLAUDE.md cannot disagree.
- **Produces:** nothing downstream (terminal task).

**Steps:**

- [ ] 5.1 Edit Process step 2 (line 32). It currently ends with the bypass-wording sentence: `… if one exists, the direct-edit instruction bypasses it and is drift.` Append, in the same bullet, a new sentence:

  ````text
   Also flag **over-broad capture criterion**: a non-negotiable or pointer that mandates a lesson on "any friction" / every turn, or makes the status-block `Pending lessons` line mandatory with no "none"/N/A default, or states the lessons mandate without the (A)+(B) bar (a concrete reusable check AND a recurring/non-obvious class). The bar must read so that most turns produce no lesson; "any friction"/every-turn wording is drift.
  ````

- [ ] 5.2 Edit Red Flags. After line 61 (the bypass-wording red flag), add a new bullet:

  ````text
  - A non-negotiable/pointer that requires a lesson on "any friction" or every turn, or a `Pending lessons` line with no "none" default — the capture criterion is over-broad and will flood the log; the manual must gate capture on the (A)+(B) bar (a concrete reusable check AND a recurring/non-obvious class).
  ````

- [ ] 5.3 Edit Rationalizations table. After line 71, add a new row:

  ````text
  | "It captures on any friction — that's just being thorough." | An over-broad bar floods the log with one-offs and trains the agent to ignore it. Capture must be gated on (A) a concrete reusable check AND (B) a recurring/non-obvious class; most turns produce none. Flag the "any friction"/every-turn wording as drift. |
  ````

- [ ] 5.4 Validators on `auditing-claude-md`:

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  F=skills/foundation/auditing-claude-md/SKILL.md
  echo "name:"; grep -nE '^name: [a-z0-9-]+$' "$F"
  echo "fences even:"; grep -c '^```' "$F"
  echo "ref links resolve:"; grep -oE 'references/[a-zA-Z0-9_-]+\.md' "$F" | while read r; do test -f "skills/foundation/auditing-claude-md/$r" && echo "OK $r" || echo "MISSING $r"; done
  ```

  Expected: `name: auditing-claude-md`; fence count even; every ref link `OK`.

- [ ] 5.5 GREEN (auditor cross-check). Dispatch a subagent with the FULL updated `auditing-claude-md` skill text and two inputs:
  - Input A = the OLD #6 (`Capture the bottleneck, same turn … any friction …`). Expected: **flags** it as over-broad-criterion drift.
  - Input B = the NEW #6 (Task 2.2). Expected: **does not flag** it.
  Both correct = GREEN; proves auditor and generated manual agree on "over-broad".

- [ ] 5.6 Commit:

  ```bash
  cd /Users/nerhei/Documents/projects/sdd-workflow
  git add skills/foundation/auditing-claude-md/SKILL.md
  git commit -m "feat(auditing-claude-md): flag over-broad lessons-capture criterion as drift"
  ```

---

## Self-review

- **Spec coverage:** Edit 1 → Task 2; Edit 2 (a/b) → Task 2; Edit 3 → Task 1; Edit 4 → Task 3; Edit 5 (a/b) → Task 4; Edit 6 → Task 5. Spec Verification: validators (Tasks 1.4, 4.3, 5.4), RED/GREEN behavioral (Tasks 1, 2), auditor cross-check (Task 5.5), grep sweep (Task 3.2). All covered.
- **Show-don't-describe:** every edit step shows the actual old + new markdown block; every test step shows the exact subagent prompt + expected verdict or the exact shell command + expected output; every task commits.
- **Wording consistency:** the (A)+(B) / negative-test / most-turns-none / MUST-capture phrasing is identical across Tasks 1, 2, 4, 5 (verbatim canonical block); Task 5's auditor definition quotes the same "(A) a concrete reusable check AND (B) a recurring/non-obvious class" form.

## Execution handoff

Tasks are **tightly coupled** (all reuse Task 1's verbatim wording; Tasks 2–5 consume it). Recommended flow: **`inline-driven-development`** (small, coupled plan held solo) rather than subagent-per-task. Before the first edit, run `pre-implementation-protocol` on this plan (confirm contracts, the real verification commands above, and a clean git baseline). Each task's edits are documentation; the per-task "test" is the validator/subagent/grep step shown — `test-driven-development`'s RED→GREEN maps to the RED/GREEN subagent runs, not unit tests.
