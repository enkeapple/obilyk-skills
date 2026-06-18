# Spec Template

One canonical template. Copy it, fill every section, keep the order — the order *is* the recipe. Never delete a section; if something is cut, it becomes an Out-of-scope bullet, not a missing heading.

Language- and framework-agnostic. Replace `<lang>` with the project's language and quote *actual* code, not pseudocode.

## Template

```markdown
# <Topic>

## Goal
<One or two sentences. What changes for the user / the codebase. No "and also".>

## Scope
- <what is in>

## Out of scope
- <what looks related but is NOT in — be explicit; this is where churn comes from>

## Contracts
```<lang>
// Actual types / signatures / request+response shapes / state shape.
// Reuse existing types? Link the file with line numbers instead of copying.
```

## Files touched
| File | Change | Why |
|------|--------|-----|
| path/to/file | NEW / EDIT / DELETE | one line |

## Edge cases
- Empty: <behavior>
- Error: <behavior>
- Loading / in-flight: <behavior>

## Verification
- `<real typecheck / lint / test / build command from this repo>`
- Manual: <steps a human runs to confirm>

## Risks
- <known unknown> — mitigation: <how it is handled / confirmed>
```

## Variants (same template, two extra notes)

Don't restructure the template for these — just add to the sections you already have:

- **Refactor / changing a public interface:** in **Contracts**, write the shape *before → after*. Add a **Callers** subsection under Files touched listing every dependent and whether it needs updating.
- **Continuing a half-finished feature (retroactive):** add a **Current state** subsection at the very top (what exists, what is stubbed/broken, what actually runs today — from running it, not from the handoff claim). Title the spec `<Topic> (retroactive)`. Everything else is unchanged.

## Filled example

A neutral reference for the level of detail expected.

```markdown
# Export items list to CSV

## Goal
Let a user download the current items list as a CSV file from the list screen.

## Scope
- A "Export CSV" action on the items list.
- Server endpoint that streams the user's items as CSV.

## Out of scope
- Column selection / custom field ordering.
- Export formats other than CSV (XLSX, JSON).
- Scheduled / emailed exports.

## Contracts
```<lang>
// GET /items/export -> text/csv
// Columns, in order: id, name, status, createdAt
// One header row, then one row per item. Empty list -> header row only.
```

## Files touched
| File | Change | Why |
|------|--------|-----|
| api/items/export | NEW | endpoint that produces the CSV |
| api/items/csv | NEW | row serialization + escaping |
| ui/ItemsList | EDIT | add the "Export CSV" action |

## Edge cases
- Empty: header row only, no error.
- Error (export fails mid-stream): surface a failure message; do not download a truncated file silently.
- Loading: disable the action and show progress while the export is in flight.
- Field contains a comma / quote / newline: quote and escape per CSV rules.

## Verification
- `<typecheck command>` and `<test command for the items module>`
- Manual: open the list, click Export CSV, confirm the file opens with correct columns and row count.

## Risks
- Very large lists could time out or exhaust memory — mitigation: stream rows instead of buffering the whole file.
```
