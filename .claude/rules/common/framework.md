# Framework Charter

How to work in this repo, regardless of which skill or rule you touch. This is a **skills vault**, not an app: no `package.json`, no build, no unit-test suite, no `src/`. Verification here is **the skill validators + RED/GREEN subagent runs** — never `pnpm`/Vitest/simulator (that would be a consumer-repo leak). Domain vocabulary lives alongside in [domains-glossary.md](./domains-glossary.md); read it first if a request says "test", "RED/GREEN", "skill vs rule", or names the vault vs a consumer repo.

## Implementation Protocol

Before any change to a skill, rule, or hook:

1. **Read the full request**; restate the change in one line. If it touches a skill, identify the operating mode (AUTHOR / AUDIT / APPLY).
2. **Scan every layer the change touches** and classify each NONE / PARTIAL / FULL. The layers of a skill change are: `SKILL.md` frontmatter → `SKILL.md` body → `references/*.md` → `skills-routing.json` (triggers) → `.claude/hooks/*.sh`. A new/renamed/deleted skill or a trigger change is NOT done until routing matches disk (see [skill-routing-sync.md](./skill-routing-sync.md)).
3. **Write the contract as the artifact, not prose** — for a skill that means the actual `name:`/`description:` frontmatter and the precise prohibition or recipe; for a rule, the `## When` triggers and the canonical table. If you can't write it concretely yet, the task isn't understood — read more.
4. **Walk the behaviour**: the happy path plus how the skill holds under pressure (the loophole a subagent will try, the edge the rule must name).
5. **Only then write**, in dependency order: contract/frontmatter → body → references → routing. For PARTIAL, touch only the missing layers.

**Iron Law (AUTHOR):** no skill or skill edit without a failing test first. Run the baseline subagent scenarios and watch them fail (RED) *before* writing. Wrote it first? Delete it, start over. No exception for "simple edits". Abbreviate the phases for a trivial fix; never skip them.

## Suspicion Protocol

Run every phase presuming something is wrong. After each, check this vault's recurring failure modes — run the check, don't assume:

1. **Skipped RED** — did you observe a verbatim baseline failure WITHOUT the skill? No failure observed → there is nothing to fix; do not write the skill.
2. **Project leakage** — does the skill name a stack, path, or command (`pnpm`, `src/`, a route)? An agnostic skill must let the consumer repo fill specifics; mark unavoidable examples illustrative.
3. **Hallucinated skill name / symbol** — every referenced skill, rule, hook, path, or `references/*.md` link is verified by a `Read`/`Grep`/`Glob` THIS session. A skill name is a structural claim: it must equal a real dir and `SKILL.md` `name:`.
4. **Test passes for the wrong reason** — invert it: would the subagent *also* comply WITHOUT the skill? If yes, the GREEN run proves nothing — the scenario doesn't exert the pressure you think.
5. **Missed duplicate** — before adding a skill/rule, grep for an existing one that already covers it (the registry has 12 skills); extend rather than fork.
6. **Silent cut** — re-read the request bullet by bullet against the diff; a bullet with no corresponding edit is a silent cut, name it.

If suspicion confirms a defect: STOP, name the failure mode, go back one phase — do not patch silently.

## Zero-hallucination Rule

No structural claim about a skill, rule, or hook without a read THIS session. STOP-and-read phrases: "it probably exports…", "by analogy the other skill…", "I assume the routing has…". Memory is not evidence — label an unverified claim `(unverified — need to read X)`. **Editing a skill or rule doc IS editing code:** every symbol, path, link anchor, and skill name in it is re-verified before you write it.

## Evidence-Based Verification

A change is not done until you run and SHOW the vault's real checks (no "should pass"):

- **Validators** — frontmatter ≤1024, `name` regex, every `references/*.md` link resolves, fences balanced, word count sane. Paste the result.
- **GREEN subagent run** — re-run the RED scenarios WITH the skill; paste the compliance. Markdown existing is not "done".
- There is **no** `pnpm`/build/test pipeline and no simulator — do not claim to have run one. Read-only `git` is the only routine shell use; the human owns the commit.

## Question Discipline

Asking is the LAST step. Before a question, search in order: the skill in question → `writing-great-skills` → `.claude/rules/` → [lessons-learned.md](./lessons-learned.md) → `git log` → the skill files. If the answer is derivable, decide, justify in one line (smallest diff, closest existing pattern), and proceed. Reserve questions for a genuine product/scope decision or a git-boundary action — never an A/B/C/D menu on a derivable choice.
