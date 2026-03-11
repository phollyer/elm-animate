# Scale

Scale elements uniformly or independently on each axis.

**Module:** `Anim.Property.Scale`

**GPU Accelerated:** ✅ Yes — composited on the GPU for smooth performance.

## Basic Usage

??? example "Show Source Code"

    ```elm
    import Anim.Property.Scale as Scale

    grow : AnimBuilder -> AnimBuilder
    grow =
        Scale.for "animGroup"
            >> Scale.to 1.5
            >> Scale.duration 300
            >> Scale.build
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns.

## API

### Types

| Type | Description |
| -------- | ----------- |
| `Builder` | Alias for the Internal builder used to configure the animation |
| `GroupName` | Alias for the animation group name |

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `init` | `GroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial scale (uniform) |
| `initXYZ` | `GroupName -> Float -> Float -> Float -> AnimBuilder -> AnimBuilder` | Set the initial X, Y, and Z scale |
| `initXY` | `GroupName -> Float -> Float -> AnimBuilder -> AnimBuilder` | Set the initial X and Y scale |
| `initXZ` | `GroupName -> Float -> Float -> AnimBuilder -> AnimBuilder` | Set the initial X and Z scale |
| `initX` | `GroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial X scale |
| `initYZ` | `GroupName -> Float -> Float -> AnimBuilder -> AnimBuilder` | Set the initial Y and Z scale |
| `initY` | `GroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial Y scale |
| `initZ` | `GroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial Z scale |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `GroupName -> AnimBuilder -> Builder` | Start building |
| `build` | `Builder -> AnimBuilder` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `from` | `Float -> Builder -> Builder` | Starting scale (uniform, 1.0 = 100%) |
| `fromXYZ` | `Float -> Float -> Float -> Builder -> Builder` | Starting X, Y, and Z scales |
| `fromXY` | `Float -> Float -> Builder -> Builder` | Starting X and Y scales |
| `fromXZ` | `Float -> Float -> Builder -> Builder` | Starting X and Z scales |
| `fromX` | `Float -> Builder -> Builder` | Starting X-axis scale |
| `fromYZ` | `Float -> Float -> Builder -> Builder` | Starting Y and Z scales |
| `fromY` | `Float -> Builder -> Builder` | Starting Y-axis scale |
| `fromZ` | `Float -> Builder -> Builder` | Starting Z-axis scale |

### End Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `to` | `Float -> Builder -> Builder` | Ending scale (uniform, 1.0 = 100%) |
| `toXYZ` | `Float -> Float -> Float -> Builder -> Builder` | Ending X, Y, and Z scales |
| `toXY` | `Float -> Float -> Builder -> Builder` | Ending X and Y scales |
| `toXZ` | `Float -> Float -> Builder -> Builder` | Ending X and Z scales |
| `toX` | `Float -> Builder -> Builder` | Ending X-axis scale |
| `toYZ` | `Float -> Float -> Builder -> Builder` | Ending Y and Z scales |
| `toY` | `Float -> Builder -> Builder` | Ending Y-axis scale |
| `toZ` | `Float -> Builder -> Builder` | Ending Z-axis scale |

### Timing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `delay` | `Int -> Builder -> Builder` | The delay in ms before the animation starts |
| `duration` | `Int -> Builder -> Builder` | The duration in ms that the animation lasts for |
| `speed` | `Float -> Builder -> Builder` | Scale units per second |

### Easing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `easing` | `Easing -> Builder -> Builder` | Add natural motion |

## Next Steps

The Translate property.

[Translate →](translate.md){ .md-button .md-button--primary }

Non-GPU Accelerated Properties.

[Non-GPU →](non-gpu.md){ .md-button .md-button--primary }

Play with and learn from the examples.

[Examples →](../examples.md){ .md-button .md-button--primary }


