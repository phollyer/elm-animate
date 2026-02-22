# CSS Keyframes Engine

The CSS Keyframes Engine uses native browser CSS `@keyframes` animations for complex animations with iterations, looping, and pause/resume control. The browser handles all rendering, providing excellent performance.

## Basic Usage

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Keyframes/BasicUsage/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/Keyframes/BasicUsage/index.html){ .md-button target="_blank" }

## Keyframes Style Node

Keyframe animations require a `<style>` node to define the `@keyframes` rules. Include this in your view:

??? example "View Source Code"

    ```elm
    view model =
        div []
            [ Keyframes.styleNode model.animState
            , div
                (Keyframes.attributes "box" model.animState)
                [ ... ]
            ]
    ```

    Or for a specific element:

    ```elm
    Keyframes.styleNodeFor "box" model.animState
    ```

!!! tip "Positioning the `style` node"
    Keyframe animations restart whenever the browser re-renders their `<style>` node.

    Place `styleNode` in a stable part of your DOM — ideally near the root, outside any conditionally-rendered elements or frequently-updating regions.

## Iterations and Looping

### Fixed Iterations

Run an animation a specific number of times:

??? example "View Source Code"

    ```elm
    Keyframes.animate model.animState <|
        (Keyframes.iterations 3 >> bounceAnimation)
    ```

### Infinite Looping

Run an animation forever:

??? example "View Source Code"

    ```elm
    Keyframes.animate model.animState <|
        (Keyframes.loopForever >> pulseAnimation)
    ```

!!! tip "Tracking Iterations"

    You can keep track of the number of iterations/loops with the `Iteration` `AnimEvent`

## Keyframes-Specific Events

The Keyframes engine has a unique `Iteration` event that fires after each loop cycle. This is useful for tracking loop count in infinite or multi-iteration animations.

| Event | Fires when... |
| ----- | ------------- |
| `Started` | The animation begins playing |
| `Ended` | The animation completes (after all iterations) |
| `Iteration` | Each cycle completes (useful for tracking loop count) |
| `Cancelled` | The browser aborts the animation |


## Events

CSS animations don't fire DOM events for pause/resume/restart. To receive these events through `update`, use the `*Cmd` variants:

| Control | Event Function | Event Produced |
| ------- | -------------- | -------------- |
| `pause` | `pauseCmd` | `Paused` |
| `resume` | `resumeCmd` | `Resumed` |
| `restart` | `restartCmd` | `Restarted` |

??? example "View Source Code"

    ```elm
    -- Simple pause (no event)
    Pause ->
        ( { model | animState = Keyframes.pause "box" model.animState }
        , Cmd.none
        )

    -- Pause with event
    Pause ->
        let
            ( newState, cmd ) =
                Keyframes.pauseCmd "box" GotAnimMsg model.animState
        in
        ( { model | animState = newState }, cmd )
    ```

The Cmd routes back through your `update`, which returns the corresponding event for your `reactToEvent` function.

## Shared Features

The following features work the same across all engines. See [Engine Overview](overview.md) for detailed examples with tabbed code for each engine:

- [Initializing Property Configs](overview.md#initializing-property-configs) — Setting up `AnimState` with optional initial values
- [Default Settings](overview.md#default-settings) — Setting duration, easing, and delay defaults
- [Event Handling](overview.md#event-handling) — Handling animation lifecycle events
- [Querying Animation State](overview.md#querying-animation-state) — Checking if animations are running or complete
- [Querying Property Values](overview.md#querying-property-values) — Getting start, end, and current values
- [Transform Ordering](overview.md#transform-ordering) — Custom transform order with `animateOrder`
- [3D Transforms](../concepts/3d.md) — Full 3D animation support
- [Controlling Animations](../concepts/controlling-animations.md) — Stop, reset, restart, pause, and resume controls

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animations configurations |
| `AnimEvent` | Events received during a keyframe animation lifecycle |
| `TransformOrder` | Custom transform ordering |

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `List (AnimBuilder -> AnimBuilder) -> AnimState` | Create initial animation state |
| `animate` | `AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Create a state-tracked animation |
| `fireAndForget` | `(AnimBuilder -> AnimBuilder) -> AnimState` | Fire-and-forget animation (no state tracking) |
| `animateOrder` | `List TransformOrder -> AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Animate with custom transform order |
| `fireAndForgetOrder` | `List TransformOrder -> (AnimBuilder -> AnimBuilder) -> AnimState` | Fire-and-forget with custom transform order |

### View Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `String -> AnimState -> List (Html.Attribute msg)` | Get the animation attributes for an element |
| `styleNode` | `AnimState -> Html msg` | Generate `@keyframes` rules for all elements |
| `styleNodeFor` | `String -> AnimState -> Html msg` | Generate `@keyframes` rules for a specific element |
| `events` | `String -> (AnimEvent -> msg) -> List (Attribute msg)` | Attach keyframe event listeners |

### Event Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `handleEvent` | `AnimEvent -> AnimState -> AnimState` | Update AnimState after a keyframe event |

### Default Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

### Iteration Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `iterations` | `Int -> AnimBuilder -> AnimBuilder` | Set number of iterations |
| `loopForever` | `AnimBuilder -> AnimBuilder` | Loop animation infinitely |

### Control Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `stop` | `String -> AnimState -> AnimState` | Jump to end state and stop |
| `reset` | `String -> AnimState -> AnimState` | Jump to start state and stop |
| `restart` | `String -> AnimState -> AnimState` | Reset and begin playing again |
| `restartCmd` | `String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Restart and receive `Restarted` event |
| `pause` | `String -> AnimState -> AnimState` | Freeze at current position |
| `pauseCmd` | `String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Pause and receive `Paused` event |
| `resume` | `String -> AnimState -> AnimState` | Continue from paused position |
| `resumeCmd` | `String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Resume and receive `Resumed` event |

### State Query Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `anyRunning` | `AnimState -> Bool` | Check if any animations are running |
| `isRunning` | `String -> AnimState -> Bool` | Check if a specific element is animating |
| `allComplete` | `AnimState -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `String -> AnimState -> Maybe Bool` | Check if a specific element's animation is complete |

### Property Query Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `getStartTranslate` | `String -> AnimState -> Maybe { x, y, z }` | Get start translate value |
| `getEndTranslate` | `String -> AnimState -> Maybe { x, y, z }` | Get end translate value |
| `getCurrentTranslate` | `String -> AnimState -> Maybe { x, y, z }` | Get current translate value |
| `getStart*` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get start value |
| `getEnd*` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get end value |
| `getCurrent*` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get current value |

For complete API details, see the [Anim.Engine.CSS.Keyframes](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-CSS-Keyframes) documentation.

## Next Steps

The Sub Engine which provides a few more features than you get with keyframes.

[Sub Engine →](sub.md){ .md-button .md-button--primary }
