# Hook Drift Catalog

The detection contract for `auditing-hooks`: the 5 drift classes, each with its layer, detection method, and fix lane; then the locked finding shape every report row uses. A "hook" here is an executable script wired to a harness event; "wiring" is a `command` entry under an event (and matcher) in a `settings.json` `hooks` block or a plugin `hooks.json`.

Agnostic note: the *correspondence* each class checks is generic Claude Code harness structure (events, matchers, `command` paths, optional symlink indirection). The concrete paths shown in examples — `.claude/settings.json`, `plugins/*/hooks/hooks.json`, `hooks/guards/`, the `.claude/hooks/` symlink layer — are one repo's instantiation _(illustrative — your repo's layout may differ)_. Discover the real locations; do not assume these.

## The 5 classes

| # | Class | Layer | Detection method | Fix lane |
| --- | --- | --- | --- | --- |
| D1 | **Orphan script** — a hook script on disk referenced by no wiring entry in any config | mechanical | set-difference: `{scripts on disk}` − `{scripts named by a `command`}` | mechanical (wire it) or owner (delete it) |
| D2 | **Dangling wiring** — a `command` path that resolves to no script on disk | mechanical | for each wiring `command`, resolve its path; assert the target file exists | mechanical (restore the script or remove the entry) |
| D3 | **Broken symlink indirection** — where the repo surfaces hooks via symlinks, a symlink whose target is missing | mechanical | resolve each symlink in the indirection dir; assert the target exists | mechanical (repoint or recreate the symlink) |
| D4 | **Event/matcher mismatch** — a hook wired under an event/matcher inconsistent with what its body reads or does | judgment | read the script body; compare the tool payload it inspects / the decision it makes against the wired event + matcher | owner-action (which matcher is correct is the owner's call) |
| D5 | **Fixture gap** — a wired hook script with no fixture/test file beside it | mechanical | for each wired script, assert a fixture exists (e.g. a `tests/<script>.cases` or the repo's fixture convention) | mechanical (add a fixture stub via `writing-hooks`) |

D1/D2/D3/D5 are **mechanical** — a deterministic check, reproducible by the recipes in [mechanical-checks.md](./mechanical-checks.md). D4 is **judgment** — a light read of the script against its wiring, fixed by the owner (never auto-edit a matcher).

### Class boundaries (what each class is NOT)

- D2 vs **logic defect**: D2 is "the script file is absent". A script that exists but misbehaves (broad match, no deny branch, no-op body, fail-open) is NOT D2 and NOT any class here — it is hook *logic*, owned by `writing-hooks` / code review. Out of scope.
- D5 vs **fixture quality**: D5 is "no fixture file exists for a wired hook". Whether an existing fixture's assertions are correct, cover the happy/garbage paths, or pass is NOT D5 — it is fixture content, owned by `writing-hooks` and the consumer's fixture runner. This audit never executes a fixture.
- D4 vs **logic defect**: D4 is the *wiring* (event/matcher) disagreeing with the script's evident purpose — a structural correspondence. It is not a judgment that the script's logic is wrong; it is that the right script is wired in the wrong place.

## Locked finding shape

Every finding — mechanical or judgment — uses this exact shape, so a report never degrades into prose:

```text
[D<n> <class name>] <severity: High|Medium|Low>
  what:     <the drifted correspondence, one line>
  evidence: <file:line on disk> ↔ <file:line in wiring>  (both sides, verbatim paths)
  recommend: <the recommended disposition, naming the fix lane>
```

- **High** — a wired hook will fail at runtime (D2, D3) or a guard fires on the wrong event (D4 on a security/guard hook).
- **Medium** — a hook is silently inactive (D1 orphan), or a wired hook is untested (D5).
- **Low** — cosmetic / non-runtime correspondence.

For every class with no instance, emit a single line instead of a finding:

```text
D<n> <class name>: no drift found
```

Never omit a clean class — a missing class line reads as "not checked", not "clean". The report carries a **recommended disposition per finding** because the disposition picker is one batched C-drift picker, not one per finding.
