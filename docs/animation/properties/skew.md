# Skew

Skew elements along the X and Y axes.

**Module:** `Anim.Property.Skew`

**GPU Accelerated:** ✅ Yes — composited with transform on the GPU.

## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Property.Skew as Skew

    tilt : AnimBuilder -> AnimBuilder
    tilt =
        Skew.for "animGroup"
            >> Skew.toXY 12 0
            >> Skew.duration 400
            >> Skew.build
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns.

## API

### Types

| Type | Description |
| -------- | ----------- |
| `Builder` | Alias for the internal builder used to configure the animation |
| `AnimGroupName` | Alias for the animation group name |

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `initXY` | `AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder` | Set the initial X and Y skew |
| `initX` | `AnimGroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial X skew |
| `initY` | `AnimGroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial Y skew |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> AnimBuilder -> Builder` | Start building |
| `build` | `Builder -> AnimBuilder` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `fromXY` | `Float -> Float -> Builder -> Builder` | Starting X and Y skew (degrees) |
| `fromX` | `Float -> Builder -> Builder` | Starting X skew (degrees) |
| `fromY` | `Float -> Builder -> Builder` | Starting Y skew (degrees) |

### End Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `toXY` | `Float -> Float -> Builder -> Builder` | Ending X and Y skew (degrees) |
| `toX` | `Float -> Builder -> Builder` | Ending X skew (degrees) |
| `toY` | `Float -> Builder -> Builder` | Ending Y skew (degrees) |

### Timing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `delay` | `Int -> Builder -> Builder` | Delay in ms before animation starts |
| `duration` | `Int -> Builder -> Builder` | Duration in ms |
| `speed` | `Float -> Builder -> Builder` | Degrees per second |

### Easing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `easing` | `Easing -> Builder -> Builder` | Add natural motion |

## Next Steps

The Scale property.

[Scale →](scale.md){ .md-button .md-button--primary }
