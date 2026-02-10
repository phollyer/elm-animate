# Size

Animate the width and height of elements.

**Module:** `Anim.Property.Size`

**GPU Accelerated:** ❌ No — triggers browser reflows and repaints.

!!! warning "Performance Impact"
    Size changes trigger browser reflows. The scope depends on layout context—a fixed-size container with `overflow: hidden` limits reflow to its subtree. In unbounded layouts, reflow can propagate widely. Consider using `Scale` transforms when you don't need actual layout changes.

## Basic Usage

```elm
import Anim.Property.Size as Size

expandBox : AnimBuilder -> AnimBuilder
expandBox builder =
    builder
        |> Size.for "my-element"
        |> Size.fromHW 100 100
        |> Size.toHW 150 200
        |> Size.duration 300
        |> Size.build
```

## API

### Targeting

| Function | Description |
| ---------- | ------------- |
| `for` | Target an element by ID |

### Values — Uniform

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `from` | `Float` | Starting size (both dimensions) |
| `to` | `Float` | Ending size (both dimensions) |

### Values — Individual

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `fromH` | `Float` | Starting height (pixels) |
| `fromW` | `Float` | Starting width (pixels) |
| `toH` | `Float` | Ending height (pixels) |
| `toW` | `Float` | Ending width (pixels) |

### Values — Combined

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `fromHW` | `Float -> Float` | Starting height and width |
| `toHW` | `Float -> Float` | Ending height and width |

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
| `init` | Set initial size (uniform) |
| `initH`, `initW` | Set initial height or width |
| `initWH` | Set initial width and height |

## Examples

### Expand Panel

```elm
expandPanel builder =
    builder
        |> Size.for "panel"
        |> Size.fromH 0
        |> Size.toH 300
        |> Size.duration 300
        |> Size.easing QuintOut
        |> Size.build
```

### Collapse Panel

```elm
collapsePanel builder =
    builder
        |> Size.for "panel"
        |> Size.toH 0
        |> Size.duration 200
        |> Size.easing QuintIn
        |> Size.build
```

### Resize Card

```elm
resizeCard builder =
    builder
        |> Size.for "card"
        |> Size.fromHW 150 200
        |> Size.toHW 300 400
        |> Size.duration 400
        |> Size.easing QuintInOut
        |> Size.build
```

### Width-Only Animation

```elm
expandWidth builder =
    builder
        |> Size.for "drawer"
        |> Size.fromW 0
        |> Size.toW 250
        |> Size.duration 300
        |> Size.build
```

## Scale vs Size

| Aspect | Scale | Size |
| -------- | ------- | ------ |
| GPU Accelerated | ✅ Yes | ❌ No |
| Affects Layout | ❌ No | ✅ Yes |
| Affects Children | Scales children | Children reflow |
| Text Scaling | Text scales | Text reflows |
| Use When | Visual effect only | Layout must change |

### When to Use Size

- Accordion/collapsible panels where content must reflow
- Responsive resizing where layout needs to adapt
- When you need precise pixel dimensions

### When to Use Scale Instead

- Visual hover effects
- Entrance/exit animations
- When children shouldn't reflow

## Tips

!!! tip "Combine with overflow"
    For collapse animations, ensure the element has `overflow: hidden` to clip content during the animation.

!!! tip "Consider max-height"
    For accordion patterns, you might animate `max-height` via CSS instead, especially if the content height is unknown.

!!! warning "Omit `from` carefully"
    If you omit `from`, the animation starts from the element's current computed size. This works well for dynamic content but be aware the initial size depends on CSS and content.

!!! tip "Use will-change sparingly"
    Adding `will-change: width, height` can hint the browser to optimize, but use it sparingly as it consumes memory.
