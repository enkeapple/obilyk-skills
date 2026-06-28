# Rule Efficacy Test Prompt Template

Use this **after** the rule is drafted and passes static self-review, to prove the rule actually steers an agent — not just that it is well-formed. Two cold-agent runs on the same concrete target case: RED without the rule, GREEN with it. Each returns a structured verdict; nothing is written to disk.

**Purpose:** confirm the rule earns its context load — a cold agent commits the mistake WITHOUT it (RED) and complies WITH it (GREEN).

**Dispatch after:** the rule file is drafted and statically reviewed.

**Pick the target case first:** a real file or task in this repo where the mistake the rule prevents would naturally occur. No such case → the rule guards nothing; reconsider it before testing.

## RED run — cold agent, no rule

```markdown
Subagent (general-purpose):
  description: "Do a task cold (no rule)"
  prompt: |
    You are working in this repo. Do the task below. You have only your default
    judgement and the repo — no special project rules are in effect.

    **Task:** [CONCRETE TARGET TASK — e.g. "add an endpoint at <path> that …"]

    Produce the change (or the diff), then report, as your result:
    ## Cold Run
    **What I did:** [1–3 lines]
    **Self-assessed against these checks:** [paste the rule's Review Checklist items]
    - [item]: PASS | FAIL — [why]
```

Expected: at least one checklist item FAILs — the mistake the rule exists to prevent. If every item PASSes cold, the rule is a **no-op** here: stop and cut it, or find a case where the mistake is real.

## GREEN run — cold agent, rule injected

```markdown
Subagent (general-purpose):
  description: "Do the same task with the rule"
  prompt: |
    You are working in this repo. The following project rule is in effect —
    follow it. Then do the task.

    **Rule:**
    [PASTE THE FULL RULE FILE]

    **Task:** [THE SAME CONCRETE TARGET TASK as the RED run]

    Produce the change (or the diff), then report, as your result:
    ## Ruled Run
    **What I did:** [1–3 lines]
    **Compliance against the rule's Review Checklist:**
    - [item]: PASS | FAIL — [why]
```

Expected: every checklist item PASSes. If any FAILs, the rule is real but **ineffective** — its wording doesn't steer a cold reader. Sharpen the Implementation (stronger imperative, a ✅/❌ closer to the target case), then re-run GREEN until a cold agent complies.

## Reading the result

- **RED fails + GREEN passes** → the rule works; it is done.
- **RED passes (cold agent already complied)** → no-op; the rule guards nothing on this case.
- **GREEN still fails** → ineffective wording; revise and re-run.

Both verdicts come back as the subagents' returned text. Do NOT hand-write any `/tmp` file — if a verdict must be persisted across sessions, route it through the `handoff` skill, which owns temp files.
