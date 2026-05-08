# Build

## The Builder Pattern

Elm Motion uses a fluent builder pattern for defining animations.
This approach provides a consistent, composable API across all engines
and properties that reads naturally and is easy to reason about — you can
see at a glance what an animation does and how it behaves.

## Basic Structure

Every animation follows this pattern:


??? example "View Source Code"

    ```elm
    animationFunction : AnimBuilder mode -> AnimBuilder mode
    animationFunction =
        Property.for animGroup              -- Animation group name (required)
            >> Property.from startValue     -- Optional starting value
            >> Property.to endValue         -- Property specific alternatives to `to` are available
            >> Property.delay 100           -- ms
            >> Property.duration 500        -- ms, or `Property.speed 50` (units per second)
            >> Property.easing BounceOut    -- Make the animation feel natural
            >> Property.build               -- Finalize (required)
    ```

    `for` and `build` are required to start and end the builder chain respectively. All other configurations are optional,
    although without an end value the animations won't have anywhere to go!!

## Builder Modes

`AnimBuilder` has a type parameter (`mode`) that controls where a builder can be used.
Use this to keep helper functions either broad (cross-engine) or intentionally restricted.

??? example "View Source Code"

    ```elm
    import Anim.Builder exposing (AnimBuilder)
    import Anim.Property.Opacity as Opacity


    -- Works with any animation engine.
    fadeIn : AnimBuilder mode -> AnimBuilder mode
    fadeIn =
        Opacity.for "card"
            >> Opacity.to 1
            >> Opacity.build
    ```

### Document Timeline Restrictions

`ForDocumentTimeline engine` restricts usage to Document timeline engines:

- Transition
- Keyframe
- Sub
- WAAPI

??? example "View Source Code"

    ```elm
    import Anim.Builder exposing (AnimBuilder, ForDocumentTimeline)
    import Anim.Engine.Transition as Transition


    -- These are equivalent.
    f : Transition.TimelineBuilder engine -> Transition.TimelineBuilder engine
    f : AnimBuilder (ForDocumentTimeline engine) -> AnimBuilder (ForDocumentTimeline engine)
    f =
        identity
    ```

### Engine-Specific Restrictions

Use an engine mode when a helper must only work with one specific engine.

??? example "View Source Code"

    ```elm
    import Anim.Builder exposing (AnimBuilder, ForDocumentTimeline, ForTransitionEngine)
    import Anim.Engine.Transition as Transition


    -- All three are equivalent.
    transitionOnlyA : Transition.EngineBuilder -> Transition.EngineBuilder
    transitionOnlyA =
        identity


    transitionOnlyB : Transition.TimelineBuilder ForTransitionEngine -> Transition.TimelineBuilder ForTransitionEngine
    transitionOnlyB =
        identity


    transitionOnlyC : AnimBuilder (ForDocumentTimeline ForTransitionEngine) -> AnimBuilder (ForDocumentTimeline ForTransitionEngine)
    transitionOnlyC =
        identity
    ```

Use the narrowest mode that matches your intent:

- Reusable helper across engines: `AnimBuilder mode -> AnimBuilder mode`
- Any Document timeline engine: `AnimBuilder (ForDocumentTimeline engine) -> ...`
- One specific Document timeline engine: `AnimBuilder (ForDocumentTimeline ForXEngine) -> ...`

### Why Tighten Builder Modes?

Using a more specific mode can improve both readability and maintenance:

- Intent signaling: type signatures communicate purpose immediately (for example, "Transition-only helper").
- Faster bug triage: when a bug is tied to one engine or timeline, helpers with incompatible modes can be ruled out quickly.

This is similar to passing only the fields a function needs instead of a full model.
Narrower types do not prove correctness, but they reduce the search space when diagnosing issues.

## Animation Group Names

The first argument to `Property.for` is the **animation group name** — a string that groups
animation configurations together. Use it to animate multiple properties at once, or to create
multiple animations for different elements.

### Multiple Properties

Properties with the same group name animate together and are applied to the same element:

??? example "View Source Code"

    ```elm
    -- Both properties share "boxAnim" - they animate together on the same element
    enterAnimation : AnimBuilder mode -> AnimBuilder mode
    enterAnimation =
        Opacity.for "boxAnim"
            >> Opacity.to 1
            >> Opacity.build
            >> Translate.for "boxAnim"
            >> Translate.toY 0
            >> Translate.build
    ```

### Multiple Animations

Use different group names when you want separate animation sets for different elements:

??? example "View Source Code"

    ```elm
    -- Different groups for different element animations
    pageAnimations : AnimBuilder mode -> AnimBuilder mode
    pageAnimations =
        Opacity.for "header"            -- Header fades in
            >> Opacity.to 1
            >> Opacity.build
            >> Translate.for "sidebar"  -- Sidebar slides in
            >> Translate.toX 0
            >> Translate.build
    ```

## Best Practices

!!! tip "Keep animations small and focused"
    Create small, single-purpose animation functions and compose them together.

!!! tip "Use meaningful names"
    Name your animation functions based on what they do: `fadeIn`, `slideLeft`, `bounceOnHover`.

!!! tip "Extract common patterns"
    If you use the same configurations often, create helper functions.

??? example "View Source Code"

    ```elm
    fadeIn : String -> AnimBuilder mode -> AnimBuilder mode
    fadeIn animGroup =
        Opacity.for animGroup
            >> Opacity.to 1
            >> Opacity.build

    rotateClockwise : String -> AnimBuilder mode -> AnimBuilder mode
    rotateClockwise animGroupName =
        Rotate.for animGroup
            >> Rotate.toZ 90
            >> Rotate.build

    rotateAntiClockwise : String -> AnimBuilder mode -> AnimBuilder mode
    rotateAntiClockwise animGroupName =
        Rotate.for animGroup
            >> Rotate.toZ 0
            >> Rotate.build

    slideDown : String -> AnimBuilder mode -> AnimBuilder mode
    slideDown animGroup =
        Translate.for animGroup
            >> Translate.toY 50
            >> Translate.build


    slideUp : String -> AnimBuilder mode -> AnimBuilder mode
    slideUp animGroup =
        Translate.for animGroup
            >> Translate.toY 0
            >> Translate.build

    -- Common timing helper
    withStandardTiming : AnimBuilder mode -> AnimBuilder mode
    withStandardTiming =
        Engine.duration 300
            >> Engine.easing QuintOut

    -- Compose small helpers into a larger animation
    myAnimation : String -> AnimBuilder mode -> AnimBuilder mode
    myAnimation animGroup =
        withStandardTiming
            >> fadeIn animGroup
            >> slideUp animGroup
            >> rotateClockwise animGroup

    myOtherAnimation : String -> AnimBuilder mode -> AnimBuilder mode
    myOtherAnimation animGroup =
        withStandardTiming
            >> fadeIn animGroup
            >> slideDown animGroup
            >> rotateAntiClockwise animGroup
    ```

## Next Steps

Now that you've defined your animations, the next step is initializing your animation state.

[Initialize →](init.md){ .md-button .md-button--primary }

