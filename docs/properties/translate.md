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

## API

### Targeting

| Function | Description |
| ---------- | ------------- |
| `for` | Target an element by ID |

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

### Timing

| Function | Description |
| ---------- | ------------- |
| `duration` | Animation duration in milliseconds |
| `speed` | Animation speed in pixels per second |
| `delay` | Delay before animation starts |
| `easing` | Easing function for the animation |

### Initialization

| Function | Description |
| ---------- | ------------- |
| `init` | Set initial position (uniform) |
| `initX`, `initY`, `initZ` | Set initial position on single axis |
| `initXY`, `initXZ`, `initYZ` | Set initial position on two axes |
| `initXYZ` | Set initial X, Y, and Z positions |

## Examples

### Slide In From Left

```elm
slideInLeft builder =
    builder
        |> Translate.for "box"
        |> Translate.fromX -100
        |> Translate.toX 0
        |> Translate.duration 500
        |> Translate.easing QuintOut
        |> Translate.build
```

### Diagonal Movement

```elm
moveDiagonally builder =
    builder
        |> Translate.for "box"
        |> Translate.fromXY 0 0
        |> Translate.toXY 100 100
        |> Translate.duration 500
        |> Translate.build
```

### 3D Movement

```elm
moveIn3D builder =
    builder
        |> Translate.for "box"
        |> Translate.fromXYZ 0 0 -200
        |> Translate.toXYZ 0 0 0
        |> Translate.duration 800
        |> Translate.easing QuintOut
        |> Translate.build
```

!!! note "3D requires perspective"
    For Z-axis movement to be visible, apply perspective to a parent container. See [3D Animations](../concepts/3d.md).

### Speed-Based Animation

Use `speed` for consistent velocity regardless of distance:

```elm
moveToTarget targetX builder =
    builder
        |> Translate.for "box"
        |> Translate.toX targetX
        |> Translate.speed 500  -- 500 pixels per second
        |> Translate.build
```

## Tips

!!! tip "Omit `from` for current position"
    If you omit `from` values, the animation starts from the element's current position. This enables smooth interruptions when redirecting animations mid-flight.

!!! tip "Use `speed` for drag interactions"
    When animating to a user-defined target (like drag-and-drop), `speed` gives consistent feel regardless of distance.

!!! tip "Transform order matters"
    If combining Translate with Rotate, the order affects the path. See [Transform Order](../concepts/3d.md#transform-order) for details.
