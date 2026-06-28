# Promotion Reviewer Prompt Template

Use this when a cause-tag cluster reaches the threshold and you need an independent decision: **does this lesson stay in the log, or become a rule — and at what level?** Dispatch a fresh subagent so the judgment is not biased by the session that produced the entries.

**Dispatch after:** the promotion-debt scan flags a cause-tag at count ≥ 3 (or your chosen threshold) with no ledger line.

````markdown
Subagent (general-purpose):
  description: "Review lessons cluster for promotion"
  prompt: |
    You decide whether a recurring lesson should be promoted to a durable rule,
    and where the rule belongs. You did not write these entries — judge them cold.

    **Lessons log:** [PATH to .claude/lessons-learned.md]
    **Candidate cause-tag:** [TAG]
    **Existing rule homes in this repo:** [list the .claude/rules/ subfolders/files, or "flat .claude/rules/"]

    ## Read first
    - Every entry carrying that cause-tag (Symptom, Root cause, Prevention).
    - The `## Promoted clusters` ledger (is it already promoted?).
    - The existing rules, so a new rule does not duplicate one.

    ## Decide

    1. **Is it a real, generalizable pattern?** The entries must share a root-cause
       *class*, not just a surface symptom. Three unrelated bugs that got the same
       tag by accident are NOT a cluster — say so and recommend re-tagging.

    2. **Promote or keep?**
       - PROMOTE — three+ entries, one cause class, a check that generalizes beyond
         the specific files.
       - KEEP IN LESSONS — recurs but is too situational to state as a standing rule,
         or already covered by an existing rule (point to it).

    3. **If PROMOTE, choose the level/home** by scope:
       - Project-local process discipline (how THIS repo/owner works) → a local rule home.
       - General engineering pattern (would help any project on this stack) → a shared/common rule home.
       - If the repo has a flat `.claude/rules/`, just name the topic file.
       Justify the choice in one line.

    4. **Draft the rule text.** It must be ACTIONABLE — a check someone runs, not a
       story. Use one of: "Before X, always Y." / "X is forbidden; use Y because Z." /
       "When you see X, run Y to check Z."

    ## Output format

    ## Promotion Review — [TAG]

    **Decision:** Promote | Keep in lessons | Re-tag (not a real cluster)

    **Reason:** [one or two sentences]

    **If Promote:**
    - Target: `.claude/rules/<home>/<topic>.md`
    - Rule text:
      ```
      <the actionable rule lines>
      ```
    - Ledger line: `- <tag> → rules/<home>/<topic>.md (YYYY-MM-DD)`
    - Contributing entry bodies to delete from `## Entries`: [list the entry titles]
````

**Reviewer returns:** Decision, Reason, and (when promoting) the target file, the actionable rule text, the ledger line, and the list of contributing entry bodies to delete. You then apply those edits and commit them together.

If the decision is *Keep in lessons*, add a ledger line recording why it does not yet generalize, so the scan stops flagging it as debt.
