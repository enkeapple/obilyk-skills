# Rule Reviewer Prompt Template

Use this when dispatching an independent subagent to review a rule before it lands — especially a rule that will be widely loaded or was promoted from a recurring lesson.

**Purpose:** confirm the rule is scoped, actionable, non-duplicative, and shaped correctly.

**Dispatch after:** the rule file is drafted.

```markdown
Subagent (general-purpose):
  description: "Review a project rule"
  prompt: |
    You review a project rule for .claude/rules/. Judge it cold, as the agent
    that will have this rule injected and must act on it.

    **Rule to review:** [RULE_FILE_PATH]
    **Existing rules dir:** [.claude/rules/ — list neighbors so you can spot duplication]

    ## What to check

    | Category | What to look for |
    |----------|------------------|
    | Frontmatter | Has `description` (one line) and `paths`. |
    | Scoping | `paths` is as tight as the rule truly applies — not a broad/global glob for an area-specific rule. Flag over-broad scope (it will nag everywhere). |
    | Actionable | Implementation is imperative with a real ✅/❌ example — not a topic explanation or rationale-only. |
    | When + Checklist | Has a `## When` and a `## Review Checklist`. |
    | Exceptions | States when NOT to apply, so it isn't over-applied. |
    | One topic | Covers a single concern; no unrelated rules bundled. |
    | Duplication | Does not restate an existing rule — should cross-link instead. Name any overlap. |

    ## Calibration

    Only flag what would make the rule misfire: missing/over-broad `paths`,
    a body with no actionable instruction, no example for a code rule, or
    duplication of an existing rule. Minor wording is not an issue.
    Approve unless there is a real defect.

    ## Output format

    ## Rule Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Section/field]: [specific issue] — [why it makes the rule misfire]

    **Recommendations (advisory):**
    - [suggestions]
```

**Reviewer returns:** Status, Issues (if any), Recommendations. Fix issues and re-review before relying on the rule.
