module Anim.Sub exposing
    ( TargetId
    , animate, AnimationState, AnimationMsg(..)
    , subscriptions, update
    , getPosition, getCurrentStyles
    , transform
    )

{-| Subscription-based animation system for Anim.

This module converts AnimBuilder configurations to frame-based animations using
onAnimationFrameDelta subscriptions for smooth, controlled animations.


# Animation Execution

@docs TargetId

@docs animate, AnimationState, AnimationMsg


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
animate builder =
    let
        processedData =
            Builder.processAnimationData builder

        startValues =
            { position = { x = 0, y = 0 }
            , rotate = 0
            , scale = { x = 1.0, y = 1.0 }
            , color = Color.rgba255 255 255 255 1.0
            , opacity = 1.0
            }

        elementStates =
            Dict.empty

        -- TODO: implement
        --Dict.map (createElementAnimationState startValues) processedData.elements
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
    -> Builder.ElementConfig
    -> ElementAnimationState
createElementAnimationState startValues _ elementConfig =
    { properties = [] -- List.map (createPropertyAnimationState startValues) elementConfig.properties
    , isComplete = False
    }



{-
   createPropertyAnimationState :
       { position : { x : Float, y : Float }
       , rotate : Float
       , scale : { x : Float, y : Float }
       , color : Color
       , opacity : Float
       }
       -> Builder.PropertyConfig
       -> PropertyAnimationState
   createPropertyAnimationState startValues property =

       case property of
           Builder.PositionConfig config ->
               let
                   position =
                       Position.fromTuple ( startValues.position.x, startValues.position.y )

                   distance =
                       Position.distance config.startAt config.endAt

                   duration =
                       case config.timing of
                           Just (Duration ms) ->
                               toFloat ms

                           Just (Speed unitsPerSecond) ->
                               distance / unitsPerSecond * 1000

                           Nothing ->
                               0

                   speed =
                       case config.timing of
                           Just (Duration ms) ->
                               if ms == 0 then
                                   0

                               else
                                   distance / (toFloat ms / 1000)

                           Just (Speed unitsPerSecond) ->
                               unitsPerSecond

                           Nothing ->
                               0
               in
               { propertyType = "position"
               , startValue = PositionAnimationValue position
               , targetValue = PositionAnimationValue config.target
               , currentValue = PositionAnimationValue position
               , elapsed = 0
               , delay = config.delay
               , easing = config.easing
               , speed = speed
               , distance = distance
               , duration = duration
               , isComplete = False
               }

           Builder.RotateConfig config ->
               let
                   rotate =
                       Rotate.fromFloat startValues.rotate

                   distance =
                       Rotate.distance config.startAt config.endAt

                   speed =
                       case config.timing of
                           Just (Duration ms) ->
                               if ms == 0 then
                                   1000000

                               else
                                   distance / (toFloat ms / 1000)

                           Just (Speed unitsPerSecond) ->
                               unitsPerSecond

                           Nothing ->
                               0

                   duration =
                       case config.timing of
                           Just (Duration ms) ->
                               toFloat ms

                           Just (Speed unitsPerSecond) ->
                               distance / unitsPerSecond * 1000

                           Nothing ->
                               0
               in
               { propertyType = "rotate"
               , startValue = RotateAnimationValue rotate
               , targetValue = RotateAnimationValue config.target
               , currentValue = RotateAnimationValue rotate
               , elapsed = 0
               , delay = config.delay
               , easing = config.easing
               , speed = speed
               , distance = distance
               , duration = duration
               , isComplete = False
               }

           Builder.ScaleConfig config ->
               let
                   scale =
                       Scale.fromTuple ( startValues.scale.x, startValues.scale.y )

                   startTuple =
                       Scale.toTuple scale

                   targetTuple =
                       Scale.toTuple config.target

                   distance =
                       sqrt ((targetTuple.x - startTuple.x) ^ 2 + (targetTuple.y - startTuple.y) ^ 2)

                   speed =
                       case config.timing of
                           Duration ms ->
                               if ms == 0 then
                                   1000000

                               else
                                   distance / (toFloat ms / 1000)

                           Speed unitsPerSecond ->
                               unitsPerSecond

                   duration =
                       case config.timing of
                           Duration ms ->
                               toFloat ms

                           Speed unitsPerSecond ->
                               distance / unitsPerSecond * 1000
               in
               { propertyType = "scale"
               , startValue = ScaleAnimationValue scale
               , targetValue = ScaleAnimationValue config.target
               , currentValue = ScaleAnimationValue scale
               , elapsed = 0
               , delay = config.delay
               , easing = config.easing
               , speed = speed
               , distance = distance
               , duration = duration
               , isComplete = False
               }

           Builder.ColorConfig config ->
               let
                   distance =
                       1.0

                   -- Color distance is not easily calculated
                   speed =
                       case config.timing of
                           Duration ms ->
                               if ms == 0 then
                                   1000000

                               else
                                   1.0 / (toFloat ms / 1000)

                           Speed unitsPerSecond ->
                               unitsPerSecond

                   duration =
                       case config.timing of
                           Duration ms ->
                               toFloat ms

                           Speed unitsPerSecond ->
                               1.0 / unitsPerSecond * 1000
               in
               { propertyType = "color"
               , startValue = ColorAnimationValue startValues.color
               , targetValue = ColorAnimationValue config.target
               , currentValue = ColorAnimationValue startValues.color
               , elapsed = 0
               , delay = config.delay
               , easing = config.easing
               , speed = speed
               , distance = distance
               , duration = duration
               , isComplete = False
               }

           Builder.OpacityConfig config ->
               let
                   opacity =
                       Opacity.fromFloat startValues.opacity

                   distance =
                       abs (Opacity.toFloat config.endAt - Opacity.toFloat opacity)

                   speed =
                       case config.timing of
                           Just (Duration ms) ->
                               if ms == 0 then
                                   1000000

                               else
                                   distance / (toFloat ms / 1000)

                           Just (Speed unitsPerSecond) ->
                               unitsPerSecond

                           Nothing ->
                               0

                   duration =
                       case config.timing of
                           Just (Duration ms) ->
                               toFloat ms

                           Just (Speed unitsPerSecond) ->
                               distance / unitsPerSecond * 1000

                           Nothing ->
                               0
               in
               { propertyType = "opacity"
               , startValue = OpacityAnimationValue opacity
               , targetValue = OpacityAnimationValue config.endAt
               , currentValue = OpacityAnimationValue opacity
               , elapsed = 0
               , delay = config.delay
               , easing = config.easing
               , speed = speed
               , distance = distance
               , duration = duration
               , isComplete = False
               }

-}
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


timingToMs : TimeSpec -> Float
timingToMs timing =
    case timing of
        Duration ms ->
            toFloat ms

        Speed unitsPerSecond ->
            -- Convert speed to duration (approximate)
            -- Assume 100 unit movement for speed-based timing
            100 / unitsPerSecond * 1000


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
