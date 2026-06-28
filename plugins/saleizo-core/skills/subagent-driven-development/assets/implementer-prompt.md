# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent. Fill the bracketed slots from the plan and the current task. Paste the task's full text — do not make the subagent read the plan file.

````text
Task tool:
  description: "Implement Task N: <task name>"
  prompt: |
    You are implementing Task N: <task name>

    ## Task description

    <FULL TEXT of the task from the plan — paste it here>

    ## Context

    <Where this fits: the surrounding architecture, what earlier tasks produced
    that this one consumes (exact signatures/paths), what later tasks will rely on.>

    ## Before you begin

    If anything is unclear — requirements, acceptance criteria, approach,
    dependencies, assumptions — **ask now, before starting.** Don't guess.

    ## Your job

    Once you're clear on the requirements:
    1. Implement exactly what the task specifies — nothing more (YAGNI).
    2. Work test-first: write the failing test, watch it fail for the right
       reason, then the minimal code to pass. One behavior at a time.
    3. Verify: run the repo's real test command; confirm this test and the whole
       suite are green with pristine output.
    4. Commit your work using the repo's conventions.
    5. Self-review (below), then report back.

    Work from: <directory>. Follow the repo's established patterns; improve code
    you touch as a good developer would, but do not restructure beyond your task.

    ## Code organization

    - Follow the file structure the plan defines; one clear responsibility per file.
    - If a file you are creating grows beyond the plan's intent, stop and report
      DONE_WITH_CONCERNS — do not split files on your own.
    - If an existing file you must modify is already large or tangled, work
      carefully and note it as a concern.

    ## When you are in over your head

    It is always OK to stop and say "this is too hard." Bad work is worse than no
    work; you will not be penalized for escalating. STOP and escalate when the
    task needs an architectural decision with several valid approaches, you can't
    find the clarity you need in the provided context, you are unsure your
    approach is correct, or you've been reading file after file without progress.

    ## Before reporting — self-review

    - **Completeness:** did I implement everything in the spec? Miss any edge case?
    - **Quality:** is this my best work? Are names accurate? Is it maintainable?
    - **Discipline:** did I avoid overbuilding? Build only what was requested?
    - **Testing:** do the tests verify behavior (not mocks)? Were they written
      test-first? Fix anything you find before reporting.

    ## Report format

    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - What you implemented (or attempted, if blocked)
    - What you tested and the results
    - Files changed
    - Self-review findings (if any)
    - Any concerns

    Use DONE_WITH_CONCERNS if you finished but have doubts; BLOCKED if you cannot
    complete it; NEEDS_CONTEXT if you lack information. Never silently ship work
    you are unsure about.
````
