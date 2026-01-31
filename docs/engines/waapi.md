# WAAPI Engine

The WAAPI Engine uses the Web Animations API via Elm ports and a JavaScript companion. It combines browser-native performance with programmatic control.

## When to Use

✅ **For:**

- Complex animations needing both performance and control
- Pause, resume, reset, and restart functionality
- Many simultaneous element animations
- When you need browser-native rendering with JavaScript control
- Animations requiring state tracking and querying

❌ **Consider other engines for:**

- Avoiding JavaScript dependencies (use CSS or Sub)
- Simple fire-and-forget animations (use CSS)

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
        WAAPI.init
            |> WAAPI.builder
            |> Translate.for "button"
            |> Translate.fromZ 0
            |> Translate.toZ 10
            |> Translate.duration 500
            |> Translate.build
            |> WAAPI.fireAndForget waapiCommand
    ```

## Event Handling

The WAAPI engine decodes events through a single subscription. The `decode` function returns the updated `AnimState` and a `Maybe AnimationEvent`. Each event carries the `elementId` of the animated element:

??? example "View Source Code"

    ```elm
    type Msg
        = GotWaapiUpdate ( WAAPI.AnimState, Maybe WAAPI.AnimationEvent )


    subscriptions : Model -> Sub Msg
    subscriptions model =
        waapiEvent (GotWaapiUpdate << WAAPI.decode model.animState)


    update msg model =
        case msg of
            GotWaapiUpdate ( newAnimState, maybeEvent ) ->
                case maybeEvent of
                    Just (WAAPI.Started elementId) ->
                        -- Animation began playing for elementId
                        ( { model | animState = newAnimState }, Cmd.none )

                    Just (WAAPI.Completed "box") ->
                        -- The "box" element finished animating
                        ( { model | animState = newAnimState }, Cmd.none )

                    Just (WAAPI.Completed elementId) ->
                        -- Some other element finished animating
                        ( { model | animState = newAnimState }, Cmd.none )

                    Just (WAAPI.Paused elementId) ->
                        -- Animation was paused for elementId
                        ( { model | animState = newAnimState }, Cmd.none )

                    Just (WAAPI.Resumed elementId) ->
                        -- Animation continued after pause for elementId
                        ( { model | animState = newAnimState }, Cmd.none )

                    Just (WAAPI.Canceled elementId) ->
                        -- Animation was canceled (via reset) for elementId
                        ( { model | animState = newAnimState }, Cmd.none )

                    Just (WAAPI.Restarted elementId) ->
                        -- Animation was restarted for elementId
                        ( { model | animState = newAnimState }, Cmd.none )

                    Nothing ->
                        -- Property update (no lifecycle change)
                        ( { model | animState = newAnimState }, Cmd.none )
    ```


## Animation Control

All control functions take the element ID and the port as arguments.

### Pause and Resume

??? example "View Source Code"

    ```elm
    type Msg
        = Pause
        | Resume


    update msg model =
        case msg of
            Pause ->
                ( model, WAAPI.pause "box" waapiCommand )

            Resume ->
                ( model, WAAPI.resume "box" waapiCommand )
    ```

### Stop Animation

Stop instantly jumps to the end state:

??? example "View Source Code"

    ```elm
    update msg model =
        case msg of
            Stop ->
                ( model, WAAPI.stop "box" waapiCommand )
    ```

### Reset Animation

Reset cancels and returns to the start state, updating the `AnimState`:

??? example "View Source Code"

    ```elm
    update msg model =
        case msg of
            Reset ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.reset "box" waapiCommand model.animState
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
                        WAAPI.restart "box" waapiCommand model.animState
                in
                ( { model | animState = newAnimState }, cmd )
    ```

## Global Settings

Set (optional) defaults for all properties:

- Timing: use `speed` or `duration`
- Easing
- Delay

These settings will be used for all property animations.

??? example "View Source Code"

    ```elm
    let
        ( newAnimState, cmd ) =
            WAAPI.animate waapiCommand model.animState <|
                \builder ->
                    builder
                        |> WAAPI.duration 500
                        |> WAAPI.easing QuintOut
                        |> WAAPI.delay 100
                        |> myAnimation
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

Set initial property values before animating:

??? example "View Source Code"

    ```elm
    init : ( Model, Cmd Msg )
    init =
        let
            ( initialAnimState, initCmd ) =
                WAAPI.initProperties waapiCommand
                    [ Translate.initXY "element-id" 100 50
                    , Opacity.init "element-id" 1.0
                    ]
        in
        ( { animState = initialAnimState }, initCmd )
    ```

## 3D Transforms and Perspective

The WAAPI Engine fully supports 3D animations. See [3D Animations](../concepts/3d.md) for how to define 3D transforms.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animations configurations |
| `AnimationEvent` | Lifecycle events with elementId: `Started String`, `Completed String`, `Paused String`, `Resumed String`, `Canceled String`, `Restarted String` |

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `AnimState` | Create initial animation state |
| `initProperties` | `(Value -> Cmd msg) -> List (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )` | Initialize properties without animation |
| `builder` | `AnimState -> AnimBuilder` | Create builder for defining animations |
| `animate` | `(Value -> Cmd msg) -> AnimState -> (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )` | Execute animation with state tracking |
| `fireAndForget` | `(Value -> Cmd msg) -> AnimBuilder -> Cmd msg` | Execute animation without state tracking |
| `decode` | `AnimState -> Value -> ( AnimState, Maybe AnimationEvent )` | Decode port events |

### View Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `htmlAttributes` | `String -> AnimState -> List (Html.Attribute msg)` | Get HTML animation attributes |

### Control Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `pause` | `String -> (Value -> Cmd msg) -> Cmd msg` | Pause animation |
| `resume` | `String -> (Value -> Cmd msg) -> Cmd msg` | Resume paused animation |
| `stop` | `String -> (Value -> Cmd msg) -> Cmd msg` | Jump to end state |
| `reset` | `String -> (Value -> Cmd msg) -> AnimState -> ( AnimState, Cmd msg )` | Return to start state |
| `restart` | `String -> (Value -> Cmd msg) -> AnimState -> ( AnimState, Cmd msg )` | Replay from beginning |

### Query Functions

| Function | Type | Description |
| ---------- | ----- | ------------- |
| `anyRunning` | `AnimState -> Bool` | Check if any animations are running |
| `isRunning` | `String -> AnimState -> Bool` | Check if specific element is animating |
| `allComplete` | `AnimState -> Maybe Bool` | Check if all animations completed |
| `isComplete` | `String -> AnimState -> Maybe Bool` | Check if specific element's animation completed |
| `getCurrentTranslate` | `String -> AnimState -> Maybe { x : Float, y : Float, z : Float }` | Get current translate position |
| `getStartRotate` | `String -> AnimState -> Maybe { x : Float, y : Float, z : Float }` | Get the start rotation |
| `getEndScale` | `String -> AnimState -> Maybe { x : Float, y : Float, z : Float }` | Get the target end scale |

### Global Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI).
