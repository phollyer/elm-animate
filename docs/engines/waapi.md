# WAAPI Engine

The WAAPI Engine uses the Web Animations API via Elm ports and a JavaScript companion. It combines browser-native performance with programmatic control.

## When to Use

✅ **Best for:**

- Complex animations needing both performance and control
- Pause, resume, reverse, and seek functionality
- Many simultaneous element animations
- When you need browser-native rendering with JavaScript control

❌ **Consider other engines when:**

- You want to avoid JavaScript dependencies (use CSS or Sub)
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

```javascript
import { initElmAnimate } from 'elm-animate-waapi';

const app = Elm.Main.init({
    node: document.getElementById('app')
});

initElmAnimate(app);
```

### 3. Define ports in Elm

```elm
port module Main exposing (main)

import Anim.Engine.WAAPI as WAAPI


-- Outgoing ports (Elm → JS)
port animateElements : WAAPI.PortValue -> Cmd msg
port pauseAnimation : String -> Cmd msg
port resumeAnimation : String -> Cmd msg
port cancelAnimation : String -> Cmd msg


-- Incoming ports (JS → Elm)
port onAnimationStart : (WAAPI.AnimationEvent -> msg) -> Sub msg
port onAnimationEnd : (WAAPI.AnimationEvent -> msg) -> Sub msg
port onAnimationCancel : (WAAPI.AnimationEvent -> msg) -> Sub msg
```

## Basic Usage

```elm
type alias Model =
    { animState : WAAPI.AnimState }


type Msg
    = StartAnimation
    | AnimationStarted WAAPI.AnimationEvent
    | AnimationEnded WAAPI.AnimationEvent


init : ( Model, Cmd Msg )
init =
    ( { animState = WAAPI.init }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartAnimation ->
            let
                ( newAnimState, portValue ) =
                    model.animState
                        |> WAAPI.builder
                        |> slideIn
                        |> WAAPI.animate
            in
            ( { model | animState = newAnimState }
            , animateElements portValue
            )

        AnimationStarted event ->
            ( { model | animState = WAAPI.handleStart event model.animState }
            , Cmd.none
            )

        AnimationEnded event ->
            ( { model | animState = WAAPI.handleEnd event model.animState }
            , Cmd.none
            )


slideIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
slideIn builder =
    builder
        |> Translate.for "box"
        |> Translate.fromX -100
        |> Translate.toX 0
        |> Translate.duration 500
        |> Translate.build


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onAnimationStart AnimationStarted
        , onAnimationEnd AnimationEnded
        , onAnimationCancel AnimationEnded
        ]


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

## Animation Control

### Pause and Resume

```elm
type Msg
    = Pause
    | Resume


update msg model =
    case msg of
        Pause ->
            ( model, pauseAnimation "box" )

        Resume ->
            ( model, resumeAnimation "box" )
```

### Cancel Animation

```elm
type Msg
    = Cancel


update msg model =
    case msg of
        Cancel ->
            ( model, cancelAnimation "box" )
```

## Event Handling

The WAAPI Engine communicates animation lifecycle events through ports:

```elm
subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onAnimationStart AnimationStarted
        , onAnimationEnd AnimationEnded
        , onAnimationCancel AnimationCancelled
        ]


update msg model =
    case msg of
        AnimationStarted event ->
            -- event.elementId tells you which element started
            ( { model | animState = WAAPI.handleStart event model.animState }
            , Cmd.none
            )

        AnimationEnded event ->
            -- Animation completed normally
            ( { model | animState = WAAPI.handleEnd event model.animState }
            , Cmd.none
            )

        AnimationCancelled event ->
            -- Animation was interrupted
            ( { model | animState = WAAPI.handleCancel event model.animState }
            , Cmd.none
            )
```

## Global Settings

``` elm
( animState, portValue ) =
    model.animState
        |> WAAPI.builder
        |> WAAPI.duration 500
        |> WAAPI.easing QuintOut
        |> myAnimation
        |> WAAPI.animate
```

## 3D Transforms and Perspective

The CSS Engine fully supports 3D animations. See [3D Animations](../concepts/3d.md) for how to define 3D transforms.


## API Reference

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `AnimState` | Create initial animation state |
| `builder` | `AnimState -> AnimBuilder` | Get builder for defining animations |
| `animate` | `AnimBuilder -> ( AnimState, PortValue )` | Generate state and port value |

### Event Handlers

| Function | Description |
| ---------- | ------------- |
| `handleStart` | Update state when animation starts |
| `handleEnd` | Update state when animation ends |
| `handleCancel` | Update state when animation is cancelled |

### Global Functions

| Function | Description |
| ---------- | ------------- |
| `duration` | Set default duration (ms) |
| `speed` | Set default speed (px/sec) |
| `easing` | Set default easing function |
| `delay` | Set default delay (ms) |
| `perspective` | Set default 3D perspective |

### Port Types

| Type | Description |
| ------ | ------------- |
| `PortValue` | Value to send through animateElements port |
| `AnimationEvent` | Event received from JavaScript |

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI).
