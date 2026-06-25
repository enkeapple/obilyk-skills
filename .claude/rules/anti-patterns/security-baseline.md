---
description: 'Baseline for generated code: parameterize every query (never string-interpolate dynamic/user input into SQL/shell/NoSQL), keep secrets out of source (env/config/secret store, never literals), and validate + authorize input at every trust boundary. ~36-40% of AI-generated code carries at least one vulnerability; these three invariants are the always-on floor. Concrete checks are stack-specific and illustrative; the invariants are agnostic. Area-specific to code files.'
paths:
  - '**/*.{py,ts,tsx,js,jsx,mjs,cjs,go,rs,rb,java,kt,kts,php,cs,swift,scala}'
---

# Security Baseline for Generated Code

## When

STOP and apply the three invariants whenever you write code that: builds a query (SQL/NoSQL/shell), needs a credential/secret, or accepts input at a boundary (an API endpoint, a message handler, a CLI arg, a file/form upload). AI-generated code carries a vulnerability in roughly 36-40% of cases; this is the non-negotiable floor.

## Why

These are the highest-frequency, highest-impact classes an AI reproduces from its training data: injection (it learned string-built queries), leaked secrets (it inlines a key to "make it work"), and missing validation/authorization (the happy path assumes trusted input). Each is cheap to prevent at write time and expensive-to-catastrophic in production.

## Implementation

**Three invariants, always:**

1. **Parameterize — never interpolate.** Build queries with the driver's parameter binding / prepared statements / an ORM's safe API. Never concatenate or string-interpolate dynamic values into a query or shell command.
2. **No secrets in source.** Read credentials/keys/tokens from environment, config, or a secret manager. No secret literals committed to a source file — not even "temporarily".
3. **Validate and authorize at the boundary.** Validate the shape/type/range of incoming data before using it, and check authentication/authorization *before* performing the action — at every externally-reachable entry point.

```text
❌ WRONG — injection, hardcoded secret, no validation (illustrative — your stack may differ)
  cur.execute(f"SELECT * FROM users WHERE name = '{name}'")   # SQL string interpolation
  API_KEY = "sk-live-9f3c...本物"                              # secret literal in source
  def handler(req): return db.delete(req.json["id"])          # no validation, no authz

✅ CORRECT — parameterized, secret from env, validated + authorized (illustrative)
  cur.execute("SELECT * FROM users WHERE name = %s", (name,))  # bound parameter
  API_KEY = os.environ["API_KEY"]                             # from the environment
  def handler(req):
      data = DeleteSchema.parse(req.json)                     # validate shape
      require_can_delete(req.user, data.id)                   # authorize before acting
      return db.delete(data.id)
```

## Edge Cases

- **A non-secret constant is fine** — a public base URL or a feature flag is not a secret; the rule targets credentials/keys/tokens.
- **Internal/trusted callers still validate at the public boundary** — "it's only called internally" is how missing-validation ships; validate where untrusted input can reach.
- **Defer the deep audit, not the baseline** — where the repo has a security review / SAST / a security-review skill, this rule is the always-on floor that complements it, not a replacement. (See also a `security-review` pass — not required to apply this rule.)

## Review Checklist

- [ ] No query/shell command built by string concatenation or interpolation of dynamic input (grep: f-string/`+`/template literals into `execute(`/`query(`/`exec(`).
- [ ] No secret literal in source (grep for key-shaped strings, `password =`, `token =`, `api_key =`); credentials come from env/config/secret store.
- [ ] Every externally-reachable entry point validates input shape AND checks authorization before acting.
- [ ] Concrete checks were applied in the project's actual stack (parameter style, secret store, validator) — the invariants, not the illustrative snippets.
