# CSS Engine

The CSS Engine generates native CSS transitions and keyframe animations. The browser handles all rendering, providing excellent performance with minimal setup.

## When to Use

✅ **For:**

- Fire-and-forget animations
- Hover effects and micro-interactions
- Page transitions and entrances
- When you don't need to query mid-flight values
- Native performance and battery efficiency

❌ **Consider other engines when:**

- You need to know current animated values
- Animations need to be interrupted and redirected smoothly
- You need pause/resume functionality

## Basic Usage

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/CSS/BasicUsage/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/CSS/BasicUsage/index.html){ .md-button target="_blank" }

!!! note "Why the delay?"
    CSS transitions only trigger when the browser detects a *change* between renders. `Process.sleep 50` is used to ensure the element renders in its initial state first, then the animation is applied 50ms later. This creates the *change* the browser needs. This is only relevant to CSS **transitions**, **keyframe animations** run as soon as the browser renders.

## User-Triggered Animations

In practice, most animations are triggered by user interactions, which naturally provide the state change:

??? example "View Source Code"

    ```elm
    type Msg
        = AnimateBox


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            AnimateBox ->
                let
                    newAnimState =
                        CSS.init
                            |> CSS.builder
                            |> moveToNewPosition
                            |> CSS.animate
                in
                ( { model | animState = newAnimState }, Cmd.none )
    ```

## Event Handling

CSS animations generate events throughout their lifecycle. Use these events to chain animations, update state, or trigger follow-up actions.

### Transition Events

Create a `Msg` type variant for your CSS transition events.

??? example "View Source Code"

    ```elm
    type Msg
        = GotTransitionEvent CSS.TransitionEvent
        | ...
    ```

Use `CSS.transitionEvents` in your view to generate events.

??? example "View Source Code"

    ```elm
    view model =
        div
            (CSS.transitionAttributes "box" model.animState
                ++ CSS.transitionEvents "box" GotTransitionEvent
            )
            [...]
    ```

Use `CSS.handleTransitionEvent` in your `update` function. This will keep the internal state in sync with the animation lifecycle.

??? example "View Source Code"

    ```elm
    update msg model =
        case msg of
            GotTransitionEvent event ->
                let
                    newModel =
                        { model | animState = CSS.handleTransitionEvent event model.animState}
                in
                case event of
                    CSS.TransitionEnded "box" ->
                        -- Animation complete
                        (newModel, Cmd.none)

                    CSS.TransitionStarted "box" ->
                        -- Animation started
                        (newModel, Cmd.none)

                    _ ->
                        ( newModel, Cmd.none )
    ```

### Keyframe Animation Events

Create a `Msg` type variant for your Keyframe events.

??? example "View Source Code"

    ```elm
    type Msg
        = GotKeyframeEvent CSS.KeyframeEvent
        | ...
    ```

Use `CSS.keyframeEvents` in your view to generate events.

??? example "View Source Code"

    ```elm
    view model =
        div
            (CSS.transitionAttributes "box" model.animState
                ++ CSS.keyframeEvents "box" GotKeyframeEvent
            )
            [...]
    ```

Use `CSS.handleKeyframeEvent` in your `update` function. This will keep the internal state in sync with the animation lifecycle.

??? example "View Source Code"

    ```elm
    update msg model =
        case msg of
            GotKeyframeEvent event ->
                let
                    newModel =
                        { model | animState = CSS.handleKeyframeEvent event model.animState}
                in
                case event of
                    CSS.AnimationEnded "box" ->
                        -- Animation complete
                        (newModel, Cmd.none)

                    CSS.AnimationStarted "box" ->
                        -- Animation started
                        (newModel, Cmd.none)

                    _ ->
                        ( newModel, Cmd.none )
    ```


## Global Settings

Set (optional) defaults for all properties:

- Timing: use `speed` or `duration`
- Easing
- Delay

These settings will be used for all property animations in the pipeline.

??? example "View Source Code"

    ```elm

    animState =
        CSS.init
            |> CSS.builder
            |> CSS.duration 500
            |> CSS.easing QuintOut
            |> CSS.delay 100
            |> myAnimation
            |> CSS.animate
    ```

Individual properties can override them:

??? example "View Source Code"

    ```elm
    myAnimation builder =
        builder
            |> Opacity.for "box"
            |> Opacity.duration 1000  
            |> Opacity.easing SineOut 
            |> Opacity.delay 0
            |> Opacity.build
    ```


## 3D Transforms

The CSS Engine fully supports 3D animations. See [3D Animations](../concepts/3d.md) for more information. 3D animations are Engine agnostic.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animations configurations |
| `TransitionEvent` | Events received during a transitions lifecycle |
| `KeyframeEvent` | Events received during a keyframe animations lifecycle |
| `TransformOrder` | Custom transform ordering |

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `AnimState` | Create initial animation state |
| `builder` | `AnimState -> AnimBuilder` | Get builder for defining animations |
| `animate` | `AnimBuilder -> AnimState` | Generate final animation state |

### Event Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `handleTransitionEvent` | `TransitionEvent -> AnimState -> AnimState` | Update AnimState after a transition event |
| `handleKeyframeEvent` | `KeyframeEvent -> AnimState -> AnimState` | Update AnimState after a keyframe event |

### View Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `transitionAttributes` | `String -> AnimState -> List (Html.Attribute msg)` | Get the HTML `transition` attributes for the element |
| `transitionEvents` | `String -> (TransitionEvent -> msg) -> List (Attribute msg)` | Attach CSS transition event listeners |
| `keyframesAttribute` | `String -> AnimState -> Html.Attribute msg` | Get the HTML `animation` attribute for the element |
| `keyframeAnimationEvents` | `String -> (KeyframeEvent -> msg) -> List (Attribute msg)` | Attach keyframe animation event listeners |
| `keyframesStyleNode` | `AnimState -> Html msg` | Get the Keyframes `node` for  all the animated elements |
| `keyframesStyleNodeFor` | `String -> AnimState -> Html msg` | Get the Keyframes `node` for a specific element |

### Global Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-CSS).
