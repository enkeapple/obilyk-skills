# Document Domains Glossary

## When

STOP and read this before touching anything involving "document" / «документ». Triggers:

- The word **document / documents** or **документ / документы** appears in a task, ticket, or UI string — it is ambiguous and maps to THREE different domains.
- **сертификат, паспорт, медкнижка / certificate, passport, medical** (seafarer's personal papers).
- **knowledge base, instruction, manual, regulation, SOP / база знаний, инструкция, регламент** — and the UI labels **Community** and **Instructions**.
- You edit, route to, or add an edit/view button for any path:
  - `src/shared/api/documents/`
  - `src/shared/api/organizations/document/`
  - `src/shared/api/knowledge-base/`

## Why

"Document" is overloaded across three unrelated domains with three owners. Confusing them ships data to the wrong screen: an **edit button once pointed at the wrong screen** because someone wired a seafarer-document action to an organization-document (or knowledge-base) route. Because the team works in **English and Russian**, the same concept arrives under two words — both must resolve here.

Source-of-truth principle: if code and this glossary disagree, **fix the glossary first**, then the code. Do not invent entities or naming not present in the repo.

## Implementation

Ownership table:

| Concept | Owning path | What it represents |
|---|---|---|
| Seafarer document | `src/shared/api/documents/` | A seafarer's PERSONAL papers: certificates, passports, medical records. |
| Organization document | `src/shared/api/organizations/document/` | Documents OWNED BY a company/organization. |
| Knowledge-base document | `src/shared/api/knowledge-base/` | Manuals, regulations, SOPs. Surfaced in UI under **Community / Instructions**. |

Term disambiguation (resolve by context):

- "my document / certificate / passport / medical", «мой документ / сертификат / паспорт / медкнижка», anything about a person → **Seafarer document** (`documents/`).
- "company / org document", «документ организации / компании» → **Organization document** (`organizations/document/`).
- "manual / regulation / SOP / instruction", «инструкция / регламент», or shown under Community/Instructions → **Knowledge-base document** (`knowledge-base/`).
- Bare "document" with no context → DO NOT GUESS. Confirm which of the three before routing or wiring a button.

What is NOT in these domains: any non-document feature (auth, vessels, messaging, etc.) — they don't own "document" and must not be routed here.

## Edge Cases

- An org may store a seafarer's papers — ownership still decides: personal-to-the-seafarer → `documents/`; held-by-the-company → `organizations/document/`.
- A regulation attached to a person is still a Knowledge-base doc, not a Seafarer document.
- Russian label and English label of the same screen must point to the same domain.

## Review Checklist

- [ ] Every "document" / «документ» reference resolved to exactly one of the three paths.
- [ ] Edit/view buttons route to the SAME domain the data came from (the incident).
- [ ] Knowledge-base items go through Community/Instructions, not a document screen.
- [ ] Both EN and RU terms map to the same domain.
- [ ] No new entity or path invented; matches code read.
