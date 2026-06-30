---
description: 'Consumer config for resolving-requirements in this repo — fills the four slots the agnostic skill leaves to the consumer: the ticket-ID prefix set (FLIBCO-, NIN-, …, extensible), the remote spec source (Azure DevOps flibco-specs — one repo for every prefix), how to sync it into /tmp/flibco-specs fresh, and where provenance is recorded. Task-scoped to a resolving-requirements run; no file paths.'
---

# Resolving Requirements — flibco-specs source

## When

The `resolving-requirements` skill is resolving a ticket-ID input in this repo. The skill is agnostic and reads its source specifics from consumer config (its "Two input modes" section says the pattern, source, sync, and provenance location are "never baked into this skill"). This file IS that config — it does not change the skill.

## Implementation

Apply these four values where the skill says "the configured …":

- **Ticket-ID prefix set** — the resolve-mode prefixes are `FLIBCO` and `NIN` (extend this set as new trackers are added). An input is in **resolve** mode iff it matches `^(FLIBCO|NIN)-\d+$` — a configured prefix + `-` + digits. **Adding a future prefix is a one-token edit to this alternation; the source, sync, and provenance below are unchanged because every prefix resolves from the same `flibco-specs` repo.** Anything else (free-text, a pasted URL body) stays **direct**: pass through to `grilling` unchanged.
- **Remote spec repository** — `https://flibco-ci@dev.azure.com/flibco-ci/Flibco%20AI%20Tooling/_git/flibco-specs` (Azure DevOps, project "Flibco AI Tooling", repo `flibco-specs`). This is the ONLY spec source, for **every** configured prefix; there is no per-prefix repo and no local-path lookup.
- **Sync** — fresh every time into the working copy `/tmp/flibco-specs`; no env vars, no cache, no assumed user folder layout.
  - if `/tmp/flibco-specs/.git` exists → `git -C /tmp/flibco-specs pull --rebase --quiet`
  - else → `git clone --depth=1 'https://flibco-ci@dev.azure.com/flibco-ci/Flibco%20AI%20Tooling/_git/flibco-specs' /tmp/flibco-specs`
- **Locate the bundle** by the matched ID — use the **full matched ticket ID verbatim** (`FLIBCO-1234`, `NIN-77`, …), never the bare prefix. A match may be a file OR a directory (the "story folder"): `find /tmp/flibco-specs -iname "*<TICKET>*" -print`. Per the skill, read every file in a directory bundle; prefer the fullest match; never let filesystem order pick between matches.
- **Provenance** — record in the SPEC frontmatter so audits trace to the exact QA/BA bundle: `source` (absolute path inside `/tmp/flibco-specs`), `revision` (HEAD sha), `ticket` (the full matched ticket ID, any configured prefix), `files` (every file read).

```text
✅ CORRECT — input "NIN-77" (any configured prefix resolves the same way)
  # sync fresh: if /tmp/flibco-specs/.git exists → git -C /tmp/flibco-specs pull --rebase --quiet; else clone (below)
  git clone --depth=1 'https://flibco-ci@dev.azure.com/flibco-ci/Flibco%20AI%20Tooling/_git/flibco-specs' /tmp/flibco-specs
  find /tmp/flibco-specs -iname "*NIN-77*" -print   # full matched ID, read the whole match verbatim
  → hand grilling the verbatim bundle + provenance (source/revision/ticket/files)

❌ WRONG
  - inventing or paraphrasing the requirements when the clone/find fails
  - resolving from a local/assumed path, or a per-prefix repo, instead of the single flibco-specs remote
  - searching by the bare prefix ("*NIN*") instead of the full matched ID ("*NIN-77*")
  - recording no provenance, so the fetch is non-reproducible
```

On clone/pull failure (auth, network, missing/expired Azure DevOps PAT) or an ID that matches nothing, follow the skill's own **Failure path**: surface the error verbatim, offer the two options (paste-as-text → `direct` mode recording `source: free-text fallback (<TICKET>, original error: …)`, or abort), never auto-retry, never invent content.

## Edge Cases

- **Not this repo's product code** — these flibco-specs values (the prefix set, remote, sync, provenance) are deliberately here in repo-local config, NOT in the agnostic `resolving-requirements` skill (which ships via the `saleizo-core` plugin). Editing the skill to hard-code them — or to hard-code the prefix list — is the project-leakage defect this rule exists to avoid.
- **Adding a prefix** — extend the `^(FLIBCO|NIN)-\d+$` alternation (e.g. `^(FLIBCO|NIN|ACME)-\d+$`) and nothing else, since the source is shared. Only if a future prefix needs a *different* repo does this single-source rule no longer fit — at that point introduce a prefix→source table; do not silently point one prefix at a second remote here.
- **When NOT to apply** — the input is not a configured-prefix ID (does not match `^(FLIBCO|NIN)-\d+$`): it is free-text/URL, the skill's `direct` mode, and no fetch happens.
- The `*<TICKET>*` glob uses the concrete full ID from the input (e.g. `FLIBCO-1234`, `NIN-77`), never the literal `<TICKET>` and never the bare prefix.

## Review Checklist

- [ ] An input matching `^(FLIBCO|NIN)-\d+$` (any configured prefix) triggers a fresh clone/pull of the Azure `flibco-specs` remote into `/tmp/flibco-specs` — no per-prefix repo, no local-path lookup, no cache.
- [ ] The `find` glob uses the full matched ticket ID (`*FLIBCO-1234*`, `*NIN-77*`), not the bare prefix.
- [ ] The whole match is read (every file of a directory bundle) and handed to `grilling` verbatim, not paraphrased.
- [ ] Provenance (`source`/`revision`/`ticket`/`files`) is recorded in the SPEC frontmatter, with `ticket` the full matched ID.
- [ ] Clone/find failure surfaces the error verbatim and offers paste-or-abort — no auto-retry, no invented requirements.
- [ ] The agnostic `resolving-requirements` skill was NOT modified, and the prefix set is defined only here — the specifics live only in this config.
