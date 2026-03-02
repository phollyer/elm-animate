# Scroll Engine

!!! info "Prerequisites"
    This page assumes you've completed [Getting Started](../getting-started/installation.md) and are familiar with [animation concepts](../concepts/controlling-animations.md) like the builder pattern, AnimState, and property initializers.

The Scroll Engine provides smooth scrolling to elements or positions. It shares the same builder API as the animation engines.

## Basic Usage

### Fire-and-Forget (Cmd)

The simplest approach — just scroll and forget:

??? example "View Source Code"

    ```elm
    import Anim.Engine.Scroll as Scroll

    type Msg
        = ScrollComplete String
        | ...

    scrollToElement : Cmd Msg
    scrollToElement =
        Scroll.toCmd ScrollComplete <|
            Scroll.forDocument
                >> Scroll.toElement "target-section"
                >> ... -- Continue configuring
                >> Scroll.build

    ```

### With Error Handling (Task)

Use Tasks for composable operations with error handling:

??? example "View Source Code"

    ```elm
    import Anim.Engine.Scroll as Scroll exposing (AnimBuilder)
    import Task


    scrollToElement : AnimBuilder -> AnimBuilder
    scrollToElement =
        Scroll.forDocument
            >> Scroll.toElement "target-section"
            >> ... -- Continue configuring
            >> Scroll.build
        


    performScroll : Cmd Msg
    performScroll =
        Scroll.toTask scrollToElement
            |> Task.attempt ScrollResult

    type Msg
        = ScrollResult (Result Scroll.ScrollError Scroll.ScrollOk)
        | ...

    ```

### With State Tracking (Subscriptions)

For full control with mid-scroll updates:

??? example "View Source Code"

    ```elm
    import Anim.Engine.Scroll as Scroll


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
                            Scroll.forDocument
                                >> Scroll.toElement "target-section"
                                >> ... -- Continue Configuring
                                >> Scroll.build
                in
                ( { model | scrollState = newState }, cmd )

            ScrollMsg scrollMsg ->
                let
                    ( newState, cmd ) =
                        Scroll.update ScrollMsg scrollMsg model.scrollState
                in
                ( { model | scrollState = newState }, cmd )


    subscriptions : Model -> Sub Msg
    subscriptions model =
        Scroll.subscriptions ScrollMsg model.scrollState
    ```

## Scroll Targets

### Scroll to Element

??? example "View Source Code"

    ```elm
    Scroll.forDocument
        >> Scroll.toElement "section-id"
        >> Scroll.build
    ```

### Scroll to Position

??? example "View Source Code"

    ```elm
    -- Scroll to specific Y position
    Scroll.forDocument
        >> Scroll.toY 500
        >> Scroll.build

    -- Scroll to specific X position
    Scroll.forDocument
        >> Scroll.toX 200
        >> Scroll.build

    -- Scroll to both
    Scroll.forDocument
        >> Scroll.toXY 200 500
        >> Scroll.build
    ```

### Scroll to Top/Bottom

??? example "View Source Code"

    ```elm
    -- Scroll to top
    Scroll.forDocument
        >> Scroll.toTop
        >> Scroll.build

    -- Scroll to bottom
    Scroll.forDocument
        >> Scroll.toBottom
        >> Scroll.build
    ```

## Container Scrolling

By default, scrolls the document. To scroll within a container:

??? example "View Source Code"

    ```elm
    Scroll.toCmd ScrollComplete <|
        Scroll.forContainer "scrollable-container"
            >> Scroll.toElement "item-in-container"
            >> Scroll.build
    ```

## Default Settings

Set (optional) defaults for all scroll actions:

- Timing: use `speed` or `duration`
- Easing

These settings will be used for all scroll actions.

### Duration

??? example "View Source Code"

    ```elm
    Scroll.toCmd ScrollComplete <|
        Scroll.defaultDuration 800  -- 800ms scroll duration
            >> Scroll.forDocument
            >> Scroll.toElement "section"
            >> Scroll.build
    ```

### Easing

??? example "View Source Code"

    ```elm
    Scroll.toCmd ScrollComplete <|
        Scroll.defaultEasing QuintOut
            >> Scroll.forDocument
            >> Scroll.toElement "section"
            >> Scroll.build
    ```

## Per-Scroll Settings

Individual scroll actions can have their own settings that override global defaults.

### Offset

Add offset from the target (useful for fixed headers):

??? example "View Source Code"

    ```elm
    Scroll.forDocument
        >> Scroll.toElement "section"
        >> Scroll.withOffsetY 80  -- 80px offset from top
        >> Scroll.build
    ```

### Axis

Control which axis to scroll:

??? example "View Source Code"

    ```elm
    -- Vertical only (default)
    Scroll.forDocument
        >> Scroll.toElement "section"
        >> Scroll.onYAxis
        >> Scroll.build

    -- Horizontal only
    Scroll.forDocument
        >> Scroll.toElement "section"
        >> Scroll.onXAxis
        >> Scroll.build

    -- Both axes
    Scroll.forDocument
        >> Scroll.toElement "section"
        >> Scroll.onBothAxes
        >> Scroll.build
    ```

### Per-Scroll Duration/Speed/Easing

??? example "View Source Code"

    ```elm
    Scroll.forDocument
        >> Scroll.toElement "section"
        >> Scroll.duration 500
        >> Scroll.easing QuintOut
        >> Scroll.build
    ```

## Error Handling

The Scroll Engine can fail if elements don't exist:

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
    Scroll.toTask
        (Scroll.forDocument
            >> Scroll.toElement "section"
            >> Scroll.build
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

!!! warning "Cmd and Task timing varies with display refresh rate"
    The `toCmd` and `toTask` functions calculate animation frames assuming a **60 FPS** display. On higher refresh rate displays (120Hz, 144Hz), animations complete faster than the specified duration:

    | Display | Duration Effect |
    | ------- | --------------- |
    | 60Hz | Matches specified duration |
    | 120Hz | Completes in **half** the time |
    | 144Hz | Completes in ~42% of the time |

    For consistent timing across all displays, use `animate` with subscriptions - it uses delta-time interpolation and is refresh-rate independent.

    [Check your display's refresh rate](../tools/fps-test.html){ target="_blank" } to see how it affects timing.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks scroll state for subscription-based scrolling |
| `AnimBuilder` | Carries all the scroll configurations |
| `AnimMsg` | Opaque message type for subscription-based scrolling |
| `ScrollBuilder` | Per-scroll configuration builder |
| `ScrollError` | Error record with containerId, targetElementId, and domError |
| `ScrollOk` | Result of a completed scroll operation |

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `AnimState` | Create initial state |
| `toCmd` | `(String -> msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Execute as Cmd (fire-and-forget) |
| `toTask` | `(AnimBuilder -> AnimBuilder) -> Task ScrollError ScrollOk` | Execute as Task (with error handling) |
| `animate` | `(AnimMsg -> msg) -> AnimState -> (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )` | Execute with state tracking |
| `update` | `(AnimMsg -> msg) -> AnimMsg -> AnimState -> ( AnimState, Cmd msg )` | Update scroll state |
| `subscriptions` | `(AnimMsg -> msg) -> AnimState -> Sub msg` | Animation frame subscription |

### Scroll Target Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `forDocument` | `AnimBuilder -> ScrollBuilder` | Start scroll in document |
| `forContainer` | `String -> AnimBuilder -> ScrollBuilder` | Start scroll in container |
| `toElement` | `String -> ScrollBuilder -> ScrollBuilder` | Scroll to element by ID |
| `toTop` | `ScrollBuilder -> ScrollBuilder` | Scroll to top |
| `toBottom` | `ScrollBuilder -> ScrollBuilder` | Scroll to bottom |
| `toX` | `Float -> ScrollBuilder -> ScrollBuilder` | Scroll to X position |
| `toY` | `Float -> ScrollBuilder -> ScrollBuilder` | Scroll to Y position |
| `toXY` | `Float -> Float -> ScrollBuilder -> ScrollBuilder` | Scroll to X and Y position |
| `build` | `ScrollBuilder -> AnimBuilder` | Finalize scroll action |

### Per-Scroll Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> ScrollBuilder -> ScrollBuilder` | Set duration (ms) for this scroll |
| `speed` | `Float -> ScrollBuilder -> ScrollBuilder` | Set speed (px/sec) for this scroll |
| `easing` | `Easing -> ScrollBuilder -> ScrollBuilder` | Set easing for this scroll |
| `delay` | `Int -> ScrollBuilder -> ScrollBuilder` | Set delay (ms) for this scroll |
| `onXAxis` | `ScrollBuilder -> ScrollBuilder` | Scroll X axis only |
| `onYAxis` | `ScrollBuilder -> ScrollBuilder` | Scroll Y axis only |
| `onBothAxes` | `ScrollBuilder -> ScrollBuilder` | Scroll both axes |
| `withOffsetX` | `Float -> ScrollBuilder -> ScrollBuilder` | Add X offset |
| `withOffsetY` | `Float -> ScrollBuilder -> ScrollBuilder` | Add Y offset |

### Default Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `defaultDuration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `defaultSpeed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (px/sec) |
| `defaultEasing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing |
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

