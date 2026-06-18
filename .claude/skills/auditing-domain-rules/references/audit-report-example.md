# Domain-Rules Audit Report — Filled Example

A concrete reference for the report shape. Plain text, produced before editing. Every status is backed by a grep/read run this session — not from memory.

```text
# Domain-Rules Audit — document-domains.md

## Claims checked
| Claim (doc says) | Code shows (grep/read) | Status |
| --- | --- | --- |
| path src/shared/api/documents/ | exists | Confirmed |
| path src/shared/api/organizations/document/ | exists | Confirmed |
| path src/shared/api/knowledge-base/ | exists | Confirmed |
| Routes.UPSERT_CERTIFICATE | exists | Confirmed |
| Routes.UPSERT_COMPANY_DOCUMENT | exists | Confirmed |
| Routes.UPSERT_DOCUMENT (knowledge-base row) | not found; real route is Routes.UPSERT_INSTRUCTION | Stale doc |
| ownership: "company docs never per-user" | code adds a per-user companyDoc.ownerId field | Code drift |
| enum TECH_DOC_TYPE = CERT/CHKL/MANL | matches knowledge-base.schemes.ts | Confirmed |
| i18n key documentation.document-types.* | greps to nothing | Hallucination |

## Summary
- Confirmed: 6
- Stale doc: 1 (UPSERT_DOCUMENT → UPSERT_INSTRUCTION)
- Code drift: 1 (per-user field on company docs contradicts the rule)
- Hallucination: 1 (documentation.document-types.* — never existed / removed)

## Decisions needed
- Code drift — company-doc ownerId: revert the code to honor "company docs are per-organisation, not per-user", OR change the rule to allow per-user ownership? (external-ish: affects the ownership model — pick deliberately)

## Planned edits (after decision)
- Stale doc: knowledge-base row route → Routes.UPSERT_INSTRUCTION.
- Hallucination: remove the documentation.document-types.* line.
- Code drift: apply only what is chosen above.
```

Note how each row names *what the code actually shows*, not just "wrong" — and how Code drift becomes a decision (revert code vs change rule), never a silent doc rewrite that blesses the divergence.
