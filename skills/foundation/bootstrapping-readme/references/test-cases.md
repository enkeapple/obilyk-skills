# Test Cases — bootstrapping-readme

Persisted RED baselines and GREEN expectations. Failure class: **shaping** (the README's structure and the catalog row shape, not a discipline gate). Layer 2 runs these WITH the skill and inverts each (would it comply WITHOUT?).

## Scenario 1 — fresh README, superpowers-style landing page

**Prompt:** "The repo's README.md is bare (just a title). Generate a full README landing page styled like the Superpowers project — intro, sections, and a catalog of the skills grouped by category."

**RED (baseline, no skill — observed):** Two reps produced divergent section sets (each invented its own intro + sections) and BOTH rendered the catalog as plain links `- [name](path) — desc`, never the bold-link form. Neither marked any prose as a human-fill placeholder; one wrote invented prose straight in as if final. No fixed scaffold, no derived/auditable boundary.

**GREEN (with skill — expected):**
- The page is the fixed scaffold from `assets/readme-scaffold.md`: `# <repo>` H1, placeholder sections (intro, Quickstart, How it works, Installation, Philosophy, Contributing) emitted as `<!-- TODO -->` stubs, and the catalog under `## Skills`.
- The catalog sits inside the `<!-- skills:start --> … <!-- skills:end -->` marker pair with the generated-by comment.
- Every catalog row is the bold-link shape `- **[name](link)** — description`, grouped by `###` category, ordered per the contract.
- Scaffold prose is clearly placeholder/human-owned, not invented final copy.

**Inversion:** without the skill the row shape is not bold-linked and the section set does not converge to the scaffold → GREEN is meaningful.

## Scenario 2 — re-run against an existing README with filled scaffold

**Prompt:** "Regenerate the skills catalog. README already has a filled-in intro, Quickstart, and Philosophy the team wrote, plus the managed block."

**GREEN (expected):** Only the content between the markers is replaced (rows re-derived, bold-link shape). The human-authored intro/Quickstart/Philosophy prose is byte-for-byte untouched; no scaffold `<!-- TODO -->` stubs are re-injected over real prose.

**Inversion:** a skill that re-scaffolds or rewrites the prose on re-run fails this case.

## Scenario 3 — row shape regression guard

**GREEN (expected):** rows are never a table, never a plain `- [name](link)` without bold, never carry a kind column. The bold link `**[name](link)**` is required by the catalog-derivation contract (shared verbatim with `auditing-readme`).
