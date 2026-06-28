---
name: drafting-release-notes
description: >-
  Use to turn the diff between the current release branch and the previous one
  into human, user-facing store release notes for Google Play and the App Store —
  one localized bullet list per locale the app ships. The diff is the source of
  truth; the output is plain-language "what's new" copy, not a changelog. Detects
  available locales (commonly a `translations/` folder) and produces one block per
  locale; falls back to English-only when none are found. Triggers on: "write the
  release notes", "draft store release notes", "what's new for this release",
  "release notes for Google Play / App Store", "generate release notes from the
  diff", "релиз-ноуты", "что нового для релиза", "опиши изменения для стора".
---

# Drafting Release Notes

Turn the diff between the **current release branch** and the **previous** one into store-ready
release notes: short, human, user-facing bullets — one localized list per locale the app ships.
The diff is the source of truth; the notes are **plain-language benefits a user feels**, never a
copied changelog of commit subjects.

## The recipe (in order)

1. **Get the diff.** List what changed between the current and previous release branch using the
   project's VCS — commonly `git log --oneline <previous-release>..<current-release>` (illustrative;
   the consumer repo names its branches). This commit list is the only source; do not invent items.
2. **Triage to user-facing changes.** Keep only what a user notices: new features, visible
   improvements, user-relevant fixes. **Drop** everything internal — dependency bumps, refactors,
   test/CI/build changes, formatting, internal analytics, docs, version/SDK changes. When in doubt,
   ask "would a user ever notice this?"; if no, cut it.
3. **Draft the English bullets.** Rewrite each kept change as one benefit-first, present-tense line
   in plain language (see Voice). Fold the small fixes and perf work into a single closing
   **`• Bug fixes and performance improvements`** bullet — the store convention — rather than
   listing each fix. Aim for **3–6 bullets total.** If triage leaves nothing user-facing, say so
   and confirm with the user before emitting a notes set — do not emit empty or filler blocks.
4. **Detect locales.** Read the project's locale directory (commonly `translations/`; the consumer
   repo may differ). **Conditional:** if it exists, the locale list is the set of files found
   (e.g. `en-US`, `de-DE`, `fr-FR`, …). If it is **absent**, produce **English only** and say so.
5. **Translate per locale.** For every detected locale, translate the English bullets so each locale
   block reads as natively authored — no literal calques, no English word-order carried into the
   target language. English stays as its own block too.
6. **Emit one block per locale** in the output shape below.

## Output shape (REQUIRED)

The content contract is fixed; the serialization is flexible (the consumer may instead write one
file per locale for the store consoles). Default representation — one block per detected locale,
locale code as the tag, `•` bullets inside:

```text
<en-US>
• <benefit-first line>
• <benefit-first line>
• Bug fixes and performance improvements
</en-US>
<de-DE>
• <same items, natural German>
• …
</de-DE>
```

- **Every detected locale gets its own block** — never one English block "for all locales", never a
  locale silently dropped.
- **No `translations/` (or equivalent) found** → a single `<en-US>` block, plus a one-line note that
  localization was skipped because no locales were detected.

## Voice

- **Benefit-first.** "See the price per passenger on every tour card", not "Added
  per-passenger price field to TourCard".
- Present tense, second person where natural. No jargon, no class/file/API names, no version
  numbers, no ticket IDs, no commit hashes.
- **One idea per bullet**, short.

A worked diff → notes example: [example.md](./assets/example.md).

## Red Flags — STOP

- Copying commit subjects verbatim (`fix(crash): guard against NPE…`) into a bullet — that is a
  changelog, not release notes. Rewrite as a user benefit or fold into the catch-all.
- Including an internal change — the categories from Step 2 — that a user never sees.
- Producing **English only when locales exist**, or deferring translation as "needs review" — the
  detected locales each get a translated block now.
- One block reused for every locale, or a detected locale missing from the output.
- Version numbers, ticket IDs, or internal names leaking into the copy.
- Inventing a change that is not in the diff.
