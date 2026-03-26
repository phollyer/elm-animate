# Scroll Task Engine

This page focuses on what makes this engine different, read [Scroll Engines Overview](overview.md) for features that are shared across all Scroll engines.

The Scroll Task Engine provides composable scrolling with typed error handling. Use it when you need to chain scroll operations, handle failures, or compose scrolls with other `Task`s.


## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Engine.Scroll.Task as Scroll exposing (AnimBuilder)
    import Anim.Engine.Scroll.Builder as ScrollTo
    import Task

    scrollToElement : AnimBuilder -> AnimBuilder
    scrollToElement =
        ScrollTo.forDocument
            >> ScrollTo.toElement "target-section"
            >> ScrollTo.build

    type Msg
        = ScrollResult (Result Scroll.ScrollError Scroll.ScrollOk)
        | ...

    performScroll : Cmd Msg
    performScroll =
        Scroll.animate scrollToElement
            |> Task.attempt ScrollResult
    ```


## Error Handling

The Scroll Task engine provides typed errors when scroll operations fail:

??? example "View Source Code"

    ```elm
    type ScrollError
        = ScrollError
            { containerId : String
            , targetElementId : Maybe String
            , domError : Dom.Error
            }
    ```

Handle errors with Tasks:

??? example "View Source Code"

    ```elm
    Scroll.animate
        (ScrollTo.forDocument
            >> ScrollTo.toElement "section"
            >> ScrollTo.build
        )
        |> Task.attempt
            (\result ->
                case result of
                    Ok _ ->
                        ScrollComplete

                    Err (Scroll.ScrollError error) ->
                        ShowError ("Scroll failed: " ++ Debug.toString error.domError)
            )
    ```


## How To Use

**Single scroll:**

1. Configure one scroll target in your `AnimBuilder` pipeline
2. Call `animate` to get a `Task ScrollError ScrollOk`
3. Convert to `Cmd` with `Task.attempt`
4. Handle the `Result ScrollError ScrollOk` in your update function

**Multiple sequential scrolls:**

1. Configure multiple scroll targets in the same `AnimBuilder` pipeline
2. Call `animate` to get a `Task ScrollError ScrollOk`
3. Convert to `Cmd` with `Task.attempt` (scrolls execute one after another)
4. Handle the result in your update function (single `ScrollOk` for last successful scroll, or `ScrollError` for first error - subsequent scrolls not attempted)

**Multiple concurrent scrolls with individual error handling:**

1. Create separate `AnimBuilder`s for each scroll target
2. Convert each to a `Task` with `animate`
3. Convert each `Task` to a `Cmd` with `Task.attempt`
4. Batch all `Cmd`s with `Cmd.batch`
5. Handle individual `Result ScrollError ScrollOk` for each scroll in your update function


## Under The Hood

??? info "How Task Execution Works"

    **Single scroll target:**

    1. DOM queries retrieve current scroll position and target element position
    2. Distance is calculated from current to target position
    3. Animation steps are pre-calculated based on distance, timing and easing
    4. Steps are sequenced into a `Task` chain
    5. `Task` is executed when converted to `Cmd` with `Task.attempt` or composed with other tasks
    6. Returns `ScrollOk` on success or `ScrollError` on failure

    **Multiple sequential scroll targets:**

    - Each scroll is processed sequentially (one after another, in pipeline order)
    - First scroll goes through steps 1-5, then second scroll begins
    - Returns `ScrollError` for the first scroll that fails, subsequent scrolls are not attempted
    - Returns `ScrollOk` only if all scrolls succeed, with details of the last completed scroll

    **Multiple concurrent scroll targets:**

    - Each scroll is independently converted to a `Task` (following steps 1-5 above)
    - Each `Task` is independently converted to a `Cmd` via `Task.attempt`
    - All `Cmd`s are `Cmd.batch`ed into a single `Cmd`
    - Elm runtime receives the single `Cmd` and executes all scrolls concurrently
    - Browser's rendering engine handles all simultaneous scroll animations in parallel
    - Each scroll returns its own `ScrollOk` or `ScrollError` independently

    **Error handling:**

    - Returns `ScrollOk` on success with details about the completed scroll
    - Returns `ScrollError` on failure with details about what failed
    - Errors typically occur when target elements don't exist in the DOM
    - Can be composed with other tasks using `Task.andThen`, `Task.map`, etc.


## API Quick Reference

| Function / Type | Type | Description |
| ---------- | ------ | ------------- |
| `animate` | `(AnimBuilder -> AnimBuilder) -> Task ScrollError ScrollOk` | Composable scroll with error handling |
| `ScrollError` | type | Error with containerId, targetElementId, domError |
| `ScrollOk` | type alias | Success with containerId, targetElementId, targetDescription |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (px/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

For complete API details, see the [Anim.Engine.Scroll.Task](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Scroll-Task) documentation.


## Next Steps

Need state tracking, events, or mid-scroll control?

[Scroll Sub Engine →](sub.md){ .md-button .md-button--primary }
