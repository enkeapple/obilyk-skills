# Vocabulary — the leading words of skill design

A skill exists to wrangle determinism out of a stochastic system. **Predictability** — the agent
taking the same *process* every run, not producing identical output — is the root virtue; every
term below serves it. These are **leading words**: compact concepts the model already holds, reused
across a skill so they accumulate a shared meaning and anchor behaviour in few tokens. SKILL.md and
the other references use these in bold; look them up here.

## Core virtue

- **Predictability** — the agent runs the same *process* each time. The goal of every lever here. Output may vary; the path should not.
- **Leading word** — a pretrained concept (e.g. *lesson*, *tracer bullet*, *red*) the agent thinks *with* while running the skill. Repeated, it builds a distributed definition and recruits priors in few tokens. It anchors execution in the body and invocation in the description. Prefer a stronger word over more prose (*relentless*, not "be thorough").

## Invocation & load

- **Model-invoked** — the skill keeps a `description`, so the agent (or another skill) can fire it autonomously. Costs **context load**: the description sits in the window every turn.
- **User-invoked** — `disable-model-invocation: true`; only a human typing its name invokes it, and no other skill can. Zero context load, but spends **cognitive load**: the human is the index that must remember it.
- **Context load** — tokens a skill costs by being loaded (chiefly its description, every turn).
- **Cognitive load** — the human burden of remembering a user-invoked skill exists.
- **Router skill** — one user-invoked skill that names the others and when to reach each, curing piled-up cognitive load.

## Information hierarchy — how far down a piece sits

A ladder ranked by how immediately the agent needs the material:

1. **In-skill step** — an ordered action in SKILL.md (the primary tier): what the agent does, in order. Ends on a **completion criterion**.
2. **In-skill reference** — a definition/rule/fact in SKILL.md, consulted on demand; often a flat peer-set (fine, not a smell).
3. **External reference** — reference pushed into a separate file, reached by a **context pointer**, loaded only when the pointer fires.

- **Completion criterion** — the checkable condition that tells the agent a step is done. Make it *checkable* and, where it matters, *exhaustive* ("every modified case accounted for"). A vague one invites **premature completion**.
- **Progressive disclosure** — the move down the ladder: out of SKILL.md into a linked file, so the top stays legible. Inline what every branch needs; push behind a pointer what only some reach.
- **Context pointer** — a link to disclosed material; its *wording* (not its target) decides when and how reliably the agent follows it.
- **Branch** — a distinct way the skill is used; different runs take different paths. The cleanest disclosure test: inline the shared path, disclose the branch-specific.
- **Co-location** — once material sits on a rung, keep a concept's definition, rules, and caveats under one heading rather than scattered.
- **Legwork** — the digging the agent does within the work; a demanding completion criterion drives more of it.

## Splitting & pruning

- **Granularity** — how finely skills are divided; each cut spends a load, so split only when the cut earns it (by invocation, or by sequence to defeat premature completion).
- **Single source of truth** — each meaning lives in exactly one authoritative place; changing behaviour is a one-place edit.
- **Relevance** — does a line still bear on what the skill does? If not, cut.
- **No-op test** — does a line change behaviour versus the model's default? If not, it is a **no-op**: load paid to say nothing.

## Failure modes (diagnostics)

- **Premature completion** — ending a step before it is genuinely done, attention slipping to *being done*. Fix: sharpen the completion criterion first; only then hide post-completion steps by splitting.
- **Duplication** — the same meaning in more than one place. Costs maintenance and tokens, and inflates a meaning's apparent rank.
- **Sediment** — stale layers that settle because adding feels safe and removing feels risky. The default fate without a pruning discipline.
- **Sprawl** — a skill simply too long, even when every line is live. Cure: the ladder — disclose reference, split by branch/sequence.
- **No-op** — a line the model already obeys by default. Fix: a stronger leading word, not a different technique — or delete it.
