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

```elm
--8<-- "examples/src/Docs/Engines/Sub/BasicUsage/Main.elm"
```

[:material-play-circle: Run this example](../../examples/src/Docs/Engines/Sub/BasicUsage/index.html){ .md-button target="_blank" }


## Interrupting Animations

Start a new animation at any time — the Sub Engine handles smooth transitions:

```elm
update msg model =
    case msg of
        MoveLeft ->
            let
                newAnimState =
                    model.animState
                        |> Sub.builder
                        |> moveLeft
                        |> Sub.animate
            in
            ( { model | animState = newAnimState }, Cmd.none )

        MoveRight ->
            let
                newAnimState =
                    model.animState
                        |> Sub.builder
                        |> moveRight
                        |> Sub.animate
            in
            ( { model | animState = newAnimState }, Cmd.none )


move : Float -> Sub.AnimBuilder -> Sub.AnimBuilder
move amount =
    Translate.for "element-id"
        >> Translate.byX amount
        >> Translate.speed 50
        >> Translate.build

moveLeft : Sub.AnimBuilder -> Sub.AnimBuilder
moveLeft =
    move -100

moveRight : Sub.AnimBuilder -> Aub.AnimBuilder
moveRight =
    move 100

```

The new animation starts from the current position, not the original start position.

## Querying Current Values

Get the current animated value for an element:

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

```elm
view model =
    div []
        [ if Sub.isAnimating model.animState then
            text "Animating..."
          else
            text "Complete"
        ]
```

## Global Settings

Set (optional) defaults for all properties:

- Timing: use `speed` or `duration`
- Easing
- Delay

These settings will be used for all property animations.


```elm
animState =
    model.animState
        |> Sub.builder
        |> Sub.duration 500
        |> Sub.easing QuintOut
        |> Sub.delay 100
        |> myAnimation
        |> Sub.animate
```

Individual properties can override them:

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

## API Reference

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `AnimState` | Create initial animation state |
| `builder` | `AnimState -> AnimBuilder` | Get builder for defining animations |
| `animate` | `AnimBuilder -> AnimState` | Start the animation |
| `tick` | `Float -> AnimState -> AnimState` | Update state with frame delta |
| `subscriptions` | `(Float -> msg) -> AnimState -> Sub msg` | Animation frame subscription |
| `styles` | `String -> AnimState -> List (Html.Attribute msg)` | Get HTML attributes |

### Query Functions

| Function | Description |
| ---------- | ------------- |
| `isAnimating` | Check if any animation is running |
| `getCurrentTranslate` | Get current translate position |
| `getCurrentRotate` | Get current rotation |
| `getCurrentScale` | Get current scale |
| `getCurrentOpacity` | Get current opacity |

### Global Functions

| Function | Description |
| ---------- | ------------- |
| `duration` | Set default duration (ms) |
| `speed` | Set default speed (px/sec) |
| `easing` | Set default easing function |
| `delay` | Set default delay (ms) |
| `perspective` | Set default 3D perspective |

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Sub).
