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

Cautionary prose that names a noun (e.g. "a command not in `package.json`") is NOT drift — a
cautionary mention is not a generated slot; do not flag it.
