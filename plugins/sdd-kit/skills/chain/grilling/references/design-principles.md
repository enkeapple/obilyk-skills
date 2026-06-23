# Design Principles

What a good design *is*, once the interview has surfaced the decisions. Use these to shape the design you present and to judge whether it is ready to spec.

## Propose 2-3 approaches first

Before presenting one design, lay out **2-3 approaches** with trade-offs, and lead with your recommendation and why. Settling on the first idea hides the cheaper or sturdier one. Frame them conversationally (MVP-first vs sturdiest vs fastest-to-ship), not as a wall of options.

## Design for isolation and clarity

Break the system into small units that each have **one clear purpose**, communicate through **well-defined interfaces**, and can be **understood and tested independently**. For every unit, you should be able to answer three questions:

1. What does it do?
2. How do you use it (its interface)?
3. What does it depend on?

If you can't understand a unit without reading its internals, or can't change its internals without breaking consumers, the boundaries are wrong — rework them before specing.

**Deep modules:** prefer a small interface over a large implementation. A unit that exposes three methods and hides a lot is better than one that exposes twenty. A file that keeps growing is usually doing too much — that's a signal to split, and a split is a legitimate part of the design.

## Decompose multi-subsystem ideas

If the idea is actually several independent subsystems ("a platform with chat, billing, and analytics"), **stop and decompose first** — don't grill the details of something that needs splitting. Identify the independent pieces, how they relate, and the build order. Then take the **first** sub-project through the normal grill → design flow. Each sub-project gets its own spec → plan → implementation cycle.

## Working in an existing codebase

- Explore the current structure before proposing changes; **follow existing patterns**.
- Where existing code genuinely blocks the work (a file grown too large, tangled responsibilities), include a **targeted** improvement in the design — the way a good developer improves code they're already in.
- Do **not** propose unrelated refactoring. Stay focused on what serves the current goal.

## YAGNI, ruthlessly

Cut every feature the user doesn't need for this goal. A cut is a decision to record (it becomes an Out-of-scope line in the spec), not a "maybe later" left in the design. The smallest design that delivers the value wins.

## Present in sections, approve incrementally

Present the design in **sections scaled to their complexity** — a few sentences when straightforward, more when nuanced. Cover architecture, data flow, components, error/edge handling. Ask after each section whether it's right, and revise before moving on. Incremental approval beats one big reveal the user has to swallow whole.
