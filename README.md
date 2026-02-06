# Elm Animate

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling.

## ✨ Features

- **Multiple Engines:** Choose the best engine for your use case.
- **Unified Fluent API:** Consistent builder pattern for all engines.
- **Hardware-Accelerated:** GPU-accelerated transforms for smoother animations and better battery efficiency
(translate, rotate, scale, opacity).
- **Full 3D Support:** Transform elements in 3D space with XYZ positioning, multi-axis rotation, and configurable perspective for depth.
- **Composable, type-safe, and easy to integrate.**

---

## 🚦 Animation Engines

All animation Engines use a unified builder API, so you can switch between them with minimal changes.

Here's a simple [BackgroundColor](Anim-Property-BackgroundColor) animation.

```elm
backgroundColorAnimation : AnimBuilder -> AnimBuilder
backgroundColorAnimation builder =
    builder 
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.from (hex "#ff0000")
        |> BackgroundColor.to (elmColor Color.blue)
        |> BackgroundColor.duration 2000
        |> BackgroundColor.build
```

And here's a more complex, GPU rendered, 3D [Translate](Anim-Property-Translate) animation that zooms in on the element.

```elm
zoomInAnimation : AnimBuilder -> AnimBuilder
zoomInAnimation builder =
    builder
        |> Translate.for "my-element"
        |> Translate.perspective "my-element-container" 900
        |> Translate.fromXYZ 100 200 0
        |> Translate.toZ 300
        |> Translate.speed 150
        |> Translate.easing BounceOut
        |> Translate.build
```

Both can be used by all of the Engines - without any changes to the animations themselves. The quick-eyed out there will also have noticed that both animation functions share the same signature: `AnimBuilder -> AnimBuilder`. This means they can be chained together, and small single-purpose animations can be composed into larger, more complex ones.

Here's both of the animations being consumed by the [CSS Engine](Anim-Engine-CSS).

```elm
CSS.init
    |> CSS.builder
    |> backgroundAnimation
    |> zoomInAnimation
    |> CSS.animate
```

And now by the [Sub Engine](Anim-Engine-Sub).

```elm
Sub.init
    |> Sub.builder
    |> backgroundAnimation
    |> zoomInAnimation
    |> Sub.animate
```

And finally by the [WAAPI Engine](Anim-Engine-WAAPI).

```elm
WAAPI.init
    |> WAAPI.builder
    |> backgroundAnimation
    |> zoomInAnimation
    |> WAAPI.animate
```

The re-usability of animations means switching between Engines is simply a matter of changing a few implementation details, you never have to touch the animations themselves.

This makes it easy to start off with the CSS Engine for simple CSS transitions, and then migrate to the Sub or WAAPI Engines as your requirements change.

---

### 1. [Anim.Engine.CSS](Anim-Engine-CSS#design-decisions)

- **Best for:** Fire-and-forget animations, minimal setup.
- **API:** Generates CSS (transitions or keyframes) for browser-native rendering.

---

### 2. [Anim.Engine.Sub](Anim-Engine-Sub)

- **Best for:** Full programmatic control, querying mid-flight values, dynamic interruptions.
- **API:** Frame-based updates via subscriptions.

---

### 3. [Anim.Engine.WAAPI](Anim-Engine-WAAPI)

- **Best for:** Browser-native performance with programmatic control, mid-flight queries and dynamic interruptions.
- **API:** Web Animations API via Elm ports and companion JS.

---

## 🚦 Scroll Engine

Uses the same fluent builder API as the animation engines. This makes it easy to start with fire-and-forget scrolls, and introduce more complexity as your requirements change.

```elm

import Anim.Engine.Scroll as Scroll exposing (ScrollError(..), ScrollResult)

-- Reusable scroll animation

scrollToElement : String -> String -> ScrollBuilder -> ScrollBuilder
scrollToElement targetElementId elementContainerId builder =
    builder
        |> Scroll.forContainer elementContainerId
        >> Scroll.toElement targetElementId
        >> Scroll.build

-- Fire-and-forget Cmd

doScroll : Cmd Msg 
doScroll =
    Scroll.toCmd (always NoOp) <|
        scrollToElement "my-element" "my-element-container"

-- Composable Tasks with errors

doScroll : Task ScrollError ScrollResult
doScroll =
    Scroll.toTask <|
        scrollToElement "my-element" "my-element-container"

-- Mid-flight control/updates with state tracking and subscriptions

doScroll : Model -> (AnimState, Cmd Msg)
doScroll model =
    Scroll.animate ScrollMsg model.scrollAnimations <|
        scrollToElement "my-element" "my-element-container" 
```

---

### 4. [Anim.Engine.Scroll](Anim-Engine-Scroll)

- **Document and container scrolling**
- **X, Y, or Both axes**
- **Offset configuration**
- **Full easing support**
- **Fire-and-forget execution:** `Cmd` based.
- **Composable with error handling:** `Task` based.
- **Mid-flight interuptions:** Subscription based.
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

All the examples for the CSS, Sub and WAAPI engines use the same animations which can
be found in `examples/src/Common/Animations/`. The only differences between the animation
examples, are the implementation details for each Engine.

To view the examples, in the project root run:

`open examples/index.html`

---

## Roadmap

In no particular order, and no particular time frame at the moment...

- **Complete Properties**: Add all CSS animateable properties as per the CSS specifications
- **Add Canvas Support**
- **Add WebGL Support**
---

## 🙏 Credits

Uses code from [`linuss/smooth-scroll`](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/), expanded for multi-engine animations.

---

## 📄 License

BSD-3-Clause
