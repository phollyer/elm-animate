# Sub Engine

The Sub Engine uses Elm subscriptions to update animation state on every frame. This provides full programmatic control over animations, including mid-flight queries and mid-flight redirections.

## Basic Usage

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Sub/BasicUsage/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/Sub/BasicUsage/index.html){ .md-button target="_blank" }

!!! note "Sub always uses `animate`"
    The Sub engine does not have a `fireAndForget` function. Because the engine uses `subscriptions` with frame-by-frame `update`s, the fire-and-forget concept doesn't apply.

## Subscriptions

The Sub Engine requires a subscription to receive animation frame updates:

??? example "View Source Code"

    ```elm
    type Msg
        = GotAnimMsg Sub.AnimMsg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotAnimMsg model.animState
    ```

When the animation is running, this subscription fires on each animation frame. When no animations are active, the subscription is dormant.

## Update

Handle animation messages in your update function. The `update` function returns both the new state and any events that occurred:

??? example "View Source Code"

    ```elm
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update animMsg model.animState
                in
                handleAnimationEvents events { model | animState = newAnimState }

            ...
    ```

## Interrupting Animations

Start a new animation at any time — the Sub Engine handles smooth transitions from the current position:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Sub/InterruptingAnimations/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/Sub/InterruptingAnimations/index.html){ .md-button target="_blank" }

The new animation starts from the current position, not the original start position. This enables smooth redirections mid-flight.

## True Mid-Flight Values

Unlike CSS-based engines, the Sub Engine can give you true interpolated mid-flight values:

??? example "View Source Code"

    ```elm
    view model =
        let
            positionText =
                case Sub.getCurrentTranslate "box" model.animState of
                    Just { x, y, z } ->
                        "Position: " ++ String.fromFloat x ++ ", " ++ String.fromFloat y

                    Nothing ->
                        "No translate animation"
        in
        div [] [ text positionText ]
    ```

Available getters: `getCurrentTranslate`, `getCurrentScale`, `getCurrentRotate`, `getCurrentOpacity`, `getCurrentSize`, `getCurrentBackgroundColor`.

## Sub-Specific Events

The Sub engine returns a **list** of events from `update` (not a single event), because multiple events can occur in one frame:

??? example "View Source Code"

    ```elm
    handleAnimationEvents : List Sub.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvents events model =
        case events of
            [] ->
                ( model, Cmd.none )

            event :: rest ->
                case event of
                    Sub.Ended "box" ->
                        handleAnimationEvents rest model

                    _ ->
                        handleAnimationEvents rest model
    ```

| Event | Fires when... |
| ----- | ------------- |
| `Started` | The animation begins playing |
| `Ended` | The animation finishes |
| `Cancelled` | The animation is stopped or reset |
| `Paused` | The animation is paused |
| `Resumed` | The animation is resumed |
| `Restarted` | The animation is restarted |

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
| `AnimMsg` | Messages from animation frame subscription |
| `AnimEvent` | Events returned by `update` (Started, Ended, etc.) |
| `TransformOrder` | Custom transform ordering (Translate, Rotate, Scale) |

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `List (AnimBuilder -> AnimBuilder) -> AnimState` | Create initial animation state |
| `animate` | `AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Start the animation |
| `animateOrder` | `List TransformOrder -> AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Animate with custom transform order |
| `update` | `AnimMsg -> AnimState -> ( AnimState, List AnimEvent )` | Update state and get events |
| `subscriptions` | `(AnimMsg -> msg) -> AnimState -> Sub msg` | Animation frame subscription |

### View Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `String -> AnimState -> List (Html.Attribute msg)` | Get HTML animation attributes |

### Default Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

### Control Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `stop` | `String -> AnimState -> AnimState` | Jump to end state and stop |
| `reset` | `String -> AnimState -> AnimState` | Jump to start state and stop |
| `restart` | `String -> AnimState -> AnimState` | Reset and begin playing again |
| `pause` | `String -> AnimState -> AnimState` | Freeze at current position |
| `resume` | `String -> AnimState -> AnimState` | Continue from paused position |

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

For complete API details, see the [Anim.Engine.Sub](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Sub) documentation.

## Next Steps

The WAAPI Engine which provides all of the features of the Transitions, Keyframes and Sub Engines combined; all with Native browser control.

[WAAPI Engine →](waapi.md){ .md-button .md-button--primary }
