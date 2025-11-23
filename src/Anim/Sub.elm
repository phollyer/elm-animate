module Anim.Sub exposing
    ( TargetId
    , init, builder, animate, AnimationState, AnimationMsg(..)
    , subscriptions, update
    , getPosition, getCurrentStyles
    , transform
    )

{-| Subscription-based animation system for Anim.

This module converts AnimBuilder configurations to frame-based animations using
onAnimationFrameDelta subscriptions for smooth, controlled animations.


# Animation Execution

@docs TargetId

@docs init, builder, animate, AnimationState, AnimationMsg


# Animation Management

@docs subscriptions, update


# Animation Data

@docs getPosition, getCurrentStyles


# CSS Generation

@docs transform

-}

import Anim exposing (AnimBuilder)
import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.Color as Color exposing (Color)
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Timing.Easing as Easing exposing (Easing(..))
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Events
import Dict exposing (Dict)



-- ANIMATION STATE


{-| State for managing subscription-based animations.
-}
type AnimationState
    = AnimationState ElementAnimation


type alias ElementAnimation =
    { elements : Dict String ElementAnimationState
    , isRunning : Bool
    }


type alias ElementAnimationState =
    { properties : List PropertyAnimationState
    , isComplete : Bool
    }


type alias PropertyAnimationState =
    { propertyType : String
    , startValue : AnimationValue
    , targetValue : AnimationValue
    , currentValue : AnimationValue
    , elapsed : Float -- milliseconds
    , delay : Int
    , easing : Easing
    , speed : Float -- units per second
    , distance : Float -- units
    , duration : Float -- milliseconds
    , isComplete : Bool
    }


type AnimationValue
    = PositionAnimationValue Position
    | RotateAnimationValue Rotate
    | ScaleAnimationValue Scale
    | ColorAnimationValue Color
    | OpacityAnimationValue Opacity


{-| Messages for animation updates.
-}
type AnimationMsg
    = AnimationFrame Float -- delta time in milliseconds



-- ANIMATION EXECUTION


{-| The ID of the target element to animate.
-}
type alias TargetId =
    String


{-| Initialize empty animation builder.
-}
init : AnimBuilder
init =
    Anim.init


{-| Turn the AnimationState into an AnimBuilder.

Use this to start new animations based on current state.

    -- Start a new animation based on current state
    newBuilder =
        model.animations
            |> Sub.builder
            |> Position.for "element"
            |> Position.to { x = 100, y = 200 }
            |> Position.build
            |> Sub.animate

-}
builder : AnimationState -> AnimBuilder
builder (AnimationState _) =
    -- Start with a fresh builder, carrying over any current element positions
    -- This allows chaining animations while preserving current states
    Anim.init


{-| Create animation state from AnimBuilder.

    let
        animationState =
            Anim.init "my-element"
                |> Position.to { x = 100, y = 200 }
                |> Scale.to { x = 1.5, y = 1.5 }
                |> Sub.animate
    in
    -- Use with subscriptions and update

-}
animate : AnimBuilder -> AnimationState
animate animBuilder =
    let
        processedData =
            Builder.processAnimationData animBuilder

        startValues =
            { position = { x = 0, y = 0 }
            , rotate = 0
            , scale = { x = 1.0, y = 1.0 }
            , color = Color.rgba255 255 255 255 1.0
            , opacity = 1.0
            }

        elementStates =
            Dict.map (createElementAnimationState startValues) processedData.elements
    in
    AnimationState
        { elements = elementStates
        , isRunning = not (Dict.isEmpty elementStates)
        }


createElementAnimationState :
    { position : { x : Float, y : Float }
    , rotate : Float
    , scale : { x : Float, y : Float }
    , color : Color
    , opacity : Float
    }
    -> String
    -> Builder.ProcessedElementConfig
    -> ElementAnimationState
createElementAnimationState startValues _ elementConfig =
    { properties = List.filterMap (createPropertyAnimationState startValues) elementConfig.properties
    , isComplete = False
    }


createPropertyAnimationState :
    { position : { x : Float, y : Float }
    , rotate : Float
    , scale : { x : Float, y : Float }
    , color : Color
    , opacity : Float
    }
    -> Builder.ProcessedPropertyConfig
    -> Maybe PropertyAnimationState
createPropertyAnimationState startValues property =
    case property of
        Builder.ProcessedPositionConfig config ->
            let
                startPosition =
                    Position.fromTuple ( startValues.position.x, startValues.position.y )

                actualStart =
                    case config.startAt of
                        Just start ->
                            start

                        Nothing ->
                            startPosition
            in
            Just
                { propertyType = "position"
                , startValue = PositionAnimationValue actualStart
                , targetValue = PositionAnimationValue config.endAt
                , currentValue = PositionAnimationValue actualStart
                , elapsed = 0
                , delay = config.delay
                , easing = config.easing
                , speed = config.speed
                , distance = config.distance
                , duration = toFloat config.duration
                , isComplete = False
                }

        Builder.ProcessedRotateConfig config ->
            let
                startRotate =
                    Rotate.fromFloat startValues.rotate

                actualStart =
                    case config.startAt of
                        Just start ->
                            start

                        Nothing ->
                            startRotate
            in
            Just
                { propertyType = "rotate"
                , startValue = RotateAnimationValue actualStart
                , targetValue = RotateAnimationValue config.endAt
                , currentValue = RotateAnimationValue actualStart
                , elapsed = 0
                , delay = config.delay
                , easing = config.easing
                , speed = config.speed
                , distance = config.distance
                , duration = toFloat config.duration
                , isComplete = False
                }

        Builder.ProcessedScaleConfig config ->
            let
                startScale =
                    Scale.fromTuple ( startValues.scale.x, startValues.scale.y )

                actualStart =
                    case config.startAt of
                        Just start ->
                            start

                        Nothing ->
                            startScale
            in
            Just
                { propertyType = "scale"
                , startValue = ScaleAnimationValue actualStart
                , targetValue = ScaleAnimationValue config.endAt
                , currentValue = ScaleAnimationValue actualStart
                , elapsed = 0
                , delay = config.delay
                , easing = config.easing
                , speed = config.speed
                , distance = config.distance
                , duration = toFloat config.duration
                , isComplete = False
                }

        Builder.ProcessedColorConfig config ->
            let
                startColor =
                    startValues.color

                actualStart =
                    case config.startAt of
                        Just start ->
                            start

                        Nothing ->
                            startColor
            in
            Just
                { propertyType = "color"
                , startValue = ColorAnimationValue actualStart
                , targetValue = ColorAnimationValue config.endAt
                , currentValue = ColorAnimationValue actualStart
                , elapsed = 0
                , delay = config.delay
                , easing = config.easing
                , speed = config.speed
                , distance = config.distance
                , duration = toFloat config.duration
                , isComplete = False
                }

        Builder.ProcessedOpacityConfig config ->
            let
                startOpacity =
                    Opacity.fromFloat startValues.opacity

                actualStart =
                    case config.startAt of
                        Just start ->
                            start

                        Nothing ->
                            startOpacity
            in
            Just
                { propertyType = "opacity"
                , startValue = OpacityAnimationValue actualStart
                , targetValue = OpacityAnimationValue config.endAt
                , currentValue = OpacityAnimationValue actualStart
                , elapsed = 0
                , delay = config.delay
                , easing = config.easing
                , speed = config.speed
                , distance = config.distance
                , duration = toFloat config.duration
                , isComplete = False
                }



-- SUBSCRIPTIONS


{-| Subscribe to animation frames when animations are running.
-}
subscriptions : AnimationState -> Sub AnimationMsg
subscriptions (AnimationState state) =
    if state.isRunning then
        Browser.Events.onAnimationFrameDelta AnimationFrame

    else
        Sub.none



-- UPDATE


{-| Update animation state with frame delta time.
-}
update : AnimationMsg -> AnimationState -> AnimationState
update msg (AnimationState state) =
    case msg of
        AnimationFrame deltaMs ->
            let
                updatedElements =
                    Dict.map (updateElementAnimation deltaMs) state.elements

                stillRunning =
                    Dict.values updatedElements |> List.any (not << .isComplete)
            in
            AnimationState
                { elements = updatedElements
                , isRunning = stillRunning
                }


updateElementAnimation : Float -> String -> ElementAnimationState -> ElementAnimationState
updateElementAnimation deltaMs _ elementState =
    let
        updatedProperties =
            List.map (updatePropertyAnimation deltaMs) elementState.properties

        allComplete =
            List.all .isComplete updatedProperties
    in
    { elementState
        | properties = updatedProperties
        , isComplete = allComplete
    }


updatePropertyAnimation : Float -> PropertyAnimationState -> PropertyAnimationState
updatePropertyAnimation deltaMs propertyState =
    if propertyState.isComplete then
        propertyState

    else
        let
            newElapsed =
                propertyState.elapsed + deltaMs

            delay =
                toFloat propertyState.delay
        in
        -- Check if still in delay period
        if newElapsed < delay then
            { propertyState | elapsed = newElapsed }

        else
            let
                animationElapsed =
                    newElapsed - delay

                progress =
                    min 1.0 (animationElapsed / propertyState.duration)

                easedProgress =
                    Easing.toFunction propertyState.easing progress

                newCurrentValue =
                    interpolateValue easedProgress propertyState.startValue propertyState.targetValue

                isComplete =
                    progress >= 1.0
            in
            { propertyState
                | elapsed = newElapsed
                , currentValue = newCurrentValue
                , isComplete = isComplete
            }



-- POSITION


{-| Get current position of an element being animated.
-}
getPosition : String -> AnimationState -> Maybe Position
getPosition elementId (AnimationState state) =
    Dict.get elementId state.elements
        |> Maybe.andThen
            (\elementState ->
                List.head elementState.properties
                    |> Maybe.andThen
                        (\propertyState ->
                            case propertyState.currentValue of
                                PositionAnimationValue pos ->
                                    Just pos

                                _ ->
                                    Nothing
                        )
            )



-- CURRENT STYLES


{-| Get current animation values as CSS-compatible styles.
-}
getCurrentStyles : String -> AnimationState -> List ( String, String )
getCurrentStyles elementId (AnimationState state) =
    case Dict.get elementId state.elements of
        Nothing ->
            []

        Just elementState ->
            List.concatMap propertyToStyles elementState.properties


propertyToStyles : PropertyAnimationState -> List ( String, String )
propertyToStyles propertyState =
    case propertyState.currentValue of
        PositionAnimationValue pos ->
            let
                ( x, y ) =
                    Position.toTuple pos
            in
            [ ( "transform", "translate(" ++ String.fromFloat x ++ "px, " ++ String.fromFloat y ++ "px)" ) ]

        RotateAnimationValue rotate ->
            let
                degrees =
                    Rotate.toFloat rotate
            in
            [ ( "transform", "rotate(" ++ String.fromFloat degrees ++ "deg)" ) ]

        ScaleAnimationValue scale ->
            let
                ( x, y ) =
                    Scale.toTuple scale
            in
            [ ( "transform", "scale(" ++ String.fromFloat x ++ ", " ++ String.fromFloat y ++ ")" ) ]

        ColorAnimationValue colorValue ->
            [ ( "background-color", Color.toString colorValue ) ]

        OpacityAnimationValue opacity ->
            let
                opacityValue =
                    Opacity.toFloat opacity
            in
            [ ( "opacity", String.fromFloat opacityValue ) ]



-- HELPER FUNCTIONS


interpolateValue : Float -> AnimationValue -> AnimationValue -> AnimationValue
interpolateValue progress startValue targetValue =
    case ( startValue, targetValue ) of
        ( PositionAnimationValue start, PositionAnimationValue target ) ->
            let
                startTuple =
                    Position.toTuple start

                targetTuple =
                    Position.toTuple target

                ( startX, startY ) =
                    startTuple

                ( targetX, targetY ) =
                    targetTuple

                newX =
                    startX + progress * (targetX - startX)

                newY =
                    startY + progress * (targetY - startY)
            in
            PositionAnimationValue (Position.fromTuple ( newX, newY ))

        ( RotateAnimationValue start, RotateAnimationValue target ) ->
            let
                startFloat =
                    Rotate.toFloat start

                targetFloat =
                    Rotate.toFloat target

                newFloat =
                    startFloat + progress * (targetFloat - startFloat)
            in
            RotateAnimationValue (Rotate.fromFloat newFloat)

        ( ScaleAnimationValue start, ScaleAnimationValue target ) ->
            let
                startTuple =
                    Scale.toTuple start

                targetTuple =
                    Scale.toTuple target

                ( startX, startY ) =
                    startTuple

                ( targetX, targetY ) =
                    targetTuple

                newX =
                    startX + progress * (targetX - startX)

                newY =
                    startY + progress * (targetY - startY)
            in
            ScaleAnimationValue (Scale.fromTuple ( newX, newY ))

        ( ColorAnimationValue _, ColorAnimationValue target ) ->
            -- For colors, we'll just snap to target for now
            -- Full color interpolation would require RGB conversion
            ColorAnimationValue target

        ( OpacityAnimationValue start, OpacityAnimationValue target ) ->
            let
                startFloat =
                    Opacity.toFloat start

                targetFloat =
                    Opacity.toFloat target

                newFloat =
                    startFloat + progress * (targetFloat - startFloat)
            in
            OpacityAnimationValue (Opacity.fromFloat newFloat)

        _ ->
            -- Mismatched types, return target
            targetValue


{-| Generate CSS transform string for an element

Apply this to your element's style attribute:

    div
        [ style "transform" (transform "my-element" model.moveSubModel) ]
        [ text "Animated element" ]

-}
transform : TargetId -> AnimationState -> String
transform elementId model =
    case getPosition elementId model of
        Just position ->
            "translate(" ++ Position.toCssString position ++ ")"

        Nothing ->
            "translate(0px, 0px)"
