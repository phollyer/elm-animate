# Elm Animate

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling. Supports multiple animation engines and a unified, flexible scroll engine for both documents and containers.

## ✨ Features

- **Multiple Animation Engines:** Choose the best engine for your use case: CSS, Sub, WAAPI, or Scroll.
- **Unified Fluent API:** Consistent builder pattern for all engines.
- **Composable, type-safe, and easy to integrate.**

---

## 🚦 Engines

All engines use a unified builder API, so you can switch between them with minimal changes.

### 1. `Anim.Engine.CSS` – Hardware-Accelerated CSS

- **Best for:** Simple, high-performance transitions.
- **API:** Generates CSS for browser-native transitions.

```elm
model.animations
    |> CSS.builder
    |> CSS.toElement "my-element"
    |> CSS.toXY 100 200
    |> CSS.speed 150
    |> CSS.easing EaseInOut
    |> CSS.animate

div 
    [CSS.htmlAttributes "my-element" model.animations] 
    [ text "CSS Animation!" ]
```

---

### 2. `Anim.Engine.Sub` – Subscription-Based Control

- **Best for:** Full programmatic control, live values, mid-animation changes.
- **API:** Frame-based updates, requires subscriptions.

```elm
model.animations
    |> Sub.builder
    |> Sub.toElement "my-element"
    |> Sub.toXY 100 200
    |> Sub.duration 1000
    |> Sub.easing BounceOut
    |> Sub.animate

subscriptions model = 
    Sub.subscriptions model.animations 
        |> Sub.map AnimationMsg

div 
    [Sub.htmlAttributes "my-element" model.animations] 
    [ text "Subscription Animation!" ]
```

---

### 3. `Anim.Engine.WAAPI` – Web Animations API (via Ports)

- **Best for:** Complex, timeline-based, or native browser animations.
- **API:** Uses Elm ports to communicate with a JavaScript companion.

```elm
port sendAnimationCommand : Encode.Value -> Cmd msg
port positionUpdates : (Decode.Value -> msg) -> Sub msg

let
    (newAnimations, animationCmd) =
        model.animations
            |> WAAPI.builder
            |> WAAPI.toElement "my-element"
            |> WAAPI.toXY 100 200
            |> WAAPI.speed 200
            |> WAAPI.easing (Bezier 0.4 0 0.6 1)
            |> WAAPI.animate sendAnimationCommand
in
({ model | animations = newAnimations }, animationCmd)
```

---

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
