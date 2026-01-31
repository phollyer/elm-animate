# Scroll Engine

The Scroll Engine provides smooth scrolling to elements or positions. It shares the same builder API as the animation engines.

## When to Use

✅ **For:**

- Smooth scroll to anchor links
- Scroll-to-top functionality
- Programmatic scrolling in response to events
- Single-page navigation

## Basic Usage

### Fire-and-Forget (Cmd)

The simplest approach — just scroll and forget:

??? example "View Source Code"

    ```elm
    import Anim.Engine.Scroll as Scroll
    import Anim.Action.Scroll as ScrollAction


    type Msg
        = ScrollToSection
        | NoOp


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollToSection ->
                ( model
                , Scroll.init
                    |> Scroll.builder
                    |> ScrollAction.toElement "target-section"
                    |> ScrollAction.build
                    |> Scroll.toCmd NoOp
                )

            NoOp ->
                ( model, Cmd.none )
    ```

### With Error Handling (Task)

Use Tasks for composable operations with error handling:

??? example "View Source Code"

    ```elm
    import Task


    type Msg
        = ScrollToSection
        | ScrollResult (Result Scroll.ScrollError Scroll.ScrollResult)


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollToSection ->
                ( model
                , Scroll.init
                    |> Scroll.builder
                    |> ScrollAction.toElement "target-section"
                    |> ScrollAction.build
                    |> Scroll.toTask
                    |> Task.attempt ScrollResult
                )

            ScrollResult (Ok result) ->
                -- Scroll completed successfully
                ( model, Cmd.none )

            ScrollResult (Err error) ->
                case error of
                    Scroll.ElementNotFound elementId ->
                        -- Handle missing element
                        ( model, Cmd.none )

                    Scroll.ContainerNotFound containerId ->
                        -- Handle missing container
                        ( model, Cmd.none )
    ```

### With State Tracking (Subscriptions)

For full control with mid-scroll updates:

??? example "View Source Code"

    ```elm
    type alias Model =
        { scrollState : Scroll.AnimState }


    type Msg
        = ScrollToSection
        | ScrollMsg Scroll.Msg


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollToSection ->
                let
                    ( newState, cmd ) =
                        model.scrollState
                            |> Scroll.builder
                            |> ScrollAction.toElement "target-section"
                            |> ScrollAction.build
                            |> Scroll.animate ScrollMsg
                in
                ( { model | scrollState = newState }, cmd )

            ScrollMsg scrollMsg ->
                let
                    ( newState, cmd ) =
                        Scroll.update scrollMsg model.scrollState
                in
                ( { model | scrollState = newState }, Cmd.map ScrollMsg cmd )


    subscriptions : Model -> Sub Msg
    subscriptions model =
        Scroll.subscriptions ScrollMsg model.scrollState
    ```

## Scroll Targets

### Scroll to Element

??? example "View Source Code"

    ```elm
    ScrollAction.toElement "section-id"
    ```

### Scroll to Position

??? example "View Source Code"

    ```elm
    -- Scroll to specific Y position
    ScrollAction.toY 500

    -- Scroll to specific X position
    ScrollAction.toX 200

    -- Scroll to both
    ScrollAction.toXY 200 500
    ```

### Scroll to Top/Bottom

??? example "View Source Code"

    ```elm
    -- Scroll to top
    ScrollAction.toY 0

    -- Scroll to bottom (use a large number or calculate document height)
    ScrollAction.toY 99999
    ```

## Container Scrolling

By default, scrolls the document. To scroll within a container:

??? example "View Source Code"

    ```elm
    Scroll.init
        |> Scroll.builder
        |> ScrollAction.forContainer "scrollable-container"
        |> ScrollAction.toElement "item-in-container"
        |> ScrollAction.build
        |> Scroll.toCmd NoOp
    ```

## Global Settings

Set (optional) defaults for all scroll actions:

- Timing: use `speed` or `duration`
- Easing

These settings will be used for all scroll actions.

### Duration

??? example "View Source Code"

    ```elm
    Scroll.init
        |> Scroll.builder
        |> Scroll.duration 800  -- 800ms scroll duration
        |> ScrollAction.toElement "section"
        |> ScrollAction.build
    ```

### Easing

??? example "View Source Code"

    ```elm
    Scroll.init
        |> Scroll.builder
        |> Scroll.easing QuintOut
        |> ScrollAction.toElement "section"
        |> ScrollAction.build
    ```

## Scroll Action Settings

Individual scroll actions can have their own settings.

### Offset

Add offset from the target (useful for fixed headers):

??? example "View Source Code"

    ```elm
    ScrollAction.toElement "section"
        |> ScrollAction.offset 80  -- 80px offset from top
    ```

### Axis

Control which axis to scroll:

??? example "View Source Code"

    ```elm
    -- Vertical only (default)
    ScrollAction.axis Scroll.Y

    -- Horizontal only
    ScrollAction.axis Scroll.X

    -- Both axes
    ScrollAction.axis Scroll.Both
    ```

## Error Handling

The Scroll Engine can fail if elements don't exist:

??? example "View Source Code"

    ```elm
    type ScrollError
        = ElementNotFound String      -- Target element not found
        | ContainerNotFound String    -- Container element not found
    ```

Handle errors with Tasks:

??? example "View Source Code"

    ```elm
    Scroll.toTask
        |> Task.attempt
            (\result ->
                case result of
                    Ok _ ->
                        ScrollComplete

                    Err (Scroll.ElementNotFound id) ->
                        ShowError ("Element not found: " ++ id)

                    Err (Scroll.ContainerNotFound id) ->
                        ShowError ("Container not found: " ++ id)
            )
    ```

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks scroll state for subscription-based scrolling |
| `AnimBuilder` | Carries all the scroll configurations |
| `ScrollError` | Error types: `ElementNotFound`, `ContainerNotFound` |
| `ScrollResult` | Result of a completed scroll operation |
| `Axis` | Scroll axis: `X`, `Y`, `Both` |

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `AnimState` | Create initial state |
| `builder` | `AnimState -> AnimBuilder` | Get builder for defining scroll |
| `toCmd` | `msg -> AnimBuilder -> Cmd msg` | Execute as Cmd (fire-and-forget) |
| `toTask` | `AnimBuilder -> Task ScrollError ScrollResult` | Execute as Task (with error handling) |
| `animate` | `(Msg -> msg) -> AnimBuilder -> ( AnimState, Cmd msg )` | Execute with state tracking |
| `update` | `Msg -> AnimState -> ( AnimState, Cmd Msg )` | Update scroll state |
| `subscriptions` | `(Msg -> msg) -> AnimState -> Sub msg` | Animation frame subscription |

### ScrollAction Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `toElement` | `String -> AnimBuilder -> AnimBuilder` | Scroll to element by ID |
| `toX` | `Float -> AnimBuilder -> AnimBuilder` | Scroll to X position |
| `toY` | `Float -> AnimBuilder -> AnimBuilder` | Scroll to Y position |
| `toXY` | `Float -> Float -> AnimBuilder -> AnimBuilder` | Scroll to X and Y position |
| `forContainer` | `String -> AnimBuilder -> AnimBuilder` | Set scroll container |
| `offset` | `Float -> AnimBuilder -> AnimBuilder` | Add offset from target |
| `axis` | `Axis -> AnimBuilder -> AnimBuilder` | Set scroll axis |
| `build` | `AnimBuilder -> AnimBuilder` | Finalize scroll action |

### Global Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set scroll duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set scroll speed (px/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set easing function |

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Scroll).
