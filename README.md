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

## 🧠 Core Concepts

### One Animation - Multiple Engines

There are many ways to create animations, and many good animation packages for Elm, and if all animations were equal, you could probably pick a package and stick with it. But they're not; there are CSS transitions, CSS keyframes, Timeline based animations, the Web Animations API, WebGL etc etc...

Each different way of animating comes with its own learning curve and complexities, as does each different Elm package. Imagine learning and using an Elm package for CSS transitions, and then further down the line your company decides to start using the Web Animations API as well. They give you another Elm package to learn with a different API, and a different way of thinking about animations.

So now you have two different mental models for essentially the same thing.

While that may be the 'life of a developer', it doesn't have to be that way - Elm Animate can make it easier.

Elm Animate provides a singular, composable builder API to build animation configurations, and multiple Engines that consume the configuration and output the animation to their own speciality target:

- CSS Transitions
- CSS Keyframes
- Timeline/Subscription based
- Web Animations API
- more to come...

How cool is that? Define once, use everywhere 🎉

### Animation Groups

Animations are organized into **groups**. A group is a logical name that identifies which animations run together on the same element. All properties sharing the same group name will animate simultaneously when triggered.

```elm
-- "fadeSlide" is the animation group name
fadeSlideIn : AnimBuilder -> AnimBuilder
fadeSlideIn =
    Opacity.for "fadeSlide"
        >> Opacity.from 0
        >> Opacity.to 1
        >> Opacity.build
        >> Translate.for "fadeSlide"  -- same group = animates together
        >> Translate.fromY -20
        >> Translate.toY 0
        >> Translate.build
```

---

## 🚦 Animation Engines

All animation engines use a unified builder API, so you can switch between them with minimal changes.

Here's a simple [BackgroundColor](Anim-Property-BackgroundColor) animation:

```elm
import Anim.Extra.Color exposing (hex, elmColor)
import Anim.Property.BackgroundColor as BackgroundColor
import Color

colorFade : AnimBuilder -> AnimBuilder
colorFade =
    BackgroundColor.for "colorAnim"
        >> BackgroundColor.from (hex "#ff0000")
        >> BackgroundColor.to (elmColor Color.blue)
        >> BackgroundColor.duration 2000
        >> BackgroundColor.build
```

And here's a GPU-rendered 3D [Translate](Anim-Property-Translate) animation:

```elm
import Anim.Easing exposing (BounceOut)
import Anim.Property.Translate as Translate

zoomIn : AnimBuilder -> AnimBuilder
zoomIn =
    Translate.for "zoomAnim"
        >> Translate.fromXYZ 100 200 0
        >> Translate.toZ 300
        >> Translate.speed 150
        >> Translate.easing BounceOut
        >> Translate.build
```

Both animation functions share the same signature; `AnimBuilder -> AnimBuilder`, so they can be
composed together and work with any engine:

```elm
-- CSS Transitions Engine
Transitions.animate model.animState <|
    colorFade >> zoomIn

-- CSS Keyframes Engine
Keyframes.animate model.animState <|
    colorFade >> zoomIn

-- Sub Engine
Sub.animate model.animState <|
    colorFade >> zoomIn

-- WAAPI Engine (note: requires forElement)
WAAPI.animate model.animState <|
    WAAPI.forElement "element-id"
        >> colorFade
        >> zoomIn
```

This composability means switching engines only requires changing a few implementation details — your animations stay the same.

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

Smooth scrolling with the same builder API:

```elm
import Anim.Engine.Scroll as Scroll

-- Simple fire-and-forget scroll
scrollToSection : Cmd Msg
scrollToSection =
    Scroll.toCmd (always NoOp) <|
        Scroll.forDocument
            >> Scroll.toElement "features-section"
            >> Scroll.duration 600
            >> Scroll.build
```

The Scroll engine also supports container scrolling, `Task`-based composition with error handling, and subscription-based mid-flight control.

---

### 4. [Anim.Engine.Scroll](Anim-Engine-Scroll)

- **Document and container scrolling**
- **X, Y, or both axes**
- **Offset configuration**
- **Full easing support**
- **Multiple execution modes:** `Cmd`, `Task`, or subscription-based
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

## 📚 Documentation

Full documentation is available at [phollyer.github.io/elm-animate](https://phollyer.github.io/elm-animate), including:

- **Getting Started guide** with installation and first animation tutorials
- **Engine guides** with detailed API explanations for each animation engine
- **Property documentation** covering all animatable properties (Translate, Scale, Rotate, Opacity, Colors, Size)
- **Live examples** with source code you can copy and modify

---

## Roadmap

In no particular order, and no particular time frame at the moment...

- **Animations**
  - Add reverse control
  - Add sequencing
  - Add FLIP support
- **Properties**: Add all CSS animateable properties as per the CSS specifications
- **WAAPI Engine**: Add full Web Animations API coverage
- **Add Canvas Support**
- **Add WebGL Support**
---

## 🙏 Credits

Uses code from [`linuss/smooth-scroll`](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/), expanded for multi-engine animations.

---

## 📄 License

BSD-3-Clause
