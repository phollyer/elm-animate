# Rotate

Rotate elements around the X, Y, and Z axes.

**Module:** `Anim.Property.Rotate`

**GPU Accelerated:** ✅ Yes — composited on the GPU for smooth performance.

## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Property.Rotate as Rotate

    spin : AnimBuilder -> AnimBuilder
    spin =
        Rotate.for "animGroup"
            >> Rotate.toZ 360
            >> Rotate.duration 1000
            >> Rotate.build
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns.

## API

### Types

| Type | Description |
| -------- | ----------- |
| `Builder` | Alias for the Internal builder used to configure the animation |
| `AnimGroupName` | Alias for the animation group name |

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `initXYZ` | `AnimGroupName -> Float -> Float -> Float -> AnimBuilder -> AnimBuilder` | Set the initial X, Y, and Z rotation |
| `initXY` | `AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder` | Set the initial X and Y rotation |
| `initXZ` | `AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder` | Set the initial X and Z rotation |
| `initX` | `AnimGroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial X rotation |
| `initYZ` | `AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder` | Set the initial Y and Z rotation |
| `initY` | `AnimGroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial Y rotation |
| `initZ` | `AnimGroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial Z rotation |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> AnimBuilder -> Builder` | Start building |
| `build` | `Builder -> AnimBuilder` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `fromXYZ` | `Float -> Float -> Float -> Builder -> Builder` | Starting X, Y, and Z rotations (degrees) |
| `fromXY` | `Float -> Float -> Builder -> Builder` | Starting X and Y rotations (degrees) |
| `fromXZ` | `Float -> Float -> Builder -> Builder` | Starting X and Z rotations (degrees) |
| `fromX` | `Float -> Builder -> Builder` | Starting X-axis rotation (degrees) |
| `fromYZ` | `Float -> Float -> Builder -> Builder` | Starting Y and Z rotations (degrees) |
| `fromY` | `Float -> Builder -> Builder` | Starting Y-axis rotation (degrees) |
| `fromZ` | `Float -> Builder -> Builder` | Starting Z-axis rotation (degrees) |

### End Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `toXYZ` | `Float -> Float -> Float -> Builder -> Builder` | Ending X, Y, and Z rotations (degrees) |
| `toXY` | `Float -> Float -> Builder -> Builder` | Ending X and Y rotations (degrees) |
| `toXZ` | `Float -> Float -> Builder -> Builder` | Ending X and Z rotations (degrees) |
| `toX` | `Float -> Builder -> Builder` | Ending X-axis rotation (degrees) |
| `toYZ` | `Float -> Float -> Builder -> Builder` | Ending Y and Z rotations (degrees) |
| `toY` | `Float -> Builder -> Builder` | Ending Y-axis rotation (degrees) |
| `toZ` | `Float -> Builder -> Builder` | Ending Z-axis rotation (degrees) |

### Timing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `delay` | `Int -> Builder -> Builder` | The delay in ms before the animation starts |
| `duration` | `Int -> Builder -> Builder` | The duration in ms that the animation lasts for |
| `speed` | `Float -> Builder -> Builder` | Degrees per second |

### Easing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `easing` | `Easing -> Builder -> Builder` | Add natural motion |

## Next Steps

The Scale property.

[Scale →](scale.md){ .md-button .md-button--primary }

Non-GPU Accelerated Properties.

[Non-GPU →](non-gpu.md){ .md-button .md-button--primary }
