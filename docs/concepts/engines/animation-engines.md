# Animation Engines

Elm Animate provides multiple animation engines, each optimized for different use cases. All engines share the same builder API, making it easy to switch between them.

## Overview

| Engine | Rendering | Control | Use Case |
| -------- | ----------- | --------- | ---------- |
| [Transitions](#transitions-engine) | Browser CSS | stop, reset | Simple A→B animations |
| [Keyframes](#keyframes-engine) | Browser CSS | stop, reset, restart, pause, resume | Looping, iterations, entry animations |
| [Sub](#sub-engine) | Elm subscriptions | stop, reset, restart, pause, resume | Mid-flight queries, dynamic redirects |
| [WAAPI](#waapi-engine) | Web Animations API | stop, reset, restart, pause, resume | Native performance, mid-flight queries, dynamic redirects |

## Transitions Engine

Uses native CSS transitions for simple A→B property animations. The browser handles all rendering:

- **Native performance** — Hardware-accelerated by the browser
- **Battery efficient** — No JavaScript running during animation playback
- **Simple setup** — No subscriptions or ports needed

??? example "View Source Code"

    ```elm
    import Anim.Engine.CSS.Transitions as Transitions

    animState =
        Transitions.animate model.animState myAnimation

    animState =
        Transitions.fireAndForget myAnimation
    ```

**Best for:**

- User-triggered animations (click, hover)
- Simple property changes
- Fire-and-forget animations

[Learn more about the Transitions Engine →](../../engines/transitions.md)

## Keyframes Engine

Uses native CSS `@keyframes` animations for complex animations with iterations, looping, and pause/resume control:

- **Native performance** — Hardware-accelerated by the browser
- **Battery efficient** — No JavaScript running during animation playback
- **Full playback control** — stop, reset, pause, resume, restart

??? example "View Source Code"

    ```elm
    import Anim.Engine.CSS.Keyframes as Keyframes

    animState =
        Keyframes.animate model.animState myAnimation

    animState =
        Keyframes.fireAndForget myAnimation

    -- With looping
    animState =
        Keyframes.fireAndForget <|
            Keyframes.loopForever >> pulseAnimation
    ```

**Best for:**

- Entry animations on page load
- Looping/repeating animations
- When you need pause/resume control

[Learn more about the Keyframes Engine →](../../engines/keyframes.md)


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


[Learn more about the Sub Engine →](../../engines/sub.md)

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
    port waapiEvent : (Value -> msg) -> Sub msg

    init : Model
    init =
        { animState = WAAPI.init waapiCommand waapiEvent [] }

    type Msg
        = GotWaapiMsg WAAPI.AnimMsg
        | ...

    update : Msg -> Model -> ( Model, Cmd Msg )
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

[Learn more about the WAAPI Engine →](../../engines/waapi.md)

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

    -- Use with CSS.Transitions
    Transitions.fireAndForget myAnimation

    -- Use with CSS.Keyframes
    Keyframes.fireAndForget myAnimation

    -- Use with Sub
    Sub.animate model.animState myAnimation

    -- Use with WAAPI
    WAAPI.animate model.animState myAnimation
    ```

This makes it easy to start simple with the one of the CSS Engines and migrate to Sub or WAAPI as your requirements grow.


## Hardware Acceleration

Only **transform** properties (Translate, Rotate, Scale) and Opacity get GPU acceleration by the Browser. All other properties cause Browser repaints or reflows, and so cannot run on the GPU.



## Next Steps

Now that you've learned about the animation engines, let's move on to the scroll engine.

[Scroll Engine →](scroll-engine.md){ .md-button .md-button--primary }
