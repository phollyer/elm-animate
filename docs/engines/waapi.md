# WAAPI Engine

The WAAPI Engine uses the Web Animations API via Elm ports and a JavaScript companion. It combines browser-native performance with programmatic control.

## When to Use

✅ **Best for:**

- Complex animations needing both performance and control
- Pause, resume, reset, and restart functionality
- Many simultaneous element animations
- When you need browser-native rendering with JavaScript control
- Animations requiring state tracking and querying

❌ **Consider other engines when you want:**

- to avoid JavaScript dependencies (use CSS or Sub)
- simple fire-and-forget animations (use CSS)

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

```javascript
import { init } from 'elm-animate-waapi';

const app = Elm.Main.init({
    node: document.getElementById('app')
});

init(app.ports);
```

Or using a script tag (legacy/no-bundler):

```html
<script src="node_modules/elm-animate-waapi/dist/elm-animate-waapi.js"></script>
<script>
    const app = Elm.Main.init({ node: document.getElementById('app') });
    ElmAnimateWAAPI.init(app.ports);
</script>
```

### 3. Define ports in Elm

The WAAPI engine uses just two ports - one for commands and one for events:

```elm
port module Main exposing (main)

import Json.Encode


-- Outgoing port (Elm → JS): sends all animation commands
port waapiCommand : Json.Encode.Value -> Cmd msg


-- Incoming port (JS → Elm): receives all animation events
port waapiEvent : (Json.Encode.Value -> msg) -> Sub msg
```

## Basic Usage

```elm
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Translate as Translate


type alias Model =
    { animState : WAAPI.AnimState }


type Msg
    = StartAnimation
    | GotWaapiUpdate ( WAAPI.AnimState, Maybe WAAPI.AnimationEvent )


init : ( Model, Cmd Msg )
init =
    ( { animState = WAAPI.init }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartAnimation ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate waapiCommand model.animState <|
                        \builder ->
                            builder
                                |> Translate.for "box"
                                |> Translate.fromX -100
                                |> Translate.toX 0
                                |> Translate.duration 500
                                |> Translate.build
            in
            ( { model | animState = newAnimState }, cmd )

        GotWaapiUpdate ( newAnimState, maybeEvent ) ->
            case maybeEvent of
                Just WAAPI.Completed ->
                    -- Animation finished, trigger next action
                    ( { model | animState = newAnimState }, Cmd.none )

                _ ->
                    -- Property updates or other events
                    ( { model | animState = newAnimState }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    waapiEvent (GotWaapiUpdate << WAAPI.decode model.animState)


view : Model -> Html Msg
view model =
    div
        [ id "box"
        , style "width" "100px"
        , style "height" "100px"
        , style "background" "blue"
        ]
        [ text "Hello!" ]
```

## Fire-and-Forget Animations

For simple animations that don't need state tracking:

```elm
startSimpleAnimation : Cmd msg
startSimpleAnimation =
    WAAPI.init
        |> WAAPI.builder
        |> Translate.for "box"
        |> Translate.toX 100
        |> Translate.duration 500
        |> Translate.build
        |> WAAPI.fireAndForget waapiCommand
```

## Animation Control

All control functions take the element ID and the port as arguments:

### Pause and Resume

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

```elm
update msg model =
    case msg of
        Stop ->
            ( model, WAAPI.stop "box" waapiCommand )
```

### Reset Animation

Reset cancels and returns to the start state, updating the `AnimState`:

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

## Event Handling

The WAAPI engine decodes events through a single subscription. The `decode` function returns the updated `AnimState` and an optional `AnimationEvent`:

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
                Just WAAPI.Started ->
                    -- Animation began playing
                    ( { model | animState = newAnimState }, Cmd.none )

                Just WAAPI.Completed ->
                    -- Animation finished naturally
                    ( { model | animState = newAnimState }, Cmd.none )

                Just WAAPI.Paused ->
                    -- Animation was paused
                    ( { model | animState = newAnimState }, Cmd.none )

                Just WAAPI.Resumed ->
                    -- Animation continued after pause
                    ( { model | animState = newAnimState }, Cmd.none )

                Just WAAPI.Canceled ->
                    -- Animation was canceled (via reset)
                    ( { model | animState = newAnimState }, Cmd.none )

                Just WAAPI.Restarted ->
                    -- Animation was restarted
                    ( { model | animState = newAnimState }, Cmd.none )

                Nothing ->
                    -- Property update (no lifecycle change)
                    ( { model | animState = newAnimState }, Cmd.none )
```

## Global Settings

Configure animation defaults using builder functions:

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

## Querying Animation State

The WAAPI engine provides functions to query animation status and current property values:

### Status Queries

```elm
-- Check if any animations are running
WAAPI.anyRunning model.animState

-- Check if a specific element is animating
WAAPI.isRunning "box" model.animState

-- Check if all animations have completed (returns Maybe Bool)
WAAPI.allComplete model.animState

-- Check if a specific element's animation completed
WAAPI.isComplete "box" model.animState
```

### Property Queries

Get current, start, or end values for animated properties:

```elm
-- Get current position during animation
WAAPI.getCurrentTranslate "box" model.animState
-- Returns: Maybe { x : Float, y : Float, z : Float }

-- Get start/end opacity
WAAPI.getStartOpacity "box" model.animState
WAAPI.getEndOpacity "box" model.animState

-- Get current background color
WAAPI.getCurrentBackgroundColor "box" model.animState
-- Returns: Maybe Color
```

## Initializing Properties

Set initial property values before animating:

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

## 3D Transforms

The WAAPI Engine fully supports 3D animations. See [3D Animations](../concepts/3d.md) for how to define 3D transforms.


## API Reference

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `AnimState` | Create initial animation state |
| `initProperties` | `(Value -> Cmd msg) -> List (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )` | Initialize properties without animation |
| `builder` | `AnimState -> AnimBuilder` | Create builder for defining animations |
| `animate` | `(Value -> Cmd msg) -> AnimState -> (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )` | Execute animation with state tracking |
| `fireAndForget` | `(Value -> Cmd msg) -> AnimBuilder -> Cmd msg` | Execute animation without state tracking |

### Control Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `pause` | `String -> (Value -> Cmd msg) -> Cmd msg` | Pause animation |
| `resume` | `String -> (Value -> Cmd msg) -> Cmd msg` | Resume paused animation |
| `stop` | `String -> (Value -> Cmd msg) -> Cmd msg` | Jump to end state |
| `reset` | `String -> (Value -> Cmd msg) -> AnimState -> ( AnimState, Cmd msg )` | Return to start state |
| `restart` | `String -> (Value -> Cmd msg) -> AnimState -> ( AnimState, Cmd msg )` | Replay from beginning |

### Event Handling

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `decode` | `AnimState -> Value -> ( AnimState, Maybe AnimationEvent )` | Decode port events |

### Configuration Functions

| Function | Description |
| ---------- | ------------- |
| `duration` | Set animation duration (ms) |
| `speed` | Set animation speed (px/sec) |
| `easing` | Set easing function |
| `delay` | Set animation delay (ms) |

### State Query Functions

| Function | Description |
| ---------- | ------------- |
| `anyRunning` | Check if any animations are running |
| `isRunning` | Check if specific element is animating |
| `allComplete` | Check if all animations completed |
| `isComplete` | Check if specific element's animation completed |
| `getCurrentTranslate` | Get current translate values |
| `getCurrentOpacity` | Get current opacity |
| `getCurrentScale` | Get current scale values |
| `getCurrentRotate` | Get current rotation values |

### Types

| Type | Description |
| ------ | ------------- |
| `AnimState` | Animation state container |
| `AnimBuilder` | Builder for configuring animations |
| `AnimationEvent` | Lifecycle events: `Started`, `Completed`, `Paused`, `Resumed`, `Canceled`, `Restarted` |

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI).
