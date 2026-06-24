# WCAG 2.2 AA → React Native checklist

The rule catalog the `accessibility` skill sweeps. Each rule is a concrete, statically-checkable React Native pattern tied to a WCAG 2.2 success criterion (SC). Sweep **every** rule against the target and assign `Pass` / `Fail` / `Partial` / `N/A`. A rule with no relevant element on the target is `N/A` — still give it a row.

These are the rules a freehand pass reliably misses, called out so they are not skipped: **A8 target size, A9 contrast, A10 use of color, A2 heading roles, A6 focus order, A11 text resize / `allowsFontScaling`**.

"Interactive element" = `Pressable` / `TouchableOpacity` / `TouchableHighlight` / `Button` / a custom control with an `onPress`.

| ID | Rule (what to check in the source) | WCAG SC | Typical fix |
| --- | --- | --- | --- |
| A1 | Every **icon-only / image-only** interactive element has an `accessibilityLabel` describing its action. | 1.1.1, 4.1.2 | Add `accessibilityLabel` on the touchable. |
| A2 | **Decorative** images / views carry no a11y noise: `accessible={false}` (or `importantForAccessibility="no-hide-descendants"`). Informative images have a label. | 1.1.1 | `accessible={false}` for decorative; `accessibilityLabel` for informative. |
| A3 | Every **text input** has a programmatic label (`accessibilityLabel`, or an associated label) — **not** a `placeholder` alone (placeholders vanish on input and are not a reliable name). | 3.3.2, 4.1.2 | Add `accessibilityLabel`; keep placeholder as a hint only. |
| A4 | Inputs declare **purpose** for autofill where applicable: `autoComplete` (Android) and `textContentType` (iOS), plus a fitting `keyboardType`. | 1.3.5 | Add `autoComplete` / `textContentType` / `keyboardType`. |
| A5 | Section/screen **titles** use `accessibilityRole="header"` so AT users can navigate by heading. | 1.3.1, 2.4.6 | Add `accessibilityRole="header"` to the heading `Text`. |
| A6 | **Focus / reading order** matches the visual order; off-screen or visually-hidden content is removed from the tree (`accessibilityElementsHidden` / `importantForAccessibility="no-hide-descendants"`). | 1.3.2, 2.4.3 | Reorder, or hide off-screen nodes from AT. |
| A7 | **Name, Role, Value** for custom controls: an interactive element exposes the right `accessibilityRole` (`button`, `checkbox`, `switch`, `link`, `radio`, `tab`…) and, for stateful controls, `accessibilityState` (`checked` / `selected` / `disabled` / `expanded` / `busy`). | 4.1.2 | Add `accessibilityRole` + `accessibilityState`. |
| A8 | **Target size**: interactive targets are ≥ 44×44 (pt/dp), via layout size or `hitSlop`. | 2.5.8 | Enlarge the element or add `hitSlop`. |
| A9 | **Contrast (minimum)**: text vs background ≥ 4.5:1 (≥ 3:1 for large text ≥ 24px or ≥ 18.66px bold); UI component / state indicators ≥ 3:1. | 1.4.3, 1.4.11 | Darken/adjust the color. |
| A10 | **Use of color**: state, error, or meaning is **not** conveyed by color alone — there is also text, an icon, or a shape. | 1.4.1 | Add a text/icon cue alongside the color. |
| A11 | **Text resize**: `allowsFontScaling` is not disabled (`={false}`) on body/label text; layout tolerates Dynamic Type / font scaling. | 1.4.4, 1.4.10 | Remove `allowsFontScaling={false}`; let the layout grow. |
| A12 | **Errors are identified and announced**: validation errors render with `accessibilityRole="alert"` and/or `accessibilityLiveRegion="polite"` (Android) plus `AccessibilityInfo.announceForAccessibility` (iOS); the error text names the problem. | 3.3.1, 4.1.3 | Add the live-region/alert wiring and a descriptive message. |
| A13 | **Status messages** (success, loading, count changes) are announced without moving focus, via a live region. | 4.1.3 | `accessibilityLiveRegion` / `announceForAccessibility`. |
| A14 | **Grouping**: a composite control (icon + label, or a row that acts as one tap target) is announced as **one** node — `accessible={true}` on the parent, children hidden — not several. | 1.3.1, 4.1.2 | `accessible` on the parent; hide redundant children. |
| A15 | **Hints** for non-obvious actions: `accessibilityHint` describes the outcome when the action is not clear from the label alone (do not duplicate the label). | 3.3.2 | Add a concise `accessibilityHint`. |
| A16 | **Disabled / busy state** is exposed, not just styled: `accessibilityState={{ disabled: true }}` / `{ busy: true }` mirrors the visual state. | 4.1.2 | Add the matching `accessibilityState`. |

## Notes

- **Platform split:** `accessibilityLiveRegion` is Android-only; iOS needs `AccessibilityInfo.announceForAccessibility`. A complete error/status fix usually wires both (A12, A13).
- **Contrast (A9)** is checkable statically only when both colors are literals in the source (`StyleSheet` / inline). When a color comes from a theme token or prop, mark `Partial` and name the token to check rather than guessing a ratio.
- **Target size (A8)** is judged from explicit `width`/`height`/`padding`/`hitSlop` in the source; when the size is dynamic or theme-driven, mark `Partial` and say what to verify at runtime.
- **Focus order (A6)** is not "Pass by default". A `Pass` must name what was inspected — confirm there is no off-screen, absolutely-positioned, or conditionally-rendered node that could inject an out-of-order element into the accessibility tree. If you cannot confirm that from the source, mark `Partial`.
- This skill audits **statically, from source**. Behaviors only observable at runtime (actual screen-reader output, real rendered contrast) are out of scope — flag them as `Partial` with what to verify on device.
