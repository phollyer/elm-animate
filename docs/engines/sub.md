# Sub Engine

The Sub Engine uses Elm subscriptions to update animation state on every frame. This provides full programmatic control over animations, including mid-flight queries and mid-flight redirections.

## Basic Usage

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Sub/BasicUsage/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/Sub/BasicUsage/index.html){ .md-button target="_blank" }

## Running Animations

The Sub Engine uses state-tracked animations exclusively. Use `animate` to start animations:

??? example "View Source Code"

    ```elm
    GotShowBox ->
        ( { model | animState = Sub.animate model.animState fadeIn }
        , Cmd.none
        )

    GotHideBox ->
        ( { model | animState = Sub.animate model.animState fadeOut }
        , Cmd.none
        )

    view : Model -> Html Msg
    view model =
        div []
            [ div
                (Sub.attributes "box" model.animState)
                [ text "I animate!" ]
            ]
    ```

The `animate` function takes your current `AnimState` and an animation pipeline, returning a new `AnimState` with the animation configured.

## Initialization

Create an `AnimState` using `init`:

??? example "Empty State"

    ```elm
    type alias Model =
        { animState : Sub.AnimState }

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Sub.init [] }
        , Cmd.none
        )
    ```

You can also initialize with starting property values:

??? example "With Initial Values"

    ```elm
    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                Sub.init
                    [ Opacity.init "my-element" 0
                    , Translate.initXY "my-element" 100 50
                    ]
          }
        , Cmd.none
        )
    ```

    These property values will be used in your view to set the initial state of your element(s).

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

## Event Handling

The `update` function returns a list of animation events. Use these to chain animations, update state, or trigger follow-up actions:

??? example "View Source Code"

    ```elm
    handleAnimationEvents : List Sub.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvents events model =
        case events of
            [] ->
                ( model, Cmd.none )

            event :: rest ->
                let
                    ( newModel, cmd ) =
                        case event of
                            Sub.Completed "box" ->
                                -- Animation complete
                                ( model, Cmd.none )

                            Sub.Started "box" ->
                                -- Animation started
                                ( model, Cmd.none )

                            Sub.Canceled "box" ->
                                -- Animation was stopped/reset
                                ( model, Cmd.none )

                            Sub.Paused "box" ->
                                -- Animation was paused
                                ( model, Cmd.none )

                            Sub.Resumed "box" ->
                                -- Animation was resumed
                                ( model, Cmd.none )

                            Sub.Restarted "box" ->
                                -- Animation was restarted
                                ( model, Cmd.none )

                            _ ->
                                ( model, Cmd.none )
                in
                handleAnimationEvents rest newModel
    ```

!!! info "When events fire"

    | Event | Fires when... |
    | ----- | ------------- |
    | `Started` | The animation begins playing |
    | `Completed` | The animation finishes |
    | `Canceled` | The animation is stopped or reset via `stop` or `reset` |
    | `Paused` | The animation is paused via `pause` |
    | `Resumed` | The animation is resumed via `resume` |
    | `Restarted` | The animation is restarted via `restart` |


## Interrupting Animations

Start a new animation at any time — the Sub Engine handles smooth transitions:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Sub/InterruptingAnimations/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/Sub/InterruptingAnimations/index.html){ .md-button target="_blank" }

The new animation starts from the current position, not the original start position.

## Querying Animation State

Check whether animations are running or complete:

??? example "View Source Code"

    ```elm
    view model =
        div []
            [ if Sub.anyRunning model.animState then
                text "Animating..."
              else
                text "Complete"
            ]
    ```

You can also query specific elements:

??? example "View Source Code"

    ```elm
    view model =
        let
            boxStatus =
                if Sub.isRunning "box" model.animState then
                    "Box is animating"
                else
                    case Sub.isComplete "box" model.animState of
                        Just True ->
                            "Box animation complete"

                        Just False ->
                            "Box animation not started"

                        Nothing ->
                            "No animation for box"
        in
        div [] [ text boxStatus ]
    ```

## Querying Property Values

Query the start, end, or current values of animated properties. Unlike CSS-based engines, the Sub Engine can give you true mid-flight values:

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

Available getters:

| Property | Start | End | Current |
| -------- | ----- | --- | ------- |
| Translate | `getStartTranslate` | `getEndTranslate` | `getCurrentTranslate` |
| Scale | `getStartScale` | `getEndScale` | `getCurrentScale` |
| Rotate | `getStartRotate` | `getEndRotate` | `getCurrentRotate` |
| Opacity | `getStartOpacity` | `getEndOpacity` | `getCurrentOpacity` |
| Size | `getStartSize` | `getEndSize` | `getCurrentSize` |
| Background Color | `getStartBackgroundColor` | `getEndBackgroundColor` | `getCurrentBackgroundColor` |

## Default Settings

Set (optional) defaults for all properties:

- Timing: use `speed` or `duration`
- Easing
- Delay

These settings will be used for all property animations.

??? example "View Source Code"

    ```elm
    animState =
        Sub.animate model.animState <|
            Sub.duration 500
                >> Sub.easing QuintOut
                >> Sub.delay 100
                >> myAnimation
            
    ```

Individual properties can override them:

??? example "View Source Code"

    ```elm
    myAnimation : Sub.AnimBuilder -> Sub.AnimBuilder
    myAnimation =
        Opacity.for "box"
            >> Opacity.duration 1000  
            >> Opacity.easing SineOut 
            >> Opacity.delay 0
            >> Opacity.build
    ```


## 3D Transforms and Perspective

The Sub Engine fully supports 3D animations. See [3D Animations](../concepts/3d.md) for how to define 3D transforms.

## Transform Ordering

The Sub Engine uses the default transform order: **Translate → Rotate → Scale**. This order is applied automatically and works well for most animations.

!!! note "Custom transform ordering"
    If you need custom transform ordering, use the [Keyframes Engine](keyframes.md), [Transitions Engine](transitions.md), or [WAAPI Engine](waapi.md) which support `animateOrder`.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animations configurations |
| `AnimMsg` | Messages from animation frame subscription |
| `AnimEvent` | Events returned by `update` (Started, Completed, etc.) |

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `List (AnimBuilder -> AnimBuilder) -> AnimState` | Create initial animation state |
| `animate` | `AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Start the animation |
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
