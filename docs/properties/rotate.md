# Rotate

Rotate elements around the X, Y, and Z axes.

**Module:** `Anim.Property.Rotate`

**GPU Accelerated:** ✅ Yes — composited on the GPU for smooth performance.

## Basic Usage

```elm
import Anim.Property.Rotate as Rotate

spin : AnimBuilder -> AnimBuilder
spin builder =
    builder
        |> Rotate.for "my-element"
        |> Rotate.fromZ 0
        |> Rotate.toZ 360
        |> Rotate.duration 1000
        |> Rotate.build
```

See the [Properties Overview](overview.md) for the shared patterns.

## API

### Values — Uniform (all axes)

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `from` | `Float` | Starting rotation in degrees (all axes) |
| `to` | `Float` | Ending rotation in degrees (all axes) |

### Values — Individual Axes

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `fromX` | `Float` | Starting X-axis rotation (degrees) |
| `fromY` | `Float` | Starting Y-axis rotation (degrees) |
| `fromZ` | `Float` | Starting Z-axis rotation (degrees) |
| `toX` | `Float` | Ending X-axis rotation (degrees) |
| `toY` | `Float` | Ending Y-axis rotation (degrees) |
| `toZ` | `Float` | Ending Z-axis rotation (degrees) |

### Values — Combined

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `fromXY` | `Float -> Float` | Starting X and Y rotations |
| `fromXZ` | `Float -> Float` | Starting X and Z rotations |
| `fromYZ` | `Float -> Float` | Starting Y and Z rotations |
| `fromXYZ` | `Float -> Float -> Float` | Starting X, Y, and Z rotations |
| `toXY` | `Float -> Float` | Ending X and Y rotations |
| `toXZ` | `Float -> Float` | Ending X and Z rotations |
| `toYZ` | `Float -> Float` | Ending Y and Z rotations |
| `toXYZ` | `Float -> Float -> Float` | Ending X, Y, and Z rotations |

### Initialization

| Function | Description |
| ---------- | ------------- |
| `init` | Set initial rotation (uniform) |
| `initX`, `initY`, `initZ` | Set initial rotation on single axis |
| `initXY`, `initXZ`, `initYZ` | Set initial rotation on two axes |
| `initXYZ` | Set initial rotation on all axes |

## Next Steps

The Scale property.

[Scale →](scale.md){ .md-button .md-button--primary }

Non-GPU Accelerated Properties.

[Non-GPU →](non-gpu.md){ .md-button .md-button--primary }

Play with and learn from the examples.

[Examples →](../examples.md){ .md-button .md-button--primary }

