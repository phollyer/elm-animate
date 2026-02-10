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
        const app = Elm.Main.init({ node: document.getElementById('app') });
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


## Fire-and-Forget Animations

For any animations that don't need state tracking:

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



## Interrupting Animations

Start a new animation at any time — the WAAPI Engine handles smooth transitions:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/WAAPI/InterruptingAnimations/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/WAAPI/InterruptingAnimations/index.html){ .md-button target="_blank" }

The new animation starts from the current position, not the original start position.


## Event Handling

The WAAPI engine uses a subscription-based event pattern. The `subscriptions` function handles incoming messages from JavaScript, and `update` processes them, returning the updated `AnimState` and a list of `AnimEvent`s:

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
                    ( newAnimState, events ) =
                        WAAPI.update waapiMsg model.animState
                in
                handleAnimationEvents events { model | animState = newAnimState }

            ...


    handleAnimationEvents : List WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvents events model =
        List.foldl handleSingleEvent ( model, Cmd.none ) events


    handleSingleEvent : WAAPI.AnimEvent -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
    handleSingleEvent event ( model, cmd ) =
        case event of
            WAAPI.Started elementId ->
                -- Animation began playing
                ( model, cmd )

            WAAPI.Completed "box" ->
                -- The "box" element finished animating
                ( model, Cmd.batch [ cmd, startNextAnimation ] )

            WAAPI.Completed elementId ->
                -- Some other element finished animating
                ( model, cmd )

            WAAPI.Paused elementId ->
                -- Animation was paused
                ( model, cmd )

            WAAPI.Resumed elementId ->
                -- Animation continued after pause
                ( model, cmd )

            WAAPI.Canceled elementId ->
                -- Animation was canceled (via reset)
                ( model, cmd )

            WAAPI.Restarted elementId ->
                -- Animation was restarted
                ( model, cmd )
    ```


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

## Querying Current Values

Get the current animated value for an element:

??? example "View Source Code"

    ```elm
    view model =
        let
            maybePosition =
                WAAPI.getCurrentTranslate "box" model.animState
        in
        div []
            [ case maybePosition of
                Just { x, y, z } ->
                    text ("Position: " ++ String.fromFloat x ++ ", " ++ String.fromFloat y)

                Nothing ->
                    text "Not animating"
            ]
    ```

## Animation State

Check if animations are running:

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

## Initializing Properties

Set initial property values when creating your `AnimState`. Use `WAAPI.attributes` in your view to apply these values as CSS inline styles:

??? example "View Source Code"

    ```elm
    init : ( Model, Cmd Msg )
    init =
        let
            initialAnimState =
                WAAPI.init waapiCommand waapiEvent
                    [ Translate.initXY "element-id" 100 50
                    , Opacity.init "element-id" 0
                    ]
        in
        ( { animState = initialAnimState }, Cmd.none )


    view : Model -> Html Msg
    view model =
        div
            (WAAPI.attributes "element-id" model.animState
                ++ [ id "element-id" ]
            )
            [ text "Content" ]
    ```

    **Note:** The `attributes` function handles applying initial values.

## 3D Transforms and Perspective

The WAAPI Engine fully supports 3D animations. See [3D Animations](../concepts/3d.md) for how to define 3D transforms.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState msg` | Tracks animations, their states, and the port commands |
| `AnimBuilder` | Carries all the animation configurations |
| `AnimMsg` | Opaque message type for WAAPI subscription events |
| `AnimEvent` | Lifecycle events: `Started String`, `Completed String`, `Paused String`, `Resumed String`, `Canceled String`, `Restarted String` |

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `(Value -> Cmd msg) -> ((Value -> msg) -> Sub msg) -> List (AnimBuilder -> AnimBuilder) -> AnimState msg` | Create initial animation state with ports and optional property initializers. |
| `animate` | `AnimState msg -> (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )` | Execute animation with state tracking |
| `fireAndForget` | `(Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Execute animation without state tracking |
| `update` | `AnimMsg -> AnimState msg -> ( AnimState msg, List AnimEvent )` | Process WAAPI messages and return events |
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

### Query Functions

| Function | Type | Description |
| ---------- | ----- | ------------- |
| `anyRunning` | `AnimState msg -> Bool` | Check if any animations are running |
| `isRunning` | `String -> AnimState msg -> Bool` | Check if specific element is animating |
| `allComplete` | `AnimState msg -> Maybe Bool` | Check if all animations completed |
| `isComplete` | `String -> AnimState msg -> Maybe Bool` | Check if specific element's animation completed |
| `getCurrentTranslate` | `String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }` | Get current translate position |
| `getStartRotate` | `String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }` | Get the start rotation |
| `getEndScale` | `String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }` | Get the target end scale |

### Default Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI).

## Next Steps

The Scroll Engine which provides smooth scrolling animations for the Document or containers.

[Scroll Engine →](scroll.md){ .md-button .md-button--primary }
