# Builder Pattern

Elm Animate uses a fluent builder pattern for defining animations. This approach provides a consistent, composable API across all engines and properties that reads naturally and is easy to reason about — you can see at a glance what an animation does, which element it targets, and how it behaves.

## Basic Structure

Every animation follows this pattern:


??? example "Show Source Code"

    ```elm
    animationFunction : AnimBuilder -> AnimBuilder
    animationFunction =
        Property.for "element-id"           -- Target element (required)
            >> Property.from startValue     
            >> Property.to endValue         
            >> Property.delay 100           -- ms
            >> Property.duration 500        -- ms, or (Property.speed 50 -- Int)
            >> Property.easing BounceOut    
            >> Property.build               -- Finalize (required)
    ```

    `for` and `build` are required to start and end the builder chain respectively. All other configurations are optional, although without a `to` value the animations won't have anywhere to go!!

## Why Builders?

The `AnimBuilder -> AnimBuilder` type signature enables function composition with `>>`. Small, focused animations combine into larger ones:

??? example "Show Source Code"

    ```elm
    fadeIn : AnimBuilder -> AnimBuilder
    fadeIn =
        Opacity.for "box"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

    slideUp : AnimBuilder -> AnimBuilder
    slideUp =
        Translate.for "box"
            >> Translate.fromY 50
            >> Translate.toY 0
            >> Translate.build

    -- Compose them
    enterAnimation : AnimBuilder -> AnimBuilder
    enterAnimation =
        fadeIn >> slideUp
    ```

Because all engines accept `AnimBuilder -> AnimBuilder`, the same animation works with any engine — start simple with CSS Transitions and migrate to WAAPI later without rewriting your animations.

## Multiple Elements

Animate multiple elements in a single animation:

??? example "Show Source Code"

    ```elm
    multiElementAnimation : AnimBuilder -> AnimBuilder
    multiElementAnimation =
        -- First element
        Translate.for "box-1"
            >> Translate.toX 100
            >> Translate.build
            -- Second element
            >> Translate.for "box-2"
            >> Translate.toX 200
            >> Translate.build
            -- Third element
            >> Translate.for "box-3"
            >> Translate.toX 300
            >> Translate.build
    ```

## Multiple Properties

Animate multiple properties on the same element:

??? example "Show Source Code"

    ```elm
    complexAnimation : AnimBuilder -> AnimBuilder
    complexAnimation =
        Translate.for "box"
            >> Translate.toXY 100 200
            >> Translate.build
            >> Rotate.for "box"
            >> Rotate.to 45
            >> Rotate.build
            >> Scale.for "box"
            >> Scale.to 1.5
            >> Scale.build
    ```

## Duration vs Speed

You can specify timing with either `duration` (fixed time) or `speed` (distance-based):

??? example "View Source Code"

    ```elm
    -- Fixed 500ms regardless of distance
    |> Translate.duration 500

    -- 200 pixels per second (duration varies with distance)
    |> Translate.speed 200
    ```

!!! note "Units for speed"
    The meaning of 'units' varies by property type. For `Translate` it's 'pixels'. Refer to each individual property for how speed is interpreted.

!!! warning
    Use either `duration` or `speed`, not both. If both are set, the last one wins.

!!! warning
    If no `duration` or `speed` is set, either globally on the engine, or locally on the property, then a duration of 0ms will be used, and the element will instantly jump to its end state.


## Best Practices

!!! tip "Keep animations small and focused"
    Create small, single-purpose animation functions and compose them together.

!!! tip "Use meaningful names"
    Name your animation functions based on what they do: `fadeIn`, `slideLeft`, `bounceOnHover`.

!!! tip "Extract common patterns"
    If you use the same configurations often, create helper functions.

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
            >> Translate.for "box"
            >> Translate.toX 100
            >> Translate.build
            >> Opacity.for "box"
            >> Opacity.to 1
            >> Opacity.build
    ```

## Next Steps

Now that you've learned about the builder pattern for building animations, we'll look at how to control them.

[Controlling Animations →](../concepts/controlling-animations/transitions.md){ .md-button .md-button--primary }

