# Sub Engine

The Sub Engine uses Elm subscriptions to update animation state on every frame. This provides full programmatic control over animations, including mid-flight queries and mid-flight
redirections.

## Basic Usage

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Sub/BasicUsage/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/Sub/BasicUsage/index.html){ .md-button target="_blank" }


## Interrupting Animations

Start a new animation at any time — the Sub Engine handles smooth transitions:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Sub/InterruptingAnimations/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/Sub/InterruptingAnimations/index.html){ .md-button target="_blank" }

The new animation starts from the current position, not the original start position.

## Querying Current Values

Get the current animated value for an element:

??? example "View Source Code"

    ```elm
    view model =
        let
            maybePosition =
                Sub.getCurrentTranslate "box" model.animState
        in
        div []
            [ case maybePosition of
                Just { x, y, z } ->
                    text ("Position: " ++ String.fromFloat x ++ ", " ++ String.fromFloat y)

                Nothing ->
                    text "Not animating"
            ]
    ```

## Animation State

Check if animations are running:

??? example "View Source Code"

    ```elm
    view model =
        div []
            [ if Sub.isAnimating model.animState then
                text "Animating..."
            else
                text "Complete"
            ]
    ```

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

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animations configurations |
| `AnimMsg` | Mid-flight animation messages |

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `List (AnimBuilder -> AnimBUilder) -> AnimState` | Create initial animation state |
| `animate` | `AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Start the animation |
| `update` | `AnimMsg -> AnimState -> AnimState` | Update the animation state |
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

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Sub).

## Next Steps

The WAAPI Engine which provides all of the features of the Transitions, Keyframes and Sub Engines combined; all with Native browser control.

[WAAPI Engine →](waapi.md){ .md-button .md-button--primary }
