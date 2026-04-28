# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] - 2026-04-28

Initial release of `phollyer/elm-animate`.

### Animation

- **Transition Engine** — Browser-native CSS transitions; simple state-to-state animations with minimal setup
- **Keyframe Engine** — Browser-native `@keyframes`; looping, full playback control
- **Sub Engine** — Pure Elm, frame-by-frame via subscriptions; looping, real-time mid-flight queries and diversions
- **WAAPI Engine** — Web Animations API via JavaScript ports; looping, full control, real-time mid-flight queries and diversions

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
- JavaScript companion package `elm-animate-waapi` (npm `1.0.0`) for WAAPI integration
- TypeScript definitions for the WAAPI companion
