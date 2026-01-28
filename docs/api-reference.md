# API Reference

The complete API documentation is available on the official Elm package repository:

[**View Full API Documentation →**](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/){ .md-button .md-button--primary }

## Module Overview

### Engines

| Module | Description |
|--------|-------------|
| [Anim.Engine.CSS](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-CSS) | CSS transitions and keyframe animations |
| [Anim.Engine.Sub](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Sub) | Subscription-based frame animations |
| [Anim.Engine.WAAPI](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI) | Web Animations API via ports |
| [Anim.Engine.Scroll](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Scroll) | Smooth scrolling engine |

### Actions

| Module | Description |
|--------|-------------|
| [Anim.Action.Scroll](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Action-Scroll) | Scroll action builder |

### Properties

| Module | Description |
|--------|-------------|
| [Anim.Property.Translate](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Property-Translate) | Position/movement animations |
| [Anim.Property.Rotate](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Property-Rotate) | Rotation animations |
| [Anim.Property.Scale](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Property-Scale) | Scale/zoom animations |
| [Anim.Property.Opacity](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Property-Opacity) | Fade animations |
| [Anim.Property.BackgroundColor](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Property-BackgroundColor) | Background color animations |
| [Anim.Property.FontColor](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Property-FontColor) | Text color animations |
| [Anim.Property.Size](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Property-Size) | Width/height animations |

### Utilities

| Module | Description |
|--------|-------------|
| [Anim.Easing](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Easing) | Easing functions |
| [Anim.Color](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Color) | Color utilities |

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
Engine.init
    |> Engine.builder
    |> myAnimation
    |> Engine.animate
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
