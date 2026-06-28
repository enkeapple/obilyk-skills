# Behavioral Baseline — the default coding-conduct set

The **behavioral baseline** is the small, stack-agnostic set of conduct principles a CLAUDE.md can declare so every change is shaped the same way — independent of the project's language, framework, or commands. It is **opt-in**: a repo adopts it (or a variant, or none) at intake. When adopted, it lives as one named section in the operating manual (`.claude/CLAUDE.md`), and `auditing-claude-md` checks that section against this set (its "missing/incomplete behavioral baseline" drift class).

This file is the **single canonical source** of the default set. `bootstrapping-claude-md` seeds the section from here; `auditing-claude-md` names these principles when it verifies an adopted baseline. The default set below is adapted from the public "CLAUDE.md behavioral guidelines" (Karpathy / multica-ai) — a consumer repo MAY replace, trim, or extend it, but a declared baseline must name each principle it claims to follow.

## The default four principles

| # | Principle | What it means | Verifiable signal it is being followed |
| --- | --- | --- | --- |
| 1 | **Think Before Coding** | Surface assumptions and tradeoffs before implementing; when multiple interpretations exist, present them; when unclear, stop and ask. | Clarifying questions arrive *before* implementation, not after a wrong build. |
| 2 | **Simplicity First** | Write the minimum code that solves the stated problem — no speculative features, abstractions for single-use code, or unrequested configurability. | A reviewer would not call the change overcomplicated; no feature beyond what was asked. |
| 3 | **Surgical Changes** | Touch only what the request needs; match existing style; don't refactor what isn't broken; remove only the orphans your own change created. | Every changed line traces directly to the request; diffs carry no drive-by edits. |
| 4 | **Goal-Driven Execution** | Turn the task into a verifiable success criterion before starting and loop until it is met (e.g. "write a test that reproduces the bug, then make it pass"). | Each task states a check; "done" is asserted against that check, not a vague "it works". |

## How a repo declares it

- **Adopt the default set** — emit the section verbatim from the table above (the recommended default).
- **Adopt a variant** — keep the section but replace/trim/extend the principles; each listed principle still needs a name + one-line meaning so the audit can verify presence.
- **Decline** — the repo names no behavioral baseline; the section is absent by choice. The audit's baseline drift class then does **not** fire (it only governs a repo that opted in).

## Why opt-in, not always-on

Injecting unrequested conduct rules into a repo that never asked for them is itself a violation of the "Simplicity First" principle — content beyond what was requested. The baseline is therefore checked only where the repo has *declared* it: bootstrapped with it, or the section already present. A repo with no declared baseline owes no baseline section, exactly as a non-chain repo owes no design-docs line.
