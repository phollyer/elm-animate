# Smooth Move Elm Package - AI Coding Instructions

## ⚠️ CRITICAL FILE PROTECTION RULES ⚠️

### NEVER OVERWRITE THESE PROTECTED FILES:
- **`examples/index.html`** - This is the main examples dashboard. It's a carefully crafted HTML file that provides navigation to all examples. 
- **`examples/src/ElmUI/index.html`** - This is the ElmUI examples dashboard.
- **`examples/src/HTML/index.html`** - This is the HTML examples dashboard.

### ⛔ DO NOT MODIFY HTML EXAMPLES:
- **NEVER modify any files in `examples/src/HTML/`** - These are standalone HTML examples that should remain untouched until explicitly told otherwise by the user
- **Only modify ElmUI examples in `examples/src/ElmUI/`** when working on Elm UI related features
- **User must explicitly request removal of this rule or remove it manually before HTML examples can be modified**

### OUTPUT FILE RULES:
- **Elm compilation outputs**: Always go to `/src/ModulePath/filename.js` (e.g., `src/ElmUI/Scroll/Basic/index.js`)
- **NEVER use `--output=index.html`** - This would overwrite dashboard files
- **NEVER use `--output=../index.html`** or similar paths that could target dashboard files
- **When compiling**: Always specify the exact output path ending in `.js`

### COMPILATION EXAMPLES - CORRECT:
```bash
elm make src/ElmUI/Scroll/Basic/Main.elm --output=src/ElmUI/Scroll/Basic/index.js
elm make src/HTML/SmoothMoveScroll/Basic.elm --output=src/HTML/SmoothMoveScroll/basic.js
```

### COMPILATION EXAMPLES - WRONG (WILL BREAK DASHBOARDS):
```bash
elm make src/ElmUI/Scroll/Basic/Main.elm --output=index.html  # ❌ NEVER DO THIS
elm make src/HTML/SmoothMoveScroll/Basic.elm --output=../index.html  # ❌ NEVER DO THIS
```

If you accidentally overwrite a dashboard file, it must be restored manually from git or recreated.

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
- **Usage**: Create `AnimationState`, subscribe to `subscriptions`, apply via CSS transform
- **Best for**: Multiple simultaneous element animations

### 3. CSS Transition-Based API (SmoothMoveCSS)
- **Purpose**: Native browser CSS transitions for optimal performance
- **API**: Generate CSS transition styles, browser handles animation
- **Usage**: Apply returned CSS styles directly to elements
- **Best for**: Hardware acceleration, battery efficiency, simple transitions

### 4. Ports-Based API (SmoothMovePorts)
- **Purpose**: Web Animations API integration via JavaScript
- **API**: Elm ports communicating with JavaScript companion file
- **Usage**: Requires `smooth-move-ports.js` and port definitions
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

## Development Workflows

### Testing
- Run tests with `elm-test` from project root
- Tests focus on interpolation logic in `Internal.AnimationCore`
- Test edge cases: negative/zero speed, equal start/stop positions

### Examples Organization
- **Location**: `examples/src/` with hierarchical module structure
- **Structure**: Each animation approach has its own subdirectory
  - `Scroll/` - Task-based examples (Basic.elm, Container.elm, etc.)
  - `Sub/` - Subscription-based examples (Basic.elm, Multiple.elm)
  - `CSS/` - CSS-based examples (Basic.elm, Multiple.elm)
  - `Ports/` - Ports-based examples (Basic.elm, Multiple.elm)
  - `Common/` - Reusable functions for duplicated code in the examples.
- **Compilation**: Use `examples/scripts/build.sh` to compile all examples
- **Individual Compilation**: `elm make src/ElmUI/Scroll/Basic/Main.elm --output=src/ElmUI/Scroll/Basic/index.js`
- **Development**: `elm reactor` from `examples/` directory
- **NEVER**: Use `--output=index.html` or paths that could overwrite dashboard files

### Package Structure
- **Exposed modules**: All 4 main animation approaches in `elm.json`
- **Internal modules**: Keep implementation details in `Internal/` namespace
- **JavaScript integration**: Available via npm (`npm install elm-smooth-move`) or in `examples/js/smooth-move-ports.js`

## Critical Implementation Details

### Viewport Calculations
- Document body vs container element scrolling uses different DOM APIs
- Container scrolling requires element position relative to container bounds
- Always clamp scroll destination between 0 and max scrollable area

### Animation Systems
- **SmoothMoveScroll**: Pre-calculated frame steps using `Internal.AnimationCore.animationSteps` function
- **SmoothMoveSub**: Time-based interpolation with `onAnimationFrameDelta`
- **SmoothMoveCSS**: Pure CSS generation functions (`transform`, `transition`, `transitionWithDistance`, `calculateDuration`)
- **SmoothMovePorts**: Web Animations API via JavaScript integration
- Speed parameter: pixels per second for SmoothMoveSub, frame count divisor for SmoothMoveScroll
- Easing functions from `elm-community/easing-functions` package applied to progress values

### Error Handling
- All DOM operations can fail with `Dom.Error`
- Use `Task.attempt` to handle errors gracefully in user applications
- Element IDs that don't exist will cause task failure

### Safe Compilation Practices
- **Always use the build script**: `./examples/scripts/build.sh` for compilation
- **Never use generic output names**: Avoid `--output=index.html` or `--output=main.js`
- **Specify exact paths**: Use full paths like `--output=src/ElmUI/Scroll/Basic/index.js`
- **Avoid relative paths**: Never use `../` paths that could target dashboard files
- **Dashboard protection**: The dashboard files are critical infrastructure - never overwrite them
- **When in doubt**: Use the build script rather than manual elm make commands

## Current Project Structure
```
src/
├── Internal/
│   └── AnimationCore.elm     - Pure interpolation logic (animationSteps and animationStepsWithFrames functions)
├── SmoothMoveScroll.elm      - Task-based scrolling API
├── SmoothMoveSub.elm         - Subscription-based positioning API  
├── SmoothMoveCSS.elm         - CSS transition-based API
└── SmoothMovePorts.elm       - Ports-based Web Animations API

examples/
├── scripts/
│   └── build.sh              - Main build script
├── js/
│   └── smooth-move-ports.js  - JavaScript companion for Ports API
└── src/
    ├── Common/               - Reusable functions for duplicated code in the examples
    ├── ElmUI/
    │   ├── Scroll/           - Task examples (Basic.elm, Container.elm, etc.)
    │   ├── Sub/              - Subscription examples (Basic.elm, Multiple.elm)
    │   ├── CSS/              - CSS examples (Basic.elm, Multiple.elm)
    │   └── Ports/            - Ports examples (Basic.elm, Multiple.elm)
    └── HTML/
        ├── SmoothMoveScroll/ - HTML task examples
        ├── SmoothMoveSub/    - HTML subscription examples
        ├── SmoothMoveCSS/    - HTML CSS examples
        └── SmoothMovePorts/  - HTML ports examples
```

## Dependencies & Compatibility
- Elm 0.19.x only
- Requires `elm/browser` for DOM operations
- Uses `elm-community/easing-functions` for animation curves
- Test with `elm-explorations/test`