# Elm Animate

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling. Supports multiple animation engines and a unified, flexible scroll engine for both documents and containers.

## ✨ Features

- **Multiple Engines:** Choose the best engine for your use case.
- **Unified Fluent API:** Consistent builder pattern for all engines.
- **Composable, type-safe, and easy to integrate.**

---

## 🚦 Animation Engines

All animation engines use a unified builder API, so you can switch between them with minimal changes. They also support both 2D and 3D animations.

Here's a 3D [Position](Anim.Properties.Position) animation that can be used by all of the engines - without any changes to the animation itself:

```elm
-- move left by 50px
-- move up by 100px
-- zoom in by 300px - 1/3 of the distance from the camera
-- 2s animation (max-axis: 300px / 150px/s = 2s)
positionAnimation : AnimBuilder -> AnimBuilder
positionAnimation builder =
    builder
        |> Position.for "my-element"
        |> Position.perspective "my-element-container" 900
        |> Position.fromXYZ 100 200 0
        |> Position.toXYZ 50 100 300
        |> Position.speed 150
        |> Position.easing BounceOut
        |> Position.build
```

We will use this example animation in each of the Engine examples below.

---

### 1. `Anim.Engine.CSS` – Hardware-Accelerated CSS

- **Best for:** Simple, high-performance transitions.
- **API:** Generates CSS for browser-native transitions.

The CSS Engine will create both CSS Transforms and Keyframe Animations. Choose the one you want
in your view code.

```elm
-- Build

{ model | animations = 
    model.animations
        |> CSS.builder
        |> positionAnimation
        |> CSS.animate
}

-- View

-- For CSS Transforms
div 
    ( CSS.htmlAttributes "my-element" model.animations )
    [ text "CSS Animation!" ]

-- For Keyframe Animations

-- Place your `<style>` node anywhere in your DOM
div
    []
    [ CSS.keyframesStyleNode model.animations ]

-- Connect your element to the keyframe animation defined in the `<style>` node
div
    [CSS.animationStyleAttribute "my-element" model.animations]
    [ text "Animated Element" ]
```

---

### 2. `Anim.Engine.Sub` – Subscription-Based Control

- **Best for:** Full programmatic control, live values, mid-animation changes.
- **API:** Frame-based updates, requires subscriptions.

```elm
-- Build

{ model | animations = 
    model.animations
        |> Sub.builder
        |> positionAnimation
        |> Sub.animate
}

-- Update

type Msg 
    = AnimationMsg Sub.AnimationMsg
    | ...

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of 
        AnimationMsg animMsg ->
            ({ model | animations = Sub.update animMsg model.animations }
            , Cmd.none
            )

        ...

subscriptions : Model -> Sub Msg
subscriptions model = 
    Sub.subscriptions model.animations 
        |> Sub.map AnimationMsg

-- View

div 
    (Sub.htmlAttributes "my-element" model.animations)
    [ text "Subscription Animation!" ]
```

---

### 3. `Anim.Engine.WAAPI` – Web Animations API (via Ports)

- **Best for:** Complex, timeline-based, or native browser animations.
- **API:** Uses Elm ports to communicate with a JavaScript companion.

```elm
-- MyModule.elm
port MyModule exposing (..)

-- Port functions

port sendAnimationCommand : Encode.Value -> Cmd msg
port positionUpdates : (Decode.Value -> msg) -> Sub msg

-- Build 

buildAnimation : WAAPI.AnimState -> (WAAPI.AnimState, Json.Encode.Value)
buildAnimation animations =
    animations
        |> WAAPI.builder
        |> positionAnimation
        |> WAAPI.animate


-- Send to JS

sendAnimation : Model -> Cmd msg 
sendAnimation model =
    let
        (newAnimations, animationCmd) =
            buildAnimation model.animations
    in
    ({ model | animations = newAnimations }, animationCmd)

-- Receive updates

type Msg
    = ReceiveWAAPI Decode.Value
    | ...

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of 
        ReceiveWAAPI value ->
            { model | animations = WAAPI.update value model.animations }

        ...

subscriptions : Model -> Sub Msg
subscriptions model =
    positionUpdates ReceiveWAAPI 
```

---
## 🚦 Scroll Engine

### 4. `Anim.Engine.Scroll`

- **Document and container scrolling**
- **X, Y, or Both axes**
- **Offset configuration**
- **Subscription-based animation management**
- **Fire-and-forget (Cmd/Task) execution**

### Example: Animated Scroll to Element

```elm
model.scrollAnimations
    |> Scroll.builder
    |> Scroll.toElement "target-id"
    |> Scroll.onYAxisWithOffset 60
    |> Scroll.speed 800
    |> Scroll.animate
```

### Container Scrolling

```elm
model.scrollAnimations
    |> Scroll.builder
    |> Scroll.container "container-id"
    |> Scroll.toElement "target-id"
    |> Scroll.onBothAxes
    |> Scroll.animate
```

### Fire-and-Forget (Cmd/Task) Execution

For simple, one-off scrolls:

```elm
Scroll.init
    |> Scroll.builder
    |> Scroll.toElement "target-id"
    |> Scroll.onYAxis
    |> Scroll.toCmd ScrollCompleted
```

Or with error handling:

```elm
Scroll.init
    |> Scroll.builder
    |> Scroll.toElement "target-id"
    |> Scroll.onYAxis
    |> Scroll.toTask
    |> Task.attempt HandleScrollResult
```

### Subscriptions

For animated, stateful scrolling:

```elm
subscriptions : Model -> Sub Msg
subscriptions model =
    Scroll.subscriptions ScrollAnimationMsg model.scrollAnimations
```

---

## 🚀 Quick Start

Install the package:
```bash
elm install phollyer/elm-animate
```

For WAAPI support:
```bash
npm install elm-animate-waapi
```

---

## 📚 Examples

- Run `examples/index.html` for a dashboard of all demos.
- Explore `examples/src/ElmUI/` for categorized examples by engine and feature.

---

## 🙏 Credits

Based on [`linuss/smooth-scroll`](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/), expanded for multi-engine animation.

## 📄 License

BSD-3-Clause
