# Easing Functions

Easing functions control the rate of change during an animation, making motion feel natural and polished.

## Available Easings

```elm
import Anim.Easing exposing (Easing(..))
```

### Linear

Constant speed throughout. Rarely what you want for UI animations.

```elm
|> Property.easing Linear
```

### Ease In/Out Variants

| Easing | Description |
|--------|-------------|
| `EaseIn` | Starts slow, ends fast |
| `EaseOut` | Starts fast, ends slow |
| `EaseInOut` | Slow at both ends |

### Sine

Gentle, subtle easing based on sine curve.

| Easing | Feel |
|--------|------|
| `SineIn` | Gentle acceleration |
| `SineOut` | Gentle deceleration |
| `SineInOut` | Gentle both ends |

### Quad

Quadratic (power of 2) — slightly more pronounced than sine.

| Easing | Feel |
|--------|------|
| `QuadIn` | Moderate acceleration |
| `QuadOut` | Moderate deceleration |
| `QuadInOut` | Moderate both ends |

### Cubic

Cubic (power of 3) — more noticeable acceleration/deceleration.

| Easing | Feel |
|--------|------|
| `CubicIn` | Noticeable acceleration |
| `CubicOut` | Noticeable deceleration |
| `CubicInOut` | Noticeable both ends |

### Quart

Quartic (power of 4) — dramatic effect.

| Easing | Feel |
|--------|------|
| `QuartIn` | Strong acceleration |
| `QuartOut` | Strong deceleration |
| `QuartInOut` | Strong both ends |

### Quint

Quintic (power of 5) — very dramatic.

| Easing | Feel |
|--------|------|
| `QuintIn` | Very strong acceleration |
| `QuintOut` | Very strong deceleration |
| `QuintInOut` | Very strong both ends |

### Expo

Exponential — extremely dramatic.

| Easing | Feel |
|--------|------|
| `ExpoIn` | Explosive acceleration |
| `ExpoOut` | Explosive deceleration |
| `ExpoInOut` | Explosive both ends |

### Circ

Circular — based on quarter circle.

| Easing | Feel |
|--------|------|
| `CircIn` | Circular acceleration |
| `CircOut` | Circular deceleration |
| `CircInOut` | Circular both ends |

### Back

Overshoots slightly then returns.

| Easing | Feel |
|--------|------|
| `BackIn` | Pulls back then accelerates |
| `BackOut` | Overshoots then settles |
| `BackInOut` | Both effects |

### Elastic

Spring-like bounce effect.

| Easing | Feel |
|--------|------|
| `ElasticIn` | Winds up like a spring |
| `ElasticOut` | Springs and oscillates |
| `ElasticInOut` | Both effects |

### Bounce

Bouncing ball effect.

| Easing | Feel |
|--------|------|
| `BounceIn` | Bounces at start |
| `BounceOut` | Bounces at end |
| `BounceInOut` | Both effects |

## Choosing an Easing

!!! tip "General recommendations"

    **For most UI animations:** `QuintOut` or `CubicOut`
    
    These provide a snappy start with a smooth deceleration, which feels responsive.

!!! tip "For entrances:"
    Use `Out` variants — elements should arrive and settle smoothly.

!!! tip "For exits:"
    Use `In` variants — elements should accelerate away.

!!! tip "For state changes:"
    Use `InOut` variants — smooth transitions between states.

## Examples

### Snappy button response

```elm
buttonHover builder =
    builder
        |> Scale.for "button"
        |> Scale.to 1.05
        |> Scale.duration 150
        |> Scale.easing QuintOut
        |> Scale.build
```

### Smooth modal entrance

```elm
modalEnter builder =
    builder
        |> Opacity.for "modal"
        |> Opacity.from 0
        |> Opacity.to 1
        |> Opacity.duration 300
        |> Opacity.easing CubicOut
        |> Opacity.build
        |> Translate.for "modal"
        |> Translate.fromY 20
        |> Translate.toY 0
        |> Translate.duration 300
        |> Translate.easing CubicOut
        |> Translate.build
```

### Playful bounce

```elm
notification builder =
    builder
        |> Translate.for "toast"
        |> Translate.fromY -100
        |> Translate.toY 0
        |> Translate.duration 600
        |> Translate.easing BounceOut
        |> Translate.build
```

### Elastic attention

```elm
shake builder =
    builder
        |> Rotate.for "icon"
        |> Rotate.from 0
        |> Rotate.to 15
        |> Rotate.duration 400
        |> Rotate.easing ElasticOut
        |> Rotate.build
```
