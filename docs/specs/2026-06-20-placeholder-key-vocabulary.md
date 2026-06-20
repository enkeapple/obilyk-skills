# Placeholder-key vocabulary + generator resolution

## Goal

Give the vault one canonical placeholder-key registry for stack-specific nouns, parameterize the generator templates to it, teach the `bootstrapping-*` generators to resolve each key per consumer repo (auto off disk or intake question), and add an inverse drift-check to the `auditing-*` skills so a leaked baked noun or an unresolved key is caught.

## Scope

- A self-contained copy of the registry `references/placeholder-keys.md` in EACH of the 4 generator/auditor skills (`bootstrapping-claude-md`, `bootstrapping-glossary`, `auditing-claude-md`, `auditing-glossary`): a 5-column table (`key → meaning → auto|intake(+fallback) → resolution-source → example-nouns`) covering the 12 keys, plus the resolution rule and the auditor detection contract. Each skill self-links its OWN copy — no shared file, no cross-skill link (Decision 2a, revised: each skill must stay droppable/self-contained).
- Parameterize the two generator templates to the registry keys (F1, F3).
- Document the HYBRID resolution behavior in `bootstrapping-claude-md/SKILL.md` and map intake-tagged keys in `intake-questions.md`; each skill links its own registry copy.
- Add the inverse drift-check to `auditing-claude-md` (also fixing F2) and `auditing-glossary`.
- Two discrete minor marker tasks: F4 (`writing-rules` api-folder example) and F5 (`writing-plans` anti-pattern line).

## Out of scope

- The marked-illustrative examples that legitimately show concrete stack code — `writing-plans` plan-template filled npm example, `spec-drift-audit` report-example, `codebase-design` TypeScript example — are LEFT AS-IS (sanctioned by `agnostic-skill-authoring` move 3). Not parameterized.
- Editing the vault's OWN instance docs (root `CLAUDE.md`, `framework.md`): they already correctly state "no package.json" — there is no instance/generator mismatch to fix (per `dogfood-generator-sync`).
- Monorepo / multi-manifest resolution beyond a single intake question "which manifest is primary" (YAGNI).
- Any change to `skills-routing.json` (no skill renamed/created/retriggered — only a new `references/*.md`, which is not a routing entry).
- A machine/automated resolver: resolution is the generator agent following the documented rule, not new tooling.
- A SHARED registry — in `.claude/rules/` OR in one skill's `references/` cross-linked by the others — is rejected: rules/other-skills may be absent in a drop-target, and a skill must stay a self-contained methodology. The registry is duplicated into each of the 4 skills and kept in sync; the `auditing-*` skills + `dogfood-generator-sync` catch drift between copies.

## Contracts

The registry table is the core contract (the new file's body). Concrete cells:

```text
| key                   | meaning                                  | auto|intake (+fallback)                                              | resolution-source        | example-nouns (illustrative, non-exhaustive)            |
| run-cmd               | run/start app in dev                     | auto iff a literally-named run/dev/start script; else intake        | manifest scripts          | npm run dev, pnpm dev, cargo run, go run, make run      |
| typecheck-cmd         | type/compile check                       | auto iff literally-named script; else intake                        | manifest scripts          | tsc, npm run typecheck, cargo check, mypy, go build     |
| lint-cmd              | lint                                     | auto iff literally-named script; else intake                        | manifest scripts          | eslint, npm run lint, cargo clippy, ruff, golangci-lint |
| format-cmd            | format / autofix                         | auto iff literally-named script; else intake                        | manifest scripts          | prettier, cargo fmt, gofmt, ruff format                 |
| test-cmd              | run tests                                | auto iff literally-named test script; else intake "is there a suite?" → none → emit the existing "no suite" sentence | manifest scripts | npm test, vitest, jest, cargo test, pytest, go test |
| build-deploy-cmd      | build / native install / deploy          | auto iff literally-named script; else intake                        | manifest scripts          | npm run build, cargo build --release, docker build      |
| stack-manifest        | the stack/dependency manifest file       | auto (the file exists on disk)                                      | filesystem                | package.json, Cargo.toml, go.mod, pom.xml, pyproject.toml |
| source-root           | primary source directory                 | auto iff one conventional root present; else intake                 | filesystem                | src/, app/, lib/, internal/, pkg/                       |
| layers                | architectural layers (Impl. Protocol)    | intake                                                              | human                     | screen→hook→api→store, handler→service→repo             |
| ui-exercise-method    | how UI changes are exercised             | intake                                                              | human                     | simulator, browser, emulator, (none — backend)          |
| project-name          | project / product name                   | auto (manifest name field or repo dir)                              | manifest name / dir       | (the repo's name)                                       |
| product-and-platforms | one-line product + platforms             | intake                                                              | human                     | iOS/Android app, web SPA, CLI tool, backend service     |
```

Resolution rule (HYBRID, documented in the registry + `bootstrapping-claude-md/SKILL.md`):

```text
auto ONLY when exactly one disk fact maps to the key with no judgment.
"literally-named script" = an EXACT key match in the manifest's script map
(a `test` key, not `test:unit`); a fuzzy/partial match is judgment → INTAKE.
Any of: (a) manifest exists but the exactly-named script is absent, (b) multiple
manifests present, (c) two plausible scripts → INTAKE. Never silently infer.
test-cmd is the only key with a "no suite" branch, and that branch is human-confirmed.
```

Auditor detection contract (added to both `auditing-*` skills):

```text
Flag drift on EITHER falsifiable signal in a generated doc:
  (1) an unresolved <key> token from the registry remains; OR
  (2) a registry example-noun appears in a generator-owned slot
      (a command row / a stack line / a UI-exercise line).
example-nouns is an illustrative signal, not a whitelist; signal (1) is the
exhaustive backstop. This also replaces auditing-claude-md's bare "package.json"
references with the manifest/registry vocabulary (F2).
```

## Files touched

| File | Change | Why |
|------|--------|-----|
| `skills/foundation/bootstrapping-claude-md/references/placeholder-keys.md` | NEW | registry copy (5-col table + resolution rule + auditor contract) — self-contained |
| `skills/foundation/bootstrapping-glossary/references/placeholder-keys.md` | NEW | registry copy (identical) — self-contained |
| `skills/foundation/auditing-claude-md/references/placeholder-keys.md` | NEW | registry copy (identical) — self-contained |
| `skills/foundation/auditing-glossary/references/placeholder-keys.md` | NEW | registry copy (identical) — self-contained |
| `skills/foundation/bootstrapping-claude-md/references/root-claude-md-template.md` | EDIT | F1: `[package.json](./package.json)` → `<stack-manifest>`; command rows use canonical cmd keys |
| `skills/foundation/bootstrapping-glossary/references/framework-charter-template.md` | EDIT | F3: `simulator/browser` → `<ui-exercise-method>`; verification command lines use canonical keys |
| `skills/foundation/bootstrapping-claude-md/SKILL.md` | EDIT | document HYBRID resolution + link its OWN registry copy |
| `skills/foundation/bootstrapping-claude-md/references/intake-questions.md` | EDIT | map intake-tagged keys to must-ask/confirm questions; link the sibling registry copy |
| `skills/foundation/bootstrapping-glossary/SKILL.md` | EDIT | self-link its OWN registry copy from the charter discovery section |
| `skills/foundation/auditing-claude-md/SKILL.md` | EDIT | F2: rewrite the NORMATIVE bare-`package.json` references (Process step "verify against `package.json`", the rationalization row, the checklist row) to registry/manifest vocabulary (`the repo's manifest per placeholder-keys.md / Makefile / CI`); LEAVE the cautionary-prose mention (a command "not in `package.json`") as an illustrative example — the inverse check must not flag cautionary mentions. + add the inverse drift-check (unresolved key / baked example-noun) self-linking its OWN registry copy |
| `skills/foundation/auditing-glossary/SKILL.md` | EDIT | inverse drift-check self-linking its OWN registry copy |
| `skills/authoring/writing-rules/SKILL.md` | EDIT | F4: mark the `api`-folder example illustrative |
| `skills/apply-chain/writing-plans/SKILL.md` | EDIT | F5: generalize the "Find the command in package.json" anti-pattern line |

## Edge cases

- Empty: manifest has zero scripts → all six `*-cmd` keys → intake.
- Ambiguous: multiple manifests, or two plausible scripts for one key → intake (no silent pick); single intake question "which is primary".
- `test-cmd` with no test script → human-confirmed "no suite" sentence (the existing template line), never a fabricated command.
- Non-JS consumer: `stack-manifest` resolves to whichever manifest is on disk (Cargo.toml/go.mod/…); `*-cmd` from its scripts/targets; a Makefile-only repo with no script map → cmd keys → intake.
- Loading / in-flight: N/A — generation is a one-shot doc emission, no runtime state.

## Verification

Vault verification = skill validators + RED/GREEN subagent runs on GENERATED output. There is no build/test pipeline.

- Validators on every created/edited file: frontmatter ≤1024, `name` regex, every `references/*.md` link resolves, fences balanced, word count sane.
- GREEN-1: a subagent following the fixed templates against a Rust consumer fixture emits a `CLAUDE.md`/`framework.md` with NO baked `package.json`/`simulator` — keys resolved to the consumer's real nouns or left as intake questions.
- GREEN-2: a key tagged `intake` (e.g. `layers`, `ui-exercise-method`) surfaces as a question, not silently inferred.
- Auditor RED/GREEN: a generated doc with a leftover `<key>` OR a baked example-noun is flagged by each `auditing-*` skill; a clean doc is not.
- `dogfood-generator-sync` check: confirm the vault's own instance docs are already correct (no instance edit needed) — generator + auditor moved in the same change.

## Risks

- `example-nouns` can never be exhaustive — mitigation: it is an illustrative signal only; the unresolved-`<key>` check (signal 1) is the exhaustive, falsifiable backstop. Document it as non-whitelist.
- Over-parameterizing could hurt template legibility — mitigation: Decision 3 keeps marked-illustrative examples concrete; only generator-owned slots are keyed.
- "auto" could silently write a wrong inferred command — mitigation: R2 forces intake on any ambiguity; GREEN-2 guards the intake path.
- `auditing-claude-md` is also applied to the vault's own (intentionally JS-free) docs — mitigation: the inverse check keys off the registry nouns in *generator-owned slots*, and the vault docs name those nouns only in cautionary prose, which `agnostic-skill-authoring:38` already exempts; the check must not flag cautionary mentions.
