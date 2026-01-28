# Scroll Engine

The Scroll Engine provides smooth scrolling to elements or positions. It shares the same builder API as the animation engines.

## When to Use

✅ **Best for:**

- Smooth scroll to anchor links
- Scroll-to-top functionality
- Programmatic scrolling in response to events
- Single-page navigation

## Basic Usage

### Fire-and-Forget (Cmd)

The simplest approach — just scroll and forget:

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

```elm
ScrollAction.toElement "section-id"
```

### Scroll to Position

```elm
-- Scroll to specific Y position
ScrollAction.toY 500

-- Scroll to specific X position
ScrollAction.toX 200

-- Scroll to both
ScrollAction.toXY 200 500
```

### Scroll to Top/Bottom

```elm
-- Scroll to top
ScrollAction.toY 0

-- Scroll to bottom (use a large number or calculate document height)
ScrollAction.toY 99999
```

## Container Scrolling

By default, scrolls the document. To scroll within a container:

```elm
Scroll.init
    |> Scroll.builder
    |> ScrollAction.forContainer "scrollable-container"
    |> ScrollAction.toElement "item-in-container"
    |> ScrollAction.build
    |> Scroll.toCmd NoOp
```

## Configuration Options

### Offset

Add offset from the target (useful for fixed headers):

```elm
ScrollAction.toElement "section"
    |> ScrollAction.offset 80  -- 80px offset from top
```

### Duration

```elm
Scroll.init
    |> Scroll.builder
    |> Scroll.duration 800  -- 800ms scroll duration
    |> ScrollAction.toElement "section"
    |> ScrollAction.build
```

### Easing

```elm
Scroll.init
    |> Scroll.builder
    |> Scroll.easing QuintOut
    |> ScrollAction.toElement "section"
    |> ScrollAction.build
```

### Axis

Control which axis to scroll:

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

```elm
type ScrollError
    = ElementNotFound String      -- Target element not found
    | ContainerNotFound String    -- Container element not found
```

Handle errors with Tasks:

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

## API Reference

### Core Functions

| Function | Type | Description |
|----------|------|-------------|
| `init` | `AnimState` | Create initial state |
| `builder` | `AnimState -> AnimBuilder` | Get builder |
| `toCmd` | `msg -> AnimBuilder -> Cmd msg` | Execute as Cmd |
| `toTask` | `AnimBuilder -> Task ScrollError ScrollResult` | Execute as Task |
| `animate` | `(Msg -> msg) -> AnimBuilder -> ( AnimState, Cmd msg )` | Execute with state |

### ScrollAction Functions

| Function | Description |
|----------|-------------|
| `toElement` | Scroll to element by ID |
| `toX`, `toY`, `toXY` | Scroll to position |
| `forContainer` | Set scroll container |
| `offset` | Add offset from target |
| `axis` | Set scroll axis |
| `build` | Finalize scroll action |

### Global Settings

| Function | Description |
|----------|-------------|
| `duration` | Set scroll duration (ms) |
| `speed` | Set scroll speed (px/sec) |
| `easing` | Set easing function |

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Scroll).
