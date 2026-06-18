# Rule Template

Copy this and fill the sections — the order is conventional, not a gate. `description` is required; `paths` is **optional** (include it to scope an area-specific rule, omit it for an always-on rule). Match the repo's existing frontmatter keys/folder layout if it has a convention.

## Template

```markdown
---
description: '<one line: what this rule enforces + its key points>'
# paths — optional: include to scope an area-specific rule; omit entirely for an always-on rule
paths:
  - '<glob the rule applies to, e.g. **/*.{ts,tsx}>'
---

# <Topic> Rules

## When

<One or two sentences: the situation in which an agent must apply this.>

## Implementation

<The actual instructions — imperative, with a real ✅/❌ code pair.>

```ts
// ❌ WRONG — what not to do
// ✅ CORRECT — what to do instead
```

- <imperative bullet: "Before X, always Y.">
- <imperative bullet: "X is forbidden; use Y instead, because Z.">

## Edge Cases

- <gotcha>
- When NOT to apply: <the legitimate case where this rule does not fire>.

## Review Checklist

- <a grep-able or quick check that confirms compliance>
- <another check>
```

## Filled example

A concrete rule at the level of detail expected. Note the scoped `paths`, the `## When`, the ✅/❌ pair, the explicit exception, and the checklist.

```markdown
---
description: 'Import workspace packages only from their public barrel; deep subpath imports are forbidden. Missing export → add it to the barrel.'
paths:
  - '**/*.{ts,tsx}'
---

# Package Import Rules

## When

Importing anything from an internal workspace package (an `@`-aliased package such as `@ui`, `@core`, `@api`).

## Implementation

Import ONLY from the package's public barrel — never a path beneath it.

```ts
// ❌ WRONG — reaches into internals, couples to file layout
import { Button } from '@ui/components/Button/Button';

// ✅ CORRECT — public barrel only
import { Button } from '@ui';
```

- If a symbol you need is not exported from the barrel, **add it to the barrel** (`index.ts`) and import from there — do not deep-import to get at it.
- If exposing it seems wrong, flag it rather than bypassing the barrel.

## Edge Cases

- When NOT to apply: a package that intentionally ships documented subpath entry points via its `exports` map (e.g. `@ui/styles`) — those subpaths are public API. Raw source paths are not.
- Third-party packages follow their own documented entry points.

## Review Checklist

- No import matches `from '@<pkg>/...'` with a subpath (grep: `rg "from '@[a-z]+/"`).
- Any newly needed symbol was added to the barrel, not deep-imported.
```
