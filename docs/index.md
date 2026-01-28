# Elm Animate

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling.

## ✨ Features

- **Multiple Engines** — Choose the best engine for your use case
- **Unified Fluent API** — Consistent builder pattern across all engines
- **Hardware-Accelerated** — GPU-accelerated transforms for smoother animations and better battery efficiency
- **Full 3D Support** — Transform elements in 3D space with XYZ positioning, multi-axis rotation, and configurable perspective
- **Composable & Type-Safe** — Build complex animations from simple, reusable pieces

## Quick Example

```elm
import Anim.Engine.CSS as CSS
import Anim.Property.Translate as Translate
import Anim.Easing exposing (Easing(..))

-- Define a reusable animation
slideIn : AnimBuilder -> AnimBuilder
slideIn builder =
    builder
        |> Translate.for "my-element"
        |> Translate.fromX -100
        |> Translate.toX 0
        |> Translate.duration 500
        |> Translate.easing QuintOut
        |> Translate.build

-- Use it with the CSS engine
animState =
    CSS.init
        |> CSS.builder
        |> slideIn
        |> CSS.animate
```

## Animation Engines

| Engine | Best For |
|--------|----------|
| [CSS](engines/css.md) | Fire-and-forget animations, minimal setup |
| [Sub](engines/sub.md) | Full programmatic control, mid-flight queries |
| [WAAPI](engines/waapi.md) | Browser-native performance with programmatic control |
| [Scroll](engines/scroll.md) | Smooth scrolling to elements or positions |

## Getting Started

Ready to add smooth animations to your Elm app?

[Get Started →](getting-started/installation.md){ .md-button .md-button--primary }

## API Reference

For detailed API documentation, see the official Elm package docs:

[View on elm-lang.org →](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/){ .md-button }
