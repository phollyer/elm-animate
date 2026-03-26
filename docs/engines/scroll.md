# Scroll Engine

The Scroll Engine provides smooth scrolling to elements or positions. It shares the same builder API as the animation engines and offers three execution modules:

| Module | Import | Use When |
| ------ | ------ | -------- |
| **Scroll.Cmd** | `import Anim.Engine.Scroll.Cmd as Scroll` | Simple fire-and-forget scrolling |
| **Scroll.Task** | `import Anim.Engine.Scroll.Task as Scroll` | You need error handling or task composition |
| **Scroll.Sub** | `import Anim.Engine.Scroll.Sub as Scroll` | You need state tracking, events, or mid-scroll control |

All three modules use the same [Builder](../api-reference.md) for configuring scroll targets.

## Basic Usage

### Fire-and-Forget (Scroll.Cmd)

The simplest approach — just scroll and forget:

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

### With Error Handling (Scroll.Task)

Use Tasks for composable operations with error handling:

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

### With State Tracking (Scroll.Sub)

For full control with mid-scroll updates:

??? example "View Source Code"

    ```elm
    import Anim.Engine.Scroll.Sub as Scroll
    import Anim.Engine.Scroll.Builder as ScrollTo

    type alias Model =
        { scrollState : Scroll.AnimState }

    type Msg
        = ScrollToSection
        | ScrollMsg Scroll.AnimMsg

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollToSection ->
                let
                    ( newState, cmd ) =
                        Scroll.animate ScrollMsg model.scrollState <|
                            ScrollTo.forDocument
                                >> ScrollTo.toElement "target-section"
                                >> ScrollTo.build
                in
                ( { model | scrollState = newState }, cmd )

            ScrollMsg scrollMsg ->
                let
                    ( newState, _, cmd ) =
                        Scroll.update ScrollMsg scrollMsg model.scrollState
                in
                ( { model | scrollState = newState }, cmd )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Scroll.subscriptions ScrollMsg model.scrollState
    ```

## Scroll Targets

All target functions are in the [Builder](../api-reference.md) module.

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

Set (optional) defaults for all scroll actions. Each engine module has its own `duration`, `speed`, `easing`, and `delay` functions for global defaults. These are chained before the first scroll target.

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

Individual scroll actions can have their own settings that override global defaults. These are set in the [Builder](../api-reference.md) module.

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

## Error Handling

The `Scroll.Task` module provides typed errors when scroll operations fail:

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

## Timing & Refresh Rates

!!! warning "Cmd and Task timing is approximate"
    The `Scroll.Cmd` and `Scroll.Task` modules pre-calculate animation frames and execute them sequentially via `Task.sequence`. Because they lack access to the browser's vsync signal (`requestAnimationFrame`), the actual scroll duration depends on how fast the browser processes each DOM write — which varies by machine speed and display refresh rate.

    **On a 60Hz display**, a scroll that should take 3400ms (850px at 250px/sec) may complete in roughly half that time, because each `setViewport` call resolves faster than the 16.67ms frame budget.

    **On higher refresh rate displays** (120Hz, 144Hz), the discrepancy can be even larger.

    | Display | Approximate Effect |
    | ------- | ------------------ |
    | 60Hz | Completes faster than specified duration |
    | 120Hz | Completes significantly faster |
    | 144Hz | Completes significantly faster |

    If accurate timing matters, use **Scroll.Sub** — it uses `onAnimationFrameDelta` (the browser's actual vsync signal) with delta-time interpolation, producing frame-rate independent animations that match the specified duration precisely.

    [Check your display's refresh rate](../tools/fps-test.html){ target="_blank" } to see how it affects timing.

## API Quick Reference

### Scroll.Cmd

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `animate` | `msg -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Fire-and-forget scroll |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (px/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

### Scroll.Task

| Function / Type | Type | Description |
| ---------- | ------ | ------------- |
| `animate` | `(AnimBuilder -> AnimBuilder) -> Task ScrollError ScrollOk` | Composable scroll with error handling |
| `ScrollError` | type | Error with containerId, targetElementId, domError |
| `ScrollOk` | type alias | Success with containerId, targetElementId, targetDescription |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (px/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

### Scroll.Sub

| Function / Type | Type | Description |
| ---------- | ------ | ------------- |
| `AnimState` | type alias | Scroll animation state for your model |
| `AnimMsg` | type alias | Opaque message type |
| `AnimEvent` | type | `Started`, `Ended`, `Progress`, `Stopped`, `Paused`, `Resumed`, `Restarted` |
| `init` | `AnimState` | Create initial state |
| `animate` | `(AnimMsg -> msg) -> AnimState -> (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )` | Trigger stateful scroll |
| `update` | `(AnimMsg -> msg) -> AnimMsg -> AnimState -> ( AnimState, List AnimEvent, Cmd msg )` | Handle scroll messages |
| `subscriptions` | `(AnimMsg -> msg) -> AnimState -> Sub msg` | Animation frame subscription |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (px/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |
| `stop` / `stopContainer` | | Jump to target position |
| `pause` / `pauseContainer` | | Freeze at current position |
| `resume` / `resumeContainer` | | Continue paused scroll |
| `reset` / `resetContainer` | | Jump to start position |
| `restart` / `restartContainer` | | Reset and replay |
| `anyRunning` | `AnimState -> Maybe Bool` | Check if any scrolls are running |
| `isRunning` | `String -> AnimState -> Maybe Bool` | Check specific container |
| `getPosition` | `String -> AnimState -> Maybe { x : Float, y : Float }` | Current scroll position |
| `getPositionX` | `String -> AnimState -> Maybe Float` | Current X position |
| `getPositionY` | `String -> AnimState -> Maybe Float` | Current Y position |

### Builder (Scroll.Builder)

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

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Scroll).

---

## How To Use

You can configure and execute single or multiple scroll animations using any of the three execution methods.

=== "Cmd (Fire-and-Forget)"

    **Single scroll:**

    1. Configure one scroll target in your `AnimBuilder` pipeline
    2. Call `toCmd` with your completion message constructor
    3. Handle the completion message in your update function

    **Multiple concurrent scrolls:**

    1. Configure multiple scroll targets in the same `AnimBuilder` pipeline
    2. Call `toCmd` with your completion message constructor
    3. Handle multiple completion messages (one per target) in your update function

=== "Task (With Error Handling)"

    **Single scroll:**

    1. Configure one scroll target in your `AnimBuilder` pipeline
    2. Call `toTask` to get a `Task ScrollError ScrollOk`
    3. Convert to `Cmd` with `Task.attempt`
    4. Handle the `Result ScrollError ScrollOk` in your update function

    **Multiple sequential scrolls:**

    1. Configure multiple scroll targets in the same `AnimBuilder` pipeline
    2. Call `toTask` to get a `Task ScrollError ScrollOk`
    3. Convert to `Cmd` with `Task.attempt` (scrolls execute one after another)
    4. Handle the result in your update function (single `ScrollOk` for last successful scroll, or `ScrollError` for first error - subsequent scrolls not attempted)

    **Multiple concurrent scrolls with individual error handling:**

    1. Create separate `AnimBuilder`s for each scroll target
    2. Convert each to a `Task` with `toTask`
    3. Convert each `Task` to a `Cmd` with `Task.attempt`
    4. Batch all `Cmd`s with `Cmd.batch`
    5. Handle individual `Result ScrollError ScrollOk` for each scroll in your update function

=== "Subscriptions (State Tracking)"

    **Single scroll:**

    1. Add `AnimState` to your model
    2. Add `subscriptions` to your subscriptions function
    3. Configure one scroll target in your `AnimBuilder` pipeline
    4. Call `animate` with your message constructor
    5. Store the returned `AnimState` in your model
    6. Handle animation messages in your update function with `update`

    **Multiple concurrent scrolls:**

    1. Add `AnimState` to your model
    2. Add `subscriptions` to your subscriptions function
    3. Configure multiple scroll targets in the same `AnimBuilder` pipeline
    4. Call `animate` with your message constructor
    5. Store the returned `AnimState` in your model
    6. Handle animation messages in your update function with `update`
    7. Use query functions to track individual scroll progress

---

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

??? info "How Subscription-based Animation Works"

    **Single scroll target:**

    1. DOM queries retrieve current scroll position and target element position
    2. Distance is calculated from current to target position
    3. Animation state is initialized with scroll configuration
    4. `AnimState` is updated with animation data
    5. Initial `Cmd` is returned to query DOM positions
    6. `subscriptions` listen for animation frame updates
    7. Each frame: calculates new position using delta-time and easing, then scrolls
    8. Animation continues until progress reaches 1.0

    **Multiple scroll targets:**

    - Each scroll independently goes through steps 1-7 above
    - All scroll animations are tracked in the same `AnimState`
    - `subscriptions` handle all animations simultaneously
    - All scroll animations run concurrently
    - Each animation can be queried independently during execution
    - Animations complete independently as they reach their targets

    **State management:**

    - Returns updated `AnimState` that must be stored in your model
    - Requires `subscriptions` to be active for animation to progress
    - Enables real-time queries during animation (position, duration, status)
    - Allows intervention and reaction to ongoing animations

