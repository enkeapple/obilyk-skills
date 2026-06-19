# Interactive Gate Prompts Implementation Plan

**Goal:** Replace ad-hoc prose gate-prompts at SDD-chain decision points with one canonical interactive picker, defined by a new vault-only rule and wired into three chain skills.
**Architecture:** A new rule `interactive-gates.md` owns the mechanism + four archetype option-templates; three `apply-chain` skills gain a pointer to it (and `spec-drift-audit` swaps its per-finding loop for a batched picker). No app code — these are vault docs; "tests" are the vault's validators + RED/GREEN subagent pressure runs.
**Tech stack:** Markdown rules/skills; harness `AskUserQuestion` tool (concrete picker); `git` for read-only inspection.

## Global constraints

- The rule is **tool-agnostic prose** — name `AskUserQuestion` as the harness-concrete mechanism but state the role + a markdown-list fallback; never bake the tool in as the only path (`agnostic-skill-authoring` applies only to skills, but keep the rule portable so the chain skills degrade in a consumer repo).
- `sdd-lifecycle`'s gate **prohibition** prose ("present artifact, then STOP … Never auto-advance") and its red-flag list stay **verbatim** — edits are additive only.
- dogfood-generator-sync is `[N/A]` — the rule is vault-only, no `bootstrapping-*` template emits it; do **not** touch `operating-manual-template.md`, `auditing-claude-md`, or `.claude/CLAUDE.md`.
- Markdown per `markdown-style.md`: frontmatter first (`description: >-` block, no `paths:`, mirror `phase-task-visualization.md`), one `#` H1, blank lines around headings/blocks, fences language-tagged, spaced table delimiter rows.
- Git boundary: **no autonomous commit.** Each task ends with a *proposed* one-line Conventional Commit for the human to run.
- A "test" here = a subagent pressure scenario (RED without the change, GREEN with it) + the doc validators — never a unit test.

## Files (map)

| File | Responsibility |
| --- | --- |
| `.claude/rules/common/interactive-gates.md` | NEW — the convention: mechanism, archetypes A/B/C, option templates, inclusion criterion, gate-honesty, fallback. |
| `skills/apply-chain/sdd-lifecycle/SKILL.md` | EDIT — execution-mode fork (B) as a presentation point + pointer; gate prohibition unchanged. |
| `skills/apply-chain/pre-implementation-protocol/SKILL.md` | EDIT — readiness verdict (C-readiness) via picker + pointer. |
| `skills/apply-chain/spec-drift-audit/SKILL.md` | EDIT — replace per-finding loop with batched C-drift picker + per-finding recommended disposition + pointer. |
| `skills/apply-chain/spec-drift-audit/references/report-example.md` | EDIT — bring the filled example into line: add recommended disposition, swap the open-question block for the batched picker. |

Order: T1 first (defines the convention the others reference); T2/T3/T4 are mostly independent.

---

## Task 1 — Create the `interactive-gates` rule

**Files:** `.claude/rules/common/interactive-gates.md` (NEW)

**Interfaces:**
- Consumes: nothing.
- Produces: the link target `.claude/rules/common/interactive-gates.md` and the four archetype names (A approval / B execution-mode / C-readiness / C-drift) that T2–T4 reference by name.

### Steps

- [ ] **RED — baseline drift.** Dispatch a subagent (general-purpose), no rule present:

  ```text
  Prompt: "You are at the writing-specs approval gate under sdd-lifecycle. The
  spec is saved. Present the gate prompt to the user." Run this 3× in separate
  dispatches.
  ```

  Confirm the failure: the three runs produce **divergent prose** / different or absent option sets / no clickable choice. Record verbatim. (If all three already produce one identical canonical picker, there is no drift to fix — STOP and reconsider; this is the tautology trap.)

- [ ] **Write the rule.** Create `.claude/rules/common/interactive-gates.md` with exactly:

  ````markdown
  ---
  description: >-
    Present every SDD-chain gate choice as one canonical interactive picker of
    options-with-descriptions (the AskUserQuestion tool; markdown-list fallback
    when absent), not ad-hoc prose. Covers four archetypes — phase approval (A),
    execution-mode fork (B), readiness (C-readiness), drift disposition (C-drift,
    batched). Owns presentation only: the stop is sdd-lifecycle's gate, the
    progress list is phase-task-visualization. Vault-only; not shipped to consumers.
  ---

  # Interactive Gate Prompts

  ## When

  At any SDD-chain decision point that needs an **explicit, non-derivable user choice**:

  - each phase **approval gate** (owned by `sdd-lifecycle`);
  - the **execution-mode fork** after plan approval (inline vs subagent, owned by `sdd-lifecycle`);
  - the **readiness verdict** (`pre-implementation-protocol`);
  - the **post-report disposition** (`spec-drift-audit`).

  Do NOT add a picker where the choice is **agent-derivable** (entry classification in `sdd-lifecycle`) or **already conversational** (`grilling`'s one-question recommended-answer interview).

  ## Why

  Without one canonical form, gate prompts drift run to run — prose one time, a different option set the next, no clickable choice — and the user re-reads a bespoke sentence at every gate. The value is **convergence** (as in [phase-task-visualization](./phase-task-visualization.md)), not "offer a choice": one mechanism + fixed option templates make every gate recognizable and the approval explicit and one-click. This rule owns only the **presentation** of the gate choice — the **stop** is owned by `sdd-lifecycle`'s gate, the **progress-list visual** by `phase-task-visualization`. Cross-link, do not restate.

  ## Implementation

  ### Mechanism

  Present the choice as a **numbered picker of options-with-descriptions**. In this harness that is the `AskUserQuestion` tool (1–4 questions; each 2–4 explicit options; an "Other" free-text option is added automatically, so never list it). When no picker tool exists (e.g. a consumer repo's harness), **fall back** to a markdown numbered list with one-line descriptions and ask the user to reply with a number — never silently drop the choice.

  ### Archetypes and option templates

  Each list is the 2–4 explicit options (auto-"Other" omitted):

  | Archetype | Fires | Options (label → description) |
  | --- | --- | --- |
  | **A — approval gate** | after each phase | `Approve` → approve this artifact, advance · `Request changes` → revise this same artifact (user says what) · `Redo a previous phase` → defect upstream, return and rework (user names the phase) |
  | **B — execution-mode fork** | after plan approval | `Inline (solo)` → coupled tasks / small plan, execute in-session · `Subagents` → independent tasks, fresh subagent per task + review gates |
  | **C-readiness** | readiness check | `Proceed` → readiness confirmed, begin implementation · `Not ready` → gaps remain, list them and return to the plan |
  | **C-drift** | after the audit report (ONE picker) | `Apply recommended` → apply the per-finding recommended dispositions · `Adjust per-finding` → walk findings one by one · `Stop` → take no action now |

  C-drift is **one batched picker**, never one picker per finding; the audit must therefore record a **recommended disposition per finding** in its report.

  ### Gate-honesty

  The picker **is** the stop: presenting options and waiting for a pick is the gate's "STOP for explicit approval"; "never auto-advance" means "never advance without a pick". An `Approve` pick **is** that explicit approval, so advancing after it honors the gate — `sdd-lifecycle`'s prohibition is unchanged in meaning. A gate-turn awaiting a pick is `Result: IN PROGRESS` (awaiting approval), never `BLOCKED` (reserved for scope decisions / git-boundary actions).

  ## Edge Cases

  - **No picker tool** → markdown numbered-list fallback (above); the choice is never dropped.
  - **Consumer repo without this rule** → the chain skills' pointers degrade to their prior prose; the picker simply does not appear. The rule being vault-only is intentional, not a leak.
  - **Two-step picks** — `Redo a previous phase` (A) and `Adjust per-finding` (C-drift) collect the *branch*; a follow-up free-text prompt collects the detail (which phase / walking findings).
  - **Standalone phase invocation** (not under `sdd-lifecycle`) → the phase skill still presents its own archetype picker at its gate; archetype **B** is only meaningful post-plan and stays owned by `sdd-lifecycle`.

  ## Review Checklist

  - [ ] Every gate choice in the four covered points is a picker (or its markdown fallback), never bespoke prose.
  - [ ] Option sets match the archetype table verbatim; auto-"Other" not listed; each list is 2–4 options.
  - [ ] C-drift is one batched picker and the audit produces a per-finding recommended disposition.
  - [ ] No restatement of `sdd-lifecycle`'s stop or `phase-task-visualization`'s list — only cross-links.
  - [ ] Gate-turn status is `IN PROGRESS`, not `BLOCKED`.
  ````

- [ ] **Validate (doc validators).** Run and confirm clean output:

  ```bash
  test -f .claude/rules/common/interactive-gates.md && echo OK
  grep -nE '\|-{2,}\|' .claude/rules/common/interactive-gates.md   # expect: no output (no unspaced delimiter rows)
  grep -c '^```' .claude/rules/common/interactive-gates.md          # expect: even count (balanced fences)
  grep -n 'phase-task-visualization.md' .claude/rules/common/interactive-gates.md && test -f .claude/rules/common/phase-task-visualization.md && echo LINK_OK
  ```

  Expected: `OK`, no delimiter hits, an even fence count, `LINK_OK`.

- [ ] **GREEN — convergence.** Dispatch a subagent handed only this rule file:

  ```text
  Prompt: "Read .claude/rules/common/interactive-gates.md. You are at (a) a phase
  approval gate, (b) the post-plan execution-mode fork, (c) a readiness check,
  (d) a post-audit disposition. For each, state the picker you would present."
  ```

  Confirm: it produces archetype A / B / C-readiness / C-drift pickers with the exact option labels from the table, and names the markdown fallback. Record the GREEN output.

- [ ] **Propose commit** (human runs it):

  ```text
  feat(rules): add interactive-gates rule for SDD-chain gate prompts
  ```

---

## Task 2 — Wire fork B + pointer into `sdd-lifecycle`

**Files:** `skills/apply-chain/sdd-lifecycle/SKILL.md` (EDIT)

**Interfaces:**
- Consumes: `interactive-gates.md` (archetype B) from Task 1.
- Produces: nothing new; adds a presentation point + pointer.

### Steps

- [ ] **RED.** Dispatch a subagent driving `sdd-lifecycle` just after plan approval:

  ```text
  Prompt: "Under sdd-lifecycle, the plan was just approved. What do you present
  next before execution?"
  ```

  Confirm: it advances toward execution **without** presenting an explicit inline-vs-subagent choice (the skill currently names the fork only in the phase chain, never tells the agent to present it). Record verbatim.

- [ ] **Edit — add the fork-B presentation point.** In `skills/apply-chain/sdd-lifecycle/SKILL.md`, immediately after the `## Controls` list and before `## Rationalizations`, insert:

  ```markdown
  ## Execution-mode fork

  After the plan is approved and before execution, present the inline-vs-subagent choice as archetype **B** per [interactive-gates](../../../.claude/rules/common/interactive-gates.md): `inline-driven-development` (coupled tasks / small plan) vs `subagent-driven-development` (independent tasks). This is a presentation point only — the chosen flow owns the execution.
  ```

- [ ] **Edit — point the gate at the rule (prohibition unchanged).** In `## The gate — the load-bearing rule`, append one sentence to the first paragraph (leave every existing sentence verbatim):

  ```text
  Before (verbatim, unchanged):
    … One approval unlocks exactly one phase.

  After (append, same paragraph):
    … One approval unlocks exactly one phase. Present that approval choice as
    archetype A per [interactive-gates](../../../.claude/rules/common/interactive-gates.md).
  ```

- [ ] **Validate.** Confirm the prohibition is untouched and links resolve:

  ```bash
  grep -n 'present its artifact, then STOP' skills/apply-chain/sdd-lifecycle/SKILL.md   # still present, verbatim
  grep -n 'Red Flags — STOP' skills/apply-chain/sdd-lifecycle/SKILL.md                   # red-flag list still present, untouched
  grep -n 'interactive-gates' skills/apply-chain/sdd-lifecycle/SKILL.md                  # 2 hits (gate + fork)
  # resolved relative link from the skill dir reaches the rule (depth check, not just existence):
  test -f skills/apply-chain/sdd-lifecycle/../../../.claude/rules/common/interactive-gates.md && echo LINK_RESOLVES
  grep -c '^```' skills/apply-chain/sdd-lifecycle/SKILL.md                                # even
  ```

- [ ] **GREEN.** Re-dispatch the RED scenario. Confirm the subagent now presents the archetype-B picker (Inline vs Subagents) post-plan, and references archetype A at the approval gate. Record output.

- [ ] **Propose commit:**

  ```text
  feat(sdd-lifecycle): present execution fork and approval gate via interactive-gates
  ```

---

## Task 3 — Wire C-readiness picker into `pre-implementation-protocol`

**Files:** `skills/apply-chain/pre-implementation-protocol/SKILL.md` (EDIT)

**Interfaces:**
- Consumes: `interactive-gates.md` (C-readiness) from Task 1.
- Produces: nothing new.

### Steps

- [ ] **RED.** Dispatch a subagent driving the readiness check to its end:

  ```text
  Prompt: "You ran the pre-implementation-protocol readiness check; Go/No-go is
  GO. How do you present the go/no-go to the user before execution?"
  ```

  Confirm: it hands off to execution with no explicit, clickable Proceed / Not-ready choice. Record verbatim.

- [ ] **Edit — point the hand-off at the rule.** In `skills/apply-chain/pre-implementation-protocol/SKILL.md`, in the `## Hand-off` section, append a bullet after the `Downstream` bullet:

  ```markdown
  - **Gate presentation:** present the readiness verdict as archetype **C-readiness** per [interactive-gates](../../../.claude/rules/common/interactive-gates.md) — `Proceed` (begin implementation) vs `Not ready` (list gaps, return to the plan) — before handing to the execution flow.
  ```

- [ ] **Validate.**

  ```bash
  grep -n 'interactive-gates' skills/apply-chain/pre-implementation-protocol/SKILL.md   # 1 hit
  test -f .claude/rules/common/interactive-gates.md && echo LINK_OK
  grep -c '^```' skills/apply-chain/pre-implementation-protocol/SKILL.md                 # even
  ```

- [ ] **GREEN.** Re-dispatch the RED scenario. Confirm the subagent presents the C-readiness picker (Proceed / Not ready) before hand-off. Record output.

- [ ] **Propose commit:**

  ```text
  feat(pre-implementation-protocol): present readiness verdict via interactive-gates
  ```

---

## Task 4 — Swap `spec-drift-audit` to the batched C-drift picker

**Files:** `skills/apply-chain/spec-drift-audit/SKILL.md` (EDIT), `skills/apply-chain/spec-drift-audit/references/report-example.md` (EDIT)

**Interfaces:**
- Consumes: `interactive-gates.md` (C-drift) from Task 1.
- Produces: a per-finding **recommended disposition** field in the report.

### Steps

- [ ] **RED.** Dispatch a subagent finishing an audit with several findings:

  ```text
  Prompt: "You produced a drift report with 4 findings (2 silent expansions,
  1 missed scope, 1 schema drift). How do you collect the user's decisions?"
  ```

  Confirm: per the current skill it asks an **open either/or question per finding** ("remove it, or document it — which?"), producing no single batched choice and no pre-computed recommendation. Record verbatim.

- [ ] **Edit — add recommended disposition to the report.** In `## Report format`, append to item 5 (or add item 6):

  ```text
  Before (verbatim):
    5. **Summary** — counts per classification.

  After:
    5. **Summary** — counts per classification.
    6. **Recommended disposition** — per finding, the audit's recommended action
       (Fix code / Amend spec / Accept) with a one-line reason.
  ```

- [ ] **Edit — replace the per-finding loop with the batched picker.** Replace the entire `## Required decision after the report` section body with:

  ```markdown
  ## Required decision after the report

  End with **one** decision, not edits and not a question per finding. Having
  recorded a recommended disposition per finding (Report item 6), present
  archetype **C-drift** per [interactive-gates](../../../.claude/rules/common/interactive-gates.md):

  - `Apply recommended` → apply the per-finding recommended dispositions.
  - `Adjust per-finding` → walk findings one by one.
  - `Stop` → take no action now.

  The user picks. The audit itself still does not edit code — applying a
  disposition is the follow-up task the user authorizes here.
  ```

- [ ] **Edit — bring the example into line.** The skill references `references/report-example.md` as "a concrete reference for the report format"; it still ends with the old open-question loop and has no recommended disposition. Inside its ` ```text ` block, replace the `## Decisions for the user` section (lines 33–37) with:

  ```text
  ## Recommended disposition
  - Load more button (missed scope): Fix code — implement per spec.
  - sort param + sortItems() (silent expansion, out of scope): Fix code — remove.
  - Avatar in Row (silent expansion): Fix code — remove.
  - nextCursor→cursor + hasMore (schema drift, external): Fix code — revert to spec contract.

  ## Decision
  Presented as one batched picker (interactive-gates archetype C-drift):
  - Apply recommended → apply all four dispositions above.
  - Adjust per-finding → walk the four findings one by one.
  - Stop → take no action now.
  ```

- [ ] **Validate.**

  ```bash
  grep -n 'remove it, or document it' skills/apply-chain/spec-drift-audit/SKILL.md   # expect: no output (old loop gone)
  grep -n 'interactive-gates' skills/apply-chain/spec-drift-audit/SKILL.md            # 1 hit
  grep -n 'Recommended disposition' skills/apply-chain/spec-drift-audit/SKILL.md      # present
  # the referenced example must not keep the old open-question model:
  grep -nE 'remove, or document in the spec|implement now, or move to a follow-up' \
    skills/apply-chain/spec-drift-audit/references/report-example.md                  # expect: no output
  grep -n 'Recommended disposition' skills/apply-chain/spec-drift-audit/references/report-example.md  # present
  test -f .claude/rules/common/interactive-gates.md && echo LINK_OK
  grep -c '^```' skills/apply-chain/spec-drift-audit/SKILL.md                          # even
  ```

  Confirm the read-only invariant prose ("It does not edit code" / "report the drift; do not fix it") is **still present** — the swap must not weaken it:

  ```bash
  grep -n 'does not edit code' skills/apply-chain/spec-drift-audit/SKILL.md
  ```

- [ ] **GREEN.** Re-dispatch the RED scenario. Confirm: one batched C-drift picker (Apply recommended / Adjust per-finding / Stop), a recommended disposition per finding, and no per-finding open-question loop. Record output.

- [ ] **Propose commit:**

  ```text
  feat(spec-drift-audit): batch drift disposition via interactive-gates picker
  ```

---

## Verification (whole plan)

- Each task's validators clean (above) + its RED→GREEN subagent run recorded.
- Cross-skill: `grep -rn 'interactive-gates' skills/apply-chain/*/SKILL.md` → 4 hits across the 3 skills (sdd-lifecycle ×2, pre-impl ×1, spec-drift ×1).
- No forbidden edits: `git status` shows no change to `operating-manual-template.md`, `auditing-claude-md`, or `.claude/CLAUDE.md` (dogfood-sync N/A holds).
- No autonomous commits made; four one-line commit proposals offered to the human.

## Risks

- **RED tautology** (T1) — mitigated by requiring observed *drift* across 3 runs, not "no list".
- **Gate prohibition softened** (T2) — mitigated by the verbatim-preservation grep in T2 validate.
- **Read-only invariant weakened** (T4) — mitigated by the "does not edit code" grep in T4 validate.
