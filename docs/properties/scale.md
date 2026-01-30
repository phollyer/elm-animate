# Scale

Scale elements uniformly or independently on each axis.

**Module:** `Anim.Property.Scale`

**GPU Accelerated:** ✅ Yes — composited on the GPU for smooth performance.

## Basic Usage

```elm
import Anim.Property.Scale as Scale

grow : AnimBuilder -> AnimBuilder
grow builder =
    builder
        |> Scale.for "my-element"
        |> Scale.from 1
        |> Scale.to 1.5
        |> Scale.duration 300
        |> Scale.build
```

## API

### Targeting

| Function | Description |
|----------|-------------|
| `for` | Target an element by ID |

### Values — Uniform

| Function | Type | Description |
|----------|------|-------------|
| `from` | `Float` | Starting scale (1.0 = 100%) |
| `to` | `Float` | Ending scale (1.0 = 100%) |

### Values — Individual Axes

| Function | Type | Description |
|----------|------|-------------|
| `fromX` | `Float` | Starting X-axis scale |
| `fromY` | `Float` | Starting Y-axis scale |
| `fromZ` | `Float` | Starting Z-axis scale |
| `toX` | `Float` | Ending X-axis scale |
| `toY` | `Float` | Ending Y-axis scale |
| `toZ` | `Float` | Ending Z-axis scale |

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
| `initX`, `initY`, `initZ` | Set initial scale on single axis |
| `initXYZ` | Set initial scale on all axes |

## Examples

### Pop In

```elm
popIn builder =
    builder
        |> Scale.for "box"
        |> Scale.from 0
        |> Scale.to 1
        |> Scale.duration 300
        |> Scale.easing BackOut
        |> Scale.build
```

### Shrink Out

```elm
shrinkOut builder =
    builder
        |> Scale.for "box"
        |> Scale.from 1
        |> Scale.to 0
        |> Scale.duration 200
        |> Scale.easing QuintIn
        |> Scale.build
```

### Horizontal Stretch

```elm
stretch builder =
    builder
        |> Scale.for "box"
        |> Scale.fromX 1
        |> Scale.toX 1.5
        |> Scale.duration 300
        |> Scale.build
```

### Squash and Stretch

Classic animation principle for bouncy feel:

```elm
squash builder =
    builder
        |> Scale.for "box"
        |> Scale.fromX 1
        |> Scale.fromY 1
        |> Scale.toX 1.2
        |> Scale.toY 0.8
        |> Scale.duration 150
        |> Scale.easing QuintOut
        |> Scale.build
```

### Button Press

```elm
buttonPress builder =
    builder
        |> Scale.for "button"
        |> Scale.from 1
        |> Scale.to 0.95
        |> Scale.duration 100
        |> Scale.build
```

## Tips

!!! tip "Scale vs Size"
    Use `Scale` instead of `Size` whenever possible. Scale is GPU-accelerated and doesn't affect layout, while Size triggers expensive reflows.

!!! tip "Scale from center"
    By default, elements scale from their center. Use CSS `transform-origin` to change the anchor point.

!!! tip "Combine with Opacity"
    Scale animations look more polished when combined with opacity:

    ```elm
    popIn builder =
        builder
            |> Scale.for "box"
            |> Scale.from 0.8
            |> Scale.to 1
            |> Scale.build
            |> Opacity.for "box"
            |> Opacity.from 0
            |> Opacity.to 1
            |> Opacity.build
    ```

!!! warning "Scale affects children"
    Scaling affects all child elements. If you need to scale only the container, consider using `Size` or restructuring your HTML.
