# Translate

Move elements in 2D or 3D space by animating their position.

**Module:** `Anim.Property.Translate`

**GPU Accelerated:** ✅ Yes — composited on the GPU for smooth performance.

## Basic Usage

```elm
import Anim.Property.Translate as Translate

slideRight : AnimBuilder -> AnimBuilder
slideRight builder =
    builder
        |> Translate.for "my-element"
        |> Translate.fromX 0
        |> Translate.toX 100
        |> Translate.duration 500
        |> Translate.build
```

See the [Properties Overview](overview.md) page for the shared usage patterns.

## API

### Values — Uniform (all axes)

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `from` | `Float` | Starting position (all axes) |
| `to` | `Float` | Ending position (all axes) |

### Values — Individual Axes

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `fromX` | `Float` | Starting X position (pixels) |
| `fromY` | `Float` | Starting Y position (pixels) |
| `fromZ` | `Float` | Starting Z position (pixels) |
| `toX` | `Float` | Ending X position (pixels) |
| `toY` | `Float` | Ending Y position (pixels) |
| `toZ` | `Float` | Ending Z position (pixels) |

### Values — Combined

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `fromXY` | `Float -> Float` | Starting X and Y positions |
| `fromXZ` | `Float -> Float` | Starting X and Z positions |
| `fromYZ` | `Float -> Float` | Starting Y and Z positions |
| `fromXYZ` | `Float -> Float -> Float` | Starting X, Y, and Z positions |
| `toXY` | `Float -> Float` | Ending X and Y positions |
| `toXZ` | `Float -> Float` | Ending X and Z positions |
| `toYZ` | `Float -> Float` | Ending Y and Z positions |
| `toXYZ` | `Float -> Float -> Float` | Ending X, Y, and Z positions |

### Relative Movement (by)

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `by` | `Float` | Move by amount (all axes) |
| `byX` | `Float` | Move by X amount |
| `byY` | `Float` | Move by Y amount |
| `byZ` | `Float` | Move by Z amount |
| `byXY` | `Float -> Float` | Move by X and Y amounts |
| `byXZ` | `Float -> Float` | Move by X and Z amounts |
| `byYZ` | `Float -> Float` | Move by Y and Z amounts |
| `byXYZ` | `Float -> Float -> Float` | Move by X, Y, and Z amounts |

### Initialization

| Function | Description |
| ---------- | ------------- |
| `init` | Set initial position (uniform) |
| `initX`, `initY`, `initZ` | Set initial position on single axis |
| `initXY`, `initXZ`, `initYZ` | Set initial position on two axes |
| `initXYZ` | Set initial X, Y, and Z positions |

## Next Steps

Non-GPU Accelerated Properties.

[Non-GPU →](non-gpu.md){ .md-button .md-button--primary }

Play with and learn from the examples.

[Examples →](../examples.md){ .md-button .md-button--primary }

