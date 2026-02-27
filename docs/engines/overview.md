# Animation Engines

Elm Animate provides four animation engines, each optimized for different use cases. All engines share the same builder API for defining animations - where they differ is in how they run those animations and what control they offer.

This page covers the shared patterns. For engine-specific details, see:

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
| Pause/Resume | | ✓ | ✓ | ✓ |
| **Playback** |
| Looping/Iterations | | ✓ | ✓ | ✓ |
| Event callbacks | ✓ | ✓ | ✓ | ✓ |
| **Mid-Flight Access** |
| Query current values | | | ✓ | ✓ |
| Dynamic redirects | ✓ | | ✓ | ✓ |
| **Properties** |
| Custom transform order | ✓ | ✓ | ✓ | ✓ |
| 3D transforms | ✓ | ✓ | ✓ | ✓ |


## Getting Started

### Initialization

All engines use `Engine.init` to create the initial `AnimState`. You can optionally pass property initializers to set starting values:

??? example "View Source Code"

    === "Transitions"

        ```elm
        -- Empty state
        animState = Transitions.init []

        -- With initial values
        animState =
            Transitions.init
                [ Opacity.init "box" 0
                , Translate.initXY "box" 100 50
                ]
        ```

    === "Keyframes"  

        ```elm
        -- Empty state
        animState = Keyframes.init []

        -- With initial values
        animState =
            Keyframes.init
                [ Opacity.init "box" 0
                , Translate.initXY "box" 100 50
                ]
        ```

    === "Sub"  

        ```elm
        -- Empty state
        animState = Sub.init []

        -- With initial values
        animState =
            Sub.init
                [ Opacity.init "box" 0
                , Translate.initXY "box" 100 50
                ]
        ```

    === "WAAPI"  

        ```elm
        -- Empty state
        animState = WAAPI.init waapiCommand waapiEvent []

        -- With initial values
        animState =
            Keyframes.init waapiCommand waapiEvent <|
                [ Opacity.init "box" 0
                , Translate.initXY "box" 100 50
                ]
        ```

        WAAPI additionally requires port functions to talk to JS - see [WAAPI Setup](waapi.md#setup).


### Triggering Animations

All engines provide `animate` for state-tracked animations. There's also `fireAndForget` for one-shot animations, although this isn't available for the Sub Engine because it tracks state automatically:

| Function | What It Does |
| -------- | ------------ |
| `animate` | Tracks state in `AnimState`, enabling sequencing, control, and events |
| `fireAndForget` | Starts fresh each time, no state needed |

#### Suggested Use Cases

| Scenario | Transitions | Keyframes | Sub | WAAPI |
| -------- | :---------: | :-------: | :-: | :---: |
| One-shot, no control needed | `fireAndForget` | `fireAndForget` | `animate` | `fireAndForget` |
| Stop/reset/pause controls | `animate` | `animate` | `animate` | `animate` |
| Sequencing animations | `animate` | `animate` | `animate` | `animate` |
| Redirecting mid-flight | either | | `animate` | `animate` |

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

        WAAPI needs to send animation data to JS for the Web Animations API to use, so it returns `Cmd`s.

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


## Reacting to Animations

All engines provide lifecycle events (`Started`, `Ended`, `Cancelled`, etc.), but the mechanism differs:

| Engine | Event Mechanism |
| ------ | --------------- |
| Transitions, Keyframes | DOM event listeners in view |
| Sub | Events returned from `update` |
| WAAPI | Port subscriptions |

### Event Types

| Event | Transitions | Keyframes | Sub | WAAPI |
| ----- | :---------: | :-------: | :-: | :---: |
| Run | ✓ | | | |
| Started | ✓ | ✓ | ✓ | ✓ |
| Ended | ✓ | ✓ | ✓ | ✓ |
| Cancelled | ✓ | ✓ | ✓ | ✓ |
| Iteration | | ✓ | ✓ | ✓ |
| Paused | | | ✓ | ✓ |
| Resumed | | | ✓ | ✓ |
| Restarted | | | ✓ | ✓ |
| Changed | | | | ✓ |


See [Events](../concepts/events.md) for the full pattern, or the individual engine docs for specifics.


## Querying State

All engines use the same API for querying animation state and property values:

??? example "View Source Code"

    === "Transitions"

        ```elm
        -- Is anything animating?
        Transitions.anyRunning model.animState  -- Bool

        -- Is a specific group animating?
        Transitions.isRunning "box" model.animState  -- Bool

        -- Have they all completed?
        Transitions.allComplete model.animState -- Bool

        -- Has it completed?
        Transitions.isComplete "box" model.animState  -- Maybe Bool
        ```

    === "Keyframes"

        ```elm
        -- Is anything animating?
        Keyframes.anyRunning model.animState  -- Bool

        -- Is a specific group animating?
        Keyframes.isRunning "box" model.animState  -- Bool

        -- Have they all completed?
        Keyframes.allComplete model.animState -- Bool

        -- Has it completed?
        Keyframes.isComplete "box" model.animState  -- Maybe Bool
        ```

    === "Sub"

        ```elm
        -- Is anything animating?
        Sub.anyRunning model.animState  -- Bool

        -- Is a specific group animating?
        Sub.isRunning "box" model.animState  -- Bool

        -- Have they all completed?
        Sub.allComplete model.animState -- Bool

        -- Has it completed?
        Sub.isComplete "box" model.animState  -- Maybe Bool
        ```

    === "WAAPI"

        ```elm
        -- Is anything animating?
        WAAPI.anyRunning model.animState  -- Bool

        -- Is a specific group animating?
        WAAPI.isRunning "box" model.animState  -- Bool

        -- Have they all completed?
        WAAPI.allComplete model.animState -- Bool

        -- Has it completed?
        WAAPI.isComplete "box" model.animState  -- Maybe Bool
        ```

### Querying Property Values

```elm
Engine.getStartTranslate "box" model.animState    -- Maybe { x, y, z }
Engine.getEndTranslate "box" model.animState      -- Maybe { x, y, z }
Engine.getCurrentTranslate "box" model.animState  -- Maybe { x, y, z }
```

Available for: Translate, Scale, Rotate, Opacity, Size, BackgroundColor.

!!! note "Mid-flight values"
    CSS engines (Transitions, Keyframes) don't track true mid-flight values - "current" returns start before animation and end after. For true interpolated values, use Sub or WAAPI.


## Switching Engines

Because all engines share the same builder API, animations are portable:

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
```

This makes it easy to start simple with Transitions and migrate to Sub or WAAPI as requirements grow.


## Next Steps

Explore each engine in detail, or check out the scroll engine for smooth scrolling animations.

[Scroll Engine →](scroll.md){ .md-button .md-button--primary }
