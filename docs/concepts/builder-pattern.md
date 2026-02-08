# Builder Pattern

Elm Animate uses a fluent builder pattern for defining animations. This approach provides a consistent, composable API across all engines and properties that reads naturally and is easy to reason about — you can see at a glance what an animation does, which element it targets, and how it behaves.

## Basic Structure

Every animation follows this pattern:


??? example "Show Source Code"

    ```elm
    animationFunction : AnimBuilder -> AnimBuilder
    animationFunction =
        Property.for "element-id"           -- Target element (required)
            >> Property.from startValue     -- Starting value
            >> Property.to endValue         -- Ending value
            >> Property.delay 100           -- Delay (ms) before starting
            >> Property.duration 500        -- Timing (ms, or Property.speed)
            >> Property.easing BounceOut    -- Easing function
            >> Property.build               -- Finalize (required)
    ```

    `for` and `build` are required to start and end the builder chain respectively. All other configurations are optional, although without a `to` value the animations won't have anywhere to go!!
    
    A timing configuration of either `duration` or `speed` is also required, or a `duration` of `0ms` will be used causing the element to instantly jump to the end value. However, this can be set once on the engine pipeline for all properties, and then overriden where necessary on a per-property basis.

## Why Builders?

### 1. Composability

Small animations combine into larger ones:

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

### 2. Reusability

Define once, use everywhere:

??? example "Show Source Code"

    ```elm
    -- Define a standard fade-in transition
    standardFadeIn : String -> AnimBuilder -> AnimBuilder
    standardFadeIn elementId =
        Opacity.for elementId
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.duration 300
            >> Opacity.easing QuintOut
            >> Opacity.build

    -- Reuse for different elements
    entranceAnimation : AnimBuilder -> AnimBuilder
    entranceAnimation =
        standardFadeIn "card-1"
            >> standardFadeIn "card-2"
            >> standardFadeIn "card-3"
    ```

### 3. Engine Independence

The same animation works with any engine:

??? example "Show Source Code"

    ```elm
    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "box"
            >> Translate.toXY 100 200
            >> Translate.speed 100
            >> Translate.build

    -- Works with CSS.Transitions
    Transitions.animate model.animState myAnimation
    
    Transitions.fireAndForget myAnimation

    -- Works with CSS.Keyframes
    Keyframes.animate model.animState myAnimation

    Keyframes.fireAndForget myAnimation

    -- Works with Sub
    Sub.animate model.animState myAnimation

    -- Works with WAAPI
    WAAPI.animate model.animState myAnimation

    port waapiCommand : Json.Encode.Value -> Cmd msg

    WAAPI.fireAndForget waapiCommand myAnimation

    ```

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
        CSS.duration 300
            >> CSS.easing QuintOut

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

