# Placeholder-key vocabulary + generator resolution — Implementation Plan

**Goal:** Add a canonical placeholder-key registry, parameterize the generator templates to it, document hybrid resolution in the generators, and add an inverse drift-check to the auditors.
**Architecture:** One new registry reference file is the single source of truth for 12 keys; the two `bootstrapping-*` templates reference its keys instead of baked stack nouns; the two `auditing-*` skills gain an inverse drift-check keyed to the registry. Verification is markdown validators + RED/GREEN subagent runs on GENERATED output — there is NO build/unit-test pipeline.
**Tech stack:** Markdown skill files under `skills/foundation/**`, `skills/authoring/**`, `skills/apply-chain/**`. Validators = grep/structural checks. RED/GREEN = subagent scenarios.

## Global constraints

- Spec: `docs/specs/2026-06-20-placeholder-key-vocabulary.md` — contracts copied verbatim below; do not re-derive.
- Agnostic-by-default: no vault path/command baked into a generator template; keys only (`agnostic-skill-authoring`).
- `dogfood-generator-sync`: a generator fix (F1/F3) and its auditor mirror (D4) move in this same plan; GREEN is proven on the GENERATED output, never only on the hand-fixed template.
- Marked-illustrative examples (writing-plans plan-template npm example, spec-drift-audit report-example, codebase-design TS example) are OUT of scope — do not touch.
- No git ops beyond the per-task commit *proposal*; the human runs commits. No edits to `.claude/hooks/**` or `settings.json`.
- "literally-named script" = EXACT key match in the manifest script map (`test`, not `test:unit`); fuzzy = judgment → intake.

---

## Task 1: Create the placeholder-key registry

**Files:**
- Create: `skills/foundation/bootstrapping-claude-md/references/placeholder-keys.md`

**Interfaces:**
- Consumes: nothing (first task).
- Produces: the 12 key tokens (`<run-cmd>`, `<typecheck-cmd>`, `<lint-cmd>`, `<format-cmd>`, `<test-cmd>`, `<build-deploy-cmd>`, `<stack-manifest>`, `<source-root>`, `<layers>`, `<ui-exercise-method>`, `<project-name>`, `<product-and-platforms>`), the 5-column schema, the resolution rule, and the auditor detection contract — all later tasks reference these.

- [ ] **Step 1: Write the failing test (the file is absent)**
```bash
test ! -f skills/foundation/bootstrapping-claude-md/references/placeholder-keys.md && echo "RED: registry absent"
```
Expected: prints `RED: registry absent`.

- [ ] **Step 2: Create the registry file** with this exact content (the 5-column table from the spec Contracts, plus the resolution rule and auditor contract):
```markdown
# Placeholder Keys Registry

The canonical keys a generated CLAUDE.md / glossary.md / framework.md uses for stack-specific
nouns. The `bootstrapping-*` skills resolve each key per consumer repo; the `auditing-*` skills
flag a leftover key or a baked noun. Keys are written `<key>` in templates.

## Keys

| key | meaning | auto\|intake (+fallback) | resolution-source | example-nouns (illustrative, non-exhaustive) |
| --- | --- | --- | --- | --- |
| `<run-cmd>` | run/start app in dev | auto iff a literally-named run/dev/start script; else intake | manifest scripts | npm run dev, pnpm dev, cargo run, go run, make run |
| `<typecheck-cmd>` | type/compile check | auto iff literally-named script; else intake | manifest scripts | tsc, npm run typecheck, cargo check, mypy, go build |
| `<lint-cmd>` | lint | auto iff literally-named script; else intake | manifest scripts | eslint, npm run lint, cargo clippy, ruff, golangci-lint |
| `<format-cmd>` | format / autofix | auto iff literally-named script; else intake | manifest scripts | prettier, cargo fmt, gofmt, ruff format |
| `<test-cmd>` | run tests | auto iff literally-named test script; else intake "is there a suite?" → none → emit the "no suite" sentence | manifest scripts | npm test, vitest, jest, cargo test, pytest, go test |
| `<build-deploy-cmd>` | build / native install / deploy | auto iff literally-named script; else intake | manifest scripts | npm run build, cargo build --release, docker build |
| `<stack-manifest>` | the stack/dependency manifest file | auto (the file exists on disk) | filesystem | package.json, Cargo.toml, go.mod, pom.xml, pyproject.toml |
| `<source-root>` | primary source directory | auto iff one conventional root present; else intake | filesystem | src/, app/, lib/, internal/, pkg/ |
| `<layers>` | architectural layers (Implementation Protocol) | intake | human | screen→hook→api→store, handler→service→repo |
| `<ui-exercise-method>` | how UI changes are exercised | intake | human | simulator, browser, emulator, (none — backend) |
| `<project-name>` | project / product name | auto (manifest name field or repo dir) | manifest name / dir | (the repo's name) |
| `<product-and-platforms>` | one-line product + platforms | intake | human | iOS/Android app, web SPA, CLI tool, backend service |

## Resolution rule (HYBRID)

Resolve a key to a real value ONLY when exactly one disk fact maps to it with no judgment
("literally-named script" = an EXACT key match in the manifest script map — `test`, not
`test:unit`). Any of: (a) manifest exists but the exactly-named script is absent, (b) multiple
manifests present, (c) two plausible scripts → leave the `<key>` and raise an intake question.
Never silently infer. `<test-cmd>` is the only key with a "no suite" branch, and that branch is
human-confirmed, never silent.

## Auditor detection contract

In a generated doc, flag drift on EITHER falsifiable signal:
1. an unresolved `<key>` token from this registry remains (exhaustive backstop); OR
2. a registry example-noun appears in a generator-owned slot (a command row, the stack line, the
   UI-exercise line). example-nouns is an illustrative signal, not a whitelist.
Cautionary prose that names a noun (e.g. "a command not in `package.json`") is NOT drift —
`agnostic-skill-authoring` exempts cautionary mentions; do not flag them.
```

- [ ] **Step 3: Run the test, confirm it passes (12 keys + validators)**
```bash
F=skills/foundation/bootstrapping-claude-md/references/placeholder-keys.md
echo "keys: $(grep -cE '^\| `<[a-z-]+>`' $F) (expect 12)"
echo "fences: $(grep -c '^```' $F) (expect even)"
```
Expected: `keys: 12`, `fences:` an even number.

- [ ] **Step 4: Commit**
```bash
git add skills/foundation/bootstrapping-claude-md/references/placeholder-keys.md && git commit -m "feat(bootstrapping-claude-md): add placeholder-key registry"
```

---

## Task 2: Parameterize root-claude-md-template (F1)

**Files:**
- Modify: `skills/foundation/bootstrapping-claude-md/references/root-claude-md-template.md`

**Interfaces:**
- Consumes: `<stack-manifest>`, `<run-cmd>`, `<typecheck-cmd>`, `<lint-cmd>`, `<format-cmd>`, `<build-deploy-cmd>` from Task 1.
- Produces: a fully key-parameterized root template (no baked `package.json`).

- [ ] **Step 1: Write the failing test (baked package.json link present)**
```bash
F=skills/foundation/bootstrapping-claude-md/references/root-claude-md-template.md
grep -n ']\(\./package\.json\)' $F && echo "RED: baked package.json link"
```
Expected: matches line 34, prints `RED: baked package.json link`.

- [ ] **Step 2: Replace the baked manifest link** (line ~34). Old → New:
```markdown
<!-- OLD -->
Stack pins live in [package.json](./package.json) and [.claude/rules/](./.claude/rules/) — read them, do not infer.
<!-- NEW -->
Stack pins live in [`<stack-manifest>`](./<stack-manifest>) and [.claude/rules/](./.claude/rules/) — read them, do not infer.
```

- [ ] **Step 3: Align the command table labels to the canonical keys** (the table at lines ~38–45). This is a ROW-BY-ROW relabel, NOT a single exact-block Edit — the real table also has a `| <start / serve> | `<real cmd>` |` row (line 41) between the shown rows; consolidate it away (the 6 cmd keys cover run/dev). Old rows → New rows:
```markdown
<!-- OLD (6 rows incl. the start/serve row at line 41) -->
| <run / dev> | `<real cmd>` |
| <start / serve> | `<real cmd>` |
| <typecheck> | `<real cmd>` |
| <lint> | `<real cmd>` |
| <lint autofix / format> | `<real cmd>` |
| <native install / build / deploy> | `<real cmd>` |
<!-- NEW (start/serve folded into run/dev; add a test row) -->
| run / dev | `<run-cmd>` |
| typecheck | `<typecheck-cmd>` |
| lint | `<lint-cmd>` |
| lint autofix / format | `<format-cmd>` |
| test | `<test-cmd>` |
| native install / build / deploy | `<build-deploy-cmd>` |
```

- [ ] **Step 4: Run the test, confirm it passes**
```bash
F=skills/foundation/bootstrapping-claude-md/references/root-claude-md-template.md
grep -c ']\(\./package\.json\)' $F   # expect 0
grep -cE '<(stack-manifest|run-cmd|typecheck-cmd|lint-cmd|format-cmd|test-cmd|build-deploy-cmd)>' $F  # expect >=7
```
Expected: first `0`; second `>= 7`.

- [ ] **Step 5: Commit**
```bash
git add skills/foundation/bootstrapping-claude-md/references/root-claude-md-template.md && git commit -m "refactor(bootstrapping-claude-md): key-parameterize root template (F1)"
```

---

## Task 3: Parameterize framework-charter-template (F3)

**Files:**
- Modify: `skills/foundation/bootstrapping-glossary/references/framework-charter-template.md`

**Interfaces:**
- Consumes: `<ui-exercise-method>`, `<typecheck-cmd>`, `<lint-cmd>`, `<test-cmd>` from Task 1.
- Produces: a charter template with no baked `simulator/browser`.

- [ ] **Step 1: Write the failing test (baked simulator/browser present)**
```bash
F=skills/foundation/bootstrapping-glossary/references/framework-charter-template.md
grep -n 'simulator/browser' $F && echo "RED: baked ui-exercise nouns"
```
Expected: matches line ~48, prints `RED: baked ui-exercise nouns`.

- [ ] **Step 2: Replace the UI-exercise line** (line ~48). Old → New:
```markdown
<!-- OLD -->
- For UI changes: exercise it (simulator/browser) or say explicitly you couldn't.
<!-- NEW -->
- For UI changes: exercise it via `<ui-exercise-method>` or say explicitly you couldn't.
```

- [ ] **Step 3: Align the verification command lines to canonical keys** (lines ~45–47). Old → New:
```markdown
<!-- OLD -->
- `<real typecheck command>`
- `<real lint command>`
- `<real test command, if any — else state there is no suite and what you verified manually>`
<!-- NEW -->
- `<typecheck-cmd>`
- `<lint-cmd>`
- `<test-cmd>` (if none, state there is no suite and what you verified manually)
```

- [ ] **Step 4: Run the test, confirm it passes**
```bash
F=skills/foundation/bootstrapping-glossary/references/framework-charter-template.md
grep -c 'simulator/browser' $F  # expect 0
grep -cE '<(ui-exercise-method|typecheck-cmd|lint-cmd|test-cmd)>' $F  # expect >=4
```
Expected: first `0`; second `>= 4`.

- [ ] **Step 5: Commit**
```bash
git add skills/foundation/bootstrapping-glossary/references/framework-charter-template.md && git commit -m "refactor(bootstrapping-glossary): key-parameterize charter template (F3)"
```

---

## Task 4: Document hybrid resolution + wire intake + cross-link the registry

**Files:**
- Modify: `skills/foundation/bootstrapping-claude-md/SKILL.md`
- Modify: `skills/foundation/bootstrapping-claude-md/references/intake-questions.md`
- Modify: `skills/foundation/bootstrapping-glossary/SKILL.md`

**Interfaces:**
- Consumes: the registry path + the auto|intake tags from Task 1.
- Produces: the documented resolution behavior generators follow.

- [ ] **Step 1: Write the failing test (no link to the registry yet)**
```bash
grep -rl 'placeholder-keys.md' skills/foundation/bootstrapping-claude-md/SKILL.md skills/foundation/bootstrapping-claude-md/references/intake-questions.md skills/foundation/bootstrapping-glossary/SKILL.md || echo "RED: registry not referenced"
```
Expected: prints `RED: registry not referenced`.

- [ ] **Step 2: Add a resolution paragraph to `bootstrapping-claude-md/SKILL.md`** (after the "Stack & real commands" bullet, ~line 38):
```markdown
- **Resolve placeholder keys (hybrid).** The templates use the keys in [references/placeholder-keys.md](references/placeholder-keys.md). Resolve a key to a real value ONLY when exactly one disk fact maps to it (an exactly-named manifest script; the manifest file itself) — auto. Anything ambiguous (no exactly-named script, multiple manifests, two plausible scripts) or any `intake`-tagged key (`<layers>`, `<ui-exercise-method>`, `<product-and-platforms>`) stays a `<key>` and becomes an intake question. Never infer a command silently.
```

- [ ] **Step 3: Map the intake-tagged keys in `intake-questions.md`** — add to the "Confirm-against-repo" / "Turn answers into sections" area (~line 18):
```markdown
- **Placeholder keys** — for each key in [placeholder-keys.md](placeholder-keys.md) tagged `intake` (`<layers>`, `<ui-exercise-method>`, `<product-and-platforms>`) or left ambiguous after the disk read, ask the human; auto-tagged keys you resolved from disk are confirmed, not asked.
```

- [ ] **Step 4: Cross-link the registry from `bootstrapping-glossary/SKILL.md`** — in the "For the charter" discovery bullet (~line 38):
```markdown
  The charter template's stack-specific slots use the keys in [../bootstrapping-claude-md/references/placeholder-keys.md](../bootstrapping-claude-md/references/placeholder-keys.md) — resolve them by the same hybrid rule (auto off disk only when unambiguous, else intake).
```

- [ ] **Step 5: Run the test, confirm it passes + links resolve**
```bash
grep -rc 'placeholder-keys.md' skills/foundation/bootstrapping-claude-md/SKILL.md skills/foundation/bootstrapping-claude-md/references/intake-questions.md skills/foundation/bootstrapping-glossary/SKILL.md  # each >=1
# link target resolves from bootstrapping-glossary:
test -f skills/foundation/bootstrapping-claude-md/references/placeholder-keys.md && echo "target OK"
```
Expected: each file `>= 1`; prints `target OK`.

- [ ] **Step 6: Commit**
```bash
git add skills/foundation/bootstrapping-claude-md/SKILL.md skills/foundation/bootstrapping-claude-md/references/intake-questions.md skills/foundation/bootstrapping-glossary/SKILL.md && git commit -m "feat(bootstrapping): document hybrid placeholder resolution + wire intake"
```

---

## Task 5: Add the inverse drift-check to both auditors (D4 + F2)

**Files:**
- Modify: `skills/foundation/auditing-claude-md/SKILL.md`
- Modify: `skills/foundation/auditing-glossary/SKILL.md`

**Interfaces:**
- Consumes: the auditor detection contract from Task 1.
- Produces: an auditor that flags a leftover `<key>` or a baked example-noun.

- [ ] **Step 1: Write the failing test (no inverse-check; bare normative package.json in auditing-claude-md)**
```bash
grep -rl 'placeholder-keys.md\|unresolved .*key\|example-noun' skills/foundation/auditing-claude-md/SKILL.md skills/foundation/auditing-glossary/SKILL.md || echo "RED: no inverse drift-check"
```
Expected: prints `RED: no inverse drift-check`.

- [ ] **Step 2: Add an inverse-check bullet to `auditing-claude-md/SKILL.md` Process step 2** (append to ~line 32):
```markdown
Also flag **placeholder-key drift**: against [../bootstrapping-claude-md/references/placeholder-keys.md](../bootstrapping-claude-md/references/placeholder-keys.md), a generated doc that still contains an unresolved `<key>` token, OR a registry example-noun sitting in a generator-owned slot (a command row, the stack line, the UI-exercise line), is drift. Cautionary prose naming a noun is NOT drift.
```

- [ ] **Step 3: F2 — rewrite the NORMATIVE bare-`package.json` references** in `auditing-claude-md/SKILL.md` to registry/manifest vocabulary; LEAVE the cautionary mention. Three normative edits:
```markdown
<!-- Process step 2 (~line 32) OLD: "`package.json`/Makefile/CI for commands" -->
<!-- NEW -->
the repo's manifest (per placeholder-keys.md — `package.json`/`Cargo.toml`/`go.mod`/…) / Makefile / CI for commands
<!-- Red Flags (~line 60) OLD: "verify against `package.json`, or it is unverified." -->
<!-- NEW -->
verify against the repo's manifest (package.json/Cargo.toml/go.mod/…)/Makefile/CI, or it is unverified.
<!-- Rationalizations row (~line 69) OLD: "Check each against `package.json`;" -->
<!-- NEW -->
Check each against the repo's manifest/Makefile/CI;
```
Leave line ~15 ("a command not in `package.json`") AS-IS — it is cautionary illustration.

- [ ] **Step 4: Add the same inverse-check to `auditing-glossary/SKILL.md`** (in its claims-checking process):
```markdown
Also flag **placeholder-key drift** against [../bootstrapping-claude-md/references/placeholder-keys.md](../bootstrapping-claude-md/references/placeholder-keys.md): an unresolved `<key>` token left in a generated glossary/charter, or a registry example-noun in a generator-owned slot, is drift; cautionary prose naming a noun is not.
```

- [ ] **Step 5: Behavioral RED/GREEN — dispatch a subagent auditor on two fixtures.** Give a fresh subagent the updated `auditing-claude-md` body + (a) a generated CLAUDE.md containing a leftover `<test-cmd>` and a baked `simulator` in the UI-exercise line, (b) a clean generated CLAUDE.md. Expected: it flags (a) on both signals, passes (b). Record the verdict (no `/tmp` file — the subagent returns pass/fail).
```bash
grep -rc 'placeholder-key drift\|placeholder-keys.md' skills/foundation/auditing-claude-md/SKILL.md skills/foundation/auditing-glossary/SKILL.md  # each >=1
grep -c 'not in `package.json`' skills/foundation/auditing-claude-md/SKILL.md  # cautionary line 15 STAYS: expect 1
grep -c 'verify against `package.json`' skills/foundation/auditing-claude-md/SKILL.md  # normative line 60 GONE: expect 0
```
Expected: each auditor `>= 1`; subagent flags fixture (a), passes (b).

- [ ] **Step 6: Commit**
```bash
git add skills/foundation/auditing-claude-md/SKILL.md skills/foundation/auditing-glossary/SKILL.md && git commit -m "feat(auditing): inverse placeholder-key drift-check + generalize package.json refs (D4,F2)"
```

---

## Task 6: Minor marker tweaks (F4 + F5)

**Files:**
- Modify: `skills/authoring/writing-rules/SKILL.md`
- Modify: `skills/apply-chain/writing-plans/SKILL.md`

**Interfaces:**
- Consumes: nothing (independent leak-marker tweaks).
- Produces: F4 illustrative marker; F5 generalized anti-pattern line.

- [ ] **Step 1: Write the failing test**
```bash
grep -n 'Example — an `api` domain' skills/authoring/writing-rules/SKILL.md   # F4: example present, no illustrative marker
grep -n 'Find the command in package.json' skills/apply-chain/writing-plans/SKILL.md  # F5: JS-specific anti-pattern line
echo "RED: F4 unmarked + F5 JS-specific"
```
Expected: both grep hits present, prints `RED:` line.

- [ ] **Step 2: F4 — mark the api-folder example illustrative** in `writing-rules/SKILL.md` (~line 60). Old → New:
```markdown
<!-- OLD -->
Example — an `api` domain:
<!-- NEW -->
Example (illustrative — your stack/paths may differ) — an `api` domain:
```

- [ ] **Step 3: F5 — generalize the anti-pattern line** in `writing-plans/SKILL.md` (~line 82). Old → New:
```markdown
<!-- OLD -->
- "Find the command in package.json" — look it up now and write the exact command.
<!-- NEW -->
- "Find the command in the repo's manifest/CI" — look it up now and write the exact command.
```

- [ ] **Step 4: Run the test, confirm it passes**
```bash
grep -c 'illustrative — your stack/paths may differ) — an `api` domain' skills/authoring/writing-rules/SKILL.md  # expect 1
grep -c 'Find the command in package.json' skills/apply-chain/writing-plans/SKILL.md  # expect 0
```
Expected: first `1`; second `0`.

- [ ] **Step 5: Commit**
```bash
git add skills/authoring/writing-rules/SKILL.md skills/apply-chain/writing-plans/SKILL.md && git commit -m "refactor(skills): mark api example illustrative + generalize manifest ref (F4,F5)"
```

---

## Task 7: Integration GREEN + validators + dogfood confirmation

**Files:**
- None (verification-only; the deliverable is the GREEN evidence).

**Interfaces:**
- Consumes: all prior tasks' outputs.
- Produces: the spec's GREEN-1/GREEN-2 evidence + a clean validator pass + the dogfood-sync confirmation.

- [ ] **Step 1: GREEN-1 — generated-output proof on a non-JS consumer.** Dispatch a fresh subagent: give it the fixed `root-claude-md-template.md` + `framework-charter-template.md` + `placeholder-keys.md` + the hybrid resolution rule, and a Rust consumer fixture (a `Cargo.toml` with `[package] name = "acme"`, no `[scripts]`, a `src/` dir). Ask it to emit the consumer's `CLAUDE.md` + `framework.md`.
Expected (GREEN): output has NO `package.json`, NO `simulator`; `<stack-manifest>` resolved to `Cargo.toml`; `<run-cmd>`/`<typecheck-cmd>` resolved to `cargo run`/`cargo check` only if unambiguous, else surfaced as intake; `<layers>`/`<ui-exercise-method>` raised as intake questions.

- [ ] **Step 2: GREEN-2 — intake key surfaces as a question.** From the Step-1 transcript, confirm the agent ASKED for `<layers>` / `<ui-exercise-method>` / `<product-and-platforms>` rather than inventing values. Record pass/fail.

- [ ] **Step 3: Run all validators across the 10 touched files**
```bash
FILES="skills/foundation/bootstrapping-claude-md/references/placeholder-keys.md skills/foundation/bootstrapping-claude-md/references/root-claude-md-template.md skills/foundation/bootstrapping-glossary/references/framework-charter-template.md skills/foundation/bootstrapping-claude-md/SKILL.md skills/foundation/bootstrapping-claude-md/references/intake-questions.md skills/foundation/bootstrapping-glossary/SKILL.md skills/foundation/auditing-claude-md/SKILL.md skills/foundation/auditing-glossary/SKILL.md skills/authoring/writing-rules/SKILL.md skills/apply-chain/writing-plans/SKILL.md"
for f in $FILES; do
  echo "$f fences=$(grep -c '^```' "$f")"   # each must be even
done
# reference links resolve (registry referenced from 5 files):
for f in $FILES; do grep -oE '\]\(([^)]+\.md)\)' "$f"; done | sort -u
```
Expected: every `fences=` even; every extracted `.md` link path resolves (manual confirm).

- [ ] **Step 4: dogfood-generator-sync confirmation (no instance edit needed)**
```bash
grep -n 'no `package.json`\|No application code, no `package.json`' CLAUDE.md .claude/rules/domains/framework.md
```
Expected: the vault's own instance docs already correctly state "no package.json" — confirms NO instance/generator mismatch; generator + auditor moved together this plan. Record as `[N/A] — instance already correct`.

- [ ] **Step 5: Commit (if any validator fix was needed; else nothing to commit)**
```bash
git status --short  # expect clean if Steps 1-4 needed no fix
```

---

## Notes for the executor

- Tasks 1→5 are dependency-ordered (registry first; auditors after the templates they check). Tasks 6 and 7 are independent of each other but 7 depends on 1–5.
- Every "test" here is a grep/validator or a subagent scenario — there is no `npm`/`cargo` to run in the vault itself. The Rust fixture in Task 7 lives only inside the subagent prompt, not on disk.
- If a subagent GREEN fails, do not patch the template silently — return to the failing task, fix the template/registry, and re-run the generated-output proof (dogfood-generator-sync step 3).
