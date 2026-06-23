---
description: 'Before treating a search "0 results" as evidence of absence, confirm the search itself could reach the target — right grep flavor (macOS -E, not BRE \|), no depth limit hiding deeper paths, no --include allowlist omitting file types. A scoped or syntactically-broken search returns a false-clean 0. Always-on; triggered by any grep/find used as verification, not by a file type.'
---

# Search Scope Verification

## When

STOP and apply this whenever you run a `grep`, `find`, or equivalent search and report its "0 matches" / "not found" as a **verified fact** — especially:

- orphan-ref / dead-link sweeps and "file X is not referenced anywhere" claims;
- "no persisted Y exists" claims;
- pre-deletion / pre-rename reference checks.

Do NOT skip the check because the search "looks complete" — the three recurring failures below all looked complete.

## Why

A scoped or syntactically-broken search that returns 0 is indistinguishable from a correct 0 — until a downstream break proves it wrong. The recurring false-clean modes in this vault:

- **BRE alternation** — `grep -c "a\|b"` on macOS/BSD grep treats `\|` as a literal pipe, not alternation; the pattern never matches → phantom "absent" reported as verified.
- **Depth-limited find** — `find . -maxdepth N` structurally cannot reach a target one level deeper; "not found" is a scope artifact, not absence.
- **Extension allowlist** — `grep --include='*.md' --include='*.json'` never searches `.yml`, `.github/`, `scripts/`, `Makefile`; a reference in CI/workflow config is invisible to the sweep.

## Implementation

Before asserting "0 results = absent / no references / clean":

1. **Confirm the grep flavor supports the pattern.** On macOS use `grep -E` for alternation (`a|b`); never `\|` in BRE. Sanity-test the pattern against a file you KNOW contains the target and confirm it matches.
2. **Confirm the search reaches where the target would live.** For `find`, drop `-maxdepth` or set it past the known depth of a real instance. For `grep`, use `-r` without `--include` for a reference check, or explicitly confirm every file type/directory the target could appear in is covered.
3. **For a reference/orphan sweep after delete/rename, search the WHOLE repo, not an enumerated extension set.** Include `.github/workflows/`, `*.yml`/`*.yaml`, `scripts/`, `Makefile` — exactly what an `--include` allowlist silently omits.
4. **A "0 results" that contradicts a plausible expectation is a red flag.** Widen (drop the limiter / fix the flavor flag), re-run, confirm. Absence is established only after the *widened* search also returns 0.

```text
# ❌ WRONG — three false-clean patterns
grep -c "tightening-prose\|prose" CLAUDE.md          # BRE: \| is literal, never matches
find skills/personal -maxdepth 2 -type f             # depth 2 cannot reach depth-3 targets
grep -r "old-file.json" . --include="*.md" \
  --include="*.json" --include="*.sh"                # .github/workflows/*.yml never searched

# ✅ CORRECT — confirmed-scope equivalents
grep -cE "tightening-prose|prose" CLAUDE.md          # -E: | is alternation
find skills/personal -type f                          # no depth limit
grep -r "old-file.json" .                             # whole repo, no extension filter
```

## Edge Cases

- An `--include` allowlist or `find -maxdepth` is fine when you can enumerate every type/depth the target could appear in AND confirm all are covered. In doubt, drop the limiter.
- **When NOT to apply** — a quick exploratory search that is not reported as a verified claim; this rule governs only searches used as *evidence of absence*.
- It does not demand infinite-depth searches for every lookup — only for the ones that back an absence/clean assertion.

## Review Checklist

- [ ] Any "0 results" reported as verified was re-run with confirmed scope (flavor flag, no depth limit, no extension allowlist) before asserting absence.
- [ ] `grep` alternation uses `-E`, never BRE `\|` on macOS.
- [ ] A reference/orphan sweep after delete/rename included `.github/`, `*.yml`, `scripts/`, `Makefile` — confirmed, not assumed.
- [ ] A surprising "0 results" was widened before being reported.
