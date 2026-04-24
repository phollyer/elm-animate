# Translate

Move elements in 2D or 3D space by animating their position.

**Module:** `Anim.Property.Translate`

**GPU Accelerated:** ✅ Yes — composited on the GPU for smooth performance.

## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Property.Translate as Translate

    slideRight : AnimBuilder -> AnimBuilder
    slideRight =
        Translate.for "animGroup"
            >> Translate.toX 100
            >> Translate.duration 500
            >> Translate.build
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
| `initXYZ` | `AnimGroupName -> Float -> Float -> Float -> AnimBuilder -> AnimBuilder` | Set the initial X, Y, and Z position |
| `initXY` | `AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder` | Set the initial X and Y position |
| `initXZ` | `AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder` | Set the initial X and Z position |
| `initX` | `AnimGroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial X position |
| `initYZ` | `AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder` | Set the initial Y and Z position |
| `initY` | `AnimGroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial Y position |
| `initZ` | `AnimGroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial Z position |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> AnimBuilder -> Builder` | Start building |
| `build` | `Builder -> AnimBuilder` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `fromXYZ` | `Float -> Float -> Float -> Builder -> Builder` | Starting X, Y, and Z positions |
| `fromXY` | `Float -> Float -> Builder -> Builder` | Starting X and Y positions |
| `fromXZ` | `Float -> Float -> Builder -> Builder` | Starting X and Z positions |
| `fromX` | `Float -> Builder -> Builder` | Starting X position (pixels) |
| `fromYZ` | `Float -> Float -> Builder -> Builder` | Starting Y and Z positions |
| `fromY` | `Float -> Builder -> Builder` | Starting Y position (pixels) |
| `fromZ` | `Float -> Builder -> Builder` | Starting Z position (pixels) |

### End Value (Absolute)

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `toXYZ` | `Float -> Float -> Float -> Builder -> Builder` | Ending X, Y, and Z positions |
| `toXY` | `Float -> Float -> Builder -> Builder` | Ending X and Y positions |
| `toXZ` | `Float -> Float -> Builder -> Builder` | Ending X and Z positions |
| `toX` | `Float -> Builder -> Builder` | Ending X position (pixels) |
| `toYZ` | `Float -> Float -> Builder -> Builder` | Ending Y and Z positions |
| `toY` | `Float -> Builder -> Builder` | Ending Y position (pixels) |
| `toZ` | `Float -> Builder -> Builder` | Ending Z position (pixels) |

### End Value (Relative)

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `byXYZ` | `Float -> Float -> Float -> Builder -> Builder` | Move by X, Y, and Z amounts |
| `byXY` | `Float -> Float -> Builder -> Builder` | Move by X and Y amounts |
| `byXZ` | `Float -> Float -> Builder -> Builder` | Move by X and Z amounts |
| `byX` | `Float -> Builder -> Builder` | Move by X amount |
| `byYZ` | `Float -> Float -> Builder -> Builder` | Move by Y and Z amounts |
| `byY` | `Float -> Builder -> Builder` | Move by Y amount |
| `byZ` | `Float -> Builder -> Builder` | Move by Z amount |

### Timing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `delay` | `Int -> Builder -> Builder` | The delay in ms before the animation starts |
| `duration` | `Int -> Builder -> Builder` | The duration in ms that the animation lasts for |
| `speed` | `Float -> Builder -> Builder` | Pixels per second |

### Easing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `easing` | `Easing -> Builder -> Builder` | Add natural motion |

## Next Steps

Non-GPU Accelerated Properties.

[Non-GPU →](non-gpu.md){ .md-button .md-button--primary }

