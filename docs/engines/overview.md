# Animation Engines Overview

This page mainly covers the shared patterns that are the same/similar for each Engine. For engine-specific details, see:

- [Transitions](transitions.md) — CSS transitions, simplest setup
- [Keyframes](keyframes.md) — CSS @keyframes, looping and iterations
- [Sub](sub.md) — Elm subscriptions, full Elm-side control
- [WAAPI](waapi.md) — Web Animations API, browser-native with JS


## Choosing an Engine

### Quick Recommendation

| Use Case | Recommended Engine |
| -------- | ------------------ |
| Simple hover/click effects | Transitions |
| Entry animations, loops | Keyframes |
| Full Elm control, mid-flight access | Sub |
| Complex animations, best performance | WAAPI |

### Feature Comparison

| Feature | Transitions | Keyframes | Sub | WAAPI |
| ------- | :---------: | :-------: | :-: | :---: |
| **Rendering** |
| Browser-native interpolation | ✓ | ✓ | | ✓ |
| Hardware acceleration | ✓ | ✓ | ✓ | ✓ |
| JavaScript required | | | | ✓ |
| **Animation Control** |
| Stop | ✓ | ✓ | ✓ | ✓ |
| Reset | ✓ | ✓ | ✓ | ✓ |
| Restart | | ✓ | ✓ | ✓ |
| Pause | | ✓ | ✓ | ✓ |
| Resume | | ✓ | ✓ | ✓ |
| **Events** |
| Run | ✓ | | | |
| Started | ✓ | ✓ | ✓ | ✓ |
| Ended | ✓ | ✓ | ✓ | ✓ |
| Cancelled | ✓ | ✓ | ✓ | ✓ |
| Restarted | | ✓ | ✓ | ✓ |
| Paused | | ✓ | ✓ | ✓ |
| Resumed | | ✓ | ✓ | ✓ |
| Iteration | | ✓ | ✓ | ✓ |
| Changed | | | | ✓ |
| **Playback** |
| Looping/Iterations | | ✓ | ✓ | ✓ |
| Alternate | | ✓ | ✓ | ✓ |
| **Mid-Flight Access** |
| Query current values | | | ✓ | ✓ |
| Dynamic redirects | ✓ | | ✓ | ✓ |
| **Properties** |
| Custom transform order | ✓ | ✓ | ✓ | ✓ |
| 3D transforms | ✓ | ✓ | ✓ | ✓ |


## Getting Started

### Initialization

All engines use `Engine.init` to create the initial `AnimState`. Pass property initializers to set starting values for animated elements:

??? example "View Source Code"

    === "Transitions"

        ```elm
        animState =
            Transitions.init
                [ Opacity.init "box" 0
                , Translate.initXY "box" 100 50
                ]
        ```

    === "Keyframes"  

        ```elm
        animState =
            Keyframes.init
                [ Opacity.init "box" 0
                , Translate.initXY "box" 100 50
                ]
        ```

    === "Sub"  

        ```elm
        animState =
            Sub.init
                [ Opacity.init "box" 0
                , Translate.initXY "box" 100 50
                ]
        ```

    === "WAAPI"  

        ```elm
        animState =
            Keyframes.init waapiCommand waapiEvent <|
                [ Opacity.init "box" 0
                , Translate.initXY "box" 100 50
                ]
        ```

        WAAPI additionally requires port functions to talk to JS - see [WAAPI Setup](waapi.md#setup).

📖 See [Animation Workflow - Initialize](../animation-workflow/init.md) for detailed information.

### Triggering Animations

All engines provide `animate` for state-tracked animations. There's also `fireAndForget` for one-shot animations, although this isn't available for the Sub Engine because it tracks state by default and therefore has no concept of `fireAndForget`:

| Function | What It Does |
| -------- | ------------ |
| `animate` | Tracks state in `AnimState` |
| `fireAndForget` | Starts fresh each time, no state needed |

??? example "View Source Code"

    === "Transitions"

        ```elm
        -- State-tracked
        newAnimState = Transitions.animate model.animState fadeIn

        -- Fire-and-forget (no state continuity)
        newAnimState = Transitions.fireAndForget fadeIn
        ```

    === "Keyframes"

        ```elm
        -- State-tracked
        newAnimState = Keyframes.animate model.animState fadeIn

        -- Fire-and-forget (no state continuity)
        newAnimState = Keyframes.fireAndForget fadeIn
        ```

    === "Sub"

        ```elm
        -- State-tracked
        newAnimState = Transitions.animate model.animState fadeIn
        ```

        Sub uses subscriptions with frame-by-frame updates, so fire-and-forget doesn't apply.

    === "WAAPI"

        ```elm
        -- State-tracked
        (newAnimState, cmd) = WAAPI.animate model.animState fadeIn

        -- Fire-and-forget (no state continuity)
        cmd = WAAPI.fireAndForget waapiCommand fadeIn
        ```

        WAAPI needs to send animation data to JS for the Web Animations API to use, so `fireAndForget` requires the outgoing port function, and both return a `Cmd` which sends the animation to JS.

📖 See [Animation Workflow - Trigger](../animation-workflow/trigger.md) for detailed information.

## Building Animations

### Default Settings

Set default timing, easing, and delay for all properties in an animation. Individual properties can override these:

??? example "View Source Code"

    === "Transitions"

        ```elm
        Transitions.animate model.animState <|
            Transitions.duration 500
                >> Transitions.easing QuintOut
                >> Transitions.delay 100
                >> myAnimation

        Transitions.fireAndForget <|
            Transitions.duration 500
                >> Transitions.easing QuintOut
                >> Transitions.delay 100
                >> myAnimation
        ```


    === "Keyframes"

        ```elm
        Keyframes.animate model.animState <|
            Keyframes.duration 500
                >> Keyframes.easing QuintOut
                >> Keyframes.delay 100
                >> myAnimation

        Keyframes.fireAndForget <|
            Keyframes.duration 500
                >> Keyframes.easing QuintOut
                >> Keyframes.delay 100
                >> myAnimation
        ```

    === "Sub"

        ```elm
        Sub.animate model.animState <|
            Sub.duration 500
                >> Sub.easing QuintOut
                >> Sub.delay 100
                >> myAnimation
        ```

    === "WAAPI"

        ```elm
        WAAPI.animate model.animState <|
            WAAPI.duration 500
                >> WAAPI.easing QuintOut
                >> WAAPI.delay 100
                >> myAnimation

        WAAPI.fireAndForget waapiCommand <|
            WAAPI.duration 500
                >> WAAPI.easing QuintOut
                >> WAAPI.delay 100
                >> myAnimation
        ```

📖 See [Getting Started - Timing](../getting-started/timing.md) for detailed timing information.

📖 See [Getting Started - Easing](../getting-started/easing.md) for detailed easing information.


### Transform Ordering

The default transform order is **Translate → Rotate → Scale**. Use `animateOrder` or `fireAndForgetOrder` for custom ordering:

??? example "View Source Code"

    === "Transitions"

        ```elm
        import Anim.Engine.CSS.Transitions exposing (TransformOrder(..))

        Transitions.animateOrder [ Scale, Rotate, Translate ] model.animState myAnimation

        Transitions.fireAndForgetOrder [ Scale, Rotate, Translate ] myAnimation
        ```

    === "Keyframes"

        ```elm
        import Anim.Engine.CSS.Keyframes exposing (TransformOrder(..))

        Keyframes.animateOrder [ Scale, Rotate, Translate ] model.animState myAnimation

        Keyframes.fireAndForgetOrder [ Scale, Rotate, Translate ] myAnimation
        ```

    === "Sub"

        ```elm
        import Anim.Engine.Sub exposing (TransformOrder(..))

        Sub.animateOrder [ Scale, Rotate, Translate ] model.animState myAnimation
        ```

    === "WAAPI"

        ```elm
        import Anim.Engine.WAAPI exposing (TransformOrder(..))

        WAAPI.animateOrder [ Scale, Rotate, Translate ] model.animState myAnimation

        WAAPI.fireAndForgetOrder [ Scale, Rotate, Translate ] waapiCommand myAnimation
        ```

Transform order affects how combined transforms render. Rotating then translating moves along the rotated axis; translating then rotating moves along the original axis.

📖 See [Transform Order](../concepts/transform-order.md) for visual examples and common patterns.


## Reacting to Animations

All engines provide lifecycle events (`Started`, `Ended`, `Cancelled`, etc.), which are returned from each Engine's `update` function:

| Engine | Event Mechanism |
| ------ | --------------- |
| Transitions | DOM event listeners in view, all events are native |
| Keyframes | DOM event listeners in view for native, others created by the Engine |
| Sub | created by the Engine based on internal state |
| WAAPI | some are native and sent directly from the JavaScript Web Animations API via Port subscriptions, some are created by the Engine |

### Event Types

| Event | Transitions | Keyframes | Sub | WAAPI |
| ----- | :---------: | :-------: | :-: | :---: |
| Run | ✓ | | | |
| Started | ✓ | ✓ | ✓ | ✓ |
| Ended | ✓ | ✓ | ✓ | ✓ |
| Cancelled | ✓ | ✓ | ✓ | ✓ |
| Iteration | | ✓ | ✓ | ✓ |
| Paused | | ✓ | ✓ | ✓ |
| Resumed | | ✓ | ✓ | ✓ |
| Restarted | | ✓ | ✓ | ✓ |
| Changed | | | | ✓ |


📖 See [Events](../concepts/events.md) for the full pattern, or the individual engine docs for specifics.


## Querying State

All engines use the same API for querying animation state and property values:

??? example "View Source Code"

    === "Transitions"

        ```elm
        -- Have they all completed?
        Transitions.allComplete model.animState -- Bool

        -- Is anything animating?
        Transitions.anyRunning model.animState  -- Bool

        -- Is a specific group animating?
        Transitions.isRunning "box" model.animState  -- Bool

        -- Has it completed?
        Transitions.isComplete "box" model.animState  -- Maybe Bool
        ```

    === "Keyframes"

        ```elm
        -- Have they all completed?
        Keyframes.allComplete model.animState -- Bool

        -- Is anything animating?
        Keyframes.anyRunning model.animState  -- Bool

        -- Is a specific group animating?
        Keyframes.isRunning "box" model.animState  -- Bool

        -- Has it completed?
        Keyframes.isComplete "box" model.animState  -- Maybe Bool
        ```

    === "Sub"

        ```elm
        -- Have they all completed?
        Sub.allComplete model.animState -- Bool

        -- Is anything animating?
        Sub.anyRunning model.animState  -- Bool

        -- Is a specific group animating?
        Sub.isRunning "box" model.animState  -- Bool

        -- Has it completed?
        Sub.isComplete "box" model.animState  -- Maybe Bool
        ```

    === "WAAPI"

        ```elm
        -- Have they all completed?
        WAAPI.allComplete model.animState -- Bool

        -- Is anything animating?
        WAAPI.anyRunning model.animState  -- Bool

        -- Is a specific group animating?
        WAAPI.isRunning "box" model.animState  -- Bool

        -- Has it completed?
        WAAPI.isComplete "box" model.animState  -- Maybe Bool
        ```

### Querying Property Values

All engines support querying start and end values, with the functions following this  pattern `get[Property][Position]`:

??? example "View Source Code"

    ```elm
    Transitions.getTranslateStart "box" model.animState    
    Keyframes.getOpacityEnd "box" model.animState      
    ```

    Sub and WAAPI engines also support querying current interpolated values:

    ```elm
    Sub.getTranslateCurrent "box" model.animState     
    WAAPI.getOpacityCurrent "box" model.animState   
    ```


## Switching Engines

Most of what you've learned on this page applies to all engines: initialization, triggering, default settings, events, and querying state. This shared foundation makes switching straightforward.

When migrating, you'll mainly adjust:

- Import statements
- Engine-specific return types (e.g., WAAPI returns `(AnimState, Cmd msg)`)
- Port setup for WAAPI

Animations themselves are portable - the same builder works with any engine:

??? example "View Source Code"

    ```elm
    -- This animation works with any engine
    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "box"
            >> Translate.toXY 100 200
            >> Translate.duration 500
            >> Translate.build

    -- Use with any engine
    Transitions.animate model.animState myAnimation
    Keyframes.animate model.animState myAnimation
    Sub.animate model.animState myAnimation
    WAAPI.animate model.animState myAnimation
    ```

This makes it easy to start simple with Transitions and migrate to Sub or WAAPI as requirements grow. The compiler will guide you through the differences, and the [Migration Guide](migration-guide.md) covers specifics.


## Next Steps

Explore each engine in detail:

- [Transitions](transitions.md) — CSS transitions, simplest setup
- [Keyframes](keyframes.md) — CSS @keyframes, looping and iterations
- [Sub](sub.md) — Elm subscriptions, full Elm-side control
- [WAAPI](waapi.md) — Web Animations API, browser-native with JS

Or check out the scroll engine for smooth scrolling animations.

[Scroll Engine →](scroll.md){ .md-button .md-button--primary }
