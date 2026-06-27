# Two-Layer Review — why the layers are disjoint

The spec gets two review passes that catch **different** defect classes. Keeping their remits disjoint is what makes the second pass worth its cost — an overlapping re-run of the first is theatre. The `SKILL.md` body carries the compact triggers; this file is the rationale behind them.

## Self-review (author pass — cheap, every time)

Checks you can make against the spec **itself**, with the context you already hold:

- No Placeholders — every contract, path, edge case, and command is concrete.
- Out-of-scope list is non-empty.
- All 8 required sections present and internally consistent.

This pass is **blind to what you misread**: a misread requirement yields a spec that is internally clean and self-reviews green — the same wrong premise both wrote it and checked it. No amount of re-reading your own artifact surfaces the assumption you never knew you made.

## Independent cold reviewer (the author-blind pass)

Dispatch a fresh subagent with **zero shared context** for anything **beyond small** — touches more than one surface/module, defines or changes a shared contract (API, schema, interface), or includes a destructive/irreversible operation. (A single-surface change with no shared contract is *small* — self-review suffices.)

Use [assets/spec-reviewer-prompt.md](../assets/spec-reviewer-prompt.md), and hand it the original request / approved design **alongside** the spec. Without the source it cannot judge conformance and collapses into a second self-review — the redundancy that reads as process theatre. Its remit is the class self-review structurally cannot reach:

- **Conformance to source** — the consistent-but-wrong misread: a spec internally clean but divergent from what the request/design actually asked for.
- **Ambiguity** — any requirement two competent engineers would build differently.

Fix what it finds and re-review; do not code against a spec with open issues.

## Why this split (the load-bearing reason)

A cold pass earns its load only if it is *differently informed* — fed the source the artifact derives from, with a remit disjoint from the self-review's (author-reachable checks vs the author-blind class). A fresh agent re-running the same checklist against only the artifact adds nothing the author could not see. The disjointness is the point, not the freshness alone.
