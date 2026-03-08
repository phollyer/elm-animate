# Properties Overview

This page covers the shared patterns used by all property modules. For property-specific details, see:

**GPU Accelerated:**

- [Opacity](opacity.md) — Fade elements in and out
- [Rotate](rotate.md) — Rotate around X, Y, Z axes
- [Scale](scale.md) — Resize visually without layout changes
- [Translate](translate.md) — Move in 2D or 3D space

**Non-GPU:**

- [Background Color](background-color.md) — Animate element backgrounds
- [Font Color](font-color.md) — Animate text colors
- [Size](size.md) — Animate width and height (triggers reflow)


## Quick Reference

| Property | Module | GPU | Dimensions | Units |
| -------- | ------ | :-: | ---------- | ----- |
| Opacity | `Anim.Property.Opacity` | ✓ | Single value | 0.0 – 1.0 |
| Rotate | `Anim.Property.Rotate` | ✓ | X, Y, Z | Degrees |
| Scale | `Anim.Property.Scale` | ✓ | X, Y, Z | Multiplier (1.0 = 100%) |
| Translate | `Anim.Property.Translate` | ✓ | X, Y, Z | Pixels |
| Background Color | `Anim.Property.BackgroundColor` | | Single value | Color |
| Font Color | `Anim.Property.FontColor` | | Single value | Color |
| Size | `Anim.Property.Size` | | W, H | Pixels |


## Builder Pipeline

Every property uses the same pipeline: target an element, set values, configure timing, and build:

```elm
myAnimation : AnimBuilder -> AnimBuilder
myAnimation =
    Translate.for "box"
        >> Translate.fromX 0
        >> Translate.toX 100
        >> Translate.duration 500
        >> Translate.build
```

The pipeline always follows this structure:

| Step | Function | Purpose |
| ---- | -------- | ------- |
| 1 | `for` | Target an element by ID — returns a `Builder` |
| 2 | `from` / `to` | Set start and end values |
| 3 | Timing | Set `duration`, `speed`, `delay`, `easing` |
| 4 | `build` | Complete the pipeline — returns an `AnimBuilder` |

Steps 2 and 3 can be in any order, and both are optional. The only required steps are `for` and `build`.


## Targeting

`for` starts the pipeline by targeting a DOM element by its string ID:

```elm
Opacity.for "my-element"
Scale.for "card"
Translate.for "box"
```

This is the same element ID used in your HTML or Elm view (e.g., `Html.Attributes.id "box"`).


## Values

### Absolute Values

`from` sets the starting value and `to` sets the ending value:

```elm
Opacity.from 0 >> Opacity.to 1
Translate.fromX 0 >> Translate.toX 100
BackgroundColor.from (hex "#fff") >> BackgroundColor.to (hex "#000")
```

Multi-axis properties (Translate, Rotate, Scale) provide axis-specific variants:

```elm
-- Individual axes
Translate.fromX 0 >> Translate.toX 100

-- Combined axes
Translate.fromXY 0 0 >> Translate.toXY 100 200

-- All three axes
Rotate.fromXYZ 0 0 0 >> Rotate.toXYZ 45 90 180
```

Size uses W (width) and H (height) instead of X and Y:

```elm
Size.fromHW 100 200 >> Size.toHW 150 300
```

### Omitting `from`

If you omit `from`, the animation starts from the element's current value. This enables smooth interruptions — if you redirect an animation mid-flight, the new animation picks up from wherever the element currently is rather than jumping to a fixed start position.

```elm
-- Animates from current position to 200
Translate.for "box"
    >> Translate.toX 200
    >> Translate.duration 500
    >> Translate.build
```

!!! note "Engine differences"
    How `from` omission is handled depends on the engine. Sub and WAAPI capture the current interpolated value mid-flight. Transitions start from whatever the CSS computed value is. See each engine's documentation for specifics.

### Relative Values

Translate, Rotate, Scale, and Size support `by` functions for relative movement — the animation moves by the specified amount from the current value:

```elm
-- Move 100px to the right from current position
Translate.byX 100

-- Rotate 90 degrees from current angle
Rotate.byZ 90

-- Scale up by 50% from current scale
Scale.by 1.5
```

Multi-axis `by` variants follow the same pattern as `from` / `to`:

```elm
Translate.byXY 50 100
Size.byHW 20 40
```


## Timing

All properties share the same four timing functions:

| Function | Type | Description |
| -------- | ---- | ----------- |
| `duration` | `Int` | Animation length in milliseconds |
| `speed` | `Float` | Animation speed (unit depends on property) |
| `delay` | `Int` | Wait before starting, in milliseconds |
| `easing` | `Easing` | Easing curve — see [Easing Functions](../getting-started/easing.md) |

`duration` and `speed` are alternatives — use one or the other:

- **`duration`** — fixed time regardless of distance. A 500ms animation always takes 500ms.
- **`speed`** — consistent velocity regardless of distance. Longer distances take longer.

The unit for `speed` depends on the property:

| Property | Speed Unit |
| -------- | ---------- |
| Translate | Pixels per second |
| Rotate | Degrees per second |
| Scale | Scale units per second |
| Size | Pixels per second |
| Opacity | Opacity units per second |
| Colors | Color units per second |

### Per-Property Overrides

Each property's timing overrides the engine-level defaults. If you set `duration 500` on the engine and `duration 300` on Translate, the translation takes 300ms while other properties use 500ms:

```elm
-- Engine sets 500ms default for all properties
Transitions.animate model.animState <|
    Transitions.duration 500
        >> slideAndFade

slideAndFade : AnimBuilder -> AnimBuilder
slideAndFade =
    Translate.for "box"
        >> Translate.toX 100
        >> Translate.duration 300  -- Overrides: 300ms
        >> Translate.build
        >> Opacity.for "box"
        >> Opacity.to 1
        >> Opacity.build  -- Uses engine default: 500ms
```


## Initialization

`init` sets an element's starting value so the engine can render it in your view before any animation runs. Without `init`, elements would start at their CSS default values until the first animation triggers.

```elm
animState =
    Transitions.init
        [ Opacity.init "box" 0          -- Start invisible
        , Translate.initXY "box" -100 0  -- Start off-screen
        ]
```

Multi-axis properties provide axis-specific init variants:

| Dimensions | Init Variants |
| ---------- | ------------- |
| Single (Opacity, Colors) | `init` |
| W×H (Size) | `init`, `initW`, `initH`, `initWH` |
| X,Y,Z (Translate, Rotate, Scale) | `init`, `initX`, `initY`, `initZ`, `initXY`, `initXZ`, `initYZ`, `initXYZ` |


## Build

`build` completes the property pipeline and returns an `AnimBuilder`, allowing you to chain another property or pass the result to an engine:

```elm
myAnimation : AnimBuilder -> AnimBuilder
myAnimation =
    Translate.for "box"
        >> Translate.toX 100
        >> Translate.build     -- Returns AnimBuilder
        >> Opacity.for "box"   -- Start next property
        >> Opacity.to 1
        >> Opacity.build       -- Returns AnimBuilder
```


## Composability

Since every property pipeline has the same type signature (`AnimBuilder -> AnimBuilder`), properties compose naturally with `>>`:

```elm
slide : AnimBuilder -> AnimBuilder
slide =
    Translate.for "box"
        >> Translate.fromX -100
        >> Translate.toX 0
        >> Translate.build

fade : AnimBuilder -> AnimBuilder
fade =
    Opacity.for "box"
        >> Opacity.from 0
        >> Opacity.to 1
        >> Opacity.build

-- Compose into a single animation
slideAndFade : AnimBuilder -> AnimBuilder
slideAndFade =
    slide >> fade
```

This works because `build` returns `AnimBuilder` and `for` accepts `AnimBuilder` — one property's output is the next property's input. You can compose as many properties as you need, and the result is always `AnimBuilder -> AnimBuilder`.


## Performance

GPU-accelerated properties (Opacity, Rotate, Scale, Translate) are composited on a separate GPU layer. The browser can animate them without touching the main thread, giving smooth 60fps performance.

Non-GPU properties trigger different levels of rendering work:

| Impact | Properties | Description |
| ------ | ---------- | ----------- |
| Repaint | Background Color, Font Color | Browser redraws pixels but layout is unchanged |
| Reflow + Repaint | Size | Browser recalculates layout for the element and potentially its neighbours — then repaints |

!!! tip "Prefer GPU properties when possible"
    If you only need a visual resize effect (no layout reflow), use `Scale` instead of `Size`. See [Scale vs Size](size.md#scale-vs-size) for a detailed comparison.


## Next Steps

Explore each property in detail:

- [Opacity](opacity.md) — Fade elements in and out
- [Rotate](rotate.md) — Rotate around X, Y, Z axes
- [Scale](scale.md) — Resize visually without layout changes
- [Translate](translate.md) — Move in 2D or 3D space
- [Background Color](background-color.md) — Animate element backgrounds
- [Font Color](font-color.md) — Animate text colors
- [Size](size.md) — Animate width and height
