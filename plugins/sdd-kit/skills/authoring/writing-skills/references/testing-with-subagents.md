# Testing With Subagents

How a skill earns "done": you watch a fresh agent **fail** the scenario without the skill (**RED**),
then **comply** with it (**GREEN**). If you didn't watch it fail first, you don't know the skill
teaches anything. This is the same RED→GREEN the test-first cycle runs, with the agent's *behaviour*
as the unit under test.

## A pressure scenario

A scenario that actually exerts pressure has:

- **Concrete A/B/C choices** that force an explicit decision — no hypothetical deflection ("must choose and act" framing).
- **3+ combined pressures** stacked (below) — one pressure is easy to resist; a stack reproduces real-world resistance.
- **Real constraints**: specific deadlines, file paths, prior work — not "imagine you're busy".

### Pressure types to stack

| Type | Mechanism |
| --- | --- |
| Time | deadline / deploy window closing |
| Sunk cost | hours already invested, fear of "waste" |
| Authority | a senior or manager overriding |
| Economic | job / promotion / survival framed as at stake |
| Exhaustion | end-of-day fatigue, plans waiting |
| Social | fear of looking dogmatic or inflexible |
| Pragmatic | "be pragmatic, not dogmatic" rationalization |

## The cycle

- **RED** — run the scenario WITHOUT the skill. Record the agent's rationalizations **verbatim** — those exact excuses become the skill's rationalization table. Watch the failure happen; do not infer it.
- **GREEN** — write the minimal skill addressing those specific failures, then re-run the same scenario WITH the skill. The agent should now comply.
- **REFACTOR** — each new excuse the agent invents under the skill gets: an explicit negation in the rules, a rationalization-table row, a red-flag symptom, and (if it mis-fires) a sharper description. Re-run until compliance holds.

## The control is mandatory

**Always run a no-guidance control.** If the agent complies on the bare scenario WITHOUT the skill,
there is nothing to fix — the skill would be a no-op. Stop and re-aim at a failure that actually
reproduces (invert the test: *would the agent comply WITHOUT the skill?* — if yes, the scenario
exerts no pressure).

### Caveat — a contaminated discipline baseline

A subagent dispatched inside a repo that injects an operating manual (a charter, an Iron Law,
read-before-assert) inherits that discipline, so a discipline-RED run may "comply" by obeying the
*inherited manual*, not your skill — a false no-failure. Observed: a baseline validator, told it was
an ordinary project, still cited "this vault's Suspicion Protocol #4". To measure a true discipline
baseline, run WITHOUT that injection (a controlled system prompt, or a real consumer repo). Output-
*shape* failures stay measurable in-repo regardless.

### Export-bound vs in-vault-discipline — a green in-vault RED is not a cut

Before reading a green in-vault RED as "no-op, cut it", classify the skill by **whose** discipline it
exists to enforce:

- **in-vault-discipline** — its value is enforcing discipline on THIS strong, tool-equipped agent. A
  green in-vault RED genuinely means no-op: the agent you are protecting already complies, so there is
  nothing to teach. Cut or re-aim.
- **export-bound** — its value is for weaker / non-agentic consumer harnesses in other repos. A
  tool-equipped agent recons, verifies, and self-checks by default at EVERY tier (Haiku included), so a
  green in-vault RED across tiers says nothing about the export target — it only shows that *this*
  agent does not need the skill. That is **not** a cut signal.

For an export-bound skill with a green in-vault RED, do ONE of:

1. **RED against a representative export floor** — a weaker / non-agentic harness: a controlled system
   prompt stripped of agentic recon, or a real consumer repo at the target's tier. Reproduce the
   failure where the skill's real consumers live.
2. **Ship on the policy basis** — record the in-vault no-op explicitly as an Edge Case and skip the
   in-vault GREEN gate, because the in-vault run cannot exercise the export target.

Record which basis you used. A green in-vault RED is "no-op here / valuable there", never a cut.

## Reps and reading

- **5+ reps per variant.** A single sample lies; variance across reps is itself a signal — five different shapes means the wording isn't binding yet.
- **Read every flagged match manually.** Template echoes and quoted counter-examples masquerade as hits; automated counts alone overstate both failure and success.
- **Micro-test wording before full scenarios.** Full pressure runs are the final gate but slow; verify the wording first with one fresh sample per call (system prompt = the realistic context; user message = a task that tempts the failure), always against the no-guidance control.

## Meta-test

If the agent violates *despite* the skill, ask: "how could this skill have been written to make the
right choice crystal clear?" The answer reveals whether the gap is documentation clarity or a weak
underlying principle.
