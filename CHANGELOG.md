# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added

- **`Motion.Spring`** — physics-based spring primitive with presets (`gentle`, `wobbly`, `stiff`, `slow`, `noWobble`) and a `custom` builder. Springs derive their settle time from physics rather than a user-specified duration, and produce natural overshoot and oscillation.
- Per-property `spring` setter on every property module (`Opacity`, `Translate`, `Rotate`, `Scale`, `Skew`, `Size`, `PerspectiveOrigin`, `Custom`, `CustomColor`).
- Engine-level `spring` setter on every animation engine (`Transition`, `Keyframe`, `Sub`, `WAAPI`, `ScrollTimeline`, `ViewTimeline`). Spring and easing are mutually exclusive — setting one clears the other.

### Changed

- **Renamed `Easing` → `Motion.Easing`** to bring it under the same `Motion.*` namespace as `Motion.Spring`. Callers must update `import Easing` to `import Motion.Easing` (or `import Motion.Easing as Easing` to keep qualified references unchanged).
- `Shared.Easing.toFunction` no longer takes a `durationMs` parameter; it was only used by the now-removed Custom/Advanced bounce/elastic keyframe sampling. Engine call sites updated accordingly.

### Removed

- **`BounceInCustom`, `BounceOutCustom`, `BounceInOutCustom`** — Custom bounce variants. Use `Motion.Spring` for tunable overshoot, or the standard `BounceIn` / `BounceOut` / `BounceInOut` for the algebraic curve.
- **`BounceInAdvanced`, `BounceOutAdvanced`, `BounceInOutAdvanced`** — same rationale.
- **`ElasticInCustom`, `ElasticOutCustom`, `ElasticInOutCustom`** — Custom elastic variants. Use `Motion.Spring` for tunable oscillation.
- **`ElasticInAdvanced`, `ElasticOutAdvanced`, `ElasticInOutAdvanced`** — same rationale.
- `Shared.Easing.Physics` module and the `transitionFractionOf` re-export — only the removed variants needed the physics-derived ratio; surviving easings always returned `1.0`.
- Internal `keyframeBased` helper and the bulk of `Shared.Easing.Keyframes` (~800 lines of physics simulation, transition stitching, velocity-matching, and parameter-derivation helpers).

### Preserved unchanged

- Standard `BounceIn`, `BounceOut`, `BounceInOut`.
- Standard `ElasticIn`, `ElasticOut`, `ElasticInOut`.
- All `BackIn`, `BackOut`, `BackInOut`, `BackInCustom`, `BackOutCustom`, `BackInOutCustom`.
- All Cubic/Quad/Quart/Quint/Sine/Expo/Circ/Ease/Linear/CubicBezier easings.

---

## [1.0.0] - 2026-04-28

Initial release of `phollyer/elm-motion`.

### Animation

- **Transition Engine** — Browser-native CSS transitions; simple state-to-state animations with minimal setup
- **Keyframe Engine** — Browser-native `@keyframes`; looping, full playback control
- **Sub Engine** — Pure Elm, frame-by-frame via subscriptions; looping, real-time mid-flight queries and diversions
- **WAAPI Engine** — Web Animations API via JavaScript ports; looping, full control, real-time mid-flight queries and diversions
- **ScrollTimeline Engine** — Scroll-driven animations tied to a scroll container's progress, via WAAPI
- **ViewTimeline Engine** — Viewport-driven animations tied to an element entering and leaving view, via WAAPI

### Scroll

- **Cmd Engine** — Fire-and-forget scrolling with minimal setup
- **Task Engine** — Composable scrolls with error handling
- **Sub Engine** — Stateful scrolling with events and mid-scroll queries and control

### Properties

- `Translate` — X, Y, Z translation (GPU accelerated)
- `Rotate` — Single-axis and 3D rotation (GPU accelerated)
- `Scale` — X, Y, Z scaling (GPU accelerated)
- `Skew` — X and Y skew
- `Opacity` — Opacity (GPU accelerated)
- `PerspectiveOrigin` — Perspective origin for 3D scenes
- `Size` — Width and height
- `Custom` — Arbitrary CSS property animations
- `CustomColor` — Arbitrary CSS color property animations

### Other

- Composable builder API — define animations once, run on any engine
- Full 3D support — XYZ positioning, multi-axis rotation, perspective
- Easing functions via `elm-community/easing-functions`
- JavaScript companion package `@phollyer/elm-motion` (npm `1.0.0`) for WAAPI integration
- TypeScript definitions for the WAAPI companion
