# Elm Animate Package - AI Coding Instructions

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
- **Compilation**: Use `examples/scripts/build-docs-examples.sh` to compile all examples
- **Individual Compilation**: Use `examples/scripts/build-example.sh`

### Package Structure
- **Exposed modules**: All 4 main animation approaches in `elm.json`
- **Internal modules**: Keep implementation details in `Internal/` namespace
- **JavaScript integration**: Available via npm (`npm install elm-animate`) or CDN `https://unpkg.com/elm-animate@latest/elm-animate-waapi.js`
- **Documentation**: Hosted on GitHub Pages with MkDocs, source in `docs/` directory

## Critical Implementation Details

### Viewport Calculations
- Document body vs container element scrolling uses different DOM APIs
- Container scrolling requires element position relative to container bounds
- Always clamp scroll destination between 0 and max scrollable area

### Animation Systems
- **SmoothMoveScroll**: Pre-calculated frame steps using `Internal.AnimationCore.animationSteps` function
- **SmoothMoveSub**: Time-based interpolation with `onAnimationFrameDelta`
- **SmoothMoveCSS**: Pure CSS generation functions (`transform`, `transition`, `transitionWithDistance`, `calculateDuration`)
- **SmoothMoveWAAPI**: Web Animations API via JavaScript integration
- Speed parameter: pixels per second for SmoothMoveSub, frame count divisor for SmoothMoveScroll
- Easing functions from `elm-community/easing-functions` package applied to progress values

### Safe Compilation Practices
- **Always use the build script**: `./examples/scripts/build-docs-examples.sh` for compilation
- **When in doubt**: Use the build script rather than manual elm make commands

## Project Overview
This is an Elm 0.19 package that provides multiple animation approaches for smooth DOM element movement. The package offers 4 different animation systems, each optimized for different use cases and performance requirements. The core architecture separates public APIs from internal animation logic (`Internal/AnimationCore.elm`).

## Four Animation Approaches

### 1. Task-Based API (SmoothMoveScroll)
- **Purpose**: Scrolling animations with task-based error handling
- **API**: Functions return `Task Dom.Error (List ())` for composable operations
- **Usage**: `scrollTo "element-id" |> Task.attempt (always NoOp)`
- **Best for**: Document/container scrolling, sequential animations

### 2. Subscription-Based API (SmoothMoveSub) 
- **Purpose**: Element positioning with frame-rate independent animations
- **API**: `onAnimationFrameDelta` subscriptions with model updates
- **Usage**: Create `AnimState`, subscribe to `subscriptions`, apply via CSS transform
- **Best for**: Multiple simultaneous element animations

### 3. CSS Transition-Based API (SmoothMoveCSS)
- **Purpose**: Native browser CSS transitions for optimal performance
- **API**: Generate CSS transition styles, browser handles animation
- **Usage**: Apply returned CSS styles directly to elements
- **Best for**: Hardware acceleration, battery efficiency, simple transitions

### 4. WAAPI-Based API (SmoothMoveWAAPI)
- **Purpose**: Web Animations API integration via JavaScript
- **API**: Elm ports communicating with JavaScript companion file
- **Usage**: Requires `elm-animate-waapi.js` and port definitions
- **Best for**: Complex animations, platform-specific optimizations

## Key Architecture Patterns

### Unified Configuration Pattern
```elm
-- All modules use consistent defaultConfig pattern
scrollToWithOptions { defaultConfig | offset = 60, speed = 15 } "target-id"
moveToWithOptions { defaultConfig | speed = 500, axis = Both } "element-id" 0 0 100 200
```

### Internal Module Organization
- `Internal/AnimationCore.elm` contains pure interpolation logic (`animationSteps` and `animationStepsWithFrames` functions)
- Main modules handle DOM interactions and API orchestration
- Internal modules are not exposed in `elm.json`

### ElementData Pattern (Position Preservation)
- Dict-based O(1) element lookup and state management
- `ElementData` type preserves element positions when animations stop
- Critical for smooth animation continuity across state changes

## Current Project Structure
```
src/
├── Internal/
│   └── AnimationCore.elm     - Pure interpolation logic (animationSteps and animationStepsWithFrames functions)
├── SmoothMoveScroll.elm      - Task-based scrolling API
├── SmoothMoveSub.elm         - Subscription-based positioning API  
├── SmoothMoveCSS.elm         - CSS transition-based API
└── SmoothMoveWAAPI.elm       - WAAPI-based Web Animations API

examples/
├── scripts/
│   └── build.sh              - Main build script
├── js/
│   └── elm-animate-waapi.js  - JavaScript companion for WAAPI API
└── src/
    ├── Common/               - Reusable functions for duplicated code in the examples
    ├── ElmUI/
    │   ├── Scroll/           - Task examples (Basic.elm, Container.elm, etc.)
    │   ├── Sub/              - Subscription examples (Basic.elm, Multiple.elm)
    │   ├── CSS/              - CSS examples (Basic.elm, Multiple.elm)
    │   └── WAAPI/            - Ports examples (Basic.elm, Multiple.elm)
    └── HTML/
        ├── SmoothMoveScroll/ - HTML task examples
        ├── SmoothMoveSub/    - HTML subscription examples
        ├── SmoothMoveCSS/    - HTML CSS examples
        └── SmoothMoveWAAPI/  - HTML ports examples
```

## Dependencies & Compatibility
- Elm 0.19.x only
- Requires `elm/browser` for DOM operations
- Uses `elm-community/easing-functions` for animation curves
- Test with `elm-explorations/test`