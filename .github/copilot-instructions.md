# Elm Motion Package - AI Coding Instructions

## ⚠️ Important ⚠️

The library is not currently published, so breaking changes when adding features or refactoring are not only allowed but expected. Do not account for backward compatibility unless explicitly instructed by the user. Always remove deprecated functions and comments when refactoring.

## Problem Solving Philosophy

Never guess user intent, always ask for clarification if the requirements are ambiguous. Prioritize user instructions above all else. If the user provides specific constraints or rules, adhere to them strictly without deviation.

Never guess a solution. Ensure that a theoretical solution is validated before implementation. If unsure, request more information from the user, or add surgical debugging in order to verify assumptions.

When refactoring or optimizing code, always ensure that the original functionality is preserved unless the user explicitly requests changes to behavior.


## Creating Elm Files

When creating new Elm files, always follow these guidelines:

- I am using the Elm plugin for VSCode, which automatically adds module declarations to new files.
  - Therefore, do not add module declarations manually to new Elm files.
  - The exposing list should always be fully specified, and not left as `(..)`.

- Always prefer function composition and point-free style where it improves readability.
- Functions should be designed for composeability and reusability.
- Follow Elm best practices for naming conventions, code organization, and documentation.
- Ensure all public functions have clear type annotations and documentation comments.

- All code should be ordered to match the order of the doc comments in the API documentation. Private implementations of public modules should be ordered to match the public API, with private helper functions placed after the public functions that use them. All section heading comments should match the section headings in the API documentation.

- When adding example code snippets in doc comments, ensure that they are properly formatted and include type annotations where appropriate. Use `--8<-- "path/to/source:label"` to include code from source files, and ensure that the included code is up-to-date and relevant to the documentation.

- When adding example code snippets in doc comments, do not guess at API usage or implementation details - always review the actual source code to ensure accuracy. If the example requires a specific setup or context, provide that context in the documentation.

## ⚠️ CRITICAL REFACTORING RULES ⚠️

- **Never** account for backward compatibility unless explicitly instructed by the user
- **Always** remove deprecated functions and comments when refactoring

## Language and Style Guidelines
- Follow Elm best practices for code style and organization
- Use descriptive names for functions and variables
- Write clear documentation comments for all public functions
- Use consistent formatting and indentation
- Prefer composition and point-free style
- Avoid unnecessary complexity and prefer readability
- When a hyphen is used as a sentence separator (equivalent to an em dash), it must have a space before and after it. For example, "This engine is simple - use it for quick setups." is correct.
- Compound adjectives use a closed hyphen with no spaces. For example, `compositor-accelerated`, `color-based`, `hardware-accelerated` are correct. "compositor - accelerated" is incorrect.

## Development Workflows

### Testing
- Run tests with `elm-test` from project root
- When adding new features or fixing bugs, write tests to cover the new code and any edge cases
- Ensure the public API is fully-tested with a variety of inputs and scenarios
- Ensure tests are deterministic and do not rely on external state
- Use descriptive test names and cover edge cases

### Examples Organization
- **Location**: `docs/examples/src/` with hierarchical module structure
- **Structure**: Examples are organized by Engine type, then by Engine name, then by example name (e.g. `docs/examples/src/Animation/Transition/FadeInOut/Main.elm`)
- **Naming**: Example modules are named `Main.elm` for consistency
- **Compilation**: Use `scripts/build-docs-examples.sh` to compile all examples
- **Individual Compilation**: Use `scripts/build-example.sh`

### Package Structure
- **Exposed modules**: Defined in `elm.json` — animation engines, scroll engines, property modules, extras, and `Easing`
- **Internal modules**: Keep all implementation details in the `Internal/` namespace — never expose them
- **JavaScript integration**: Available via npm (`npm install @phollyer/elm-motion`) or CDN `https://unpkg.com/@phollyer/elm-motion/dist/elm-motion.js`
- **Documentation**: Hosted on GitHub Pages with MkDocs, source in `docs/` directory

### Safe Compilation Practices
- **Always use the build script**: `./scripts/build-docs-examples.sh` to compile all examples
- **Individual examples**: Use `./scripts/build-example.sh`
- The examples live in `docs/examples/` and must be compiled from that directory, not the package root, due to ports restrictions

## Project Overview

This is an Elm 0.19 package providing 6 animation engines and 3 scroll engines under a unified builder API. All engines share the same animation and scroll configuration API — switching engines does not require rewriting animation definitions.

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

All live under `Anim.Property.*`:
- `Opacity`, `Translate`, `Rotate`, `Scale`, `Skew`, `Size`, `PerspectiveOrigin`
- `Custom` — any numeric CSS property with a unit
- `CustomColor` — any color CSS property

### Key Internal Architecture

- `Anim.Internal.Builder` — shared `AnimBuilder` type threaded through all property and engine pipelines
- `Anim.Internal.Property` — core property configuration logic shared across all property modules
- `Anim.Internal.Engine.*` — engine-specific rendering and interpolation logic
- `Scroll.Internal.*` — scroll engine internals

### JavaScript Companion

`dist/elm-motion.js` (also published as npm package `@phollyer/elm-motion`) drives WAAPI, ScrollTimeline, and ViewTimeline engines via the `waapiCommand` / `waapiEvent` ports pair. Initialize with `ElmMotion.init(app.ports)`.

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
- Test with `elm-explorations/test`