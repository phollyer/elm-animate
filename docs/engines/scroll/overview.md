# Scroll Engines Overview

The Scroll Engines provide smooth scrolling to elements or positions. They share the same [Builder](../../api-reference.md) for configuring scroll targets and offer three engines, each optimized for a different execution model:

| Engine | Import | Use When |
| ------ | ------ | -------- |
| [**Scroll Cmd**](cmd.md) | `import Anim.Engine.Scroll.Cmd as Scroll` | Simple fire-and-forget scrolling |
| [**Scroll Task**](task.md) | `import Anim.Engine.Scroll.Task as Scroll` | You need error handling or task composition |
| [**Scroll Sub**](sub.md) | `import Anim.Engine.Scroll.Sub as Scroll` | You need state tracking, events, or mid-scroll control |

### Feature Comparison

| Feature | Scroll Cmd | Scroll Task | Scroll Sub |
| ------- | :--------: | :---------: | :--------: |
| **Execution** |
| Fire-and-forget | ✓ | | |
| Task composition | | ✓ | |
| State tracking | | | ✓ |
| **Timing** |
| Frame-rate independent | | | ✓ |
| Accurate duration | | | ✓ |
| **Control** |
| Stop | | | ✓ |
| Pause / Resume | | | ✓ |
| Reset / Restart | | | ✓ |
| **Events** |
| Started | | | ✓ |
| Ended | | | ✓ |
| Progress | | | ✓ |
| Stopped | | | ✓ |
| Paused | | | ✓ |
| Resumed | | | ✓ |
| Restarted | | | ✓ |
| **Queries** |
| Current position | | | ✓ |
| Running state | | | ✓ |
| **Error Handling** |
| Typed errors | | ✓ | |


## Scroll Targets

All target functions are in the [Builder](../../api-reference.md) module.

### Scroll to Element

??? example "View Source Code"

    ```elm
    ScrollTo.forDocument
        >> ScrollTo.toElement "section-id"
        >> ScrollTo.build
    ```

### Scroll to Position

??? example "View Source Code"

    ```elm
    -- Scroll to specific Y position
    ScrollTo.forDocument
        >> ScrollTo.toY 500
        >> ScrollTo.build

    -- Scroll to specific X position
    ScrollTo.forDocument
        >> ScrollTo.toX 200
        >> ScrollTo.build

    -- Scroll to both
    ScrollTo.forDocument
        >> ScrollTo.toXY 200 500
        >> ScrollTo.build
    ```

### Scroll to Top/Bottom

??? example "View Source Code"

    ```elm
    -- Scroll to top
    ScrollTo.forDocument
        >> ScrollTo.toTop
        >> ScrollTo.build

    -- Scroll to bottom
    ScrollTo.forDocument
        >> ScrollTo.toBottom
        >> ScrollTo.build
    ```

## Container Scrolling

By default, scrolls the document. To scroll within a container:

??? example "View Source Code"

    ```elm
    Scroll.animate ScrollComplete <|
        ScrollTo.forContainer "scrollable-container"
            >> ScrollTo.toElement "item-in-container"
            >> ScrollTo.build
    ```

## Default Settings

Set (optional) defaults for all scroll actions. Each engine has its own `duration`, `speed`, `easing`, and `delay` functions for global defaults. These are chained before the first scroll target.

### Duration

??? example "View Source Code"

    ```elm
    Scroll.animate ScrollComplete <|
        Scroll.duration 800
            >> ScrollTo.forDocument
            >> ScrollTo.toElement "section"
            >> ScrollTo.build
    ```

### Easing

??? example "View Source Code"

    ```elm
    Scroll.animate ScrollComplete <|
        Scroll.easing QuintOut
            >> ScrollTo.forDocument
            >> ScrollTo.toElement "section"
            >> ScrollTo.build
    ```

## Per-Scroll Settings

Individual scroll actions can have their own settings that override global defaults. These are set in the [Builder](../../api-reference.md) module.

### Offset

Add offset from the target (useful for fixed headers):

??? example "View Source Code"

    ```elm
    ScrollTo.forDocument
        >> ScrollTo.toElement "section"
        >> ScrollTo.withOffsetY 80  -- 80px offset from top
        >> ScrollTo.build
    ```

### Axis

Control which axis to scroll:

??? example "View Source Code"

    ```elm
    -- Vertical only (default)
    ScrollTo.forDocument
        >> ScrollTo.toElement "section"
        >> ScrollTo.onYAxis
        >> ScrollTo.build

    -- Horizontal only
    ScrollTo.forDocument
        >> ScrollTo.toElement "section"
        >> ScrollTo.onXAxis
        >> ScrollTo.build

    -- Both axes
    ScrollTo.forDocument
        >> ScrollTo.toElement "section"
        >> ScrollTo.onBothAxes
        >> ScrollTo.build
    ```

### Per-Scroll Duration/Speed/Easing

??? example "View Source Code"

    ```elm
    ScrollTo.forDocument
        >> ScrollTo.toElement "section"
        >> ScrollTo.duration 500
        >> ScrollTo.easing QuintOut
        >> ScrollTo.build
    ```

## Timing & Refresh Rates

!!! warning "Cmd and Task timing is approximate"
    The Scroll Cmd and Scroll Task engines pre-calculate animation frames and execute them sequentially via `Task.sequence`. Because they lack access to the browser's vsync signal (`requestAnimationFrame`), the actual scroll duration depends on how fast the browser processes each DOM write — which varies by machine speed and display refresh rate.

    **On a 60Hz display**, a scroll that should take 3400ms (850px at 250px/sec) may complete in roughly half that time, because each `setViewport` call resolves faster than the 16.67ms frame budget.

    **On higher refresh rate displays** (120Hz, 144Hz), the discrepancy can be even larger.

    | Display | Approximate Effect |
    | ------- | ------------------ |
    | 60Hz | Completes faster than specified duration |
    | 120Hz | Completes significantly faster |
    | 144Hz | Completes significantly faster |

    If accurate timing matters, use the **[Scroll Sub](sub.md)** engine — it uses `onAnimationFrameDelta` (the browser's actual vsync signal) with delta-time interpolation, producing frame-rate independent animations that match the specified duration precisely.

    [Check your display's refresh rate](../../tools/fps-test.html){ target="_blank" } to see how it affects timing.


## Builder API Reference

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `forDocument` | `AnimBuilder -> Builder` | Start scroll in document |
| `forContainer` | `String -> AnimBuilder -> Builder` | Start scroll in container |
| `toElement` | `String -> Builder -> Builder` | Scroll to element by ID |
| `toTop` | `Builder -> Builder` | Scroll to top |
| `toBottom` | `Builder -> Builder` | Scroll to bottom |
| `toX` | `Float -> Builder -> Builder` | Scroll to X position |
| `toY` | `Float -> Builder -> Builder` | Scroll to Y position |
| `toXY` | `Float -> Float -> Builder -> Builder` | Scroll to X and Y position |
| `build` | `Builder -> AnimBuilder` | Finalize scroll action |
| `duration` | `Int -> Builder -> Builder` | Per-scroll duration (ms) |
| `speed` | `Float -> Builder -> Builder` | Per-scroll speed (px/sec) |
| `easing` | `Easing -> Builder -> Builder` | Per-scroll easing |
| `delay` | `Int -> Builder -> Builder` | Per-scroll delay (ms) |
| `onXAxis` | `Builder -> Builder` | Scroll X axis only |
| `onYAxis` | `Builder -> Builder` | Scroll Y axis only |
| `onBothAxes` | `Builder -> Builder` | Scroll both axes |
| `withOffsetX` | `Float -> Builder -> Builder` | Add X offset |
| `withOffsetY` | `Float -> Builder -> Builder` | Add Y offset |
| `defaultDelay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/).


## Next Steps

Explore each scroll engine in detail:

- [Scroll Cmd](cmd.md) — Fire-and-forget scrolling
- [Scroll Task](task.md) — Composable scrolling with error handling
- [Scroll Sub](sub.md) — Stateful scrolling with full control
