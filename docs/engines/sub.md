# Sub Engine

The Sub Engine uses Elm subscriptions to update animation state on every frame. This provides full programmatic control over animations.

## When to Use

✅ **For:**

- Interrupting and redirecting animations mid-flight
- Querying current animated values mid-flight
- Games and interactive visualizations

❌ **Consider other engines for:**

- Simple fire-and-forget animations (use CSS)
- Browser-native performance with control (use WAAPI)

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
        Sub.animate model.animState
            (Sub.duration 500
                >> Sub.easing QuintOut
                >> Sub.delay 100
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
| `init` | `AnimState` | Create initial animation state |
| `builder` | `AnimState -> AnimBuilder` | Get builder for defining animations |
| `animate` | `AnimBuilder -> AnimState` | Start the animation |
| `update` | `AnimMsg -> AnimState -> AnimState` | Update the animation state |
| `subscriptions` | `(AnimMsg -> msg) -> AnimState -> Sub msg` | Animation frame subscription |

### View Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `htmlAttributes` | `String -> AnimState -> List (Html.Attribute msg)` | Get HTML animation attributes |

### Query Functions

| Function | Type | Description |
| ---------- | ----- | ------------- |
| `isAnimating` | `String -> AnimState -> Bool` | Check if any animation is running |
| `getCurrentTranslate` | `String -> AnimState -> Maybe { x : Float, y : Float, z : Float  }` | Get current translate position |
| `getStartRotate` | `String -> AnimState -> Maybe { x : Float, y : Float, z : Float  }` | Get the start rotation |
| `getEndScale` | `String -> AnimState -> Maybe { x : Float, y : Float, z : Float  }` | Get the target end scale |

### Default Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Sub).
