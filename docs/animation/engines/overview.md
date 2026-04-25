# Animation Engines Overview

This page mainly covers the shared patterns that are used by each Engine. For engine-specific details, see:

- [Transition](transitions.md) — CSS transitions, simplest setup
- [Keyframe](keyframes.md) — CSS @keyframes, pause/resume support
- [Sub](sub.md) — Elm subscriptions, full Elm-side control
- [WAAPI](waapi.md) — Web Animations API, browser-native with JS


## Choosing an Engine

### Quick Recommendation

| Use Case | Recommended Engine |
| -------- | ------------------ |
| Simple hover/click effects | Transition |
| Entry animations, loops | Keyframe |
| Full Elm control, mid-flight access | Sub |
| Complex animations, best performance | WAAPI |

### Feature Comparison

| Feature | Transition | Keyframe | Sub | WAAPI |
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
| Progress | | | ✓ | ✓ |
| **Playback** |
| Looping/Iterations | | ✓ | ✓ | ✓ |
| Alternate | | ✓ | ✓ | ✓ |
| **Mid-Flight Access** |
| Query current values | | | ✓ | ✓ |
| Dynamic redirects | ✓ | | ✓ | ✓ |
| **Properties** |
| Custom transform order | | ✓ | ✓ | ✓ |
| Discrete properties | ✓ | ✓ | ✓ | ✓ |
| 3D transforms | ✓ | ✓ | ✓ | ✓ |

## Initialize

All engines provide `init` to initialize animations.

| Function | What It Does |
| -------- | ------------ |
| `init` | Initializes `AnimState` and animated properties |

??? example "View Source Code"

    === "Transition"

        ```elm
        animState =
            Transition.init
                [ Opacity.init "box" 0
                , Translate.initXY "box" 100 50
                ]
        ```

    === "Keyframe"  

        ```elm
        animState =
            Keyframe.init
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
            Keyframe.init waapiCommand waapiEvent <|
                [ Opacity.init "box" 0
                , Translate.initXY "box" 100 50
                ]
        ```

        WAAPI additionally requires port functions to talk to JS - see [WAAPI Setup](waapi.md#setup).

📖 See [Animation Workflow - Initialize](../workflow/init.md) for detailed information.

## Render

All engines provide `attributes` to render animations.

| Function | What It Does |
| -------- | ------------ |
| `attributes` | Renders the animation in the view |

??? example "View Source Code"

    === "Transition"

        ```elm
        Transition.attributes animGroupName model.animState
        ```

    === "Keyframe"

        ```elm
        Keyframe.attributes animGroupName model.animState
        ```

    === "Sub"

        ```elm
        Sub.attributes animGroupName model.animState
        ```

    === "WAAPI"

        ```elm
        WAAPI.attributes animGroupName model.animState
        ```

📖 See [Animation Workflow - Render](../workflow/render.md) for detailed information.


## Trigger

All engines provide `animate` to trigger animations.

| Function | What It Does |
| -------- | ------------ |
| `animate` | Computes animation data and makes it available for rendering |

??? example "View Source Code"

    === "Transition"

        ```elm
        newAnimState = Transition.animate model.animState fadeIn
        ```

    === "Keyframe"

        ```elm
        newAnimState = Keyframe.animate model.animState fadeIn
        ```

    === "Sub"

        ```elm
        newAnimState = Sub.animate model.animState fadeIn
        ```

    === "WAAPI"

        ```elm
        -- State-tracked
        (newAnimState, cmd) = WAAPI.animate model.animState fadeIn
        ```

        WAAPI needs to send animation data to JS for the Web Animations API to use, so `fireAndForget` requires the outgoing port function, and both return a `Cmd` which sends the animation to JS.

📖 See [Animation Workflow - Trigger](../workflow/trigger.md) for detailed information.

## React

All engines provide `update` to update animation state. It also returns event(s).

| Function | What It Does |
| -------- | ------------ |
| `update` | Updates state in `AnimState` and returns `AnimEvent`(s). |

??? example "View Source Code"

    === "Transition"

        ```elm
        (newAnimState, event) = Transition.update msg model.animState
        ```

    === "Keyframe"

        ```elm
        (newAnimState, event) = Keyframe.update msg model.animState
        ```

    === "Sub"

        ```elm
        (newAnimState, events) = Sub.update msg model.animState
        ```

        Sub returns a list of events because one or more event can happen on each frame.

    === "WAAPI"

        ```elm
        (newAnimState, event) = WAAPI.update msg model.animState
        ```


### Events

The available events vary by Engine.

📖 See [Animation Workflow - React](../workflow/react.md) for the full pattern, or the individual engine docs for specifics.


## Building Animations

### Builder Settings

Set timing, easing, and delay for all properties in an animation. Individual properties can override these:

??? example "View Source Code"

    === "Transition"

        ```elm
        Transition.animate model.animState <|
            Transition.duration 500
                >> Transition.easing QuintOut
                >> Transition.delay 100
                >> myAnimation
        ```


    === "Keyframe"

        ```elm
        Keyframe.animate model.animState <|
            Keyframe.duration 500
                >> Keyframe.easing QuintOut
                >> Keyframe.delay 100
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

📖 See [Getting Started - Animation Timing](../concepts/timing.md) for detailed timing information.

📖 See [Getting Started - Easing](../concepts/easing.md) for detailed easing information.


### Playback Options

Keyframe, Sub, and WAAPI engines support iterations, infinite looping, and alternating direction:

??? example "View Source Code"

    === "Keyframe"

        ```elm
        -- Run 3 times
        Keyframe.animate model.animState <|
            Keyframe.iterations 3
                >> bounceAnimation

        -- Loop forever
        Keyframe.animate model.animState <|
            Keyframe.loopForever
                >> pulseAnimation

        -- Reverse direction each iteration
        Keyframe.animate model.animState <|
            Keyframe.alternate
                >> Keyframe.iterations 4
                >> swingAnimation
        ```

    === "Sub"

        ```elm
        -- Run 3 times
        Sub.animate model.animState <|
            Sub.iterations 3
                >> bounceAnimation

        -- Loop forever
        Sub.animate model.animState <|
            Sub.loopForever
                >> pulseAnimation

        -- Reverse direction each iteration
        Sub.animate model.animState <|
            Sub.alternate
                >> Sub.iterations 4
                >> swingAnimation
        ```

    === "WAAPI"

        ```elm
        -- Run 3 times
        WAAPI.animate model.animState <|
            WAAPI.iterations 3
                >> bounceAnimation

        -- Loop forever
        WAAPI.animate model.animState <|
            WAAPI.loopForever
                >> pulseAnimation

        -- Reverse direction each iteration
        WAAPI.animate model.animState <|
            WAAPI.alternate
                >> WAAPI.iterations 4
                >> swingAnimation
        ```

!!! tip "Tracking Iterations"
    Use the `Iteration` event to track loop count during playback.



## Animation Controls

All engines support stopping and resetting. Keyframe, Sub, and WAAPI add pause, resume, and restart:

| Function | Effect |
| -------- | ------ |
| `stop` | Jump to end state |
| `reset` | Jump to start state |
| `restart` | Reset and replay |
| `pause` | Freeze in place |
| `resume` | Continue from pause |

📖 See [Controlling Animations](../concepts/controlling-animations.md) for code examples with each engine.


## Discrete Properties

All engines use the same `discreteEntry` and `discreteExit` functions to animate discrete CSS properties like `display` and `visibility` alongside interpolable animations.

| Function | Type | Description |
| -------- | ---- | ----------- |
| `discreteEntry` | `String -> String -> AnimBuilder -> AnimBuilder` | Set a CSS property value when the animation starts |
| `discreteExit` | `String -> String -> String -> AnimBuilder -> AnimBuilder` | Set a CSS property value during and after the animation |

📖 See [Discrete Properties](../concepts/discrete-properties.md) for the full explanation, live examples, and source code.


## Queries

All engines use the same API for querying animation state and property values.

### State Queries

All engines support querying whether animations are running or complete:

| Function | Type | Description |
| -------- | ---- | ----------- |
| `anyRunning` | `AnimState -> Maybe Bool` | Check if any animations are currently running |
| `isRunning` | `AnimGroupName -> AnimState -> Maybe Bool` | Check if a specific animation group is running |
| `allComplete` | `AnimState -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `AnimGroupName -> AnimState -> Maybe Bool` | Check if a specific animation group has completed |

When no animations exist (or no animations for the given group), `Nothing` is returned.

??? example "View Source Code"

    === "Transition"

        ```elm
        Transition.isRunning "box" model.animState
        -- Just True (animation is running)

        Transition.isComplete "box" model.animState
        -- Just False (not yet complete)

        Transition.anyRunning model.animState
        -- Just True (at least one animation is running)

        Transition.allComplete model.animState
        -- Just False (not all animations are complete)
        ```

    === "Keyframe"

        ```elm
        Keyframe.isRunning "box" model.animState
        -- Just True

        Keyframe.allComplete model.animState
        -- Just False
        ```

    === "Sub"

        ```elm
        Sub.isRunning "box" model.animState
        -- Just True

        Sub.allComplete model.animState
        -- Just False
        ```

    === "WAAPI"

        ```elm
        WAAPI.isRunning "box" model.animState
        -- Just True

        WAAPI.allComplete model.animState
        -- Just False
        ```

The Sub and WAAPI engines also provide `getProgress` to query how far along an animation is:

| Function | Type | Description |
| -------- | ---- | ----------- |
| `getProgress` | `AnimGroupName -> AnimState -> Maybe Float` | Get the current progress from 0.0 to 1.0 |

??? example "View Source Code"

    === "Sub"

        ```elm
        Sub.getProgress "box" model.animState
        -- Just 0.5 (halfway through)
        ```

    === "WAAPI"

        ```elm
        WAAPI.getProgress "box" model.animState
        -- Just 0.5 (halfway through)
        ```


### Property Queries

All Engines support querying start and end values, with all the functions following the same pattern:

`get[Property][Position] : AnimGroupName -> AnimState msg -> Maybe [value]`

where:

- `Property` is the property name: `Opacity`, `Scale`, etc
- `Position` is the property value to query: `Start`, `End`
- `value` is a property-specific value

When no animation exists, `Nothing` is returned.

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `getOpacityStart` | `AnimGroupName -> AnimState msg -> Maybe Float` | Get start opacity |
| `getOpacityEnd` | `AnimGroupName -> AnimState msg -> Maybe Float` | Get end opacity |
| `getRotateStart` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get start rotate value |
| `getRotateEnd` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get end rotate value |
| `get*Start` | `AnimGroupName -> AnimState msg -> Maybe *` | Get start value |
| `get*End` | `AnimGroupName -> AnimState msg -> Maybe *` | Get end value |

The Sub and WAAPI Engines also provide access to mid-flight current values.

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `getOpacityCurrent` | `AnimGroupName -> AnimState msg -> Maybe Float` | Get current opacity |
| `getRotateCurrent` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get current rotate value |
| `get*Current` | `AnimGroupName -> AnimState msg -> Maybe *` | Get current value |

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
    Transition.animate model.animState myAnimation
    Keyframe.animate model.animState myAnimation
    Sub.animate model.animState myAnimation
    WAAPI.animate model.animState myAnimation
    ```

This makes it easy to start simple with Transition and migrate to Sub or WAAPI as requirements grow. The compiler will guide you through the differences, and the [Migration Guide](migration-guide.md) covers specifics.


## Next Steps

Explore each engine in detail:

- [Transition](transitions.md) — CSS transitions, simplest setup
- [Keyframe](keyframes.md) — CSS @keyframes, pause/resume support
- [Sub](sub.md) — Elm subscriptions, full Elm-side control
- [WAAPI](waapi.md) — Web Animations API, browser-native with JS

Or, start with the Transition Engine, then move through the engines as your needs grow.

[Transition Engine →](transitions.md){ .md-button .md-button--primary }
