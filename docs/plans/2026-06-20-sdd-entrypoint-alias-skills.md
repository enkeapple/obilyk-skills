# SDD Entry-Point Alias Skills — Implementation Plan

**Goal:** Add 4 short user-typed slash entry points (`/sdd`, `/grill`, `/spec`, `/audit`) as thin `disable-model-invocation` alias skills that delegate to the canonical chain skills.
**Architecture:** Each alias is a real skill under a new `skills/entrypoints/` category with a flat symlink in `.claude/skills/`; its body holds no logic, only steering prose + `$ARGUMENTS` delegating to one canonical skill. Two vault rules (`skill-routing-sync.md`, `glossary.md`) are reworded so the `disable-model-invocation ⇒ no routing key` invariant covers alias facades, and the root `CLAUDE.md` routing table lists the short entries.
**Tech stack:** Markdown skills + symlinks; no app code, no build/test pipeline. Verification = structural validators + verification-by-invocation.

## Global constraints

- This is the vault, not a consumer repo. There is no `pnpm`/build/unit-test pipeline. "Verification" = the skill validators (frontmatter ≤1024, `name` = dir, links resolve, fences balanced, word count) + manual verification-by-invocation.
- **RED/GREEN subagent runs are N/A for a pure delegating facade** (no pressure-testable behavior) — per the spec. Do NOT fabricate a behavioral RED; verification is structural + invocation.
- Single source of truth: ALL logic stays in canonical skills; an alias only delegates.
- Do NOT touch `.claude/skills-routing.json` or any `hooks/**` file.
- `name:` in each `SKILL.md` MUST equal its directory name.
- No AI attribution in any commit message; one logical change per commit (per `git-conventions.md`).
- Markdown per `markdown-style.md` (spaced table delimiters, language on every fence, standard links).

## Files touched (map)

| File | Responsibility |
| --- | --- |
| `.claude/rules/common/skill-routing-sync.md` | reword carve-out + checklist to the `disable-model-invocation ⇒ no key` invariant; add canonical-rename→fix-alias line |
| `.claude/rules/domains/glossary.md` | generalize "no routing entry" to all `disable-model-invocation` skills; define "alias skill" sub-kind |
| `skills/entrypoints/sdd/SKILL.md` | `/sdd` → `sdd-lifecycle` |
| `skills/entrypoints/grill/SKILL.md` | `/grill` → `grilling` |
| `skills/entrypoints/spec/SKILL.md` | `/spec` → `writing-specs` |
| `skills/entrypoints/audit/SKILL.md` | `/audit` → `spec-drift-audit` |
| `.claude/skills/{sdd,grill,spec,audit}` | flat discovery symlinks → `../../skills/entrypoints/<alias>` |
| `CLAUDE.md` (root) | add 4 short entry points to the skill-routing table |

Task order: **Task 1 (rules) before Task 2 (aliases)** so the invariant exists before aliases land (else the routing-sync checklist flags them as missing keys). Task 3 (CLAUDE.md) is independent.

---

## Task 1 — Reword the two rules to the `disable-model-invocation ⇒ no key` invariant

**Files:** `.claude/rules/common/skill-routing-sync.md` (EDIT), `.claude/rules/domains/glossary.md` (EDIT)

**Interfaces:**
- Consumes: nothing.
- Produces: the invariant text that Task 2's verification relies on ("an alias with `disable-model-invocation: true` is correctly absent from `skills-routing.json`").

**Steps:**

1. Read both files first (read-before-edit). Confirm the exact current strings below still match.

2. In `skill-routing-sync.md`, replace the Edge-Cases carve-out bullet.

   Current:

   ```text
   - A reference/methodology skill that opts out of routing with `disable-model-invocation: true` in its `SKILL.md` frontmatter and declares no trigger phrases (e.g. `writing-great-skills`, `improve-codebase-architecture`) is not trigger-routed — do NOT add a `triggers` entry or a `skills` key for it. Its absence from `skills-routing.json` is correct, not a gap. The "every skill has a key" check below applies only to invocable skills.
   ```

   New:

   ```text
   - **Any skill with `disable-model-invocation: true` is not trigger-routed — do NOT add a `triggers` entry or a `skills` key for it.** This covers two sub-kinds: a **reference/methodology** skill that declares no trigger phrases (e.g. `writing-great-skills`, `improve-codebase-architecture`), and an **alias-facade** skill under `skills/entrypoints/` that is user-invocable (`/sdd`, `/grill`, …) but delegates to a canonical skill. For both, absence from `skills-routing.json` is correct, not a gap. The "every skill has a key" check below applies only to **trigger-routed** skills (those without `disable-model-invocation`).
   ```

3. In `skill-routing-sync.md`, replace the first Review-Checklist item.

   Current:

   ```text
   - [ ] Every invocable skill directory under `skills/` (excluding `disable-model-invocation` reference skills) has exactly one matching key in `skills-routing.json` (`find skills -name SKILL.md` vs `jq '.skills | keys' .claude/skills-routing.json`).
   ```

   New:

   ```text
   - [ ] Every trigger-routed skill directory under `skills/` (excluding any `disable-model-invocation` skill — reference or alias facade) has exactly one matching key in `skills-routing.json` (`find skills -name SKILL.md` vs `jq '.skills | keys' .claude/skills-routing.json`).
   ```

4. In `skill-routing-sync.md`, add a bullet under `## Implementation` (after the Trigger-change bullet) for the alias↔canonical coupling.

   Add:

   ```text
   - **Rename/move a canonical skill that an alias delegates to** → in the same change, fix the alias body under `skills/entrypoints/` that names it (the alias body is a structural skill-name reference, per "Skill names are structural claims"). The alias has no routing key to update, but its prose target must still resolve.
   ```

5. In `glossary.md`, update the "What is NOT in this domain" sentence about `writing-great-skills`.

   Current:

   ```text
   `writing-great-skills` is a reference skill (`disable-model-invocation: true`) — it is NOT trigger-routed and has no entry in `skills-routing.json`.
   ```

   New:

   ```text
   `writing-great-skills` is a reference skill (`disable-model-invocation: true`) — it is NOT trigger-routed and has no entry in `skills-routing.json`. The general rule: `disable-model-invocation: true` ⇒ no `skills-routing.json` entry, and it has two sub-kinds — **reference skills** (methodology, no triggers) and **alias skills** (see below).
   ```

6. In `glossary.md`, add an Edge-Cases bullet defining the alias sub-kind.

   Add:

   ```text
   - An **alias skill** is a thin `disable-model-invocation` facade under `skills/entrypoints/` (`sdd`, `grill`, `spec`, `audit`) whose body delegates to exactly one canonical skill and forwards `$ARGUMENTS` — it holds no logic of its own and is correctly absent from `skills-routing.json`. The invariant `name === dir === SKILL.md name:` still holds; only the routing-key expectation differs (it has none).
   ```

7. **dogfood-generator-sync determination (required, do not skip).** Grep the bootstrapping templates for the reworded sections:

   ```bash
   grep -rln "disable-model-invocation\|every skill has a key\|alias skill" skills/foundation/bootstrapping-*/
   ```

   Expected: no hit that ships this concept to a consumer repo → record `[N/A] — the "alias skill" concept and the disable-model-invocation carve-out are vault-internal; no bootstrapping-* template emits them, and no auditing-* mirror needs the inverse check`. If a hit IS found, apply the same reword to that template and its `auditing-*` mirror per `dogfood-generator-sync.md`.

8. Verify markdown + checklist self-consistency (no behavioral RED — these are rule-doc edits):

   ```bash
   grep -nE '\|-{2,}\|' .claude/rules/common/skill-routing-sync.md .claude/rules/domains/glossary.md   # expect: no unspaced table delimiters
   ```

   Expected output: empty (no matches). Re-read the full Review-Checklist of `skill-routing-sync.md` and confirm the reworded item no longer flags a `disable-model-invocation` alias as a missing key.

9. Commit:

   ```bash
   git add .claude/rules/common/skill-routing-sync.md .claude/rules/domains/glossary.md
   git commit -m "docs(rules): cover alias facades under disable-model-invocation no-key invariant"
   ```

---

## Task 2 — Create the 4 alias skills + flat symlinks

**Files:** `skills/entrypoints/{sdd,grill,spec,audit}/SKILL.md` (NEW ×4), `.claude/skills/{sdd,grill,spec,audit}` (NEW symlinks ×4)

**Interfaces:**
- Consumes: Task 1's invariant (aliases must be exempt from the routing-key check).
- Produces: `/sdd`, `/grill`, `/spec`, `/audit` user-typed entry points.

**Steps:**

1. Create the `sdd` alias. Write `skills/entrypoints/sdd/SKILL.md`:

   ```markdown
   ---
   name: sdd
   description: Short user-typed entry point that runs the full gated SDD pipeline. Alias for the sdd-lifecycle skill.
   disable-model-invocation: true
   argument-hint: "<feature idea or ticket ID, optional>"
   ---

   Use the `sdd-lifecycle` skill. Treat the input below as the build request and
   classify it per that skill's entry table (a bare ticket ID or URL routes to
   `resolving-requirements`; a free-text idea enters at `grilling`).

   Input: $ARGUMENTS
   ```

2. Create the `grill` alias. Write `skills/entrypoints/grill/SKILL.md`:

   ```markdown
   ---
   name: grill
   description: Short user-typed entry point to grill a fuzzy idea into a shared design. Alias for the grilling skill.
   disable-model-invocation: true
   argument-hint: "<the idea to grill, optional>"
   ---

   Use the `grilling` skill. Treat the input below as the idea to grill into a design.

   Input: $ARGUMENTS
   ```

3. Create the `spec` alias. Write `skills/entrypoints/spec/SKILL.md`:

   ```markdown
   ---
   name: spec
   description: Short user-typed entry point to turn an approved design into a concrete spec. Alias for the writing-specs skill.
   disable-model-invocation: true
   argument-hint: "<the approved design or requirements, optional>"
   ---

   Use the `writing-specs` skill. Treat the input below as the approved design or
   requirements to turn into a spec.

   Input: $ARGUMENTS
   ```

4. Create the `audit` alias. Write `skills/entrypoints/audit/SKILL.md`:

   ```markdown
   ---
   name: audit
   description: Short user-typed entry point to check shipped code against an approved spec. Alias for the spec-drift-audit skill.
   disable-model-invocation: true
   argument-hint: "<spec path or area to audit, optional>"
   ---

   Use the `spec-drift-audit` skill. Treat the input below as the spec or area to
   audit the shipped code against.

   Input: $ARGUMENTS
   ```

5. Create the 4 flat symlinks (relative two-up, matching the established pattern):

   ```bash
   ln -s ../../skills/entrypoints/sdd   .claude/skills/sdd
   ln -s ../../skills/entrypoints/grill .claude/skills/grill
   ln -s ../../skills/entrypoints/spec  .claude/skills/spec
   ln -s ../../skills/entrypoints/audit .claude/skills/audit
   ```

6. Verify symlinks resolve and point correctly:

   ```bash
   for a in sdd grill spec audit; do readlink .claude/skills/$a; test -f .claude/skills/$a/SKILL.md && echo "$a OK" || echo "$a BROKEN"; done
   ```

   Expected output:

   ```text
   ../../skills/entrypoints/sdd
   sdd OK
   ../../skills/entrypoints/grill
   grill OK
   ../../skills/entrypoints/spec
   spec OK
   ../../skills/entrypoints/audit
   audit OK
   ```

7. Verify `name:` equals dir for each, and routing is untouched:

   ```bash
   for a in sdd grill spec audit; do grep -q "^name: $a$" skills/entrypoints/$a/SKILL.md && echo "$a name OK" || echo "$a name MISMATCH"; done
   for a in sdd grill spec audit; do echo "$a key present: $(jq --arg a "$a" '.skills | has($a)' .claude/skills-routing.json)"; done   # expect false ×4
   git diff --stat -- .claude/skills-routing.json   # expect: empty (untouched)
   ```

   Expected: `* name OK` ×4; `* key present: false` ×4; empty diff stat.

8. **Verification-by-invocation (REQUIRED — replaces RED/GREEN for a facade).** In a session (note: a new top-level skills dir may need a session restart to appear in `/` — absence before restart is NOT a failure):
   - Type `/sdd ACME-1234` → confirm `sdd-lifecycle` is invoked AND it classifies the bare ticket ID to `resolving-requirements`, not `grilling`.
   - Type `/grill add a setting` → confirm `grilling` starts with that idea.
   - Type `/spec` and `/audit` (no arg) → confirm each launches its canonical skill.
   - If `$ARGUMENTS` does not interpolate (input does not arrive), apply the documented fallback: replace `Input: $ARGUMENTS` with prose "Pass the user's typed input to it." and re-verify.

9. Commit:

   ```bash
   git add skills/entrypoints/ .claude/skills/sdd .claude/skills/grill .claude/skills/spec .claude/skills/audit
   git commit -m "feat(entrypoints): add /sdd /grill /spec /audit alias skills"
   ```

---

## Task 3 — Add the short entry points to the root CLAUDE.md routing table

**Files:** `CLAUDE.md` (root, EDIT)

**Interfaces:**
- Consumes: the 4 alias names from Task 2.
- Produces: nothing downstream.

**Steps:**

1. Read the root `CLAUDE.md` "Skill routing" table. Confirm the current front-door row:

   ```text
   | Run the full gated SDD pipeline end-to-end on a change (front door) | `sdd-lifecycle` |
   ```

2. Add a short-entry-points note row beneath the table (a single row that names the aliases without duplicating the per-phase rows — keeps the table about capabilities, not keystrokes). Insert immediately after the table's last row:

   ```text
   | Short user-typed aliases (deterministic entry; same skills) | `/sdd`→`sdd-lifecycle`, `/grill`→`grilling`, `/spec`→`writing-specs`, `/audit`→`spec-drift-audit` |
   ```

3. Verify markdown:

   ```bash
   grep -nE '\|-{2,}\|' CLAUDE.md   # expect: empty (no unspaced table delimiters introduced)
   ```

   Expected output: empty.

4. Commit:

   ```bash
   git add CLAUDE.md
   git commit -m "docs: list short SDD alias entry points in routing table"
   ```

---

## Acceptance (whole plan)

- 4 alias `SKILL.md` files exist, each `name:` = dir, `disable-model-invocation: true`, body delegates + forwards `$ARGUMENTS`.
- 4 symlinks resolve to `skills/entrypoints/<alias>`.
- `skills-routing.json` unchanged; `jq has("<alias>")` = false ×4; reworded routing-sync checklist does not flag the aliases.
- `skill-routing-sync.md` + `glossary.md` carry the `disable-model-invocation ⇒ no key` invariant + the alias sub-kind; dogfood-generator-sync determination recorded.
- Root `CLAUDE.md` lists the 4 short entries.
- Verification-by-invocation passed (or the prose fallback applied and re-verified).
