module Anim.Engine.WAAPI exposing
    ( AnimState, init, AnimBuilder, builder
    , animate, animateBatch
    , update
    , perspective
    , perspectiveWith
    , duration, speed
    , easing
    , delay
    , anyRunning, isRunning, allComplete, isComplete
    , getStartBackgroundColor, getEndBackgroundColor, getCurrentBackgroundColor
    , getStartOpacity, getEndOpacity, getCurrentOpacity
    , getStartPosition, getEndPosition, getCurrentPosition
    , getStartRotate, getEndRotate, getCurrentRotate
    , getStartScale, getEndScale, getCurrentScale
    , getStartSize, getEndSize, getCurrentSize
    )

{-| Ports-based animation system utilising the Web Animations API with optional state tracking.

This module converts [AnimBuilder](#AnimBuilder) configurations to JavaScript Web Animations API calls
via Elm ports for maximum performance and browser compatibility.

**Note:** This module requires the accompanying JavaScript library to handle the Web Animations API.

Install the `elm-animate-waapi` package from npm.

        npm install elm-animate-waapi

Then import and initialize it in your JavaScript code:

```javascript
    import ElmAnimateWAAPI from 'elm-animate-waapi';

    const app = Elm.Main.init({ ... });

    ElmAnimateWAAPI.init(app.ports);
```


# Build

@docs AnimState, init, AnimBuilder, builder


# Animation Execution

@docs animate, animateBatch


# Animation Updates

@docs update


# 3D Animations

When using 3D transforms with Position, Rotate, or Scale animations, you need to set a perspective
to give a sense of depth. Without perspective, 3D transformations will have no visual effect, and will appear flat.


## Perspective

@docs perspective


## HTML

@docs perspectiveWith


# Global Settings

These settings will be used for all animations unless overridden on a per-animation basis.


## Timing

@docs duration, speed


## Easing

@docs easing


## Delay

@docs delay


# Querying Animation State

@docs anyRunning, isRunning, allComplete, isComplete


# Querying Animated Properties


## Background Color

@docs getStartBackgroundColor, getEndBackgroundColor, getCurrentBackgroundColor


## Opacity

@docs getStartOpacity, getEndOpacity, getCurrentOpacity


## Position

@docs getStartPosition, getEndPosition, getCurrentPosition


## Rotate

@docs getStartRotate, getEndRotate, getCurrentRotate


## Scale

@docs getStartScale, getEndScale, getCurrentScale


## Size

@docs getStartSize, getEndSize, getCurrentSize

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.BackgroundColor as BackgroundColor exposing (Color)
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position as Position
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.WAAPI as InternalWAAPI
import Anim.Timing.Easing as Easing exposing (Easing)
import Html
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode


{-| Optional State for managing animations.

This state keeps track of animations and their configurations.

    import Anim.Engine.WAAPI as WAAPI

    { model | animations : WAAPI.AnimState }

If you only need to create fire-and-forget animations without tracking state,
you don't need to add this type to your model.

-}
type alias AnimState =
    InternalWAAPI.AnimState


{-| Initialize empty animation state.

    import Anim.Engine.WAAPI as WAAPI

    { model | animations = WAAPI.init }

-}
init : AnimState
init =
    InternalWAAPI.init


{-| Animation builder type.

This is used internally to configure animations before executing them.

-}
type alias AnimBuilder =
    Builder.AnimBuilder


{-| Turn the AnimState into an AnimBuilder.

Use this to start new animations based on current state.


    newBuilder =
        model.animations
            -- Start a new animation based on current state
            |> WAAPI.builder
            |> Position.for "element"
            |> Position.to { x = 100, y = 200 }
            |> Position.build
            |> WAAPI.animate

    -- "element" will animate from its current position

-}
builder : AnimState -> AnimBuilder
builder =
    InternalWAAPI.builder


{-| Execute stateful animation using JavaScript Web Animations API via ports.

Returns updated animation state and encoded animation data for ports.

    let
        ( newAnimState, animationData ) =
            WAAPI.builder model.animationState
                |> Position.for "my-element"
                |> Position.to { x = 100, y = 200 }
                |> Position.speed 500
                |> Position.build
                |> WAAPI.animate model.animationState
    in
    ( { model | animationState = newAnimState }
    , sendAnimationCommand animationData
    )

-}
animate : AnimState -> AnimBuilder -> ( AnimState, Encode.Value )
animate =
    InternalWAAPI.animate


{-| Execute animations using JavaScript Web Animations API via ports (stateless).

For state management and position continuity, use `animate` instead.

    Anim.init "my-element"
        |> Position.to { x = 100, y = 200 }
        |> Position.speed 500
        |> WAAPI.animateStateless sendAnimationCommand

The port function should have the signature:

    port sendAnimationCommand : Encode.Value -> Cmd msg

-}
animateStateless : (Encode.Value -> Cmd msg) -> AnimBuilder -> Cmd msg
animateStateless portFunction animBuilder =
    let
        processedData =
            Builder.processAnimationData animBuilder

        encodedData =
            InternalWAAPI.encode processedData
    in
    portFunction encodedData


{-| Batch and send a List of animations in one go.

    createCircleAnimation index elementId =
        let
            angle =
                toFloat index * angleStep

            x =
                centerX + radius * cos angle

            y =
                centerY + radius * sin angle
        in
        Anim.init elementId
            |> Position.to { x = x, y = y }
            |> Position.duration 1000
            |> Position.easing Easing.easeInOut

    cmd1 =
        Anim.animateBatch animateElement <|
            [ createCircleAnimation 0 "element1"
            , createCircleAnimation 1 "element2"
            , createCircleAnimation 2 "element3"
            , createCircleAnimation 3 "element4"
            , createCircleAnimation 4 "element5"
            , createCircleAnimation 5 "element6"
            , createCircleAnimation 6 "element7"
            , createCircleAnimation 7 "element8"
            , createCircleAnimation 8 "element9"
            , createCircleAnimation 9 "element10"
            , createCircleAnimation 10 "element11"
            , createCircleAnimation 11 "element12"
            , createCircleAnimation 12 "element13"
            ]

-}
animateBatch : (Encode.Value -> Cmd msg) -> List AnimBuilder -> Cmd msg
animateBatch portFunction builders =
    builders
        |> List.map (animateStateless portFunction)
        |> Cmd.batch


{-| Check if any animations are currently running.
-}
anyRunning : AnimState -> Bool
anyRunning =
    InternalWAAPI.anyRunning


{-| Check if a specific element has any animations currently running.
-}
isRunning : String -> AnimState -> Bool
isRunning =
    InternalWAAPI.isElementRunning


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    InternalWAAPI.allComplete


{-| Check if a specific element's animations have completed.

Returns `Nothing` if there are no animations for the element.

-}
isComplete : String -> AnimState -> Maybe Bool
isComplete =
    InternalWAAPI.isElementComplete


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

Returns `black (rgb 0 0 0)` if no explicit start value was set, which is where the animation
**will** start if no explicit start value is set.

-}
getStartBackgroundColor : String -> AnimState -> Maybe Color
getStartBackgroundColor elementId animState =
    InternalWAAPI.getBackgroundColorRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        BackgroundColor.rgb255 0 0 0

                    Just startColor ->
                        startColor
            )


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getEndBackgroundColor : String -> AnimState -> Maybe Color
getEndBackgroundColor elementId animState =
    InternalWAAPI.getBackgroundColorRange elementId animState
        |> Maybe.map .end


{-| Get the current background color of an element based on its animation state.

Returns `Nothing` if the element has no background color animation.

This returns the end state color as WAAPI manages the interpolation in JavaScript.

-}
getCurrentBackgroundColor : String -> AnimState -> Maybe Color
getCurrentBackgroundColor elementId animState =
    InternalWAAPI.getBackgroundColorRange elementId animState
        |> Maybe.map .end


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is where the animation
**will** start if no explicit start value is set.

-}
getStartOpacity : String -> AnimState -> Maybe Float
getStartOpacity elementId animState =
    InternalWAAPI.getOpacityRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        1.0

                    Just startOpacity ->
                        Opacity.toFloat startOpacity
            )


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getEndOpacity : String -> AnimState -> Maybe Float
getEndOpacity elementId animState =
    InternalWAAPI.getOpacityRange elementId animState
        |> Maybe.map (.end >> Opacity.toFloat)


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

This returns the end state opacity as WAAPI manages the interpolation in JavaScript.

-}
getCurrentOpacity : String -> AnimState -> Maybe Float
getCurrentOpacity elementId animState =
    InternalWAAPI.getOpacityRange elementId animState
        |> Maybe.map (.end >> Opacity.toFloat)


{-| Get the start position of an element being animated.

Returns `Nothing` if the element has no position animation.

Returns `(0, 0, 0)` if no explicit start value was set, which is where the animation
**will** start if no explicit start value is set.

-}
getStartPosition : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartPosition elementId animState =
    InternalWAAPI.getPositionRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 0, y = 0, z = 0 }

                    Just startPos ->
                        Position.toRecord startPos
            )


{-| Get the end position of an element being animated.

Returns `Nothing` if the element has no position animation.

-}
getEndPosition : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndPosition elementId animState =
    InternalWAAPI.getPositionRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Position.toRecord


{-| Get the current position of an element based on its animation state.

Returns `Nothing` if the element has no position animation.

This returns the end state position as WAAPI manages the interpolation in JavaScript.

-}
getCurrentPosition : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentPosition elementId animState =
    InternalWAAPI.getPositionRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Position.toRecord


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `0.0 degrees` if no explicit start value was set, which is where the animation
**will** start if no explicit start value is set.

-}
getStartRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartRotate elementId animState =
    InternalWAAPI.getRotateRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 0, y = 0, z = 0 }

                    Just startRotate ->
                        Rotate.toRecord startRotate
            )


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getEndRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndRotate elementId animState =
    InternalWAAPI.getRotateRange elementId animState
        |> Maybe.map (.end >> Rotate.toRecord)


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

This returns the end state rotation as WAAPI manages the interpolation in JavaScript.

-}
getCurrentRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentRotate elementId animState =
    InternalWAAPI.getRotateRange elementId animState
        |> Maybe.map (.end >> Rotate.toRecord)


{-| Get the start scale of an element being animated.

Returns `1.0` if no explicit start value was set, which is where the animation
**will** start if no explicit start value is set.

Returns `Nothing` if the element has no scale animation.

-}
getStartScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartScale elementId animState =
    InternalWAAPI.getScaleRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 1, y = 1, z = 1 }

                    Just startScale ->
                        Scale.toRecord startScale
            )


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getEndScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndScale elementId animState =
    InternalWAAPI.getScaleRange elementId animState
        |> Maybe.map (.end >> Scale.toRecord)


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

This returns the end state scale as WAAPI manages the interpolation in JavaScript.

-}
getCurrentScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentScale elementId animState =
    InternalWAAPI.getScaleRange elementId animState
        |> Maybe.map (.end >> Scale.toRecord)


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `(0, 0)` if no explicit start value was set, which is where the animation
**will** start if no explicit start value is set.

-}
getStartSize : String -> AnimState -> Maybe { width : Float, height : Float }
getStartSize elementId animState =
    InternalWAAPI.getSizeRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { width = 0, height = 0 }

                    Just startSize ->
                        Size.toRecord startSize
            )


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getEndSize : String -> AnimState -> Maybe { width : Float, height : Float }
getEndSize elementId animState =
    InternalWAAPI.getSizeRange elementId animState
        |> Maybe.map (.end >> Size.toRecord)


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

This returns the end state size as WAAPI manages the interpolation in JavaScript.

-}
getCurrentSize : String -> AnimState -> Maybe { width : Float, height : Float }
getCurrentSize elementId animState =
    InternalWAAPI.getSizeRange elementId animState
        |> Maybe.map (.end >> Size.toRecord)


{-| Set global duration in milliseconds (overrides any previous speed setting).

    WAAPI.init
        |> WAAPI.duration 1000
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> WAAPI.animate

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalWAAPI.duration


{-| Set global speed in units per second (overrides any previous duration setting).

    WAAPI.init
        |> WAAPI.speed 100
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> WAAPI.animate

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalWAAPI.speed


{-| Set global easing function.

    Ports.init
        |> Ports.easing EaseInOutQuad
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Ports.animate

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Easing.mapInternal InternalWAAPI.easing


{-| Set global delay in milliseconds.

    Ports.init
        |> Ports.delay 500
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Ports.animate

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalWAAPI.delay


{-| Set the global perspective value for 3D transforms.

The perspective value determines the distance between the viewer and the `z = 0` plane.
A smaller value creates a more pronounced 3D effect, while a larger value creates
a more subtle effect.

**Important:** The `containerId` must match the `id` attribute of the DOM container element.
The JavaScript will automatically apply perspective CSS to this container.

    div
        [ id "my-container" ]
        -- Must match the containerId below
        [ div
            [ id "animated-element" ]
            [ text "3D content" ]
        ]

    WAAPI.init
        |> WAAPI.perspective "my-container" 1000
        |> Position.for "animated-element"
        |> Position.toXYZ 100 200 50
        |> Position.build
        |> WAAPI.animate

You can override this global setting for specific properties using property-specific perspective functions.

**For dynamic perspective control** (e.g., zoom in/out), use [perspectiveWith](#perspectiveWith)
instead of relying on this automatic behavior.

-}
perspective : String -> Float -> AnimBuilder -> AnimBuilder
perspective =
    Builder.perspective


{-| Manually generate HTML attributes with a given perspective value.

Think zoom level for 3D transforms!!

    -- Zoom in/out by changing the perspective value

    update msg model =
        case msg of
            ZoomIn ->
                { model | zoomLevel = model.zoomLevel - 100 }

            ZoomOut ->
                { model | zoomLevel = model.zoomLevel + 100 }


    div
        (CSS.perspectiveWith model.zoomLevel)
        [ -- Animated content
        ]

**Elm-side styles take precedence**: When you use this function, the JavaScript will detect
the existing inline style and skip auto-applying perspective, giving you full control.

-}
perspectiveWith : Float -> List (Html.Attribute msg)
perspectiveWith perspectiveValue =
    [ Html.Attributes.style "perspective" (String.fromFloat perspectiveValue ++ "px")
    , Html.Attributes.style "transform-style" "preserve-3d"
    , Html.Attributes.attribute "data-perspective-source" "elm"
    ]


{-| Update animation state with data received from JavaScript via ports.

This function processes animation update data received from the JavaScript WAAPI
integration and updates the internal animation state accordingly.

    type Msg
        = ReceiveWAAPI Decode.Value
        | ...

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ReceiveWAAPI value ->
                ( { model | animations = WAAPI.update value model.animations }, Cmd.none )

-}
update : Decode.Value -> AnimState -> AnimState
update =
    InternalWAAPI.update
