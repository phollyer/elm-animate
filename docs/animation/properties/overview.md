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

📖 - [The Builder Pattern](../workflow/build.md#the-builder-pattern)

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

📖 - [Animation Group Names](../workflow/build.md#animation-group-names)

## Start Values

All animations need a start value.

All properties have either an `init` function, or a variety of `init*` functions that are property specific, or both. These should be used in the Engine's `init` function to set initial values for properties.

??? example "View Source Code"

    ```elm
    Transition.init [ Opacity.init "animGroup" 0 ]

    Keyframe.init [ Size.initHW "animGroup" 80 100 ]

    WAAPI.init [ Translate.initXYZ "animGroup" 50 100 75 ]
    ```

This performs three functions:

- It sets initial values for first render
- It gives the Engine starting values to use for the first time the `animGroup` is animated
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
        Opacity.for "animGroup"
            >> Opacity.to 1
            >> ... -- Continue configuring the animation

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Size.for "animGroup"
            >> Size.toHW 150 120
            >> ... -- Continue configuring the animation

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroup"
            >> Translate.toXYZ 120 150 100
            >> ... -- Continue configuring the animation
    ```

## Easing

Make your animations smooth and life-like with easing curves.

All properties have an `easing` function which takes an `Easing` type variant. This will override any default easing set by the Engine.

??? example "View Source"

    ```elm 
    import Easing exposing (Easing(..))

    slideInAnimation : AnimBuilder -> AnimBuilder
    alideInAnimation =
        Translate.for "sidebarAnim"
            >> Translate.toX 0
            >> Translate.easing BounceOut
            >> ... -- Continue configuring the animation
    ```

📖 - [Easing Type](../concepts/easing.md)

## Delay

Add a delay before the animation starts.

All properties have a `delay` function which takes an `Int` representing milliseconds. This will override any default delay set by the Engine.

??? example "View Source Code"

    ```elm
    fadeInAfterDelay : AnimBuilder -> AnimBuilder
    fadeInAfterDelay =
        Opacity.for "contentAnim"
            >> Opacity.to 1
            >> Opacity.delay 300
            >> ... -- Continue configuring the animation
    ```

!!! tip "Staggering animations"
    Use different delays on properties within the same group to stagger their start times, creating a sequenced feel without needing separate animations.


## Duration

Set a fixed time for the animation to complete.

All properties have a `duration` function which takes an `Int` representing milliseconds. This will override any default duration set by the Engine.

??? example "View Source Code"

    ```elm
    slideIn : AnimBuilder -> AnimBuilder
    slideIn =
        Translate.for "panelAnim"
            >> Translate.toX 0
            >> Translate.duration 500
            >> ... -- Continue configuring the animation
    ```

📖 - [Duration vs Speed](../concepts/timing.md#duration-vs-speed)


## Speed

Set a consistent velocity for the animation, where time varies based on the distance between start and end values. Longer distances take longer, shorter distances take less time.

All properties have a `speed` function which takes a `Float`. The unit depends on the property. This will override any default speed set by the Engine.

??? example "View Source Code"

    ```elm
    moveToTarget : Float -> AnimBuilder -> AnimBuilder
    moveToTarget targetX =
        Translate.for "cursorAnim"
            >> Translate.toX targetX
            >> Translate.speed 500
            >> ... -- Continue configuring the animation
    ```

!!! tip "When to use `speed` over `duration`"
    `speed` is ideal when the distance varies at runtime — for example, drag-and-drop targets or scrolling to dynamic positions. It gives a consistent feel regardless of how far the element needs to travel.

📖 - [Duration vs Speed](../concepts/timing.md#duration-vs-speed)

## Build

`build` completes the pattern and returns an `AnimBuilder`, allowing you to build another animation or pass the builder to an engine for triggering.

??? example "View Source Code"

    ```elm
    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "myGroup"
            >> Translate.toX 100
            >> Translate.build              -- Returns AnimBuilder
            >> Opacity.for "myGroup"        -- Start next property
            >> Opacity.to 1
            >> Opacity.build                -- Returns AnimBuilder
            >> Translate.for "myOtherGroup" -- Start another group
            >> Translate.toY 200
            >> Translate.build              -- Returns AnimBuilder
    ```

📖 - [The Builder Pattern](../workflow/build.md#the-builder-pattern)

## Quick Reference

| Property | Module | GPU | Dimensions | Units |
| -------- | ------ | :-: | ---------- | ----- |
| [BackgroundColor](background-color.md) | `Anim.Property.BackgroundColor` | | Single value | Color |
| [FontColor](font-color.md) | `Anim.Property.FontColor` | | Single value | Color |
| [Opacity](opacity.md) | `Anim.Property.Opacity` | ✓ | Single value | 0.0 – 1.0 |
| [Rotate](rotate.md) | `Anim.Property.Rotate` | ✓ | X, Y, Z | Degrees |
| [Scale](scale.md) | `Anim.Property.Scale` | ✓ | X, Y, Z | Multiplier (1.0 = 100%) |
| [Skew](skew.md) | `Anim.Property.Skew` | ✓ | X, Y | Degrees |
| [Size](size.md) | `Anim.Property.Size` | | W, H | Pixels |
| [Translate](translate.md) | `Anim.Property.Translate` | ✓ | X, Y, Z | Pixels |
| [Custom Property](custom-property.md) | `Anim.Property.Custom` | varies | Single value | Any unit |
| [Custom Color Property](custom-color-property.md) | `Anim.Property.CustomColor` | varies | Single value | Color |


## Next Steps

GPU Accelerated Properties.

[GPU Accelerated →](gpu.md){ .md-button .md-button--primary }

