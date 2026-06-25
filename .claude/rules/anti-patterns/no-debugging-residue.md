---
description: 'After a change works, leave exactly one version of what you built — delete superseded files, abandoned retry attempts, and shadow copies (auth_v2, auth_new, *.bak, large commented-out dead blocks). AI works forward in a try-fail-retry loop and never cleans up the discarded attempts. Area-specific to code files. Pure-hygiene policy: no single-shot RED target (residue accrues across turns), so its efficacy test is deliberately skipped.'
paths:
  - '**/*.{py,ts,tsx,js,jsx,mjs,cjs,go,rs,rb,java,kt,kts,php,cs,swift,scala}'
---

# No Debugging Residue

## When

STOP and clean up before declaring a change done — especially after a try-fail-retry loop or several attempts at the same file. AI works forward: it writes `attempt 2` in a new file and never deletes `attempt 1`.

## Why

The agent's loop produces discarded attempts (`auth_v2.py`, `auth_new.py`, a `.bak`, a half-rewritten copy) and leaves them in the tree. The result is a directory where a reader cannot tell which file is live, imports point at the wrong copy, and the next change is built on a dead branch. One change should leave one implementation.

## Implementation

**Before calling the change done, ensure the repo holds exactly one version of what you built.**

- Delete files your iterations orphaned — shadow copies (`<name>_v2`, `<name>_new`, `<name>_old`, `<name>.bak`, `<name>.copy`) and any abandoned attempt superseded by the final one.
- Remove large commented-out dead blocks left "just in case" — version control already keeps the old code.
- Confirm the live file is the one actually imported/wired; no dead duplicate is left shadowing it.

```text
❌ WRONG — three attempts left in the tree (illustrative — your stack may differ)
  src/auth.py        # original
  src/auth_v2.py     # second attempt
  src/auth_new.py    # the one that finally worked
  → reader/imports cannot tell which is live; two are dead residue

✅ CORRECT — one version of the thing you built (illustrative)
  src/auth.py        # the working implementation; v2/new attempts deleted
```

## Edge Cases

- **Intentional versioned artifacts are NOT residue** — a deliberately co-existing `api/v1` and `api/v2`, or a migration shim kept on purpose, are real code, not leftovers. The rule targets *abandoned* copies, not deliberate versioning.
- **When NOT to apply** — a genuine backup/fixture the task requires; say so rather than deleting it.
- **No silent deletion of someone else's file** — only remove the orphans *your* change created; an unrelated stray file you did not create is flagged, not deleted.

## Review Checklist

- [ ] No shadow/abandoned copies left from this change (grep the touched dirs for `_v2`, `_new`, `_old`, `.bak`, `.copy`, `.orig`).
- [ ] No large commented-out dead blocks left behind — old code lives in version control, not in comments.
- [ ] The live file is the one actually imported/wired; no dead duplicate shadows it.
- [ ] Any retained backup/versioned file is deliberate and stated, not leftover residue.
