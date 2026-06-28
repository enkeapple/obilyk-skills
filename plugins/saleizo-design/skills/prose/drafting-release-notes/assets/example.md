# Worked example — diff to release notes

Illustrative only; a consumer repo supplies its own branches, locales, and product voice.

## Input — `git log --oneline release/2.3.0..release/2.4.0`

```text
a1f0c92 feat(tour-card): show per-passenger price breakdown on tour cards
b2e1d83 feat(boarding): allow boarding flow for families travelling with infants
c3d2e74 fix(privacy): point Privacy Policy link at the new 2024 policy URL
d4c3f65 chore(deps): bump react-native from 0.73.2 to 0.73.6
e5b4a56 refactor(api): extract TourPricingService out of TourRepository
f6a5b47 fix(crash): guard against NPE in SeatMapView when seatMap is null
0072c38 test(boarding): add unit tests for InfantBoardingValidator
118d3e9 chore(ci): cache pods directory in iOS workflow
229e4fa fix(perf): debounce search input to cut re-renders on the explore screen
33af50b feat(analytics): add Segment events for checkout funnel (internal only)
44b061c style: run prettier across the codebase
55c172d fix(i18n): correct German plural form for "1 passenger"
66d283e docs(readme): update local-setup instructions
77e394f fix(ui): increase tap target on the date picker chevrons
88f4a5e build(android): raise minSdk to 24
```

## Triage

- **Kept (user-facing):** per-passenger price (`a1f0c92`), infant boarding (`b2e1d83`), Privacy
  Policy link (`c3d2e74`). Folded into the catch-all: crash fix (`f6a5b47`), search perf
  (`229e4fa`), German plural (`55c172d`), bigger tap target (`77e394f`).
- **Dropped (internal):** `d4c3f65` RN bump, `e5b4a56` refactor, `0072c38` tests, `118d3e9` CI,
  `33af50b` internal analytics, `44b061c` prettier, `66d283e` docs, `88f4a5e` minSdk/build.

## Locales

`translations/` holds `en-US de-DE es-ES fr-FR it-IT nl-NL pt-PT` → one block each, translated.

## Output (English block shown; the other six are natural translations of the same bullets)

```text
<en-US>
• Tour cards now show the price per passenger
• Boarding now works for families travelling with infants
• Updated Privacy Policy links
• Bug fixes and performance improvements
</en-US>
<de-DE>
• Tour-Karten zeigen jetzt den Preis pro Person
• Das Boarding funktioniert nun für Familien, die mit Säuglingen reisen
• Aktualisierte Links zur Datenschutzrichtlinie
• Fehlerbehebungen und Leistungsverbesserungen
</de-DE>
```

Had `translations/` been absent, the output would be the `<en-US>` block alone, with a one-line note
that localization was skipped because no locales were detected.
