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
        |> Rotate.from 0
        |> Rotate.to 360
        |> Rotate.duration 1000
        |> Rotate.build
```

## API

### Targeting

| Function | Description |
| ---------- | ------------- |
| `for` | Target an element by ID |

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

### Timing

| Function | Description |
| ---------- | ------------- |
| `duration` | Animation duration in milliseconds |
| `speed` | Animation speed in degrees per second |
| `delay` | Delay before animation starts |
| `easing` | Easing function for the animation |

### Initialization

| Function | Description |
| ---------- | ------------- |
| `init` | Set initial rotation (uniform) |
| `initX`, `initY`, `initZ` | Set initial rotation on single axis |
| `initXY`, `initXZ`, `initYZ` | Set initial rotation on two axes |
| `initXYZ` | Set initial rotation on all axes |

## Examples

### Simple Spin (Z-axis)

```elm
spin builder =
    builder
        |> Rotate.for "box"
        |> Rotate.from 0
        |> Rotate.to 360
        |> Rotate.duration 1000
        |> Rotate.easing Linear
        |> Rotate.build
```

### Flip Card (Y-axis)

```elm
flipCard builder =
    builder
        |> Rotate.for "card"
        |> Rotate.fromY 0
        |> Rotate.toY 180
        |> Rotate.duration 600
        |> Rotate.easing QuintInOut
        |> Rotate.build
```

!!! note "Requires perspective"
    Y-axis rotation needs perspective on a parent container to look 3D. See [3D Animations](../concepts/3d.md).

### Tilt Effect (X-axis)

```elm
tilt builder =
    builder
        |> Rotate.for "box"
        |> Rotate.fromX 0
        |> Rotate.toX 15
        |> Rotate.duration 300
        |> Rotate.build
```

### Combined 3D Rotation

```elm
tumble builder =
    builder
        |> Rotate.for "box"
        |> Rotate.fromX 0
        |> Rotate.fromY 0
        |> Rotate.fromZ 0
        |> Rotate.toX 45
        |> Rotate.toY 90
        |> Rotate.toZ 180
        |> Rotate.duration 1000
        |> Rotate.build
```

## Tips

!!! tip "Z-axis for 2D rotation"
    For simple 2D rotation (like spinning a loading icon), use Z-axis rotation — it rotates in the plane of the screen.

!!! tip "Transform order affects path"
    When combining Rotate with Translate, the order determines whether the element moves along screen coordinates or rotated coordinates. See [Transform Order](../concepts/3d.md#transform-order).

!!! warning "Gimbal lock"
    Complex 3D rotations on multiple axes can exhibit gimbal lock. For advanced 3D work, consider animating axes separately with careful sequencing.
