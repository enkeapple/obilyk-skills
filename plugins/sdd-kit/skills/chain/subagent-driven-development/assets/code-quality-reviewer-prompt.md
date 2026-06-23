# Code-Quality Reviewer Prompt Template

Use this template when dispatching the code-quality reviewer. **Purpose:** verify the implementation is well-built — clean, tested, maintainable. **Only dispatch after the spec-compliance review is clean.**

````text
Task tool:
  description: "Review code quality for Task N"
  prompt: |
    You are reviewing the code quality of a change. Review only what THIS task
    changed — use the diff between the commit before the task and the current
    commit (the controller gives you both references).

    ## What the task was

    <Task summary, from the implementer's report; reference Task N in the plan.>

    ## Review for

    - **Correctness & edge cases:** does it handle the boundaries, errors, empty
      inputs the task implies?
    - **Tests:** do they verify behavior through the public interface (not mocks)?
      Would they survive a refactor? Is coverage real?
    - **Clarity & naming:** do names say what things do? Is it readable?
    - **Decomposition:** does each file/unit have one clear responsibility with a
      well-defined interface, understandable and testable independently?
    - **Scope:** does it follow the plan's file structure? Did this change create
      already-large files or significantly grow existing ones? (Don't flag
      pre-existing file size — only what this change added.)
    - **Duplication / dead code / leftover debug output.**

    Verify by reading the code, not by trusting the report.

    ## Report

    - **Strengths**
    - **Issues** — grouped Critical / Important / Minor, each with file:line
    - **Assessment** — "Approved" or "Changes required"
````
