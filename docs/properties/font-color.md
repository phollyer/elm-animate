# Font Color

Animate the text color of elements.

**Module:** `Anim.Property.FontColor`

**GPU Accelerated:** ❌ No — triggers browser repaints.

## Basic Usage

```elm
import Anim.Property.FontColor as FontColor
import Anim.Extra.Color exposing (hex)

textHighlight : AnimBuilder -> AnimBuilder
textHighlight builder =
    builder
        |> FontColor.for "my-element"
        |> FontColor.from (hex "#000000")
        |> FontColor.to (hex "#0066cc")
        |> FontColor.duration 300
        |> FontColor.build
```

See the [Properties Overview](overview.md) page for the shared usage patterns.

## API

### Values

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `from` | `Color` | Starting text color |
| `to` | `Color` | Ending text color |

Colors can be created using the `Anim.Color` module:

- `hex "#ff0000"` — Hex string
- `rgb 255 0 0` — RGB values (0-255)
- `rgba 255 0 0 0.5` — RGBA with alpha

### Initialization

| Function | Description |
| ---------- | ------------- |
| `init` | Set initial font color without animating |

## Examples

### Link Hover Effect

```elm
linkHover builder =
    builder
        |> FontColor.for "link"
        |> FontColor.from (hex "#0066cc")
        |> FontColor.to (hex "#004499")
        |> FontColor.duration 200
        |> FontColor.build
```

### Error Text

```elm
showErrorText builder =
    builder
        |> FontColor.for "message"
        |> FontColor.to (hex "#cc0000")
        |> FontColor.duration 300
        |> FontColor.build
```

### Theme Transition

```elm
toDarkModeText builder =
    builder
        |> FontColor.for "content"
        |> FontColor.from (hex "#333333")
        |> FontColor.to (hex "#e0e0e0")
        |> FontColor.duration 500
        |> FontColor.easing QuintInOut
        |> FontColor.build
```

### Success Feedback

```elm
successText builder =
    builder
        |> FontColor.for "status"
        |> FontColor.to (hex "#28a745")
        |> FontColor.duration 300
        |> FontColor.build
```

## Combining with Background Color

For full color scheme transitions:

```elm
import Anim.Property.BackgroundColor as BackgroundColor
import Anim.Property.FontColor as FontColor

themeTransition builder =
    builder
        |> BackgroundColor.for "card"
        |> BackgroundColor.from (hex "#ffffff")
        |> BackgroundColor.to (hex "#1a1a1a")
        |> BackgroundColor.duration 500
        |> BackgroundColor.build
        |> FontColor.for "card"
        |> FontColor.from (hex "#333333")
        |> FontColor.to (hex "#e0e0e0")
        |> FontColor.duration 500
        |> FontColor.build
```

## Tips

!!! warning "Performance"
    Font color changes trigger browser repaints. This is fine for a few elements but avoid animating text color on many elements simultaneously.

!!! tip "Inherited colors"
    Font color is inherited by child elements. Animating a parent's color will affect all text descendants unless they have their own color set.
