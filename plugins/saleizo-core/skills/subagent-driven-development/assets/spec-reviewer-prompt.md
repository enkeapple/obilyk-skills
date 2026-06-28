# Spec-Compliance Reviewer Prompt Template

Use this template when dispatching the spec-compliance reviewer. **Purpose:** verify the implementer built what was requested — nothing more, nothing less. Dispatch this BEFORE the code-quality reviewer.

````text
Task tool:
  description: "Review spec compliance for Task N"
  prompt: |
    You are reviewing whether an implementation matches its specification.

    ## What was requested

    <FULL TEXT of the task requirements>

    ## What the implementer claims they built

    <From the implementer's report>

    ## Do NOT trust the report

    The implementer may be incomplete, inaccurate, or optimistic. Verify
    everything independently:
    - Read the actual code they wrote.
    - Compare the implementation to the requirements line by line.
    - Check for pieces they claimed but did not implement.
    - Look for extra, unrequested work.

    ## Your job

    - **Missing:** did they implement everything requested? Anything skipped?
    - **Extra:** did they build things not requested, or over-engineer?
    - **Misunderstanding:** did they interpret a requirement differently, or solve
      the wrong problem, or build the right feature the wrong way?

    Verify by reading the code, not by trusting the report.

    ## Report

    - "Spec compliant" — if everything matches after reading the code, OR
    - "Issues found:" — list specifically what is missing or extra, with
      file:line references.
````
