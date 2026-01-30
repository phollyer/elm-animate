# Opacity

Fade elements in and out by animating their opacity value.

**Module:** `Anim.Property.Opacity`

**GPU Accelerated:** ✅ Yes — composited on the GPU for smooth performance.

## Basic Usage

```elm
import Anim.Property.Opacity as Opacity

fadeIn : AnimBuilder -> AnimBuilder
fadeIn builder =
    builder
        |> Opacity.for "my-element"
        |> Opacity.from 0
        |> Opacity.to 1
        |> Opacity.duration 500
        |> Opacity.build
```

## API

### Targeting

| Function | Description |
|----------|-------------|
| `for` | Target an element by ID |

### Values

| Function | Type | Description |
|----------|------|-------------|
| `from` | `Float` | Starting opacity (0.0 to 1.0) |
| `to` | `Float` | Ending opacity (0.0 to 1.0) |

### Timing

| Function | Description |
|----------|-------------|
| `duration` | Animation duration in milliseconds |
| `speed` | Animation speed (alternative to duration) |
| `delay` | Delay before animation starts |
| `easing` | Easing function for the animation |

### Initialization

| Function | Description |
|----------|-------------|
| `init` | Set initial opacity without animating |

## Examples

### Fade In

```elm
fadeIn builder =
    builder
        |> Opacity.for "box"
        |> Opacity.from 0
        |> Opacity.to 1
        |> Opacity.duration 300
        |> Opacity.easing QuintOut
        |> Opacity.build
```

### Fade Out

```elm
fadeOut builder =
    builder
        |> Opacity.for "box"
        |> Opacity.from 1
        |> Opacity.to 0
        |> Opacity.duration 300
        |> Opacity.easing QuintIn
        |> Opacity.build
```

### Pulse Effect

Combine with other properties for a pulse:

```elm
pulse builder =
    builder
        |> Opacity.for "box"
        |> Opacity.from 1
        |> Opacity.to 0.5
        |> Opacity.duration 500
        |> Opacity.easing SineInOut
        |> Opacity.build
        |> Scale.for "box"
        |> Scale.from 1
        |> Scale.to 1.05
        |> Scale.duration 500
        |> Scale.easing SineInOut
        |> Scale.build
```

## Tips

!!! tip "Omit `from` for current value"
    If you omit `from`, the animation starts from the element's current opacity. This is useful for interrupting animations smoothly.

!!! tip "Combine with Translate for entrances"
    Fade-in animations feel more polished when combined with subtle movement:

    ```elm
    slideAndFade builder =
        builder
            |> Opacity.for "box"
            |> Opacity.from 0
            |> Opacity.to 1
            |> Opacity.build
            |> Translate.for "box"
            |> Translate.fromY 20
            |> Translate.toY 0
            |> Translate.build
    ```
