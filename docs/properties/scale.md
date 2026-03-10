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

See the [Properties Overview](overview.md) for the shared patterns.

## API

### Values — Uniform

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `from` | `Float` | Starting scale (1.0 = 100%) |
| `to` | `Float` | Ending scale (1.0 = 100%) |

### Values — Individual Axes

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `fromX` | `Float` | Starting X-axis scale |
| `fromY` | `Float` | Starting Y-axis scale |
| `fromZ` | `Float` | Starting Z-axis scale |
| `toX` | `Float` | Ending X-axis scale |
| `toY` | `Float` | Ending Y-axis scale |
| `toZ` | `Float` | Ending Z-axis scale |

### Values — Combined

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `fromXY` | `Float -> Float` | Starting X and Y scales |
| `fromXZ` | `Float -> Float` | Starting X and Z scales |
| `fromYZ` | `Float -> Float` | Starting Y and Z scales |
| `fromXYZ` | `Float -> Float -> Float` | Starting X, Y, and Z scales |
| `toXY` | `Float -> Float` | Ending X and Y scales |
| `toXZ` | `Float -> Float` | Ending X and Z scales |
| `toYZ` | `Float -> Float` | Ending Y and Z scales |
| `toXYZ` | `Float -> Float -> Float` | Ending X, Y, and Z scales |

### Initialization

| Function | Description |
| ---------- | ------------- |
| `init` | Set initial scale (uniform) |
| `initX`, `initY`, `initZ` | Set initial scale on single axis |
| `initXY`, `initXZ`, `initYZ` | Set initial scale on two axes |
| `initXYZ` | Set initial scale on all axes |

## Next Steps

The Translate property.

[Translate →](translate.md){ .md-button .md-button--primary }

Non-GPU Accelerated Properties.

[Non-GPU →](non-gpu.md){ .md-button .md-button--primary }

Play with and learn from the examples.

[Examples →](../examples.md){ .md-button .md-button--primary }


