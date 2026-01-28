# Animation Engines

Elm Animate provides multiple animation engines, each optimized for different use cases. All engines share the same builder API, making it easy to switch between them.

## Overview

| Engine | Rendering | Control | Use Case |
|--------|-----------|---------|----------|
| [CSS](#css-engine) | Browser CSS | Fire-and-forget | Simple animations, best performance |
| [Sub](#sub-engine) | Elm subscriptions | Full programmatic | Complex interactions, state queries |
| [WAAPI](#waapi-engine) | Web Animations API | Programmatic | Native performance + control |
| [Scroll](#scroll-engine) | Browser scroll | Configurable | Smooth scrolling |

## CSS Engine

The CSS Engine generates native CSS transitions or keyframe animations. The browser handles all the rendering, which means:

- **Best performance** — Hardware-accelerated by the browser
- **Battery efficient** — No JavaScript running during animation
- **Simple setup** — No subscriptions or ports needed

```elm
import Anim.Engine.CSS as CSS

animState =
    CSS.init
        |> CSS.builder
        |> myAnimation
        |> CSS.animate
```

**Best for:**

- Fire-and-forget animations
- Page transitions
- Hover effects
- Any animation where you don't need to query mid-flight values

[Learn more about CSS Engine →](../engines/css.md)

## Sub Engine

The Sub Engine uses Elm subscriptions to update animation state on each frame. This gives you full control:

- **Query current values** — Know exactly where elements are mid-animation
- **Dynamic interruptions** — Smoothly transition to new targets
- **State tracking** — Know when animations start, run, and complete

```elm
import Anim.Engine.Sub as Sub

-- In your subscriptions
subscriptions model =
    Sub.subscriptions AnimFrame model.animState
```

**Best for:**

- Interactive animations responding to user input
- Animations that need to be interrupted and redirected
- When you need to know current animated values

[Learn more about Sub Engine →](../engines/sub.md)

## WAAPI Engine

The WAAPI Engine uses the Web Animations API via Elm ports. It combines browser-native performance with programmatic control:

- **Native performance** — Browser handles rendering
- **Programmatic control** — Pause, reverse, seek
- **Mid-flight queries** — Get current values from JavaScript

```elm
import Anim.Engine.WAAPI as WAAPI

-- Requires JavaScript companion
animState =
    WAAPI.init
        |> WAAPI.builder
        |> myAnimation
        |> WAAPI.animate
```

**Best for:**

- Complex animations needing both performance and control
- When you need pause/resume/reverse functionality
- Animations with many simultaneous elements

[Learn more about WAAPI Engine →](../engines/waapi.md)

## Scroll Engine

The Scroll Engine provides smooth scrolling to elements or positions:

- **Document or container scrolling**
- **X, Y, or both axes**
- **Configurable offsets**
- **Full easing support**

```elm
import Anim.Engine.Scroll as Scroll
import Anim.Action.Scroll as ScrollAction

scrollCmd =
    Scroll.init
        |> Scroll.builder
        |> ScrollAction.toElement "target-section"
        |> ScrollAction.build
        |> Scroll.toCmd NoOp
```

[Learn more about Scroll Engine →](../engines/scroll.md)

## Switching Engines

Because all engines share the same builder API, animations are portable:

```elm
-- This animation works with any engine
myAnimation : AnimBuilder -> AnimBuilder
myAnimation builder =
    builder
        |> Translate.for "box"
        |> Translate.toXY 100 200
        |> Translate.duration 500
        |> Translate.build

-- Use with CSS
CSS.init |> CSS.builder |> myAnimation |> CSS.animate

-- Use with Sub
Sub.init |> Sub.builder |> myAnimation |> Sub.animate

-- Use with WAAPI
WAAPI.init |> WAAPI.builder |> myAnimation |> WAAPI.animate
```

This makes it easy to start simple with the CSS Engine and migrate to Sub or WAAPI as your requirements grow.
