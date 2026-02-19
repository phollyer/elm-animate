# Build

## The Builder Pattern

Elm Animate uses a fluent builder pattern for defining animations. This approach provides a consistent, composable API across all engines and properties that reads naturally and is easy to reason about — you can see at a glance what an animation does and how it behaves.

## Basic Structure

Every animation follows this pattern:


??? example "Show Source Code"

    ```elm
    animationFunction : AnimBuilder -> AnimBuilder
    animationFunction =
        Property.for animGroup             -- Animation group name (required)
            >> Property.from startValue     
            >> Property.to endValue         
            >> Property.delay 100           -- ms
            >> Property.duration 500        -- ms, or (Property.speed 50 -- Int)
            >> Property.easing BounceOut    
            >> Property.build               -- Finalize (required)
    ```

    `for` and `build` are required to start and end the builder chain respectively. All other configurations are optional, although without a `to` value the animations won't have anywhere to go!!

## Why Builders?

The `AnimBuilder -> AnimBuilder` type signature enables [function composition](https://package.elm-lang.org/packages/elm/core/latest/Basics#function-helpers)
with `>>`. Small, focused animations combine into larger ones:

??? example "Show Source Code"

    ```elm
    fadeIn : AnimBuilder -> AnimBuilder
    fadeIn =
        Opacity.for animGroup
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

    slideUp : AnimBuilder -> AnimBuilder
    slideUp =
        Translate.for animGroup
            >> Translate.fromY 50
            >> Translate.toY 0
            >> Translate.build

    rotateClockwise : AnimBuilder -> AnimBuilder
    rotateClockwise =
        Rotate.for animGroup
            >> Rotate.fromZ 0
            >> Rotate.toZ 180
            >> Rotate.build


    -- Compose them
    complexAnimation : AnimBuilder -> AnimBuilder
    complexAnimation =
        fadeIn >> slideUp >> rotateClockwise
    ```

    Build complex animations from small, reusable pieces.

## Multiple Animations

Compose multiple animations together:

??? example "Show Source Code"

    ```elm
    moveToX : String -> Float -> AnimBUilder -> AnimBUilder
    moveToX groupName toX =
        Translate.for groupName
            >> Translate.toX toX
            >> Translate.build


    multipleAnimations : AnimBuilder -> AnimBuilder
    multipleAnimations =
        moveToX "animGroup1" 100        -- First animation
            >> moveToX "animGroup2" 200 -- Second animation
            >> moveToX"animGroup3" 300  -- Third animation
    ```

    Each different group name represents a distinct animation that can be applied in your view.

## Multiple Properties

Animate multiple properties at the same time:

??? example "Show Source Code"

    ```elm
    moveXY : String -> Float -> Float -> AnimBUilder -> AnimBuilder
    moveXY groupName toX toY =
        Translate.for groupName
            >> Translate.toXY toX toY
            >> Translate.build

    rotate : String -> Float -> AnimBuilder -> AnimBuilder
    rotate groupName deg =
        Rotate.for groupName
            >> Rotate.to deg
            >> Rotate.build

    scale : String -> Float -> AnimBuilder -> AnimBuilder
    scale groupName ratio =
        Scale.for groupName
            >> Scale.to ratio
            >> Scale.build

    complexAnimation : AnimBuilder -> AnimBuilder
    complexAnimation =
        moveXY "boxAnim" 100 200
            >> rotate "boxAnim" 45
            >> scale "boxAnim" 1.5
    ```

    Give different property animations the same animation group name and they will animate together on the same element.

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

Now that you've learned about the builder pattern for building animations, the next step is triggering them.

[Trigger Animations →](trigger.md){ .md-button .md-button--primary }

