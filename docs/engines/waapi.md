# WAAPI Engine

The WAAPI Engine uses the Web Animations API via Elm ports and a JavaScript companion. It combines browser-native performance with programmatic control.

## Setup

### 1. Install the JavaScript package

=== "npm"
    ```bash
    npm install elm-animate-waapi
    ```

=== "yarn"
    ```bash
    yarn add elm-animate-waapi
    ```

### 2. Initialize in JavaScript

??? example "View Source Code"

    ```javascript
    import ElmAnimateWAAPI from 'elm-animate-waapi';

    const app = Elm.Main.init({
        node: document.getElementById('app')
    });

    ElmAnimateWAAPI.init(app.ports);
    ```

Or using a script tag (legacy/no-bundler):

??? example "View Source Code"

    ```html
    <script src="node_modules/elm-animate-waapi/dist/elm-animate-waapi.js"></script>
    <script>
        const app = Elm.Main.init({
            node: document.getElementById('app')
        });

        ElmAnimateWAAPI.init(app.ports);
    </script>
    ```

### 3. Define ports in Elm

The WAAPI engine uses just two ports - one for outgoing commands and one for incoming events:

??? example "View Source Code"

    ```elm
    port module Main exposing (main)

    import Json.Encode


    -- Outgoing port (Elm → JS): sends all animation commands
    port waapiCommand : Json.Encode.Value -> Cmd msg


    -- Incoming port (JS → Elm): receives all animation events
    port waapiEvent : (Json.Encode.Value -> msg) -> Sub msg
    ```

## Basic Usage

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/WAAPI/BasicUsage/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/WAAPI/BasicUsage/index.html){ .md-button target="_blank" }

## Running Animations

### Fire-and-Forget

For one-shot animations where you don't need to track state, use `fireAndForget`:

??? example "View Source Code"

    ```elm
    simpleButtonHover : Cmd msg
    simpleButtonHover =
        WAAPI.fireAndForget waapiCommand <|
            Translate.for "button"
                >> Translate.fromZ 0
                >> Translate.toZ 10
                >> Translate.duration 500
                >> Translate.build
    ```

Fire-and-forget is useful when you don't need chaining, state queries, or animation controls.

### State-Tracked

Use `animate` when you need to query animation state, control playback (pause, resume, stop, reset, restart), or chain animations that continue from the previous end state:

??? example "View Source Code"

    ```elm
    GotShowBox ->
        let
            ( newAnimState, cmd ) =
                WAAPI.animate model.animState fadeIn
        in
        ( { model | animState = newAnimState }, cmd )

    GotHideBox ->
        let
            ( newAnimState, cmd ) =
                WAAPI.animate model.animState fadeOut
        in
        ( { model | animState = newAnimState }, cmd )
    ```

The `animate` function takes your current `AnimState` and an animation pipeline, returning a new `AnimState` and a `Cmd` to send to JavaScript.

## Initialization

Create an `AnimState` using `init`:

??? example "Empty State"

    ```elm
    type alias Model =
        { animState : WAAPI.AnimState Msg }

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = WAAPI.init waapiCommand waapiEvent [] }
        , Cmd.none
        )
    ```

You can also initialize with starting property values:

??? example "With Initial Values"

    ```elm
    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                WAAPI.init waapiCommand waapiEvent <|
                    [ Opacity.init "my-element" 0
                    , Translate.initXY "my-element" 100 50
                    ]
          }
        , Cmd.none
        )
    ```

    Use `WAAPI.attributes` in your view to apply these values as CSS inline styles.



## Interrupting Animations

Start a new animation at any time — the WAAPI Engine handles smooth transitions:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/WAAPI/InterruptingAnimations/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/WAAPI/InterruptingAnimations/index.html){ .md-button target="_blank" }

The new animation starts from the current position, not the original start position.


## Event Handling

The WAAPI engine uses a subscription-based event pattern. The `subscriptions` function handles incoming messages from JavaScript, and `update` processes them, returning the updated `AnimState` and an optional `AnimEvent`:

??? example "View Source Code"

    ```elm
    type Msg
        = GotWaapiMsg WAAPI.AnimMsg
        | ...


    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotWaapiMsg model.animState


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotWaapiMsg waapiMsg ->
                let
                    ( newAnimState, maybeEvent ) =
                        WAAPI.update waapiMsg model.animState
                in
                handleAnimationEvent maybeEvent { model | animState = newAnimState }

            ...


    handleAnimationEvent : Maybe WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent maybeEvent model =
        case maybeEvent of
            Just (WAAPI.Started elementId) ->
                -- Animation began playing
                ( model, Cmd.none )

            Just (WAAPI.Completed "box") ->
                -- The "box" element finished animating
                startNextAnimation model

            Just (WAAPI.Completed elementId) ->
                -- Some other element finished animating
                ( model, Cmd.none )

            Just (WAAPI.Paused elementId) ->
                -- Animation was paused
                ( model, Cmd.none )

            Just (WAAPI.Resumed elementId) ->
                -- Animation continued after pause
                ( model, Cmd.none )

            Just (WAAPI.Cancelled elementId) ->
                -- Animation was Cancelled (via stop or reset)
                ( model, Cmd.none )

            Just (WAAPI.Restarted elementId) ->
                -- Animation was restarted
                ( model, Cmd.none )

            Nothing ->
                -- Property update (no lifecycle event)
                ( model, Cmd.none )
    ```

!!! info "When events fire"

    | Event | Fires when... |
    | ----- | ------------- |
    | `Started` | The animation begins playing |
    | `Completed` | The animation finishes |
    | `Paused` | The animation is paused via `pause` |
    | `Resumed` | The animation is resumed via `resume` |
    | `Cancelled` | The animation is Cancelled via `stop` or `reset` |
    | `Restarted` | The animation is restarted via `restart` |


## Animation Control

Control functions take the element ID and the current `AnimState`, returning the updated state and a command.

### Pause and Resume

??? example "View Source Code"

    ```elm
    type Msg
        = Pause
        | Resume


    update msg model =
        case msg of
            Pause ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.pause "box" model.animState
                in
                ( { model | animState = newAnimState }, cmd )

            Resume ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.resume "box" model.animState
                in
                ( { model | animState = newAnimState }, cmd )
    ```

### Stop Animation

Stop instantly jumps to the end state:

??? example "View Source Code"

    ```elm
    update msg model =
        case msg of
            Stop ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.stop "box" model.animState
                in
                ( { model | animState = newAnimState }, cmd )
    ```

### Reset Animation

Reset cancels and returns to the start state:

??? example "View Source Code"

    ```elm
    update msg model =
        case msg of
            Reset ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.reset "box" model.animState
                in
                ( { model | animState = newAnimState }, cmd )
    ```

### Restart Animation

Restart replays the animation from the beginning:

??? example "View Source Code"

    ```elm
    update msg model =
        case msg of
            Restart ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.restart "box" model.animState
                in
                ( { model | animState = newAnimState }, cmd )
    ```

## Default Settings

Set (optional) defaults for all properties:

- Timing: use `speed` or `duration`
- Easing
- Delay

These settings will be used for all property animations.

??? example "View Source Code"

    ```elm
    let
        ( newAnimState, cmd ) =
            WAAPI.animate model.animState <|
                WAAPI.duration 500
                    >> WAAPI.easing QuintOut
                    >> WAAPI.delay 100
                    >> myAnimation
    in
    ( { model | animState = newAnimState }, cmd )
    ```

Individual properties can override them:

??? example "View Source Code"

    ```elm
    myAnimation builder =
        builder
            |> Opacity.for "box"
            |> Opacity.duration 1000  
            |> Opacity.easing SineOut 
            |> Opacity.delay 0
            |> Opacity.build
    ```

## Querying Animation State

Check whether animations are running or complete:

??? example "View Source Code"

    ```elm
    view model =
        div []
            [ if WAAPI.anyRunning model.animState then
                text "Animating..."
              else
                text "Complete"
            ]
    ```

You can also query specific elements:

??? example "View Source Code"

    ```elm
    view model =
        let
            boxStatus =
                if WAAPI.isRunning "box" model.animState then
                    "Box is animating"
                else
                    case WAAPI.isComplete "box" model.animState of
                        Just True ->
                            "Box animation complete"

                        Just False ->
                            "Box animation not started"

                        Nothing ->
                            "No animation for box"
        in
        div [] [ text boxStatus ]
    ```

## Querying Property Values

Query the start, end, or current values of animated properties:

??? example "View Source Code"

    ```elm
    view model =
        let
            positionText =
                case WAAPI.getCurrentTranslate "box" model.animState of
                    Just { x, y, z } ->
                        "Position: " ++ String.fromFloat x ++ ", " ++ String.fromFloat y

                    Nothing ->
                        "No translate animation"
        in
        div [] [ text positionText ]
    ```

Available getters:

| Property | Start | End | Current |
| -------- | ----- | --- | ------- |
| Translate | `getStartTranslate` | `getEndTranslate` | `getCurrentTranslate` |
| Scale | `getStartScale` | `getEndScale` | `getCurrentScale` |
| Rotate | `getStartRotate` | `getEndRotate` | `getCurrentRotate` |
| Opacity | `getStartOpacity` | `getEndOpacity` | `getCurrentOpacity` |
| Size | `getStartSize` | `getEndSize` | `getCurrentSize` |
| Background Color | `getStartBackgroundColor` | `getEndBackgroundColor` | `getCurrentBackgroundColor` |

!!! tip "Mid-flight values"
    Unlike CSS-based engines, the "current" getters return the actual animated value at any point during the animation.

## Transform Ordering

CSS transforms are applied left-to-right. The default order is **Translate → Rotate → Scale**, meaning translate applies first, then rotate, then scale.

### Custom Transform Order

Use `animateOrder` for state-tracked animations:

??? example "Show Source Code"

    ```elm
    import Anim.Engine.WAAPI as WAAPI exposing (TransformOrder(..))

    WAAPI.animateOrder [ Rotate, Translate, Scale ] model.animState <|
        moveLeft >> scaleDown >> spin -- The order here is irrelevant
    ```

Use `fireAndForgetOrder` for fire-and-forget animations:

??? example "Show Source Code"

    ```elm
    import Anim.Engine.WAAPI as WAAPI exposing (TransformOrder(..))

    WAAPI.fireAndForgetOrder [ Rotate, Translate, Scale ] waapiCommand <|
        moveLeft >> scaleDown >> spin -- The order here is irrelevant
    ```

Both apply **Rotate → Translate → Scale** (rotate first, translate second, scale last).

### Transform Order Values

- `Translate` - Translation (movement)
- `Rotate` - Rotation
- `Scale` - Scaling

### Auto-Completion

Any missing transforms are automatically appended in the default order. For example, `[Scale]` becomes `[Scale, Translate, Rotate]`.

## 3D Transforms and Perspective

The WAAPI Engine fully supports 3D animations. See [3D Animations](../concepts/3d.md) for how to define 3D transforms.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState msg` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animation configurations |
| `AnimMsg` | Opaque message type for WAAPI subscription events |
| `AnimEvent` | Lifecycle events: `Started String`, `Completed String`, `Paused String`, `Resumed String`, `Cancelled String`, `Restarted String` |

### Core Functions

| Function | Type | Description |
| -------- | ---- | ----------- |
| `init` | `(Value -> Cmd msg) -> ((Value -> msg) -> Sub msg) -> List (AnimBuilder -> AnimBuilder) -> AnimState msg` | Create initial animation state with ports and optional property initializers. |
| `animate` | `AnimState msg -> (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )` | Execute animation with state tracking |
| `animateOrder` | `List TransformOrder -> AnimState msg -> (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )` | Execute animation with custom transform order |
| `fireAndForget` | `(Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Execute animation without state tracking |
| `fireAndForgetOrder` | `List TransformOrder -> (Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Fire-and-forget with custom transform order |
| `update` | `AnimMsg -> AnimState msg -> ( AnimState msg, Maybe AnimEvent )` | Process WAAPI messages and maybe return event |
| `subscriptions` | `(AnimMsg -> msg) -> AnimState msg -> Sub msg` | Subscribe to WAAPI events from JavaScript |

### View Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `String -> AnimState msg -> List (Html.Attribute msg)` | Apply initial animation state as inline styles |

### Control Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `pause` | `String -> AnimState msg -> ( AnimState msg, Cmd msg )` | Pause animation |
| `resume` | `String -> AnimState msg -> ( AnimState msg, Cmd msg )` | Resume paused animation |
| `stop` | `String -> AnimState msg -> ( AnimState msg, Cmd msg )` | Jump to end state |
| `reset` | `String -> AnimState msg -> ( AnimState msg, Cmd msg )` | Return to start state |
| `restart` | `String -> AnimState msg -> ( AnimState msg, Cmd msg )` | Replay from beginning |
| `onResize` | `List { elementId, elementSize, oldContainerSize, newContainerSize } -> AnimState msg -> ( AnimState msg, Cmd msg )` | Handle container resize |

### State Query Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `anyRunning` | `AnimState msg -> Bool` | Check if any animations are running |
| `isRunning` | `String -> AnimState msg -> Bool` | Check if a specific element is animating |
| `allComplete` | `AnimState msg -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `String -> AnimState msg -> Maybe Bool` | Check if a specific element's animation is complete |

### Property Query Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `getStartTranslate` | `String -> AnimState msg -> Maybe { x, y, z }` | Get start translate value |
| `getEndTranslate` | `String -> AnimState msg -> Maybe { x, y, z }` | Get end translate value |
| `getCurrentTranslate` | `String -> AnimState msg -> Maybe { x, y, z }` | Get current translate value |
| `getStart*` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get start value |
| `getEnd*` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get end value |
| `getCurrent*` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get current value |

### Default Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

For complete API details, see the [Anim.Engine.WAAPI](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI) documentation.

## Next Steps

The Scroll Engine which provides smooth scrolling animations for the Document or containers.

[Scroll Engine →](scroll.md){ .md-button .md-button--primary }
