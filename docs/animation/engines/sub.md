# Sub Engine

This page focuses on what makes this Engine different, read [Engines Overview](overview.md) for features that are shared across all Engines.

The Sub Engine uses Elm subscriptions to update animation state on every frame. This provides full programmatic control over animations, including mid-flight queries and mid-flight redirections.

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
    type Msg
        = GotAnimMsg Sub.AnimMsg
        | ...
        
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update animMsg model.animState
                in
                List.foldl handleAnimEvent ({ model | animState = newAnimState }, Cmd.none) events

            ...

    handleAnimEvent : AnimEvent -> (Model, Cmd Msg) -> (Model, Cmd Msg)
    handleAnimEvent animEvent (model, cmd) =
        case animEvent of 
            Ended "introAnim" ->
                ( { model | animState = Sub.animate model.animState nextAnimation }
                , cmd
                )

            ...
    ```

## Interrupting Animations

Start a new animation at any time — the Sub Engine handles smooth transitions from the current position.

📖 See [Interrupting Animations](../concepts/interrupting-animations.md/) for more info.

## Discrete Properties

The Sub engine manages discrete properties as inline styles. `discreteEntry` values are applied from the first animation frame, and `discreteExit` values flip on the last frame. No additional view setup is needed.

📖 See [Discrete Properties](../concepts/discrete-properties.md) for the full API, live examples, and source code.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animations configurations |
| `AnimMsg` | Messages from animation frame subscription |
| `AnimEvent` | Events returned by `update` (Started, Ended, etc.) |
| `AnimGroup` | `String` type alias representing the animation group name |
| `TransformProperty` | Custom transform ordering (Translate, Rotate, Scale) |

### Initialize

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `List (AnimBuilder -> AnimBuilder) -> AnimState` | Create initial animation state |

### Trigger

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `animate` | `AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Start the animation |

### Update

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `update` | `AnimMsg -> AnimState -> ( AnimState, List AnimEvent )` | Update state and get events |
| `subscriptions` | `(AnimMsg -> msg) -> AnimState -> Sub msg` | Animation frame subscription |

### View

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `AnimGroup -> AnimState -> List (Html.Attribute msg)` | Get HTML animation attributes |

## Events

The Sub engine returns a **list** of events from `update` (not a single event), because multiple events can occur in one frame.

| Event | Fires when... |
| ----- | ------------- |
| `Started` | The animation begins playing |
| `Ended` | The animation finishes |
| `Cancelled` | The animation is stopped or reset |
| `Paused` | The animation is paused |
| `Resumed` | The animation is resumed |
| `Restarted` | The animation is restarted |
| `Iteration` | A loop iteration completes |
| `Progress` | Each animation frame, with current progress (0.0 to 1.0) |

### Defaults

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |
| `transformOrder` | `List TransformProperty -> AnimState -> AnimState` | Set custom transform order for future animations |

### Playback

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `iterations` | `Int -> AnimBuilder -> AnimBuilder` | Set number of iterations |
| `loopForever` | `AnimBuilder -> AnimBuilder` | Loop animation infinitely |
| `alternate` | `AnimBuilder -> AnimBuilder` | Reverse direction on each iteration |

### Controls

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `stop` | `AnimGroup -> AnimState -> AnimState` | Jump to end state and stop |
| `reset` | `AnimGroup -> AnimState -> AnimState` | Jump to start state and stop |
| `restart` | `AnimGroup -> AnimState -> AnimState` | Reset and begin playing again |
| `pause` | `AnimGroup -> AnimState -> AnimState` | Freeze at current position |
| `resume` | `AnimGroup -> AnimState -> AnimState` | Continue from paused position |

### Discrete Properties

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `discreteEntry` | `String -> String -> AnimBuilder -> AnimBuilder` | Set a CSS property value when the animation starts |
| `discreteExit` | `String -> String -> String -> AnimBuilder -> AnimBuilder` | Set a CSS property value during and after the animation |

### State Queries

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `anyRunning` | `AnimState -> Maybe Bool` | Check if any animations are running |
| `isRunning` | `AnimGroup -> AnimState -> Maybe Bool` | Check if a specific element is animating |
| `allComplete` | `AnimState -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `AnimGroup -> AnimState -> Maybe Bool` | Check if a specific element's animation is complete |
| `getProgress` | `AnimGroup -> AnimState -> Maybe Float` | Get current progress (0.0 to 1.0) |

If no animation exisits `Nothing` is returned.

### Property Queries

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `getOpacityStart` | `AnimGroup -> AnimState -> Maybe Float` | Get start opacity |
| `getOpacityEnd` | `AnimGroup -> AnimState -> Maybe Float` | Get end opacity |
| `getOpacityCurrent` | `AnimGroup -> AnimState -> Maybe Float` | Get current opacity |
| `get*Start` | `AnimGroup -> AnimState -> Maybe *` | Get start * value |
| `get*End` | `AnimGroup -> AnimState -> Maybe *` | Get end * value |
| `get*Current` | `AnimGroup -> AnimState -> Maybe *` | Get current * value |

If no animation exisits `Nothing` is returned.

For complete API details, see the [Anim.Engine.Sub](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Sub) documentation.

## Next Steps

The WAAPI Engine which provides all of the features of the Transition, Keyframe and Sub Engines combined; all with Native browser control.

[WAAPI Engine →](waapi.md){ .md-button .md-button--primary }
