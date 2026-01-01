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

---

### 1. [Anim.Engine.CSS](Anim-Engine-CSS) – Hardware-Accelerated CSS

- **Best for:** Simple, high-performance transitions.
- **API:** Generates CSS for browser-native transitions.

The CSS Engine will create both CSS Transforms and Keyframe Animations. Choose the one you want
in your view code.


---

### 2. [Anim.Engine.Sub](Anim-Engine-Sub) – Subscription-Based Control

- **Best for:** Full programmatic control, live values, mid-flight changes.
- **API:** Frame-based updates, requires subscriptions.

---

### 3. [Anim.Engine.WAAPI](Anim-Engine-WAAPI) – Web Animations API (via Ports)

- **Best for:** Complex, timeline-based, or native browser animations.
- **API:** Uses Elm ports to communicate with a JavaScript companion.

---
## 🚦 Scroll Engine

### 4. [Anim.Engine.Scroll](Anim-Engine-Scroll)

- **Document and container scrolling**
- **X, Y, or Both axes**
- **Offset configuration**
- **Subscription-based animation management**
- **Fire-and-forget (Cmd/Task) execution**
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
be found in `examples/src/Common/Animations/`. The only differences between the Engine
examples, are the implementation details for each Engine.

To view the examples, in the project root run:

`open examples/index.html`

---

##  Roadmap

In no particular order, and no particular time frame at the moment...

- **Complete Properties**: Add all CSS animateable properties as per the CSS specifications
- **Add Canvas Support**
- **Add WebGL Support**
---

## 🙏 Credits

Based on [`linuss/smooth-scroll`](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/), expanded for multi-engine animation.

---

## 📄 License

BSD-3-Clause
