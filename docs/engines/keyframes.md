# CSS Keyframes Engine

The CSS Keyframes Engine uses native browser CSS `@keyframes` animations for complex animations with iterations, looping, and pause/resume control. The browser handles all rendering, providing excellent performance.

## Basic Usage

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Keyframes/BasicUsage/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/Keyframes/BasicUsage/index.html){ .md-button target="_blank" }

## Running Animations

### Fire-and-Forget

For one-shot animations where you don't need to track state, use `fireAndForget`:

??? example "View Source Code"

    ```elm
    view : Model -> Html Msg
    view model =
        let
            animState =
                Keyframes.fireAndForget <|
                    case model.state of
                        ShowText ->
                            fadeIn

                        HideText ->
                            fadeOut
        in 
        div []
            [ Keyframes.styleNode animState
            , div
                (Keyframes.attributes "text" animState)
                [ text "I fade in!" ]
            ]
    ```

Fire-and-forget is useful when you don't need chaining, state queries, or stop/reset controls.

### State-Tracked

Use `animate` when you need to query animation state, use stop/reset/pause/resume controls,
or chain animations that continue from the previous end state.

??? example "View Source Code"

    ```elm
    GotShowText ->
        ( { model| animState = Keyframes.animate model.animState fadeIn }
        , Cmd.none
        )

    GotHideText ->
        ( { model | animState = Keyframes.animate model.animState fadeOut }
        , Cmd.none
        )

    view : Model -> Html Msg
    view model =
        div []
            [ Keyframes.styleNode model.animState
            , div
                (Keyframes.attributes "text" model.animState)
                [ text "I fade in!" ]
            ]
    ```

The `animate` function takes your current `AnimState` and an animation pipeline, returning a new `AnimState` with the animation configured.

## Initialization

Create an `AnimState` for state-tracked animations using `init`:

??? example "Empty State"

    ```elm
    type alias Model =
        { animState : Keyframes.AnimState }

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Keyframes.init [] }
        , Cmd.none
        )
    ```

You can also initialize with starting property values:

??? example "With Initial Values"

    ```elm
    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                Keyframes.init
                    [ Opacity.init "my-element" 0
                    , Translate.initXY "my-element" 100 50
                    ]
          }
        , Cmd.none
        )
    ```

    These property values will be used in your view to set the initial state of your element(s) as well.

## Keyframes Style Node

Keyframe animations require a `<style>` node to define the `@keyframes` rules. Include this in your view:

??? example "View Source Code"

    ```elm
    view model =
        div []
            [ Keyframes.styleNode model.animState
            , div
                []
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

## Event Handling

Keyframe animations generate events throughout their lifecycle. Use these events to chain animations, update state, or trigger follow-up actions.

1. Create a `Msg` type variant for your keyframe events.

    ??? example "View Source Code"

        ```elm
        type Msg
            = GotKeyframeEvent Keyframes.AnimEvent
            | ...
        ```

2. Use `Keyframes.events` in your view to generate events.

    ??? example "View Source Code"

        ```elm
        view model =
            div
                []
                [ Keyframes.styleNodeFor "box" model.animState
                , div
                    (Keyframes.attributes "box" model.animState
                        ++ Keyframes.events "box" GotKeyframeEvent
                    )
                    [...]
                ]
        ```

3. Use `Keyframes.handleEvent` in your `update` function. This will keep the internal state in sync with the animation lifecycle.

    ??? example "View Source Code"

        ```elm
        update msg model =
            case msg of
                GotKeyframeEvent event ->
                    ( { model | animState = Keyframes.handleEvent event model.animState }
                    , Cmd.none 
                    )
        ```

4. Handle any events you are interested in.

    ??? example "View Source Code"

        ```elm
        update msg model =
            case msg of
                GotKeyframeEvent event ->
                    let
                        newModel =
                            { model | animState = Keyframes.handleEvent event model.animState }
                    in
                    case event of
                        Keyframes.Started "box" ->
                            (newModel, Cmd.none)
                        
                        Keyframes.Ended "box" ->
                            (newModel, Cmd.none)

                        Keyframes.Iteration "box" ->
                            (newModel, Cmd.none)

                        Keyframes.Cancelled "box" ->
                            (newModel, Cmd.none)

                        _ ->
                            ( newModel, Cmd.none )
        ```


!!! info "When events fire"

    | Event | Fires when... |
    | ----- | ------------- |
    | `Started` | The animation begins playing |
    | `Ended` | The animation completes (after all iterations) |
    | `Iteration` | Each cycle completes (useful for tracking loop count) |
    | `Cancelled` | The browser aborts the animation — e.g., the element is removed from the DOM, set to `display: none`, or the animation CSS is removed mid-flight |

## Default Settings

Set (optional) defaults for all properties:

- Timing: use `speed` or `duration`
- Easing
- Delay

These settings will be used for all property animations in the pipeline.

??? example "View Source Code"

    ```elm

    animState =
        Keyframes.animate model.animState <|
            Keyframes.duration 500 -- Or Keyframes.speed
                >> Keyframes.easing QuintOut
                >> Keyframes.delay 100
                >> myAnimation
            
    ```

Individual properties can override them:

??? example "View Source Code"

    ```elm
    myAnimation : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
    myAnimation =
        Opacity.for "box"
            >> Opacity.duration 1000  
            >> Opacity.easing SineOut 
            >> Opacity.delay 0
            >> Opacity.build
    ```

## 3D Transforms

Fully supports 3D animations. See [3D Animations](../concepts/3d.md) for more information.

## Controlling Animations

For details on `stop`, `reset`, `restart`, `pause`, and `resume` controls, see [Controlling Animations](../concepts/controlling-animations.md).

## Querying Animation State

Check whether animations are running or complete:

??? example "View Source Code"

    ```elm
    view model =
        div []
            [ if Keyframes.anyRunning model.animState then
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
                if Keyframes.isRunning "box" model.animState then
                    "Box is animating"
                else
                    case Keyframes.isComplete "box" model.animState of
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

Query the start, end, or current values of animated properties:

??? example "View Source Code"

    ```elm
    view model =
        let
            positionText =
                case Keyframes.getCurrentTranslate "box" model.animState of
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

!!! note "Mid-flight values"
    CSS keyframes don't expose actual mid-flight values. The "current" getters return the start value before the animation runs and the end value once it starts. For true mid-flight interpolation, use the [Sub Engine](sub.md) or [WAAPI Engine](waapi.md).

## Transform Ordering

The default transform order is: **Translate → Rotate → Scale**. This works well for most animations.

For custom ordering, use `animateOrder` or `fireAndForgetOrder`:

??? example "Custom Transform Order"

    ```elm
    -- Scale → Rotate → Translate
    Keyframes.animateOrder [ Scale, Rotate, Translate ] model.animState <|
        scaleUp
            >> rotateLeft
            >> moveRight
    ```

Transform order affects how combined transforms render. For example, rotating then translating moves along the rotated axis, while translating then rotating moves along the original axis.

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

For complete API details, see the [Anim.Engine.CSS.Keyframes](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-CSS-Keyframes) documentation.

## Next Steps

The Sub Engine which provides a few more features than you get with keyframes.

[Sub Engine →](sub.md){ .md-button .md-button--primary }
