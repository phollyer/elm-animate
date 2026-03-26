# Scroll Cmd Engine

This page focuses on what makes this engine different, read [Scroll Engines Overview](overview.md) for features that are shared across all Scroll engines.

The Scroll Cmd Engine provides fire-and-forget scrolling. Call `animate` and the scroll happens — no state management needed.


## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Engine.Scroll.Cmd as Scroll
    import Anim.Engine.Scroll.Builder as ScrollTo

    type Msg
        = ScrollComplete
        | ...

    scrollToElement : String -> Cmd Msg
    scrollToElement elementId =
        Scroll.animate ScrollComplete <|
            ScrollTo.forDocument
                >> ScrollTo.toElement elementId
                >> ScrollTo.build
    ```


## How To Use

**Single scroll:**

1. Configure one scroll target in your `AnimBuilder` pipeline
2. Call `animate` with your completion message
3. Handle the completion message in your update function

**Multiple concurrent scrolls:**

1. Configure multiple scroll targets in the same `AnimBuilder` pipeline
2. Call `animate` with your completion message
3. Handle multiple completion messages (one per target) in your update function


## Under The Hood

??? info "How Cmd Execution Works"

    **Single scroll target:**

    1. DOM queries retrieve current scroll position and target element position
    2. Distance is calculated from current to target position
    3. Animation steps are pre-calculated based on distance, timing and easing
    4. Animation steps are sequenced into a `Task` chain
    5. `Task` chain is converted to a `Cmd` via `Task.attempt`
    6. Elm runtime receives the `Cmd` and executes each step in the `Task` chain in sequence
    7. Completion message fires with target identifier - errors are silently ignored

    **Multiple scroll targets:**

    - Each scroll is independently converted to a `Cmd` (following steps 1-5 above)
    - All `Cmd`s are `Cmd.batch`ed into a single `Cmd`
    - Elm runtime receives the single `Cmd` and executes all scrolls concurrently
    - Browser's rendering engine handles all simultaneous scroll animations in parallel
    - Each scroll fires the completion message independently as it finishes - errors are silently ignored

    **Completion behavior:**

    - The completion message fires when the scroll animation finishes (success or failure)
    - With multiple targets, the message fires once per target as each scroll completes
    - The `String` parameter identifies the target: element ID for element targets, or a description like "document:top" for position targets


## API Quick Reference

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `animate` | `msg -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Fire-and-forget scroll |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (px/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

For complete API details, see the [Anim.Engine.Scroll.Cmd](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Scroll-Cmd) documentation.


## Next Steps

Need error handling or task composition?

[Scroll Task Engine →](task.md){ .md-button .md-button--primary }

Need state tracking, events, or mid-scroll control?

[Scroll Sub Engine →](sub.md){ .md-button .md-button--primary }
