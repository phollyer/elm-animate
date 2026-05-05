# Animation Engines Overview

This page mainly covers the shared patterns that are used by each Engine. For engine-specific details, see:

- [Transition](transition.md) — CSS transitions, simplest setup
- [Keyframe](keyframes.md) — CSS @keyframes, pause/resume support
- [Sub](sub.md) — Elm subscriptions, full Elm-side control
- [WAAPI](waapi.md) — Web Animations API, browser-native with JS
- [Scroll Timeline](scroll-timeline.md) — fire-and-forget, progress tied to scroll position
- [View Timeline](view-timeline.md) — fire-and-forget, progress tied to viewport position


## Choosing an Engine

### Quick Recommendation

| Use Case | Recommended Engine |
| -------- | ------------------ |
| Simple hover/click effects | Transition |
| Entry animations, loops | Keyframe |
| Full Elm control, mid-flight access | Sub |
| Complex animations, best performance | WAAPI |
| Animate from container scroll position | Scroll Timeline |
| Animate as elements enter/exit viewport | View Timeline |

### Feature Comparison

| Feature | Transition | Keyframe | Sub | WAAPI | Scroll Timeline | View Timeline |
| ------- | :---------: | :-------: | :-: | :---: | :-------------: | :-----------: |
| **Rendering** |
| Browser-native interpolation | ✓ | ✓ | | ✓ | ✓ | ✓ |
| Hardware acceleration | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| JavaScript required | | | | ✓ | ✓ | ✓ |
| **Animation Control** |
| Stop | ✓ | ✓ | ✓ | ✓ | | |
| Reset | ✓ | ✓ | ✓ | ✓ | | |
| Restart | | ✓ | ✓ | ✓ | | |
| Pause | | ✓ | ✓ | ✓ | | |
| Resume | | ✓ | ✓ | ✓ | | |
| **Events** |
| Run | ✓ | | | | | |
| Started | ✓ | ✓ | ✓ | ✓ | | |
| Ended | ✓ | ✓ | ✓ | ✓ | | |
| Cancelled | ✓ | ✓ | ✓ | ✓ | | |
| Restarted | | ✓ | ✓ | ✓ | | |
| Paused | | ✓ | ✓ | ✓ | | |
| Resumed | | ✓ | ✓ | ✓ | | |
| Iteration | | ✓ | ✓ | ✓ | | |
| Progress | | | ✓ | ✓ | | |
| **Playback** |
| Looping/Iterations | | ✓ | ✓ | ✓ | ✓ | ✓ |
| Alternate | | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Mid-Flight Access** |
| Query current values | | | ✓ | ✓ | | |
| Dynamic redirects | ✓ | | ✓ | ✓ | | |
| **Properties** |
| Custom transform order | | ✓ | ✓ | ✓ | | |
| Discrete properties | ✓ | ✓ | ✓ | ✓ | | |
| 3D transforms | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

## Initialize

State-tracked engines (`Transition`, `Keyframe`, `Sub`, `WAAPI`) provide `init` to initialize animations.

Timeline engines (`Scroll Timeline`, `View Timeline`) are fire-and-forget and do not use `AnimState` or `init`.

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
            WAAPI.init waapiCommand waapiEvent <|
                [ Opacity.init "box" 0
                , Translate.initXY "box" 100 50
                ]
        ```

        WAAPI additionally requires port functions to talk to JS - see [WAAPI Setup](waapi.md#setup).

📖 See [Animation Workflow - Initialize](../workflow/init.md) for detailed information.

## Render

All animation engines provide `attributes` to render animations.

State-tracked engines take `AnimState`, while timeline engines only require the animation group name.

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

    === "Scroll Timeline"

        ```elm
        ScrollTimeline.attributes animGroupName
        ```

    === "View Timeline"

        ```elm
        ViewTimeline.attributes animGroupName
        ```

📖 See [Animation Workflow - Render](../workflow/render.md) for detailed information.


## Trigger

All animation engines provide `animate` to trigger animations.

| Function | What It Does |
| -------- | ------------ |
| `animate` | Computes animation data and makes it available for rendering |

??? example "View Source Code"

    === "Transition"

        ```elm
        animState = Transition.animate model.animState fadeIn
        ```

    === "Keyframe"

        ```elm
        animState = Keyframe.animate model.animState fadeIn
        ```

    === "Sub"

        ```elm
        animState = Sub.animate model.animState fadeIn
        ```

    === "WAAPI"

        ```elm
        -- State-tracked
        (animState, cmd) = WAAPI.animate model.animState fadeIn
        ```
        WAAPI needs to send animation data to JS for the Web Animations API to use, so
        `animate` also returns a `Cmd` which sends the animation to JS.

        ```elm
        -- Fire-and-forget
        cmd = WAAPI.fireAndForget waapiCommand fadeIn
        ```        
        `fireAndForget` requires the outgoing port function instead of `AnimState`, and only returns a `Cmd` which sends the animation to JS.

        📖 See [Trigger WAAPI](./waapi.md#trigger) for more info.

    === "Scroll Timeline"

        ```elm
        cmd = ScrollTimeline.animate waapiCommand Document myAnimation
        ```

    === "View Timeline"

        ```elm
        cmd = ViewTimeline.animate waapiCommand myAnimation
        ```

📖 See [Animation Workflow - Trigger](../workflow/trigger.md) for detailed information.

## React

Only state-tracked engines (`Transition`, `Keyframe`, `Sub`, `WAAPI`) provide `update` to update animation state and return event(s).

Timeline engines are fire-and-forget and do not expose `update`.

| Function | What It Does |
| -------- | ------------ |
| `update` | Updates state in `AnimState` and returns `AnimEvent`(s). |

??? example "View Source Code"

    === "Transition"

        ```elm
        (animState, event) = Transition.update msg model.animState
        ```

    === "Keyframe"

        ```elm
        (animState, event) = Keyframe.update msg model.animState
        ```

    === "Sub"

        ```elm
        (animState, events) = Sub.update msg model.animState
        ```

        Sub returns a list of events because one or more event can happen on each frame.

        📖 See [Sub - Update](./sub.md#update) for more info.

    === "WAAPI"

        ```elm
        (animState, event) = WAAPI.update msg model.animState
        ```


### Events

The available events vary by Engine.

📖 See [Animation Workflow - React](../workflow/react.md) for the full pattern, or the individual engine docs for specifics.


## Building Animations

### Start Values

In general start values for animation configurations are not required. By default, all Engines use the values set in `init` on first run, and then the previous animation's end value for subsequent animations - ensuring smooth transitions from one to the next.

If no value is set in `init`, a default will be used. See each property for it's default value.

The only time you should need to provide a start value for an animation is if you want to
override the default behaviour.

**Note**: The [Transition Engine](./transition.md#no-starting-values) ignores start values completely.

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

Keyframe, Sub, WAAPI, Scroll Timeline, and View Timeline engines support iterations and alternating direction:

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

    === "Scroll Timeline"

        ```elm
        ScrollTimeline.animate waapiCommand Document <|
            ScrollTimeline.alternate
                >> ScrollTimeline.iterations 4
                >> swingAnimation
        ```

    === "View Timeline"

        ```elm
        ViewTimeline.animate waapiCommand <|
            ViewTimeline.alternate
                >> ViewTimeline.iterations 4
                >> swingAnimation
        ```

!!! tip "Tracking Iterations"
    Use the `Iteration` event to track loop count during playback.



## Animation Controls

State-tracked engines (`Transition`, `Keyframe`, `Sub`, `WAAPI`) support stopping and resetting. Keyframe, Sub, and WAAPI add pause, resume, and restart:

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

Only state-tracked engines (`Transition`, `Keyframe`, `Sub`, `WAAPI`) expose query APIs because they maintain `AnimState`.

Timeline engines are fire-and-forget and do not expose query APIs.

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

- [Transition](transition.md) — CSS transitions, simplest setup
- [Keyframe](keyframes.md) — CSS @keyframes, pause/resume support
- [Sub](sub.md) — Elm subscriptions, full Elm-side control
- [WAAPI](waapi.md) — Web Animations API, browser-native with JS
- [Scroll Timeline](scroll-timeline.md) — fire-and-forget scroll-driven playback
- [View Timeline](view-timeline.md) — fire-and-forget viewport-driven playback

Or, start with the Transition Engine, then move through the engines as your needs grow.

[Transition Engine →](transition.md){ .md-button .md-button--primary }
