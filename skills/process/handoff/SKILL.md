---
name: handoff
description: >-
  Use when a task crosses the plan-file threshold (shared API contract / slice
  shape / navigation route / >2 features) and its plan must be persisted to
  disk, OR when a turn ends incomplete or the context window nears its limit
  and work must resume in a fresh session. Triggers: handoff, save the plan,
  persist plan, plan file, context limit, running out of context, compact,
  resume in a new session, hand off, передать сессию.
argument-hint: "What will the next session focus on?"
---

# Handoff — Session Temp Documents

## Overview

This skill owns creation of the session's temporary documents. Rules invoke it instead of writing `/tmp/...` by hand, so temp-file creation is consistent and a fresh agent can always resume. **All files go to the OS temp directory (`$TMPDIR`), never the workspace.**

There are **two distinct documents** — do not merge them:

| Doc | Captures | Written when | Lifecycle |
| --- | --- | --- | --- |
| **Plan** (`plan-<slug>.md`) | the *contract*: goal, affected layers, contracts, out-of-scope | plan-file threshold met, after user approval | deleted after VERIFY + Checklist walk |
| **Handoff** (`handoff-<slug>.md`) | the *state*: what's actually done, what compiles, what's next | turn ends incomplete OR context nears limit | consumed/overwritten by the next session |

The plan is intent (pre-execution). The handoff is progress (mid-execution). A plan does not record which endpoints you already wrote or whether the build is green — that is the handoff's job.

## Writing the plan doc

When the threshold is met: write the approved plan to `$TMPDIR/plan-<slug>.md` (short kebab-case slug). Contents: Goal, Affected-layers table (NONE/PARTIAL/FULL), Contracts (API/slice/nav/zod), out-of-scope. Re-read it at the start of each tool-call burst (anti-amnesia). Update it **first** when scope expands. Delete it after VERIFY + the Completeness Checklist walk.

## Writing the handoff doc

Before writing, snapshot ground truth (not memory): `git status --short`, and the consumer repo's typecheck/lint command (illustrative — e.g. `pnpm typescript` / `pnpm lint` in a JS/TS repo) so the doc records a real green/red baseline. Then write `$TMPDIR/handoff-<slug>.md`:

- **Progress ledger** keyed to the consumer repo's own layer / work order (illustrative — e.g. Types/API/Slice/Hook/Screen/Nav/i18n in an RN app) each `[done|partial: …|not started]`, with exact file paths touched and still owed.
- **Verification baseline** — the pasted typecheck/lint result.
- **Suggested skills / gates to clear on resume** — name any routed skills or rule-gates the consumer repo requires the next session to invoke before its gated edits (whatever that repo's `skills-routing.json` configures), so the resuming session loads them before touching a gated path.
- **Mid-code decisions** made since plan approval that aren't in the plan yet.
- **Reference, do not duplicate** other artifacts (the plan file, specs, ADRs, commits) — link by path.
- **Redact** secrets/PII.
- Tailor to the passed argument (the next session's focus).

Then set the status-block `Next:` to the absolute path of the handoff doc.

## Red Flags — STOP, you are rationalizing

- "I'll just finish this unit of work first, the context is already loaded." — Pushing past a clean boundary can force another gated skill invocation that loads *more* rules into the context you are trying not to overflow, and risks a forbidden half-finished unit. Checkpoint at the clean boundary instead.
- "I'll jot a quick note to myself." — Forbidden (non-negotiable #7: no local memory). A note in your head is exactly what the fresh session does not inherit.
- "The plan file is still there, the next session can re-read it." — The plan is the contract, not progress; and it is deleted at VERIFY. Reference it from the handoff; never rely on it as the handoff.
- "I'll just `/compact` and keep going." — `/compact` is lossy in-session summarization with no durable artifact; a brand-new session gets nothing. It feeds the "finish the slice" temptation rather than producing resumable state on disk.

## Common mistakes

- Writing into the workspace instead of `$TMPDIR`.
- Dumping the whole conversation — keep it a resume contract, not a transcript.
- A vague `Next:` ("continue where we left off") — name the exact file and edit.
