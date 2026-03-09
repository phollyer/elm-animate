# Properties Overview

This page mainly covers the shared patterns that are used by each Property. For property-specific details, see each individual property page.

## Builder Pattern

Every property uses the same pattern: target an animation group, set values, configure timing, and build.

??? example "View Source Code"

    ```elm
    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Property.for "myGroup"
            >> Property.from 0              -- rarely used
            >> Property.to 100
            >> Property.delay 50
            >> Property.duration 500        -- or, Property.speed
            >> Property.easing BounceOut
            >> Property.build
    ```

📖 - [The Builder Pattern](../animation-workflow/build.md#the-builder-pattern)

## Animation Groups

These are important. An animation group is a group of properties that animate on an element together.

Properties are added to an animation group by providing the group name as a string when starting an animation pipeline. This is done with the `for` function; under the hood, the animation groups are stored as a `Dict` with the group name as the `key`, and the list of property animations the `value`.

??? example "View Source Code"

    ```elm
    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "myGroup"
            >> ... -- Continue configuring the animation
    ```

📖 - [Animation Group Names](../animation-workflow/build.md#animation-group-names)

## Start Values

All animations need a start value.

All properties have either an `init` function, or a variety of `init*` functions that are property specific, or both. These should be used in the Engine's `init` function to set initial values for properties.

??? example "View Source Code"

    ```elm
    Transitions.init [ Opacity.init "animGroupName" 0 ]

    Keyframes.init [ Size.initHW "animGroupName" 80 100 ]

    WAAPI.init [ Translate.initXYZ "animGroupName" 50 100 75 ]
    ```

This performs three functions:

- It sets initial values for first render
- It gives the Engine starting values to use for the first time the `animGroupName` is animated
- It ensures the Engine and your view are in sync

!!! tip "`from*`"
    All properties have either a `from` function, or a variety of `from*` functions that are property specific, or both. In general, these won't be needed, but are made available in order to override default Engine behaviour if required.

    If in doubt, start without; only add when needed.


## End Values

All animations need an end value.

All properties have either a `to` function, or a variety of `to*` functions that are property specific, or both.

??? example "View Source Code"

    ```elm
    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.to 1
            >> ... -- Continue configuring the animation

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 150 120
            >> ... -- Continue configuring the animation

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toXYZ 120 150 100
            >> ... -- Continue configuring the animation
    ```

## Easing

Make your animations smooth and life-like with easing curves.

All properties have an `easing` function which takes an `Easing` type variant. This will override any default easing set by the Engine.

??? example "View Source"

    ```elm 
    import Anim.Extra.Easing exposing (Easing(..))

    slideInAnimation : AnimBuilder -> AnimBuilder
    alideInAnimation =
        Translate.for "sidebarAnim"
            >> Translate.toX 0
            >> Translate.easing BounceOut
            >> ... -- Continue configuring the animation
    ```

📖 - [Easing Type](../getting-started/easing.md)

## Delay



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
    Translate.for "myGroup"
        >> Translate.toX 100
        >> Translate.duration 300  -- Overrides: 300ms
        >> Translate.build
        >> Opacity.for "myGroup"
        >> Opacity.to 1
        >> Opacity.build  -- Uses engine default: 500ms
```

## Build

`build` completes the pattern and returns an `AnimBuilder`, allowing you to chain another property or pass the result to an engine:

```elm
myAnimation : AnimBuilder -> AnimBuilder
myAnimation =
    Translate.for "myGroup"
        >> Translate.toX 100
        >> Translate.build     -- Returns AnimBuilder
        >> Opacity.for "myGroup"   -- Start next property
        >> Opacity.to 1
        >> Opacity.build       -- Returns AnimBuilder
```


## Composability

Since every property pipeline has the same type signature (`AnimBuilder -> AnimBuilder`), properties compose naturally with `>>`:

```elm
slide : AnimBuilder -> AnimBuilder
slide =
    Translate.for "myGroup"
        >> Translate.fromX -100
        >> Translate.toX 0
        >> Translate.build

fade : AnimBuilder -> AnimBuilder
fade =
    Opacity.for "myGroup"
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

## Quick Reference

| Property | Module | GPU | Dimensions | Units |
| -------- | ------ | :-: | ---------- | ----- |
| [Opacity](opacity.md) | `Anim.Property.Opacity` | ✓ | Single value | 0.0 – 1.0 |
| [Rotate](rotate.md) | `Anim.Property.Rotate` | ✓ | X, Y, Z | Degrees |
| [Scale](scale.md) | `Anim.Property.Scale` | ✓ | X, Y, Z | Multiplier (1.0 = 100%) |
| [Translate](translate.md) | `Anim.Property.Translate` | ✓ | X, Y, Z | Pixels |
| [BackgroundColor](background-color.md)| `Anim.Property.BackgroundColor` | | Single value | Color |
| [FontColor](font-color.md) | `Anim.Property.FontColor` | | Single value | Color |
| [Size](size.md) | `Anim.Property.Size` | | W, H | Pixels |


## Next Steps

Explore each property in detail:

- [Opacity](opacity.md) — Fade elements in and out
- [Rotate](rotate.md) — Rotate around X, Y, Z axes
- [Scale](scale.md) — Resize visually without layout changes
- [Translate](translate.md) — Move in 2D or 3D space
- [Background Color](background-color.md) — Animate element backgrounds
- [Font Color](font-color.md) — Animate text colors
- [Size](size.md) — Animate width and height
