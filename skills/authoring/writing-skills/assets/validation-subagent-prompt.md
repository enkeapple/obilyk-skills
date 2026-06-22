# Validation Subagent Prompt Template

Use this for Layer 2 of the `validate` gate: dispatch an INDEPENDENT subagent that *runs the skill's
test cases* and returns a verdict — the dynamic gate, not a static read. Dispatch only after Layer 1
(`validation-checklist.md`) is green.

**Purpose:** prove the skill *works* — that following it changes behaviour the right way (GREEN) and
that the change is attributable to the skill (the inversion check), with verbatim evidence. A
static "looks good" never reaches this; that is the failure this layer exists to catch.

**Cold means cold:** a fresh subagent with zero shared context, handed the target skill and its test
cases. For a discipline skill, run it (or note that it must run) in an environment WITHOUT an
injected operating manual — an in-vault agent inherits the discipline and yields a false pass (see
`testing-with-subagents.md`).

````markdown
Subagent (general-purpose):
  description: "Validate a skill by running its test cases"
  prompt: |
    You validate a skill by RUNNING it, not by reading it. Reading-and-reasoning
    alone is NOT a valid verdict here — you must observe behaviour.

    **Target skill:** [SKILL_DIR — path to the skill folder]
    **Test cases:** [load the staged temporary cases file whose path the dispatch
      provides, if any; ELSE synthesize cases from the skill's own contract — its
      description, completion criteria, rationalization table, red flags — and mark
      every case `synthesized` (lower-confidence, the author staged none).]

    ## For each test case

    1. Run the case's task WITH the skill in context. Record what the agent did,
       step by step, VERBATIM.
    2. Invert it: would the agent have complied WITHOUT the skill (the case's RED
       baseline)? If yes, the case proves nothing — mark it `no-op`, not `pass`.
    3. Check the case's stated GREEN expectation and the skill's requirement it
       exercises. PASS only if behaviour matches GREEN AND differs from the RED baseline.

    ## Output format

    ## Skill Validation

    **Verdict:** PASS | FAIL | INCONCLUSIVE (synthesized cases / contaminated baseline)

    **Per case:**
    - [TC id]: PASS | FAIL | no-op — [verbatim evidence of what the agent did] —
      [why it passed/failed against the case's GREEN expectation]

    **Loopholes / new rationalizations observed (feed REFACTOR):**
    - [verbatim excuse the agent invented] — [the rule/red-flag that should counter it]

    **Notes:**
    - [synthesized vs staged cases; any contamination caveat that limits confidence]
````

**Reviewer returns:** the verdict + per-case pass/fail with verbatim evidence + any new
rationalizations. A FAIL or a case that is only `no-op` means the skill is not done — loop back to
REFACTOR (close the loophole) or re-aim the scenario, then re-validate. Never ship on a FAIL. The
staged cases file is a temporary working file: the caller (the `validate` gate) deletes it after
recording this verdict — it is never persisted under the skill.
