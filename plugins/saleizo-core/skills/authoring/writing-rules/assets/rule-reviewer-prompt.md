# Rule Reviewer Prompt Template

Use this when dispatching an independent subagent to review a rule before it lands — especially a rule that will be widely loaded or was promoted from a recurring lesson.

**Purpose:** the **author-blind pass** — catch what the rule's author cannot judge from inside their own context. The author has already self-checked the form (a `description`, a `## When`, a `## Review Checklist`, an imperative ✅/❌ example, one topic); your value is the dimension they are blind to: **does this duplicate an existing rule, and is it scoped so it fires only where it should.**

**Dispatch after:** the rule file is drafted.

**Cold means cold:** a fresh subagent with zero shared context, given the existing rules directory — it re-derives whether this rule already exists rather than trusting the author it is new.

```markdown
Subagent (general-purpose):
  description: "Review a project rule"
  prompt: |
    You review a project rule for .claude/rules/. Judge it cold, as the agent
    that will have this rule injected and must act on it. Your job is NOT to
    re-run the author's form checklist; it is to catch what the author is blind to.

    **Existing rules dir:** [.claude/rules/ — list neighbors so you can spot duplication]
    **Rule to review:** [RULE_FILE_PATH]

    ## What to check (the author-blind class)

    | Category | What to look for |
    |----------|------------------|
    | Duplication, re-derived | Read the neighbors first, then the new rule. Does it restate or overlap one that already exists? The author is anchored on the rule they just wrote and won't see the overlap — you, holding the whole set, will. Name the overlapping file; it should cross-link, not fork. |
    | Scoping | An always-on rule legitimately has no `paths` — do NOT flag its absence. For an *area-specific* rule, is `paths` present and as tight as it applies? Flag missing or over-broad scope — it will nag outside its area. |
    | Applicability | Would two agents reading this rule cold apply it two different ways? An instruction clear to the author who holds the context, ambiguous to a reader who doesn't. |

    Secondary — the author has self-checked the form; flag only if you trip over it:
    a missing `description`, no actionable ✅/❌ example, no `## When` or `## Review
    Checklist`, more than one topic bundled, or no stated exception.

    ## Calibration

    Only flag what would make the rule misfire: duplication of an existing rule,
    an area-specific rule left unscoped or over-broad, or an instruction two agents
    would apply two ways. A missing `paths` on an always-on rule is NOT a defect.
    Minor wording or section-order deviation is not an issue. Approve unless there
    is a real defect.

    ## Output format

    ## Rule Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Section/field]: [specific issue] — [why it makes the rule misfire]

    **Recommendations (advisory):**
    - [suggestions]
```

**Reviewer returns:** Status, Issues (if any), Recommendations. Fix issues and re-review before relying on the rule.
