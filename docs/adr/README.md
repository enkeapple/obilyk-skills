# Architecture Decision Records

Immutable records of architectural decisions for this vault. Each ADR captures one decision that is **hard to reverse**, **surprising without context**, and a **genuine trade-off**. A decision never changes in place — it is **superseded** by a new ADR (the old one keeps its body, only its status line flips). Author and audit ADRs with the `writing-adrs` skill.

Convention (established with ADR-0001, since the repo had no prior ADRs): `docs/adr/NNNN-kebab-title.md`, zero-padded 4-digit sequential numbers, status vocabulary `Accepted` / `Superseded by ADR-MMM` / `Deprecated`. Template: [writing-adrs `adr-template.md`].

## Index

### Guardrails / hooks

- [ADR-0001 — Share the guardrail-hook session/state preamble via a sourced lib](0001-shared-hook-preamble-lib.md)
