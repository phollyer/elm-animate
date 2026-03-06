# CSS Keyframes Engine

!!! info "Prerequisites"
    It is assumed you have completed [Getting Started](../getting-started/first-animation.md) and are also familiar with animation concepts like [Building](../animation-workflow/build.md), [Rendering](../animation-workflow/render.md) and [Triggering](../animation-workflow/trigger.md) animations.


This page focuses on what makes this Engine different, read [Engines Overview](overview.md) for features that are shared across all Engines.

This Engine uses native browser CSS `@keyframes` animations for complex animations with iterations, looping, and pause/resume control. The browser handles all rendering, providing excellent performance.

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
    view : Model -> Html Msg
    view model =
        div []
            [ Keyframes.styleNode model.animState
            , div
                (Keyframes.attributes "boxAnim" model.animState)
                [ ... ]
            ]
    ```

    Or for a specific animation group:

    ```elm
    Keyframes.styleNodeFor "boxAnim" model.animState
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
        Keyframes.iterations 3 
            >> bounceAnimation
    ```

### Infinite Looping

Run an animation forever:

??? example "View Source Code"

    ```elm
    Keyframes.animate model.animState <|
        Keyframes.loopForever 
            >> pulseAnimation
    ```

!!! tip "Tracking Iterations"

    You can keep track of the number of iterations/loops with the `Iteration` event.


## Control Functions

CSS Keyframes support the following control functions:

| Function | Description |
| -------- | ----------- |
| `stop` | Jump to end state and stop |
| `reset` | Jump to start state and stop |
| `restart` | Reset and begin playing again |
| `pause` | Freeze at current position |
| `resume` | Continue from paused position |


## Events

### Native DOM Events

| Event | Fires when... |
| ----- | ------------- |
| `Started` | The animation begins playing |
| `Ended` | The animation completes (after all iterations) |
| `Iteration` | Each cycle completes (useful for tracking loop count) |
| `Cancelled` | The browser aborts the animation |


### Engine-Generated Events

CSS animations don't natively fire DOM events for pause/resume/restart. The control functions generate these events through `update`:

| Event | Fires when... |
| ----- | ------------- |
| `Paused` | `pause` is called |
| `Resumed` | `resume` is called |
| `Restarted` | `restart` is called |

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animations configurations |
| `AnimMsg` | Internal `Msg`s for state tracked animations |
| `AnimEvent` | Events received during a keyframe animation lifecycle |
| `TransformOrder` | Custom transform ordering |

### Initialize

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `List (AnimBuilder -> AnimBuilder) -> AnimState` | Create initial animation state |

### Trigger

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `animate` | `AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Create a state-tracked animation |
| `animateOrder` | `List TransformOrder -> AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Animate with custom transform order |
| `fireAndForget` | `(AnimBuilder -> AnimBuilder) -> AnimState` | Fire-and-forget animation (no state tracking) |
| `fireAndForgetOrder` | `List TransformOrder -> (AnimBuilder -> AnimBuilder) -> AnimState` | Fire-and-forget with custom transform order |

### Update

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `update` | `AnimMsg -> AnimState -> (AnimState, AnimEvent)` | Update AnimState after a keyframe event |

### View

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `String -> AnimState -> List (Html.Attribute msg)` | Get the animation attributes for an element |
| `styleNode` | `AnimState -> Html msg` | Generate `@keyframes` rules for all animation groups |
| `styleNodeFor` | `String -> AnimState -> Html msg` | Generate `@keyframes` rules for a specific animation group |
| `getElementKeyframes` | `String -> AnimState -> String` | Get the raw `@keyframes` CSS for a specific animation group |

### Event Listeners

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `events` | `String -> (AnimEvent -> msg) -> List (Attribute msg)` | Attach all animation event listeners for an animation group |
| `eventsStopPropagation` | `String -> (AnimEvent -> msg) -> List (Attribute msg)` | Attach all listeners, stops propagation |
| `onAnimationStart` | `(AnimEvent -> msg) -> Attribute msg` | Listen for animation start |
| `onAnimationEnd` | `(AnimEvent -> msg) -> Attribute msg` | Listen for animation end |
| `onAnimationIteration` | `(AnimEvent -> msg) -> Attribute msg` | Listen for animation iteration |
| `onAnimationCancel` | `(AnimEvent -> msg) -> Attribute msg` | Listen for animation cancel |
| `onAnimationStartStopPropagation` | `(AnimEvent -> msg) -> Attribute msg` | Start listener, stops propagation |
| `onAnimationEndStopPropagation` | `(AnimEvent -> msg) -> Attribute msg` | End listener, stops propagation |
| `onAnimationIterationStopPropagation` | `(AnimEvent -> msg) -> Attribute msg` | Iteration listener, stops propagation |
| `onAnimationCancelStopPropagation` | `(AnimEvent -> msg) -> Attribute msg` | Cancel listener, stops propagation |

### Event Types

| Event | Fires when... |
| ----- | ------------- |
| `Started` | The animation begins playing |
| `Ended` | The animation completes (after all iterations) |
| `Iteration` | Each cycle completes |
| `Cancelled` | The browser aborts the animation |
| `Paused` | `pause` is called |
| `Resumed` | `resume` is called |
| `Restarted` | `restart` is called |

### Defaults

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

### Playback

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `iterations` | `Int -> AnimBuilder -> AnimBuilder` | Set number of iterations |
| `loopForever` | `AnimBuilder -> AnimBuilder` | Loop animation infinitely |
| `alternate` | `AnimBuilder -> AnimBuilder` | Reverse direction on each iteration |

### Controls

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `stop` | `String -> AnimState -> AnimState` | Jump to end state and stop |
| `reset` | `String -> AnimState -> AnimState` | Jump to start state and stop |
| `restart` | `String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Reset and begin playing again |
| `pause` | `String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Freeze at current position |
| `resume` | `String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Continue from paused position |

### State Queries

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `anyRunning` | `AnimState -> Bool` | Check if any animations are running |
| `isRunning` | `String -> AnimState -> Bool` | Check if a specific element is animating |
| `allComplete` | `AnimState -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `String -> AnimState -> Maybe Bool` | Check if a specific element's animation is complete |

### Property Queries

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `getTranslateStart` | `String -> AnimState -> Maybe { x, y, z }` | Get start translate value |
| `getTranslateEnd` | `String -> AnimState -> Maybe { x, y, z }` | Get end translate value |
| `get*Start` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get start value |
| `get*End` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get end value |

For complete API details, see the [Anim.Engine.CSS.Keyframes](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-CSS-Keyframes) documentation.

## Next Steps

The Sub Engine which provides a few more features than you get with keyframes.

[Sub Engine →](sub.md){ .md-button .md-button--primary }
