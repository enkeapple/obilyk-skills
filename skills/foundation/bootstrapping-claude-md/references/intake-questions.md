# Intake Questions

Ask these before writing either CLAUDE.md. One question at a time, lead with a recommended default, prefer multiple-choice — borrow the style from `grilling`. Ask only what the human knows or must decide; **discover the rest by reading the repo** (don't ask what `package.json`/the folders already answer).

## Must-ask (only the human knows)

1. **What is the app?** Product, platforms (iOS/Android/web), the domain in one or two sentences.
2. **Managing engineer's position.** The seniority/role the agent should embody and hold the bar to — e.g. *Principal Mobile Dev*, *Staff Backend*, *Senior Frontend*. This becomes the **Role** section verbatim in spirit. (Recommended default: the seniority of the person you're talking to; confirm the exact title.)
3. **Is there a test pipeline?** yes (which runner + where) / no (verification is typecheck + lint + manual). Never assume — this changes the Completeness Checklist and the pipeline.
4. **Operating modes?** Does the team want explicit modes (work / audit / incident / explore), or just a single default flow?
5. **Session-handoff preference.** Where handoff/plan docs live, and whether a `handoff` skill is already wired.
6. **Git boundary.** Can the agent commit/push autonomously, or does the human own the commit?

## Confirm-against-repo (discover first, then confirm)

- **Stack & versions** — read `package.json`/lockfile/Makefile/CI; confirm the pins you found.
- **Real commands** — the actual run/build/typecheck/lint/test scripts. Quote them; don't paraphrase.
- **Folder layout & where rules live** — `.claude/rules/` structure, skills, slash commands.
- **Domains** — overlapping concepts that need a glossary (hand off to `bootstrapping-glossary`).
- **Placeholder keys** — for each key in [placeholder-keys.md](placeholder-keys.md) tagged `intake` (`<layers>`, `<ui-exercise-method>`, `<product-and-platforms>`) or left ambiguous after the disk read, ask the human; auto-tagged keys you resolved from disk are confirmed, not asked.

## Turn answers into sections

| Intake answer | Lands in |
| --- | --- |
| What the app is | root `CLAUDE.md` → "What this project is" |
| Managing position | `.claude/CLAUDE.md` → **Role** |
| Real commands | root → "Common commands"; checklist verification rows |
| Test pipeline yes/no | pipeline + Completeness Checklist "tests" row |
| Operating modes | `.claude/CLAUDE.md` → Operating modes |
| Handoff preference | `.claude/CLAUDE.md` → Session-handoff flow |
| Git boundary | `.claude/CLAUDE.md` → Git boundary |

If the human can't answer a must-ask, that section is a stub marked `<!-- TBD: confirm with owner -->`, not a guess presented as fact.
