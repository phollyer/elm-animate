# CSS Keyframes Engine

The CSS Keyframes Engine uses native browser CSS `@keyframes` animations for complex animations with iterations, looping, and pause/resume control. The browser handles all rendering, providing excellent performance.

## Basic Usage

Keyframe animations run immediately when rendered — no `Process.sleep` delay needed for page entry
animations like there is with transitions:

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
                []
                [ ... ]
            ]
    ```

    Or for a specific element:

    ```elm
    Keyframes.styleNodeFor "box" model.animState
    ```

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
                    let
                        newModel =
                            { model | animState = Keyframes.handleEvent event model.animState}
                    in
                    case event of
                        Keyframes.Ended "box" ->
                            -- Animation complete
                            (newModel, Cmd.none)

                        Keyframes.Started "box" ->
                            -- Animation started
                            (newModel, Cmd.none)

                        _ ->
                            ( newModel, Cmd.none )
        ```

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

For details on `stop`, `reset`, `restart`, `pause`, and `resume` controls, see [Controlling CSS Keyframe Animations](../concepts/controlling-animations/keyframes.md).

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
| `animate` | `AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Generate final animation state |
| `fireAndForget` | `(AnimBuilder -> AnimBuilder) -> AnimState` | Fire-and-forget animation |

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

For complete API details, see the [Anim.Engine.CSS.Keyframes](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-CSS-Keyframes) documentation.

## Next Steps

The Sub Engine which provides a few more features than you get with keyframes.

[Sub Engine →](sub.md){ .md-button .md-button--primary }
