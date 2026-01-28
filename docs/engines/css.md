# CSS Engine

The CSS Engine generates native CSS transitions and keyframe animations. The browser handles all rendering, providing excellent performance with minimal setup.

## When to Use

✅ **Best for:**

- Fire-and-forget animations
- Page transitions and entrances
- Hover effects and micro-interactions
- When you don't need to query mid-flight values
- Maximum performance and battery efficiency

❌ **Consider other engines when:**

- You need to know current animated values
- Animations need to be interrupted and redirected smoothly
- You need pause/resume functionality

## Basic Usage

```elm
import Anim.Engine.CSS as CSS
import Anim.Property.Translate as Translate
import Process
import Task


type alias Model =
    { animState : CSS.AnimState }


type Msg
    = TriggerAnimation


init : ( Model, Cmd Msg )
init =
    ( { animState = CSS.init }
    , Process.sleep 50 |> Task.perform (always TriggerAnimation)
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerAnimation ->
            ( { model
                | animState =
                    model.animState
                        |> CSS.builder
                        |> slideIn
                        |> CSS.animate
              }
            , Cmd.none
            )


slideIn : CSS.AnimBuilder -> CSS.AnimBuilder
slideIn builder =
    builder
        |> Translate.for "box"
        |> Translate.fromX -100
        |> Translate.toX 0
        |> Translate.duration 500
        |> Translate.build


view : Model -> Html Msg
view model =
    div
        ([ id "box"
         , style "transform" "translateX(-100px)"  -- Initial position
         ]
            ++ CSS.transitionAttributes "box" model.animState
        )
        [ text "Hello!" ]
```

!!! note "Why the delay?"
    CSS transitions only trigger when the browser detects a *change* between renders. We use `Process.sleep 50` to ensure the element renders in its initial state first, then apply the animation on the next frame.

## User-Triggered Animations

In practice, most animations are triggered by user interactions, which naturally provide the state change:

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

## Global Settings

Set defaults for all properties:

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

Individual properties can override these:

```elm
myAnimation builder =
    builder
        |> Opacity.for "box"
        |> Opacity.duration 1000  -- Overrides global 500ms
        |> Opacity.build
```

## 3D Transforms

The CSS Engine fully supports 3D animations. See [3D Animations](../concepts/3d.md) for how to define 3D transforms.

## Event Handling

The CSS Engine provides event handlers for animation lifecycle:

### Transition Events

```elm
view model =
    div
        ([ id "box" ]
            ++ CSS.transitionAttributes "box" model.animState
            ++ CSS.transitionEvents "box" TransitionEvent
        )
        []


type Msg
    = TransitionEvent CSS.TransitionEvent


update msg model =
    case msg of
        TransitionEvent event ->
            case event of
                CSS.TransitionEnded propertyName ->
                    -- Animation complete
                    ...

                CSS.TransitionStarted propertyName ->
                    -- Animation started
                    ...

                _ ->
                    ( model, Cmd.none )
```

### Keyframe Animation Events

```elm
view model =
    div
        ([ id "box" ]
            ++ CSS.transitionAttributes "box" model.animState
            ++ CSS.keyframeAnimationEvents "box" AnimationEvent
        )
        []


type Msg
    = AnimationEvent CSS.KeyframeEvent


update msg model =
    case msg of
        AnimationEvent event ->
            case event of
                CSS.AnimationEnded animationName ->
                    -- Keyframe animation complete
                    ...

                CSS.AnimationIteration animationName ->
                    -- Animation loop iteration
                    ...

                _ ->
                    ( model, Cmd.none )
```

## API Reference

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `AnimState` | Create initial animation state |
| `builder` | `AnimState -> AnimBuilder` | Get builder for defining animations |
| `animate` | `AnimBuilder -> AnimState` | Generate final animation state |
| `styles` | `String -> AnimState -> List (Html.Attribute msg)` | Get HTML attributes for element |

### Global Functions

| Function | Description |
| ---------- | ------------- |
| `duration` | Set default duration (ms) |
| `speed` | Set default speed (px/sec) |
| `easing` | Set default easing function |
| `delay` | Set default delay (ms) |

### Event Functions

| Function | Description |
| ---------- | ------------- |
| `transitionEvents` | Attach CSS transition event listeners |
| `keyframeAnimationEvents` | Attach keyframe animation event listeners |
| `handleTransitionEvent` | Update AnimState from transition event |
| `handleKeyframeEvent` | Update AnimState from keyframe event |

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-CSS).
