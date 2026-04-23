# Elm Animate

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling.

## ✨ Features

- **Multiple Engines** — Choose the best engine for your use case
- **Unified Fluent API** — Consistent builder pattern across all engines
- **Hardware-Accelerated** — GPU-accelerated transforms for smoother animations and better battery efficiency
- **Full 3D Support** — Transform elements in 3D space with XYZ positioning, multi-axis rotation, and configurable perspective
- **Composable & Type-Safe** — Build complex animations from simple, reusable pieces

## ⚙️ Engine Overview

### Animation

| Engine | Key Features |
| -------- | ---------- |
| [Transition](animation/engines/transitions.md) | Browser-native performance, quick setup for simple A→B animations |
| [Keyframe](animation/engines/keyframes.md) | Browser-native performance, looping, full control (stop, reset, restart, pause, resume) |
| [Sub](animation/engines/sub.md) | Full control, real-time mid-flight queries/diversions |
| [WAAPI](animation/engines/waapi.md) | Browser-native performance, looping, full control, real-time mid-flight queries/diversions |

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
