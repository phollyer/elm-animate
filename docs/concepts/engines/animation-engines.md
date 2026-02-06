# Animation Engines

Elm Animate provides multiple animation engines, each optimized for different use cases. All engines share the same builder API, making it easy to switch between them.

## Overview

| Engine | Rendering | Control | Use Case |
| -------- | ----------- | --------- | ---------- |
| [CSS](#css-engine) | Browser CSS | Fire-and-forget | Simple animations, Native performance |
| [Sub](#sub-engine) | Elm subscriptions | Programmatic | Complex interactions, state queries |
| [WAAPI](#waapi-engine) | Web Animations API | Fire-and-forget, Programmatic | Native performance, complex interactions, state queries |

## CSS Engine

The CSS Engine generates native CSS transitions and keyframe animations. The browser handles all the rendering, which means:

- **Native performance** — Hardware-accelerated by the browser
- **Battery efficient** — No JavaScript running during animation playback
- **Simple setup** — No subscriptions or ports needed

??? example "View Source Code"

    ```elm
    import Anim.Engine.CSS as CSS

    animState =
        CSS.animate model.animState myAnimation

    animState =
        CSS.fireAndForget myAnimation
    ```

**Best for:**

- Fire-and-forget animations
- Page transitions
- Hover effects
- Any animation where you don't need to query mid-flight values

!!! note "Hardware Acceleration"
    Only **transform** properties (Translate, Rotate, Scale) and Opacity get GPU acceleration by the Browser. All other properties cause Browser repaints or reflows, and so cannot be lifted onto the GPU.

[Learn more about CSS Engine →](../engines/css.md)

## Sub Engine

The Sub Engine uses Elm subscriptions to update animation state on each frame. This gives you full control to:

- **Query current values** — Know exactly where elements are mid-animation
- **Perform Dynamic interruptions** — Smoothly transition to new targets mid-flight

??? example "View Source Code"

    ```elm
    import Anim.Engine.Sub as Sub

    type Msg 
        = AnimationMsg Sub.AnimMsg
        | ...

    animState =
        Sub.animate model.animState myAnimation

    -- In your subscriptions
    subscriptions model =
        Sub.subscriptions AnimationMsg model.animState
    ```

**Best for:**

- Interactive animations responding to user input
- Animations that need to be interrupted and redirected
- When you need to know current animated values

!!! note "Performance Consideration"
    The Sub engine updates CSS transition attributes on every animation frame. While this enables pure Elm state management and mid-flight queries, it means Elm's Virtual DOM diffs the view each frame. For a few animated elements, this is negligible. For complex views with many simultaneous animations, if performance should become an issue, consider using the [WAAPI Engine](#waapi-engine) where the browser handles interpolation natively.

[Learn more about Sub Engine →](../engines/sub.md)

## WAAPI Engine

The WAAPI Engine combines all the good bits from the CSS and Sub Engines by using the Web Animations API via Elm ports. It combines browser-native performance with full programmatic control for:

- **Native performance** — Hardware-accelerated by the browser
- **Battery efficient** — No JavaScript running during animation playback
- **Query current values** — Know exactly where elements are mid-animation
- **Perform Dynamic interruptions** — Smoothly transition to new targets mid-flight

??? example "View Source Code"

    ```elm
    import Anim.Engine.WAAPI as WAAPI
    import Json.Encode exposing (Value)

    port waapiCommand : Value -> Cmd msg
    port waapiSubscription : (Value -> msg) -> Sub msg

    init : Model
    init =
        { animState = WAAPI.init waapiCommand waapiSubscription [] }

    type Msg
        = GotWaapiMsg WAAPI.Msg
        | ...

    update : Msg -> Model -> (Model Cmd Msg)
    update msg model =
        case msg of
            GotWaapiMsg waapiMsg ->
                let 
                    (animState, events) =
                        WAAPI.update waapiMsg model.animState
                in 
                ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotWaapiMsg model.animState

    (animState, animCmd) =
        WAAPI.animate model.animState myAnimation

    ```

**Best for:**

- Complex animations needing both performance and control
- Animations with many simultaneous elements

[Learn more about WAAPI Engine →](../engines/waapi.md)

## Switching Engines

Because all engines share the same builder API, animations are portable:

??? example "View Source Code"

    ```elm
    -- This animation works with any engine
    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "box"
            >> Translate.toXY 100 200
            >> Translate.duration 500
            >> Translate.build

    -- Use with CSS
    CSS.fireAndForget myAnimation

    -- Use with Sub
    Sub.animate model.animState myAnimation

    -- Use with WAAPI
    WAAPI.animate model.animState myAnimation
    ```

This makes it easy to start simple with the CSS Engine and migrate to Sub or WAAPI as your requirements grow.

## Next Steps

Now that you've learned about the animation engines, lets move on to the scroll engine.

[Scroll Engine →](scroll-engine.md){ .md-button .md-button--primary }
