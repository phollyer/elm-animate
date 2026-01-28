# Sub Engine

The Sub Engine uses Elm subscriptions to update animation state on every frame. This provides full programmatic control over animations.

## When to Use

✅ **Best for:**

- Animations that respond to user input
- Needing to interrupt and redirect animations smoothly
- Querying current animated values mid-flight
- Complex state-dependent animations
- Games and interactive visualizations

❌ **Consider other engines when:**

- Simple fire-and-forget animations (use CSS)
- You need browser-native performance with control (use WAAPI)

## Basic Usage

```elm
import Anim.Engine.Sub as Sub
import Anim.Property.Translate as Translate


type alias Model =
    { animState : Sub.AnimState }


type Msg
    = AnimFrame Float


init : ( Model, Cmd Msg )
init =
    ( { animState = Sub.init }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions AnimFrame model.animState


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AnimFrame delta ->
            ( { model | animState = Sub.tick delta model.animState }
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    div
        ([ id "box" ] ++ Sub.styles "box" model.animState)
        [ text "Hello!" ]
```

## Starting Animations

Create animations and apply them to your state:

```elm
type Msg
    = StartAnimation
    | AnimFrame Float


update msg model =
    case msg of
        StartAnimation ->
            let
                newAnimState =
                    model.animState
                        |> Sub.builder
                        |> slideIn
                        |> Sub.animate
            in
            ( { model | animState = newAnimState }, Cmd.none )

        AnimFrame delta ->
            ( { model | animState = Sub.tick delta model.animState }
            , Cmd.none
            )


slideIn : Sub.AnimBuilder -> Sub.AnimBuilder
slideIn builder =
    builder
        |> Translate.for "box"
        |> Translate.fromX -100
        |> Translate.toX 0
        |> Translate.duration 500
        |> Translate.build
```

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
        [ div
            ([ id "box" ] ++ Sub.styles "box" model.animState)
            []
        , case maybePosition of
            Just ( x, y, z ) ->
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

```elm
animState =
    model.animState
        |> Sub.builder
        |> Sub.duration 500
        |> Sub.easing QuintOut
        |> myAnimation
        |> Sub.animate
```

## 3D Transforms and Perspective

```elm
translate3D builder =
    builder
        |> Translate.for "card"
        |> Translate.perspective "container" 1000
        |> Translate.fromZ 0
        |> Translate.toZ 200
        |> Translate.build


view model =
    div
        ([ id "container" ] ++ Sub.perspectiveStyles "container" model.animState)
        [ div
            ([ id "card" ] ++ Sub.styles "card" model.animState)
            [ text "3D Card" ]
        ]
```

## API Reference

### Core Functions

| Function | Type | Description |
|----------|------|-------------|
| `init` | `AnimState` | Create initial animation state |
| `builder` | `AnimState -> AnimBuilder` | Get builder for defining animations |
| `animate` | `AnimBuilder -> AnimState` | Start the animation |
| `tick` | `Float -> AnimState -> AnimState` | Update state with frame delta |
| `subscriptions` | `(Float -> msg) -> AnimState -> Sub msg` | Animation frame subscription |
| `styles` | `String -> AnimState -> List (Html.Attribute msg)` | Get HTML attributes |

### Query Functions

| Function | Description |
|----------|-------------|
| `isAnimating` | Check if any animation is running |
| `getCurrentTranslate` | Get current translate position |
| `getCurrentRotate` | Get current rotation |
| `getCurrentScale` | Get current scale |
| `getCurrentOpacity` | Get current opacity |

### Global Settings

| Function | Description |
|----------|-------------|
| `duration` | Set default duration (ms) |
| `speed` | Set default speed (px/sec) |
| `easing` | Set default easing function |
| `delay` | Set default delay (ms) |
| `perspective` | Set default 3D perspective |

For complete API details, see the [elm-lang.org package documentation](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Sub).
