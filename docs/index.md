# Elm Animate

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling.


## ✨ Features

- **Multiple Engines** — 6 Animation Engines, 3 Scroll Engines
- **Composable** — Compose and reuse animation and scroll configurations
- **Type-Safe** — Invalid configurations will not compile
- **Configurable** — Delay, duration, speed and easing
- **Interruptible & Controllable** — Query, divert, and control animations and scrolls mid-flight

### **Animation**

- **Hardware-Accelerated** — GPU-powered transforms (translate, rotate, scale, opacity)
- **Full 3D Support** — XYZ positioning, multi-axis rotation, perspective
- **Animation Groups** — Animate multiple properties on the same element as a single named group

### **Scroll**

- **Smooth Scrolling** — Document and container
- **Flexible Targets** — Scroll to elements, percentages, edges, corners, or relative deltas
- **Axis Control** — Scroll horizontally, vertically or both

## ⚙️ Engine Overview

### Animation

| Engine | Key Features |
| -------- | ---------- |
| [Transition](animation/engines/transition.md) | Browser-native performance, quick setup for simple A→B animations |
| [Keyframe](animation/engines/keyframes.md) | Browser-native performance, looping, full control (stop, reset, restart, pause, resume) |
| [Sub](animation/engines/sub.md) | Full control, real-time mid-flight queries/diversions |
| [WAAPI](animation/engines/waapi.md) | Browser-native performance, looping, full control, real-time mid-flight queries/diversions |
| [Scroll Timeline](animation/engines/scroll-timeline.md) | Fire-and-forget animation tied to container scroll position |
| [View Timeline](animation/engines/view-timeline.md) | Fire-and-forget animation tied to element viewport position |

### Scroll

| Engine | Key Features |
| -------- | ---------- |
| [Cmd](scroll/engines/cmd.md) | Fire-and-forget scrolling to elements or positions |
| [Task](scroll/engines/task.md) | Composable scrolling with typed error handling |
| [Sub](scroll/engines/sub.md) | Stateful scrolling with full control, events, and mid-scroll queries |

## Next Steps

Learn why Elm Animate exists and what it's trying to solve.

[Philosophy →](philosophy.md){ .md-button .md-button--primary }

Or, jump right in and get started.

[Installation →](installation.md){ .md-button .md-button--primary }

## 📚 API Reference

For detailed API documentation, see the official Elm package docs:

[View on elm-lang.org →](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/){ .md-button }
