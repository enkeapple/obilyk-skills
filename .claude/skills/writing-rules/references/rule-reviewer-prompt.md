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
    | Frontmatter | Has a `description` (one line). `paths` only if the rule is area-specific. |
    | Scoping | An always-on rule legitimately has no `paths` — do NOT flag its absence. For an *area-specific* rule, `paths` is present and as tight as it applies — flag missing or over-broad scope (it will nag everywhere). |
    | Actionable | Implementation is imperative with a real ✅/❌ example — not a topic explanation or rationale-only. |
    | When + Checklist | Has a `## When` and a `## Review Checklist`. |
    | Exceptions | States when NOT to apply, so it isn't over-applied. |
    | One topic | Covers a single concern; no unrelated rules bundled. |
    | Duplication | Does not restate an existing rule — should cross-link instead. Name any overlap. |

    ## Calibration

    Only flag what would make the rule misfire: an area-specific rule left
    unscoped or over-broad, a body with no actionable instruction, no example
    for a code rule, or duplication of an existing rule. A missing `paths` on
    an always-on rule is NOT a defect. Minor wording or section-order deviation
    is not an issue. Approve unless there is a real defect.

    ## Output format

    ## Rule Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Section/field]: [specific issue] — [why it makes the rule misfire]

    **Recommendations (advisory):**
    - [suggestions]
```

**Reviewer returns:** Status, Issues (if any), Recommendations. Fix issues and re-review before relying on the rule.
