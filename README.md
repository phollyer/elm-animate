# Elm Animate

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling.

## ✨ Features

- **Multiple Engines:** Choose the best engine for your use case.
- **Unified Fluent API:** Consistent builder pattern for all engines.
- **GPU-Accelerated:** All animation engines offload work to the GPU for smoother animations and better battery efficiency.
- **Full 3D Support:** Transform elements in 3D space with XYZ positioning, multi-axis rotation, and configurable perspective for depth.
- **Composable, type-safe, and easy to integrate.**

---

## 🚦 Animation Engines

All animation engines use a unified builder API, so you can switch between them with minimal changes.

Here's a 3D [Position](Anim.Properties.Position) animation that zooms in on the element.

```elm
positionAnimation : AnimBuilder -> AnimBuilder
positionAnimation builder =
    builder
        |> Position.for "my-element"
        |> Position.perspective "my-element-container" 900
        |> Position.fromXYZ 100 200 0
        |> Position.toZ 300
        |> Position.speed 150
        |> Position.easing BounceOut
        |> Position.build
```
It can be used by all of the engines - without any changes to the animation itself. Switching
between engines is simply a matter of changing a few implementation details, you never have to touch the animations themselves.

This makes it easy to start off with the CSS Engine for simple CSS transitions, and then migrate to the Sub or WAAPI Engines as your requirements change.

---

### 1. [Anim.Engine.CSS](Anim-Engine-CSS#design-decisions) 

- **Best for:** Simple, high-performance transitions.
- **API:** Generates CSS for browser-native transitions.

The CSS Engine will create both CSS Transforms and Keyframe Animations. Choose the one you want
in your view code.


---

### 2. [Anim.Engine.Sub](Anim-Engine-Sub) 

- **Best for:** Full programmatic control, live values, mid-flight changes.
- **API:** Frame-based updates, requires subscriptions.

---

### 3. [Anim.Engine.WAAPI](Anim-Engine-WAAPI) 

- **Best for:** Complex, timeline-based, or native browser animations.
- **API:** Uses Elm ports to communicate with a JavaScript companion.

---
## 🚦 Scroll Engine

Uses the same fluent builder API as the animation engines. This makes it easy to start with fire-and-forget scrolls, and introduce more complexity as your requirements change.

```elm

import Anim.Action.Scroll as ScrollAction
import Anim.Engine.Scroll as Scroll exposing (ScrollError(..), ScrollResult)

-- Reusable scroll animation

scrollToElement : String -> String -> AnimState -> AnimBuilder
scrollToElement targetElementId elementContainerId animState =
    animState
        |> Scroll.builder
        |> ScrollAction.forContainer elementContainerId
        |> ScrollAction.toElement targetElementId
        |> ScrollAction.build

-- Fire-and-forget Cmd

doScroll : Cmd Msg 
doScroll =
    Scroll.init
        |> scrollToElement "my-element" "my-element-container"
        |> Scroll.toCmd NoOp

-- Composable Tasks with errors

doScroll : Task ScrollError ScrollResult
doScroll =
    Scroll.init
        |> scrollToElement "my-element" "my-element-container"
        |> Scroll.toTask

-- Mid-flight control/updates with state tracking and subscriptions

doScroll : Model -> (AnimState, Cmd Msg)
doScroll model =
    model.scrollAnimations
        |> scrollToElement "my-element" "me-element-container" 
        |> Scroll.animate ScrollMsg
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

##  Roadmap

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
