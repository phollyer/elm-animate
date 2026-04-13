# Size

Animate the width and height of elements.

**Module:** `Anim.Property.Size`

**GPU Accelerated:** ❌ No — triggers browser reflows and repaints.

!!! warning "Performance Impact"
    Size changes trigger browser reflows. The scope depends on layout context—a fixed-size container with `overflow: hidden` limits reflow to its subtree. In unbounded layouts, reflow can propagate widely. Consider using `Scale` transforms when you don't need actual layout changes.

## Basic Usage

??? example "Show Source Code"

    ```elm
    import Anim.Property.Size as Size

    expandBox : AnimBuilder -> AnimBuilder
    expandBox =
        Size.for "animGroup"
            >> Size.toHW 150 200
            >> Size.duration 300
            >> Size.build
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
| `init` | `AnimGroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial size (uniform) |
| `initWH` | `AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder` | Set the initial width and height |
| `initW` | `AnimGroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial width |
| `initH` | `AnimGroupName -> Float -> AnimBuilder -> AnimBuilder` | Set the initial height |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> AnimBuilder -> Builder` | Start building |
| `build` | `Builder -> AnimBuilder` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `fromHW` | `Float -> Float -> Builder -> Builder` | Starting height and width |
| `fromH` | `Float -> Builder -> Builder` | Starting height (pixels) |
| `fromW` | `Float -> Builder -> Builder` | Starting width (pixels) |

### End Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `toHW` | `Float -> Float -> Builder -> Builder` | Ending height and width |
| `toH` | `Float -> Builder -> Builder` | Ending height (pixels) |
| `toW` | `Float -> Builder -> Builder` | Ending width (pixels) |

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

Play with and learn from the examples.

[Examples →](../examples.md){ .md-button .md-button--primary }

