# Elm Motion Package - AI Coding Instructions

## ⚠️ Critical Rules ⚠️

The library is unpublished. Breaking changes are expected when adding features or refactoring.

- **Never** account for backward compatibility unless the user explicitly asks.
- **Never** guess user intent, a solution, or implementation details. Read API docs and codebase, ask for clarification when requirements are ambiguous, and validate any theoretical solution with tests before implementing it.
- **Always** ensure that any new code is covered by tests that verify its correctness and edge cases. If modifying existing code, ensure tests cover the modified behavior and add tests if coverage is insufficient.
- **Always** remove deprecated functions and stale comments when refactoring.
- **Always** preserve original functionality during refactoring or optimization unless the user requests a behavior change.
- **Always** prioritize explicit user instructions and constraints above any guideline in this document.

## Testing Discipline

- Run `npm test` from the project root (runs `elm-test-rs` then Vitest), or `npm run test:elm` / `npm run test:js` individually.
- If the code being modified has no tests, add tests covering its existing behavior **before** changing it, so refactors cannot silently break functionality.
- New features and bug fixes ship with tests covering the new code and edge cases.
- The public API must be exercised with a variety of inputs and scenarios.
- Tests must be deterministic and free of external state. Use descriptive test names.

## Elm Code Style

When creating or editing Elm files:

- Do **not** add module declarations manually — the VSCode Elm plugin handles that. Always specify the exposing list explicitly; never leave it as `(..)`.
- Prefer function composition and point-free style.
- Design functions for composability and reusability. Avoid unnecessary complexity.
- Use descriptive names. Follow Elm naming, organization, and documentation conventions.
- Every public function needs a clear type annotation and a documentation comment.
- Order code to match the order of doc comments in the API documentation. Private implementations of public modules follow the public API order, with private helpers placed after the public functions that use them. Section heading comments must match the API documentation's section headings.

### Doc-Comment Examples

- Format example snippets correctly and include type annotations where appropriate.
- Pull example code from real source via `--8<-- "path/to/source:label"` rather than hand-writing it; keep included code current and relevant.
- Never guess at API usage or implementation details — read the actual source. If the example needs setup or context, include it.

### Punctuation

- Hyphen as sentence separator (em-dash equivalent) takes a space on each side: `This engine is simple - use it for quick setups.`
- Compound adjectives are closed with no spaces: `compositor-accelerated`, `color-based`, `hardware-accelerated` — never `compositor - accelerated`.

## Project Layout

### Examples

- Live in `docs/examples/src/`, organized by Engine type → Engine name → example name (e.g. `docs/examples/src/Animation/Transition/FadeInOut/Main.elm`).
- Every example module is named `Main.elm`.
- Compile with `./scripts/build-docs-examples.sh` (all examples) or `./scripts/build-example.sh` (single example). Examples must be compiled from `docs/examples/`, not the package root, due to ports restrictions.

### Package Structure

- **Exposed modules** are declared in `elm.json`: animation engines, scroll engines, property modules, extras, and `Easing`.
- **Internal modules** live under any `Internal/` namespace and must never be exposed.
- **JavaScript integration** ships via npm (`npm install @phollyer/elm-motion`) and CDN (`https://unpkg.com/@phollyer/elm-motion/elm-motion.js`).
- **Documentation** is built with MkDocs from `docs/` and hosted on GitHub Pages.

## Project Overview

Elm 0.19 package providing 6 animation engines and 3 scroll engines under a unified builder API. All engines share the same animation and scroll configuration API — switching engines does not require rewriting animation definitions.

### Animation Engines

| Engine | Module | Notes |
| ------ | ------ | ----- |
| Transition | `Anim.Engine.Transition` | CSS transitions, minimal setup |
| Keyframe | `Anim.Engine.Keyframe` | CSS keyframes, looping, full control |
| Sub | `Anim.Engine.Sub` | Pure Elm, frame-based, real-time queries |
| WAAPI | `Anim.Engine.WAAPI` | Web Animations API via JS ports |
| ScrollTimeline | `Anim.Engine.ScrollTimeline` | Scroll-driven via WAAPI |
| ViewTimeline | `Anim.Engine.ViewTimeline` | Viewport-driven via WAAPI |

### Scroll Engines

| Engine | Module | Notes |
| ------ | ------ | ----- |
| Cmd | `Scroll.Engine.Cmd` | Fire-and-forget |
| Task | `Scroll.Engine.Task` | Composable with error handling |
| Sub | `Scroll.Engine.Sub` | Stateful, full control, mid-scroll queries |

### Property Modules

All under `Anim.Property.*`:

- `Opacity`, `Translate`, `Rotate`, `Scale`, `Skew`, `Size`, `PerspectiveOrigin`
- `Custom` — any numeric CSS property with a unit
- `CustomColor` — any color CSS property

### Key Internal Architecture

- `Anim.Internal.Builder` — shared `AnimBuilder` type threaded through all property and engine pipelines.
- `Anim.Internal.Property` — core property configuration logic shared across all property modules.
- `Anim.Internal.Engine.*` — engine-specific rendering and interpolation logic.
- `Scroll.Internal.*` — scroll engine internals.

### JavaScript Companion

`elm-motion.js` (npm package `@phollyer/elm-motion`, served from package root after publish) drives the WAAPI, ScrollTimeline, and ViewTimeline engines via the `waapiCommand` / `waapiEvent` port pair. Initialize with `ElmMotion.init(app.ports)`.

## Current Project Structure

```
src/
├── Easing.elm
├── Anim/
│   ├── Builder.elm
│   ├── Engine/
│   │   ├── Transition.elm
│   │   ├── Keyframe.elm
│   │   ├── Sub.elm
│   │   ├── WAAPI.elm
│   │   └── WAAPI/
│   │       ├── ScrollTimeline.elm
│   │       └── ViewTimeline.elm
│   ├── Extra/
│   │   ├── Color.elm
│   │   ├── TransformOrder.elm
│   │   └── View3D.elm
│   ├── Internal/         - Not exposed
│   └── Property/
│       ├── Custom.elm
│       ├── CustomColor.elm
│       ├── Opacity.elm
│       ├── PerspectiveOrigin.elm
│       ├── Rotate.elm
│       ├── Scale.elm
│       ├── Size.elm
│       ├── Skew.elm
│       └── Translate.elm
└── Scroll/
    ├── Builder.elm
    ├── Engine/
    │   ├── Cmd.elm
    │   ├── Sub.elm
    │   └── Task.elm
    └── Internal/         - Not exposed

docs/examples/src/
├── Animation/
│   ├── Keyframe/
│   ├── Sub/
│   ├── Transition/
│   └── WAAPI/
└── Scroll/
    ├── Cmd/
    ├── Sub/
    └── Task/

dist/
├── @phollyer/elm-motion.js      - JavaScript companion (CJS)
├── @phollyer/elm-motion.mjs     - JavaScript companion (ESM)
├── @phollyer/elm-motion.d.ts    - TypeScript definitions
└── README.md
```

## Dependencies & Compatibility

- Elm 0.19.x only
- `elm/browser`, `elm/html`, `elm/json`, `elm/core`
- `avh4/elm-color` for color support
- `elm-community/easing-functions` for easing curves
- Tests use `elm-explorations/test`
