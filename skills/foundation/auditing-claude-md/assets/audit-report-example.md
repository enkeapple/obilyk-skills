# CLAUDE.md Audit Report — Filled Example

A concrete reference for the report shape. Produced before editing. Every status is backed by a grep/read this session (package.json, the filesystem, the skill registry) — not from memory.

```text
# CLAUDE.md Audit

## Claims checked
| Claim | File | Repo shows | Status |
| --- | --- | --- | --- |
| cmd `pnpm ios` | root | package.json scripts.ios exists | Confirmed |
| cmd `pnpm typescript` | root + checklist | exists | Confirmed |
| cmd `pnpm test` | root + checklist | no `test` script in package.json | Broken |
| stack "Reanimated v3" | root | lockfile pins reanimated@4.x | Stale doc |
| path .claude/rules/common/ | root | exists | Confirmed |
| path .claude/rules/forms/ | root | folder does not exist | Broken |
| routed skill `scaffold-api` | root routing | exists in skill registry | Confirmed |
| rule "no console.* in prod" | manual | code added 3 console.log in prod paths | Code drift |

## Cross-file consistency
- Pipeline: root says "EXPLORE → PLAN → CODE → VERIFY"; manual says "grill → spec → plan → build → verify" — MISMATCH. Consolidate to the manual's vocabulary; root points to it.
- Role: root (none) / manual "senior engineer" — but intended position is Principal Mobile Dev — Stale doc.
- Commands: the `pnpm test` row appears in both — fix in both.

## Summary
- Confirmed: 4
- Stale doc: 2 (Reanimated version, Role)
- Broken: 2 (`pnpm test`, rules/forms/ path)
- Code drift: 1 (console.* in prod contradicts the rule)
- Inconsistent: 1 (pipeline vocabulary across the two files)

## Decisions needed
- Code drift — console.* in prod: revert the logging to honor the rule, OR change the rule? (recommend revert)
- Pipeline mismatch: confirm the manual's 5-stage vocabulary is the source of truth (root becomes a pointer).

## Planned edits (after decisions)
- Broken: drop `pnpm test` rows (or add the script); remove the rules/forms/ pointer.
- Stale: Reanimated v3 → v4; Role → Principal Mobile Dev.
- Inconsistent: root pipeline line → points to the manual's pipeline.
- Code drift: apply only what is chosen.
```

Note how a command/path is checked against the repo (not eyeballed), the two files are reconciled to one source, and Code drift becomes a decision — never a silent doc rewrite that blesses the divergence.
