# CSS Keyframes Engine

This page focuses on what makes this Engine different, read [Engines Overview](overview.md) for features that are shared across all Engines.

This Engine uses native browser CSS `@keyframes` animations. The browser handles all rendering, providing excellent performance.

## Basic Usage

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Keyframes/HelloText/Main.elm"
    ```

<iframe src="../../examples/src/Engines/Keyframes/HelloText/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

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

## Interrupting Animations

Keyframes don't support mid-flight redirection. Calling `animate` while a keyframe animation is running replaces the current animation — the element jumps to the start of the new animation rather than smoothly transitioning from its current position.

This is a fundamental limitation of CSS `@keyframes`:

- **No playhead access** — CSS provides no API to query where an animation currently is (e.g., "50% through the fade")
- **No progress events** — There's no event that reports intermediate values
- **Hardcoded keyframes** — The `@keyframes` rule defines fixed values; the browser can't start from an arbitrary midpoint

Even though Elm tracks the animation state, there is no way to know the current, mid-flight animated value. The browser runs the animation independently — which is exactly what makes Keyframes so performant — but it means the in-progress state isn't accessible.

This also applies when animating a **different property** — calling `animate` with any new properties cancels all currently running animations on that element, not just the ones being replaced.

If mid-flight interruption is important for your use case, consider using the [Transitions](transitions.md), [Sub](sub.md), or [WAAPI](waapi.md) engine instead.


## Control Functions

The Keyframes Engine supports the following control functions:

| Function | Type | Description |
| -------- | ---- | ----------- |
| `stop` | `AnimGroupName -> AnimState -> AnimState` | Jump to end state and stop |
| `reset` | `AnimGroupName -> AnimState -> AnimState` | Jump to start state and stop |
| `restart` | `AnimGroupName -> (AnimMsg -> msg) -> AnimState -> (AnimState, Cmd msg)` | Reset and begin playing again |
| `pause` | `AnimGroupName -> (AnimMsg -> msg) -> AnimState -> (AnimState, Cmd msg)` | Freeze at current position |
| `resume` | `AnimGroupName -> (AnimMsg -> msg) -> AnimState -> (AnimState, Cmd msg)` | Continue from paused position |

## Events

### Native DOM Events

| Event | Fires when... |
| ----- | ------------- |
| `Started` | The animation begins playing |
| `Ended` | The animation completes (after all iterations) |
| `Iteration` | Each cycle completes (useful for tracking loop count) |
| `Cancelled` | The animation is interrupted before completing |


### Engine-Generated Events

| Event | Fires when... |
| ----- | ------------- |
| `Paused` | `pause` is called |
| `Resumed` | `resume` is called |
| `Restarted` | `restart` is called |

Keyframe animations don't natively fire DOM events for pause/resume/restart. The Engine generates these events when their corresponding control function is called.

Therefore, `restart`, `pause` and `resume` return a tuple of `(AnimState, Cmd msg)`. The `Cmd msg` must be passed to the Elm runtime in order for their events to be generated.


??? example "View Source Code"

    ```elm
    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            Restart ->
                let
                    (animState, eventCmd) =
                        Keyframes.restart "boxAnim" model.animState
                in
                ( { model | animState = animState }
                , eventCmd
                )

            Resume ->
                let
                    (animState, eventCmd) =
                        Keyframes.resume "boxAnim" model.animState
                in
                ( { model | animState = animState }
                , eventCmd
                )

            Pause ->
                let
                    (animState, eventCmd) =
                        Keyframes.pause "boxAnim" model.animState
                in
                ( { model | animState = animState }
                , eventCmd
                )

            GotAnimMsg animMsg ->
                let 
                    (animState, event) = 
                        Keyframes.update animMsg model.animState
                in 
                ( handleEvent event { model | animState = animState }
                , Cmd.none
                )
            ...

    handleEvent : AnimEvent -> Model -> Model
    handleEvent event model =
        case event of 
            Restarted _ _ _ ->
                ...

            Paused _ _ _ ->
                ...

            Resumed _ _ _ ->
                ...

            ...
    ```

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
| `transformOrder` | `List TransformOrder -> AnimState -> AnimState` | Set custom transform order for future animations |

### Update

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `update` | `AnimMsg -> AnimState -> (AnimState, AnimEvent)` | Update AnimState after a keyframe event |

### View

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `AnimGroupName -> AnimState -> List (Html.Attribute msg)` | Get the animation attributes for an element |
| `styleNode` | `AnimState -> Html msg` | Generate `@keyframes` rules for all animation groups |
| `styleNodeFor` | `AnimGroupName -> AnimState -> Html msg` | Generate `@keyframes` rules for a specific animation group |
| `getElementKeyframes` | `AnimGroupName -> AnimState -> String` | Get the raw `@keyframes` CSS for a specific animation group |

### Event Listeners

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `events` | `String -> (AnimEvent -> msg) -> List (Attribute msg)` | Attach all animation event listeners for an animation group |
| `eventsStopPropagation` | `String -> (AnimEvent -> msg) -> List (Attribute msg)` | Attach all listeners, stops propagation |

### Event Types

| Event | Fires when... |
| ----- | ------------- |
| `Started` | The animation begins playing |
| `Ended` | The animation completes (after all iterations) |
| `Iteration` | Each cycle completes |
| `Cancelled` | The animation is interrupted before completing |
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
| `stop` | `AnimGroupName -> AnimState -> AnimState` | Jump to end state and stop |
| `reset` | `AnimGroupName -> AnimState -> AnimState` | Jump to start state and stop |
| `restart` | `AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Reset and begin playing again |
| `pause` | `AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Freeze at current position |
| `resume` | `AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Continue from paused position |

### State Queries

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `anyRunning` | `AnimState -> Maybe Bool` | Check if any animations are running |
| `isRunning` | `AnimGroupName -> AnimState -> Maybe Bool` | Check if a specific element is animating |
| `allComplete` | `AnimState -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `AnimGroupName -> AnimState -> Maybe Bool` | Check if a specific element's animation is complete |

### Property Queries

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `getTranslateStart` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get start translate value |
| `getTranslateEnd` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get end translate value |
| `get*Start` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get start value |
| `get*End` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get end value |

For complete API details, see the [Anim.Engine.CSS.Keyframes](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-CSS-Keyframes) documentation.

## Next Steps

The Sub Engine which provides a few more features than you get with keyframes.

[Sub Engine →](sub.md){ .md-button .md-button--primary }
