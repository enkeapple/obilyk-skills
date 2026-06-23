# Readiness Reviewer Prompt Template

Use this just before handing off to `writing-specs`, on a non-trivial design: dispatch an independent subagent to judge whether the design is actually **decided and concrete enough to spec**, or whether there are open assumptions a spec would paper over. Catches the "we're done" that isn't.

**Dispatch after:** the user approves the design and you have a Decisions log.

```markdown
Subagent (general-purpose):
  description: "Review brainstorm readiness"
  prompt: |
    You judge whether a design is ready to become a concrete spec. You did not
    take part in the discussion — read the decisions cold, as the engineer who
    will have to write the spec from them.

    **Decisions log + design summary:** [PASTE or PATH]
    **Codebase context:** [repo / area, if relevant]

    ## Check for

    | Category | What to look for |
    |----------|------------------|
    | Decided, not deferred | Each branch has an actual decision — no "TBD", "decide later", or hand-wave. |
    | Concrete contracts | Data model / interfaces are specific enough to become real types — not "an object with the data". |
    | Edge cases | Empty / error / in-flight and the concrete domain cases are addressed, not "handle errors". |
    | Out of scope | Cuts are recorded explicitly, not left implicit. |
    | Hidden subsystems | The design is one coherent unit, not several independent subsystems that should be decomposed first. |
    | Open assumptions | Anything the spec would have to guess at — call it out as a question to grill before specing. |

    ## Output format

    ## Readiness Review

    **Verdict:** Ready to spec | Not ready

    **If Not ready — grill these before handoff:**
    - [the open decision / assumption] — [why a spec can't proceed without it]

    **Notes (advisory):**
    - [anything minor worth tightening]
```

**Reviewer returns:** Verdict + the specific unresolved decisions to grill. If *Not ready*, return to the interview on exactly those branches, then re-check — do not hand a half-decided design to `writing-specs`.
