# Background Color

Animate the background color of elements.

**Module:** `Anim.Property.BackgroundColor`

**GPU Accelerated:** ❌ No — triggers browser repaints.

## Basic Usage

```elm
import Anim.Property.BackgroundColor as BackgroundColor
import Anim.Color exposing (hex, rgb)

highlightAnimation : AnimBuilder -> AnimBuilder
highlightAnimation builder =
    builder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.from (hex "#ffffff")
        |> BackgroundColor.to (hex "#ffff00")
        |> BackgroundColor.duration 300
        |> BackgroundColor.build
```

## API

### Targeting

| Function | Description |
|----------|-------------|
| `for` | Target an element by ID |

### Values

| Function | Type | Description |
|----------|------|-------------|
| `from` | `Color` | Starting color |
| `to` | `Color` | Ending color |

Colors can be created using the `Anim.Color` module:

- `hex "#ff0000"` — Hex string
- `rgb 255 0 0` — RGB values (0-255)
- `rgba 255 0 0 0.5` — RGBA with alpha

### Timing

| Function | Description |
|----------|-------------|
| `duration` | Animation duration in milliseconds |
| `speed` | Animation speed |
| `delay` | Delay before animation starts |
| `easing` | Easing function for the animation |

### Initialization

| Function | Description |
|----------|-------------|
| `init` | Set initial background color without animating |

## Examples

### Highlight on Hover

```elm
highlight builder =
    builder
        |> BackgroundColor.for "row"
        |> BackgroundColor.from (hex "#ffffff")
        |> BackgroundColor.to (hex "#f0f0f0")
        |> BackgroundColor.duration 200
        |> BackgroundColor.build
```

### Error State

```elm
showError builder =
    builder
        |> BackgroundColor.for "input"
        |> BackgroundColor.to (hex "#ffcccc")
        |> BackgroundColor.duration 300
        |> BackgroundColor.build
```

### Smooth Theme Transition

```elm
toDarkMode builder =
    builder
        |> BackgroundColor.for "body"
        |> BackgroundColor.from (hex "#ffffff")
        |> BackgroundColor.to (hex "#1a1a1a")
        |> BackgroundColor.duration 500
        |> BackgroundColor.easing QuintInOut
        |> BackgroundColor.build
```

### Pulse Warning

```elm
warningPulse builder =
    builder
        |> BackgroundColor.for "alert"
        |> BackgroundColor.from (hex "#fff3cd")
        |> BackgroundColor.to (hex "#ffc107")
        |> BackgroundColor.duration 500
        |> BackgroundColor.easing SineInOut
        |> BackgroundColor.build
```

## Color Module

The `Anim.Color` module provides color constructors:

```elm
import Anim.Color exposing (hex, rgb, rgba, hsl, hsla)

-- Hex colors
hex "#ff0000"
hex "#f00"          -- Shorthand supported

-- RGB (0-255)
rgb 255 0 0

-- RGBA with alpha (0.0-1.0)
rgba 255 0 0 0.5

-- HSL (hue 0-360, saturation 0-100, lightness 0-100)
hsl 0 100 50

-- HSLA with alpha
hsla 0 100 50 0.5
```

## Tips

!!! warning "Performance"
    Background color changes trigger browser repaints. For a few elements this is fine, but avoid animating background colors on many elements simultaneously.

!!! tip "Omit `from` for current color"
    If you omit `from`, the animation starts from the element's current background color.

!!! tip "Consider opacity for fades"
    If you're fading to/from transparent, consider using an overlay with `Opacity` instead — it's GPU-accelerated.
