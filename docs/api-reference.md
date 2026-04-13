# API Reference

The complete API documentation is available on the official Elm package repository:

[**View Full API Documentation →**](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/){ .md-button .md-button--primary }

## Module Overview

### Core

| Module | Description |
| -------- | ------------- |
| [Anim.Builder](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Builder) | AnimBuilder type for reusable animations |

### Engines

| Module | Description |
| -------- | ------------- |
| [Anim.Engine.CSS.Transition](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-CSS-Transition) | CSS transitions for A→B animations |
| [Anim.Engine.CSS.Keyframe](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-CSS-Keyframe) | CSS keyframe animations for complex animations |
| [Anim.Engine.Sub](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Sub) | Subscription-based frame animations |
| [Anim.Engine.WAAPI](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI) | Web Animations API via ports |
| [Anim.Engine.Scroll.Cmd](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Scroll-Cmd) | Fire-and-forget scrolling |
| [Anim.Engine.Scroll.Task](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Scroll-Task) | Composable scrolling with error handling |
| [Anim.Engine.Scroll.Sub](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Scroll-Sub) | Stateful scrolling with full control |

### Properties

| Module | Description |
| -------- | ------------- |
| [Anim.Property.Translate](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Property-Translate) | Position/movement animations |
| [Anim.Property.Rotate](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Property-Rotate) | Rotation animations |
| [Anim.Property.Scale](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Property-Scale) | Scale/zoom animations |
| [Anim.Property.Opacity](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Property-Opacity) | Fade animations |
| [Anim.Property.BackgroundColor](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Property-BackgroundColor) | Background color animations |
| [Anim.Property.FontColor](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Property-FontColor) | Text color animations |
| [Anim.Property.Size](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Property-Size) | Width/height animations |

### Utilities

| Module | Description |
| -------- | ------------- |
| [Anim.Extra.Easing](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Extra-Easing) | Easing functions |
| [Anim.Extra.Color](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Extra-Color) | Color utilities |
| [Anim.Extra.View3D](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Extra-View3D) | 3D perspective helpers |

## Common Patterns

### Animation Function Signature

All animation functions follow this pattern:

```elm
myAnimation : AnimBuilder -> AnimBuilder
```

This makes them composable with `>>` and reusable across engines.

### Engine Pipeline

All engines follow this pipeline:

```elm
Engine.animate animState <|
    \ builder ->
        builder
            |> ... -- Build animation
```

### Property Builder Pattern

All properties follow this pattern:

```elm
Property.for "element-id"
    |> Property.from startValue
    |> Property.to endValue
    |> Property.duration ms
    |> Property.easing easing
    |> Property.build
```
