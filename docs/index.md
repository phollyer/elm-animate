# Elm Animate

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling.

## ✨ Features

- **Multiple Engines** — Choose the best engine for your use case
- **Unified Fluent API** — Consistent builder pattern across all engines
- **Hardware-Accelerated** — GPU-accelerated transforms for smoother animations and better battery efficiency
- **Full 3D Support** — Transform elements in 3D space with XYZ positioning, multi-axis rotation, and configurable perspective
- **Composable & Type-Safe** — Build complex animations from simple, reusable pieces

## ⚙️ Engines

| Engine | Best For |
| -------- | ---------- |
| [CSS Transitions](engines/transitions.md) | Browser-native performance, simple A→B animations |
| [CSS Keyframes](engines/keyframes.md) | Browser-native performance, looping, pause/resume |
| [Sub](engines/sub.md) | Programmatic control, mid-flight queries/diversions |
| [WAAPI](engines/waapi.md) | Browser-native performance, programmatic control, mid-flight queries/diversions |
| [Scroll](engines/scroll.md) | Smooth scrolling to elements or positions |

## 🚀 Quick Example

??? example "View Source Code"

    🎨 Define a reusable animation

    ```elm
    import Anim.Builder exposing (AnimBuilder)
    import Anim.Property.Translate as Translate
    import Anim.Extra.Easing exposing (Easing(..))

    -- Define a reusable animation
    slideIn : AnimBuilder -> AnimBuilder
    slideIn =
        Translate.for "my-element"
            >> Translate.fromX -100
            >> Translate.toX 0
            >> Translate.duration 500
            >> Translate.easing QuintOut
            >> Translate.build
    ```

    🎉 Use it with any Animation Engine

    ```elm
    import Anim.Engine.CSS.Keyframes as Keyframes
    import Anim.Engine.CSS.Transitions as Transitions
    import Anim.Engine.Sub as Sub
    import Anim.Engine.WAAPI as WAAPI
    import Json.Encode as Encode

    -- Use it with the CSS Transitions engine
    animState =
        Transitions.animate model.animState slideIn

    animState =
        Transitions.fireAndForget slideIn

    -- Use it with the CSS Keyframes engine
    animState =
        Keyframes.animate model.animState slideIn

    animState =
        Keyframes.fireAndForget slideIn

    -- Use it with the Sub engine
    animState =
        Sub.animate model.animState slideIn

    -- Use it with the WAAPI engine
    (animState, cmd) =
        WAAPI.animate model.animState slideIn

    port waapiCommand : Encode.Value -> Cmd msg

    cmd =
        WAAPI.fireAndForget waapiCommand slideIn
    ```

## 📖 Getting Started

Ready to add Elm Animate to your Elm app?

[Get Started →](getting-started/installation.md){ .md-button .md-button--primary }

## 📚 API Reference

For detailed API documentation, see the official Elm package docs:

[View on elm-lang.org →](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/){ .md-button }
