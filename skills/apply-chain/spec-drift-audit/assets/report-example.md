# Drift Report — Filled Example

A concrete reference for the report format and the level of detail expected. Plain text, no edits to code. Replace commands/paths/types with the real ones from your repo.

```text
# Spec Drift Audit — pagination.md

## Verification
- `npm run typecheck` → FAIL: ItemsList.tsx:14 Property 'nextCursor' does not exist on type '{ items: Item[]; cursor: string | null; hasMore: boolean }'.

## Files touched
| File | Spec said | Code shows | Status |
| --- | --- | --- | --- |
| api/items.ts | EDIT — add cursor param, return nextCursor | EDIT happened; return shape differs; extra sort param + sortItems() added | SILENT EXPANSION |
| ui/ItemsList.tsx | EDIT — add Load more button | No Load more button; Row now renders an Avatar | MISSED + SILENT EXPANSION |

## Contract drift
- `listItems` return: spec `{ items, nextCursor: string | null }` → code `{ items, cursor, hasMore }`.
  - `nextCursor` renamed to `cursor` — schema drift, external interface (callers read it). CRITICAL.
  - `hasMore` added — schema drift, external interface. FLAG.
- `listItems` signature: spec `(cursor?)` → code `(cursor?, sort?)`. Extra `sort?` param — silent expansion.

## Out-of-scope check
- "Filtering or sorting the list" — VIOLATED. `sort` param + `sortItems()` found in api/items.ts. Silent expansion.
- "Changing how a list item is rendered" — VIOLATED. `<Avatar>` added to Row in ui/ItemsList.tsx. Silent expansion.

## Summary
- 1 missed scope (Load more button)
- 3 silent expansions (sort param, sortItems(), Avatar in Row)
- 2 external-interface schema drifts (nextCursor→cursor, hasMore)
- Verification: FAILING (typecheck)

## Recommended disposition
- Load more button (missed scope): Fix code — implement per spec.
- sort param + sortItems() (silent expansion, out of scope): Fix code — remove.
- Avatar in Row (silent expansion): Fix code — remove.
- nextCursor→cursor + hasMore (schema drift, external): Fix code — revert to spec contract.

## Decision
Presented as one batched picker (interactive-gates archetype C-drift):
- Apply recommended → apply all four dispositions above.
- Adjust per-finding → walk the four findings one by one.
- Stop → take no action now.
```
