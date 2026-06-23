---
description: 'Consumer config for resolving-requirements in this repo — fills the four slots the agnostic skill leaves to the consumer: the FLIBCO ticket-ID pattern, the remote spec source (Azure DevOps flibco-specs), how to sync it into /tmp/flibco-specs fresh, and where provenance is recorded. Task-scoped to a resolving-requirements run; no file paths.'
---

# Resolving Requirements — FLIBCO source

## When

The `resolving-requirements` skill is resolving a ticket-ID input in this repo. The skill is agnostic and reads its source specifics from consumer config (its "Two input modes" section says the pattern, source, sync, and provenance location are "never baked into this skill"). This file IS that config — it does not change the skill.

## Implementation

Apply these four values where the skill says "the configured …":

- **Ticket-ID pattern** — an input is in **resolve** mode iff it matches `^FLIBCO-\d+$`. Anything else (free-text, a pasted URL body) stays **direct**: pass through to `grilling` unchanged.
- **Remote spec repository** — `https://flibco-ci@dev.azure.com/flibco-ci/Flibco%20AI%20Tooling/_git/flibco-specs` (Azure DevOps, project "Flibco AI Tooling", repo `flibco-specs`). This is the ONLY spec source; there is no local-path lookup.
- **Sync** — fresh every time into the working copy `/tmp/flibco-specs`; no env vars, no cache, no assumed user folder layout.
  - if `/tmp/flibco-specs/.git` exists → `git -C /tmp/flibco-specs pull --rebase --quiet`
  - else → `git clone --depth=1 'https://flibco-ci@dev.azure.com/flibco-ci/Flibco%20AI%20Tooling/_git/flibco-specs' /tmp/flibco-specs`
- **Locate the bundle** by the matched ID — a match may be a file OR a directory (the "story folder"): `find /tmp/flibco-specs -iname "*FLIBCO-<id>*" -print`. Per the skill, read every file in a directory bundle; prefer the fullest match; never let filesystem order pick between matches.
- **Provenance** — record in the SPEC frontmatter so audits trace to the exact QA/BA bundle: `source` (absolute path inside `/tmp/flibco-specs`), `revision` (HEAD sha), `ticket` (the FLIBCO ID), `files` (every file read).

```text
✅ CORRECT — input "FLIBCO-1234"
  git clone --depth=1 'https://flibco-ci@dev.azure.com/flibco-ci/Flibco%20AI%20Tooling/_git/flibco-specs' /tmp/flibco-specs
  find /tmp/flibco-specs -iname "*FLIBCO-1234*" -print   # read the whole match, verbatim
  → hand grilling the verbatim bundle + provenance (source/revision/ticket/files)

❌ WRONG
  - inventing or paraphrasing the requirements when the clone/find fails
  - resolving from a local/assumed path instead of the remote flibco-specs
  - recording no provenance, so the fetch is non-reproducible
```

On clone/pull failure (auth, network, missing/expired Azure DevOps PAT) or an ID that matches nothing, follow the skill's own **Failure path**: surface the error verbatim, offer the two options (paste-as-text → `direct` mode recording `source: free-text fallback (FLIBCO-<id>, original error: …)`, or abort), never auto-retry, never invent content.

## Edge Cases

- **Not this repo's product code** — these FLIBCO values are deliberately here in repo-local config, NOT in the agnostic `resolving-requirements` skill (which ships via the `sdd-kit` plugin). Editing the skill to hard-code them is the project-leakage defect this rule exists to avoid.
- **When NOT to apply** — the input is not a `^FLIBCO-\d+$` ID: it is free-text/URL, the skill's `direct` mode, and no fetch happens.
- The `*FLIBCO-<id>*` glob uses the concrete ID from the input (e.g. `FLIBCO-1234`), never the literal `<id>`.

## Review Checklist

- [ ] A `^FLIBCO-\d+$` input triggers a fresh clone/pull of the Azure `flibco-specs` remote into `/tmp/flibco-specs` — no local-path lookup, no cache.
- [ ] The whole match is read (every file of a directory bundle) and handed to `grilling` verbatim, not paraphrased.
- [ ] Provenance (`source`/`revision`/`ticket`/`files`) is recorded in the SPEC frontmatter.
- [ ] Clone/find failure surfaces the error verbatim and offers paste-or-abort — no auto-retry, no invented requirements.
- [ ] The agnostic `resolving-requirements` skill was NOT modified — the specifics live only here.
