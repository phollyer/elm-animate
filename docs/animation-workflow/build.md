# Build

## The Builder Pattern

Elm Animate uses a fluent builder pattern for defining animations. This approach provides a consistent, composable API across all engines and properties that reads naturally and is easy to reason about — you can see at a glance what an animation does and how it behaves.

## Basic Structure

Every animation follows this pattern:


??? example "Show Source Code"

    ```elm
    animationFunction : AnimBuilder -> AnimBuilder
    animationFunction =
        Property.for animGroup              -- Animation group name (required)
            >> Property.from startValue     -- Mainly used for `fireAndForget` animations
            >> Property.to endValue         -- Property specific alternatives to `to` are available
            >> Property.delay 100           -- ms
            >> Property.duration 500        -- ms, or `Property.speed 50` (units per second)
            >> Property.easing BounceOut    -- Make the animation feel natural
            >> Property.build               -- Finalize (required)
    ```

    `for` and `build` are required to start and end the builder chain respectively. All other configurations are optional, although without an end value the animations won't have anywhere to go!!

## Animation Group Names

The first argument to `Property.for` is the **animation group name** — a string that groups animation configurations together. Use it to animate multiple properties at once, or to create multiple animations for different elements.

### Multiple Properties

Properties with the same group name animate together and are applied to the same element:

??? example "View Source Code"

    ```elm
    -- Both properties share "boxAnim" - they animate together on the same element
    enterAnimation : AnimBuilder -> AnimBuilder
    enterAnimation =
        Opacity.for "boxAnim"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build
            >> Translate.for "boxAnim"
            >> Translate.fromY 50
            >> Translate.toY 0
            >> Translate.build
    ```

### Multiple Animations

Use different group names when you want separate animation sets for different elements:

??? example "View Source Code"

    ```elm
    -- Different groups for different element animations
    pageAnimations : AnimBuilder -> AnimBuilder
    pageAnimations =
        Opacity.for "header"            -- Header fades in
            >> Opacity.to 1
            >> Opacity.build
            >> Translate.for "sidebar"  -- Sidebar slides in
            >> Translate.fromX -200
            >> Translate.toX 0
            >> Translate.build
    ```

### WAAPI Composite Keys

The WAAPI Engine extends group names into **composite keys** (`"elementId:groupName"`), enabling independent control of multiple animation groups on the same DOM element. See [Composite Keys and Animation Groups](../engines/waapi.md#composite-keys-and-animation-groups) for details.

## Why Builders?

The `AnimBuilder -> AnimBuilder` type signature enables [function composition](https://package.elm-lang.org/packages/elm/core/latest/Basics#function-helpers)
with `>>`. Small, focused animations combine into larger ones:

??? example "Show Source Code"

    ```elm
    fadeIn : String -> AnimBuilder -> AnimBuilder
    fadeIn animGroup =
        Opacity.for animGroup
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

    slideUp : String -> AnimBuilder -> AnimBuilder
    slideUp animGroup =
        Translate.for animGroup
            >> Translate.fromY 50
            >> Translate.toY 0
            >> Translate.build

    rotateClockwise : String -> AnimBuilder -> AnimBuilder
    rotateClockwise animGroup =
        Rotate.for animGroup
            >> Rotate.fromZ 0
            >> Rotate.toZ 180
            >> Rotate.build


    -- Compose them
    complexAnimation : String -> AnimBuilder -> AnimBuilder
    complexAnimation animGroup =
        fadeIn animGroup
            >> slideUp animGroup
            >> rotateClockwise animGroup
    ```

    Build complex animations from small, reusable pieces.

## Best Practices

!!! tip "Keep animations small and focused"
    Create small, single-purpose animation functions and compose them together.

!!! tip "Use meaningful names"
    Name your animation functions based on what they do: `fadeIn`, `slideLeft`, `bounceOnHover`.

!!! tip "Extract common patterns"
    If you use the same configurations often, create helper functions.

    ??? example "View Source Code"

        ```elm
        -- Common timing helper
        withStandardTiming : AnimBuilder -> AnimBuilder
        withStandardTiming =
            Sub.duration 300
                >> Sub.easing QuintOut

        -- Use it with any animation
        myAnimation : AnimBuilder -> AnimBuilder
        myAnimation =
            withStandardTiming
                >> Translate.for "boxAnim"
                >> Translate.toX 100
                >> Translate.build
                >> Opacity.for "boxAnim"
                >> Opacity.to 1
                >> Opacity.build
        ```

## Next Steps

Now that you've defined your animations, the next step is initializing your animation state.

[Initialize →](init.md){ .md-button .md-button--primary }

