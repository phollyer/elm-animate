# CSS Keyframes Engine

The CSS Keyframes Engine uses native browser CSS `@keyframes` animations for complex animations with iterations, looping, and pause/resume control. The browser handles all rendering, providing excellent performance.

```elm
import Anim.Engine.CSS.Keyframes as CSS
```

## When to Use

✅ **For:**

- Animations that need looping or iterations
- Pause/resume control during animation
- Entry animations without `Process.sleep` delays
- Complex multi-step animations
- Fire-and-forget animations with callbacks

❌ **Consider [Transitions](css-transitions.md) when:**

- Simple A→B property changes
- You don't need pause/resume or looping
- Minimal setup is preferred

## Basic Usage

Keyframe animations run immediately when rendered — no `Process.sleep` delay needed:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/CSS/Controls/KeyframeAnimations/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/CSS/Controls/KeyframeAnimations/index.html){ .md-button target="_blank" }

## Keyframes Style Node

Keyframe animations require a `<style>` node to define the `@keyframes` rules. Include this in your view:

```elm
view model =
    div []
        [ CSS.keyframesStyleNode model.animState  -- Required!
        , div
            (CSS.keyframesStyles "box" model.animState)
            [ text "Animated content" ]
        ]
```

Or for a specific element:

```elm
CSS.keyframesStyleNodeFor "box" model.animState
```

## Iterations and Looping

### Fixed Iterations

Run an animation a specific number of times:

```elm
CSS.animate model.animState <|
    (CSS.iterations 3 >> bounceAnimation)
```

### Infinite Looping

Run an animation forever:

```elm
CSS.animate model.animState <|
    (CSS.loopForever >> pulseAnimation)
```

## Event Handling

Keyframe animations generate events throughout their lifecycle. Use these events to chain animations, update state, or trigger follow-up actions.

Create a `Msg` type variant for your keyframe events.

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
            (CSS.keyframesStyles "box" model.animState
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
- Iterations

These settings will be used for all property animations in the pipeline.

??? example "View Source Code"

    ```elm

    animState =
        CSS.animate (CSS.init [])
            (CSS.duration 500
                >> CSS.easing QuintOut
                >> CSS.delay 100
                >> CSS.iterations 2
                >> myAnimation
            )
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

Fully supports 3D animations. See [3D Animations](../concepts/3d.md) for more information.

## Controlling Animations

For details on `stop`, `reset`, `restart`, `pause`, and `resume` controls, see [Controlling CSS Keyframe Animations](../concepts/controlling-animations/css/keyframes.md).

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animations configurations |
| `KeyframeEvent` | Events received during a keyframe animation lifecycle |
| `TransformOrder` | Custom transform ordering |

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `List (String, String, String) -> AnimState` | Create initial animation state |
| `builder` | `AnimState -> AnimBuilder` | Get builder for defining animations |
| `animate` | `AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Generate final animation state |
| `fireAndForget` | `(AnimBuilder -> AnimBuilder) -> AnimState` | Fire-and-forget animation |

### View Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `keyframesStyles` | `String -> AnimState -> List (Html.Attribute msg)` | Get the animation styles for an element |
| `keyframeAttribute` | `AnimBuilder -> Html.Attribute msg` | Get the animation attribute from a builder |
| `keyframesStyleNode` | `AnimState -> Html msg` | Generate `@keyframes` rules for all elements |
| `keyframesStyleNodeFor` | `String -> AnimState -> Html msg` | Generate `@keyframes` rules for a specific element |
| `keyframeEvents` | `String -> (KeyframeEvent -> msg) -> List (Attribute msg)` | Attach keyframe event listeners |

### Event Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `handleKeyframeEvent` | `KeyframeEvent -> AnimState -> AnimState` | Update AnimState after a keyframe event |

### Global Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |
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
