# Domain Glossary Template

A glossary resolves what a **word** means in this app and who owns the concept. It is the source of truth for domain vocabulary. Fill every part from the real codebase — entities, paths, routes, and types are discovered, never invented.

## Template

```markdown
# <Area> Glossary — <the collision in one line, e.g. "Documents vs Documentation">

## When

Before touching any screen / route / API / model whose name contains
<term>, <term-in-other-languages>, …; anytime the user says "<term>" / "<native term>";
anytime you read or edit <owning-path-A>, <owning-path-B>, <owning-path-C>.
<!-- List EVERY ambiguous term in EVERY language the team uses, and EVERY owning path.
     This is the trigger that makes the agent stop and read — be exhaustive. -->

## Why

<The concrete confusion this prevents — ideally the real incident: "an edit button
pointed at domain B's screen", "an i18n block leaked from A into C". State the
source-of-truth principle: if a change contradicts this file, fix THIS file first,
then the code — never the other way around.>

## Implementation

Ownership table — memorise it, do not infer from filenames:

| # | Concept / domain | Owning module(s) | Route(s) / screen(s) | Type / enum | What it represents |
|---|---|---|---|---|---|
| 1 | <domain> | <api path> | <route> | <type> | <one line> |
| 2 | … | … | … | … | … |

Term-disambiguation rules — what each word maps to, and how to resolve the ambiguous ones:

- **"<generic term>"** — defaults to domain #N unless <context signal>, then #M. Never #K.
- **"<other-language term>"** — always domain #N.
- **"<genuinely ambiguous term>"** — resolve by context: under <X> → #1; under <Y> → #2.

What is NOT in any of these domains (must not be conflated): <neighbours that share a folder/word but are separate>.

## Edge Cases

- <stale route / removed symbol that still appears in old branches — map it to the right domain, never reintroduce>.
- <a field/enum that means different things per domain — check which scheme defines it>.

## Review Checklist

- Named the domain explicitly before touching any <term>-related symbol.
- All touched routes/types/i18n keys live inside ONE domain, not crossing.
- No reference to a removed/stale symbol.
```

## Notes

- The `## When` section is the load-bearing part: if it doesn't name the trigger words and paths, the glossary never loads at the moment of confusion.
- Every cell in the ownership table is a structural claim — it must match the code you read this session. A glossary cell that greps to nothing is a hallucination; `auditing-domain-rules` exists to catch exactly that.
