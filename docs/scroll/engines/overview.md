# Scroll Engines Overview

This page mainly covers the shared patterns that are used by each Engine. For engine-specific details, see:

- [Cmd](cmd.md) — Fire-and-forget scrolling
- [Task](task.md) — Composable scrolling with error handling
- [Sub](sub.md) — Stateful scrolling with full control


## Choosing an Engine

### Quick Recommendation

| Use Case | Recommended Engine |
| -------- | ------------------ |
| Simple scroll-to-element | Cmd |
| Error handling or chaining scrolls | Task |
| Mid-scroll control, events, or state queries | Sub |

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


## Building Scroll Animations

All three engines use the same [Builder](../../api-reference.md) to configure scroll targets. The builder pipeline is engine-agnostic - you can switch engines without changing the builder code.

### Scroll Targets

Scroll to an element by ID, to a specific position, or to the top/bottom:

??? example "View Source Code"

    ```elm
    import Scroll.Builder as Scroll

    -- Scroll to element
    Scroll.forDocument
        >> Scroll.toElement "section-id"
        >> Scroll.build

    -- Scroll to position
    Scroll.forDocument
        >> Scroll.toY 500
        >> Scroll.build

    -- Scroll to top/bottom
    Scroll.forDocument
        >> Scroll.toTop
        >> Scroll.build
    ```

### Container Scrolling

By default, scrolls target the document. Use `forContainer` to scroll within a specific element:

```elm
ScrollTo.forContainer "scrollable-div"
    >> ScrollTo.toElement "item-in-container"
    >> ScrollTo.build
```

### Playback Settings

Set timing defaults for all scroll targets in a pipeline. Each engine provides its own `duration`, `speed`, `easing`, and `delay` functions for this purpose:

```elm
Scroll.animate ScrollMsg model.scrollState <|
    Scroll.duration 800
        >> Scroll.easing QuintOut
        >> ScrollTo.forDocument
        >> ScrollTo.toElement "section-1"
        >> ScrollTo.build
        >> ScrollTo.forDocument
        >> ScrollTo.toElement "section-2"
        >> ScrollTo.build
```

Both scroll targets inherit the 800ms duration and `QuintOut` easing.

### Per-Scroll Overrides

Individual scroll targets can override defaults using functions from the [Builder](../../api-reference.md) module:

```elm
ScrollTo.forDocument
    >> ScrollTo.toElement "section"
    >> ScrollTo.duration 500       -- override default duration
    >> ScrollTo.easing QuintOut    -- override default easing
    >> ScrollTo.withOffsetY 80     -- 80px offset (useful for fixed headers)
    >> ScrollTo.onBothAxes         -- scroll both X and Y (default is Y only)
    >> ScrollTo.build
```


## Timing & Refresh Rates

!!! warning "Cmd and Task timing is approximate"
    The Scroll Cmd and Scroll Task engines pre-calculate animation frames and execute them sequentially via `Task.sequence`. Because they lack access to the browser's vsync signal (`requestAnimationFrame`), the actual scroll duration depends on how fast the browser processes each DOM write - which varies by machine speed and display refresh rate.

    **On a 60Hz display**, a scroll that should take 3400ms (850px at 250px/sec) may complete in roughly half that time, because each `setViewport` call resolves faster than the 16.67ms frame budget.

    **On higher refresh rate displays** (120Hz, 144Hz), the discrepancy can be even larger.

    | Display | Approximate Effect |
    | ------- | ------------------ |
    | 60Hz | Completes faster than specified duration |
    | 120Hz | Completes significantly faster |
    | 144Hz | Completes significantly faster |

    If accurate timing matters, use the **[Scroll Sub](sub.md)** engine - it uses `onAnimationFrameDelta` (the browser's actual vsync signal) with delta-time interpolation, producing frame-rate independent animations that match the specified duration precisely.

    [Check your display's refresh rate](../../tools/fps-test.html){ target="_blank" } to see how it affects timing.


## Builder Quick Reference

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

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/).


## Next Steps

Explore each scroll engine in detail:

- [Cmd](cmd.md) — Fire-and-forget scrolling
- [Task](task.md) — Composable scrolling with error handling
- [Sub](sub.md) — Stateful scrolling with full control

Or, start with the `Cmd` Engine, then move through the Engines as your needs grow.

[Cmd Engine →](./cmd.md){ .md-button .md-button--primary }
