module Anim.Sub exposing
    ( TargetId, Position, Scale
    , animate, AnimationState, AnimationMsg(..)
    , subscriptions, update
    , getPosition, getCurrentStyles
    , transform
    , Rotation
    )

{-| Subscription-based animation system for Anim.

This module converts AnimBuilder configurations to frame-based animations using
onAnimationFrameDelta subscriptions for smooth, controlled animations.


# Animation Execution

@docs TargetId, Position, Scale

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
import Anim.Timing.Easing exposing (Easing(..))
import Browser.Events
import Dict



-- ANIMATION STATE


{-| State for managing subscription-based animations.
-}
type AnimationState
    = AnimationState Builder.State


{-| Messages for animation updates.
-}
type AnimationMsg
    = AnimationFrame Float -- delta time in milliseconds



-- ANIMATION EXECUTION


{-| The ID of the target element to animate.
-}
type alias TargetId =
    String


{-| Position coordinates for element placement.
-}
type alias Position =
    { x : Float, y : Float }


{-| Rotation angle for element rotation.
-}
type alias Rotation =
    Float


{-| Scale factors for element sizing.
-}
type alias Scale =
    { x : Float, y : Float }


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

        elementStates =
            Dict.map (createElementAnimationState startValues) processedData.elements
    in
    AnimationState
        { elements = elementStates
        , isRunning = not (Dict.isEmpty elementStates)
        }


createElementAnimationState :
    { position : { x : Float, y : Float }
    , rotation : Float
    , scale : { x : Float, y : Float }
    , color : ColorValue
    , opacity : Float
    }
    -> String
    -> ProcessedElementConfig
    -> ElementAnimationState
createElementAnimationState startValues _ elementConfig =
    { properties = List.map (createPropertyAnimationState startValues) elementConfig.properties
    , isComplete = False
    }


createPropertyAnimationState :
    { position : { x : Float, y : Float }
    , rotation : Float
    , scale : { x : Float, y : Float }
    , color : ColorValue
    , opacity : Float
    }
    -> ProcessedPropertyConfig
    -> PropertyAnimationState
createPropertyAnimationState startValues property =
    case property of
        ProcessedPositionConfig config ->
            { propertyType = "position"
            , startValue = PositionAnimationValue startValues.position
            , targetValue = PositionAnimationValue config.target
            , currentValue = PositionAnimationValue startValues.position
            , duration = timingToMs config.timing
            , elapsed = 0
            , delay = toFloat config.delay
            , easing = config.easing
            , isComplete = False
            }

        ProcessedRotateConfig config ->
            { propertyType = "rotation"
            , startValue = RotationAnimationValue startValues.rotation
            , targetValue = RotationAnimationValue config.target
            , currentValue = RotationAnimationValue startValues.rotation
            , duration = timingToMs config.timing
            , elapsed = 0
            , delay = toFloat config.delay
            , easing = config.easing
            , isComplete = False
            }

        ProcessedScaleConfig config ->
            { propertyType = "scale"
            , startValue = ScaleAnimationValue startValues.scale
            , targetValue = ScaleAnimationValue config.target
            , currentValue = ScaleAnimationValue startValues.scale
            , duration = timingToMs config.timing
            , elapsed = 0
            , delay = toFloat config.delay
            , easing = config.easing
            , isComplete = False
            }

        ProcessedColorConfig config ->
            { propertyType = "color"
            , startValue = ColorAnimationValue startValues.color
            , targetValue = ColorAnimationValue config.target
            , currentValue = ColorAnimationValue startValues.color
            , duration = timingToMs config.timing
            , elapsed = 0
            , delay = toFloat config.delay
            , easing = config.easing
            , isComplete = False
            }

        ProcessedOpacityConfig config ->
            { propertyType = "opacity"
            , startValue = OpacityAnimationValue startValues.opacity
            , targetValue = OpacityAnimationValue config.target
            , currentValue = OpacityAnimationValue startValues.opacity
            , duration = timingToMs config.timing
            , elapsed = 0
            , delay = toFloat config.delay
            , easing = config.easing
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
        in
        -- Check if still in delay period
        if newElapsed < propertyState.delay then
            { propertyState | elapsed = newElapsed }

        else
            let
                animationElapsed =
                    newElapsed - propertyState.delay

                progress =
                    min 1.0 (animationElapsed / propertyState.duration)

                easedProgress =
                    applyEasing propertyState.easing progress

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
            [ ( "transform", "translate(" ++ String.fromFloat pos.x ++ "px, " ++ String.fromFloat pos.y ++ "px)" ) ]

        RotationAnimationValue rotation ->
            [ ( "transform", "rotate(" ++ String.fromFloat rotation ++ "deg)" ) ]

        ScaleAnimationValue scale ->
            [ ( "transform", "scale(" ++ String.fromFloat scale.x ++ ", " ++ String.fromFloat scale.y ++ ")" ) ]

        ColorAnimationValue colorValue ->
            [ ( "background-color", colorValueToCSS colorValue ) ]

        OpacityAnimationValue opacity ->
            [ ( "opacity", String.fromFloat opacity ) ]



-- HELPER FUNCTIONS


timingToMs : Timing -> Float
timingToMs timing =
    case timing of
        Duration ms ->
            toFloat ms

        Speed unitsPerSecond ->
            -- Convert speed to duration (approximate)
            -- Assume 100 unit movement for speed-based timing
            100 / unitsPerSecond * 1000


applyEasing : Easing -> Float -> Float
applyEasing easing progress =
    case easing of
        Linear ->
            progress

        Bezier p1x p1y p2x p2y ->
            -- Approximate cubic Bezier easing using De Casteljau's algorithm
            let
                u =
                    1 - progress

                tt =
                    progress * progress

                uu =
                    u * u

                uuu =
                    uu * u

                ttt =
                    tt * progress

                x =
                    uuu * 0 + 3 * uu * progress * p1x + 3 * u * tt * p2x + ttt * 1

                y =
                    uuu * 0 + 3 * uu * progress * p1y + 3 * u * tt * p2y + ttt * 1
            in
            y

        -- Return the y value as eased progress
        Ease ->
            -- Standard ease (equivalent to ease-in-out)
            if progress < 0.5 then
                2 * progress * progress

            else
                1 - (-2 * progress + 2) ^ 2 / 2

        EaseIn ->
            progress * progress

        EaseOut ->
            1 - (1 - progress) * (1 - progress)

        EaseInOut ->
            if progress < 0.5 then
                2 * progress * progress

            else
                1 - (-2 * progress + 2) ^ 2 / 2

        EaseInSine ->
            1 - cos (progress * pi / 2)

        EaseOutSine ->
            sin (progress * pi / 2)

        EaseInOutSine ->
            -(cos (pi * progress) - 1) / 2

        EaseInQuad ->
            progress * progress

        EaseOutQuad ->
            1 - (1 - progress) * (1 - progress)

        EaseInOutQuad ->
            if progress < 0.5 then
                2 * progress * progress

            else
                1 - (-2 * progress + 2) ^ 2 / 2

        EaseInCubic ->
            progress * progress * progress

        EaseOutCubic ->
            1 - (1 - progress) ^ 3

        EaseInOutCubic ->
            if progress < 0.5 then
                4 * progress * progress * progress

            else
                1 - (-2 * progress + 2) ^ 3 / 2

        EaseInQuart ->
            progress ^ 4

        EaseOutQuart ->
            1 - (1 - progress) ^ 4

        EaseInOutQuart ->
            if progress < 0.5 then
                8 * progress ^ 4

            else
                1 - (-2 * progress + 2) ^ 4 / 2

        EaseInQuint ->
            progress ^ 5

        EaseOutQuint ->
            1 - (1 - progress) ^ 5

        EaseInOutQuint ->
            if progress < 0.5 then
                16 * progress ^ 5

            else
                1 - (-2 * progress + 2) ^ 5 / 2

        EaseInExpo ->
            if progress == 0 then
                0

            else
                2 ^ (10 * (progress - 1))

        EaseOutExpo ->
            if progress == 1 then
                1

            else
                1 - 2 ^ (-10 * progress)

        EaseInOutExpo ->
            if progress == 0 then
                0

            else if progress == 1 then
                1

            else if progress < 0.5 then
                2 ^ (20 * progress - 10) / 2

            else
                (2 - 2 ^ (-20 * progress + 10)) / 2

        EaseInCirc ->
            1 - sqrt (1 - progress ^ 2)

        EaseOutCirc ->
            sqrt (1 - (progress - 1) ^ 2)

        EaseInOutCirc ->
            if progress < 0.5 then
                (1 - sqrt (1 - (2 * progress) ^ 2)) / 2

            else
                (sqrt (1 - (-2 * progress + 2) ^ 2) + 1) / 2

        EaseInBack ->
            let
                c1 =
                    1.70158

                c3 =
                    c1 + 1
            in
            c3 * progress * progress * progress - c1 * progress * progress

        EaseOutBack ->
            let
                c1 =
                    1.70158

                c3 =
                    c1 + 1
            in
            1 + c3 * (progress - 1) ^ 3 + c1 * (progress - 1) ^ 2

        EaseInOutBack ->
            let
                c1 =
                    1.70158

                c2 =
                    c1 * 1.525
            in
            if progress < 0.5 then
                ((2 * progress) ^ 2 * ((c2 + 1) * 2 * progress - c2)) / 2

            else
                (((2 * progress - 2) ^ 2 * ((c2 + 1) * (progress * 2 - 2) + c2)) + 2) / 2

        EaseInElastic ->
            if progress == 0 then
                0

            else if progress == 1 then
                1

            else
                -(2 ^ (10 * progress - 10)) * sin ((progress * 10 - 10.75) * (2 * pi) / 3)

        EaseOutElastic ->
            if progress == 0 then
                0

            else if progress == 1 then
                1

            else
                (2 ^ (-10 * progress)) * sin ((progress * 10 - 0.75) * (2 * pi) / 3) + 1

        EaseInOutElastic ->
            if progress == 0 then
                0

            else if progress == 1 then
                1

            else if progress < 0.5 then
                (-(2 ^ (20 * progress - 10)) * sin ((20 * progress - 11.125) * (2 * pi) / 4.5)) / 2

            else
                (2 ^ (-20 * progress + 10)) * sin ((20 * progress - 11.125) * (2 * pi) / 4.5) / 2 + 1

        EaseInBounce ->
            let
                bounceIn t =
                    1 - bounceOut (1 - t)

                bounceOut t =
                    if t < 1 / 2.75 then
                        7.5625 * t * t

                    else if t < 2 / 2.75 then
                        7.5625 * (t - 1.5 / 2.75) * (t - 1.5 / 2.75) + 0.75

                    else if t < 2.5 / 2.75 then
                        7.5625 * (t - 2.25 / 2.75) * (t - 2.25 / 2.75) + 0.9375

                    else
                        7.5625 * (t - 2.625 / 2.75) * (t - 2.625 / 2.75) + 0.984375
            in
            bounceIn progress

        EaseOutBounce ->
            let
                bounceOut t =
                    if t < 1 / 2.75 then
                        7.5625 * t * t

                    else if t < 2 / 2.75 then
                        7.5625 * (t - 1.5 / 2.75) * (t - 1.5 / 2.75) + 0.75

                    else if t < 2.5 / 2.75 then
                        7.5625 * (t - 2.25 / 2.75) * (t - 2.25 / 2.75) + 0.9375

                    else
                        7.5625 * (t - 2.625 / 2.75) * (t - 2.625 / 2.75) + 0.984375
            in
            bounceOut progress

        EaseInOutBounce ->
            let
                bounceIn t =
                    1 - bounceOut (1 - t)

                bounceOut t =
                    if t < 1 / 2.75 then
                        7.5625 * t * t

                    else if t < 2 / 2.75 then
                        7.5625 * (t - 1.5 / 2.75) * (t - 1.5 / 2.75) + 0.75

                    else if t < 2.5 / 2.75 then
                        7.5625 * (t - 2.25 / 2.75) * (t - 2.25 / 2.75) + 0.9375

                    else
                        7.5625 * (t - 2.625 / 2.75) * (t - 2.625 / 2.75) + 0.984375
            in
            if progress < 0.5 then
                bounceIn (progress * 2) / 2

            else
                bounceOut (progress * 2 - 1) / 2 + 0.5

        Custom _ ->
            -- For custom CSS strings, fallback to ease-in-out
            if progress < 0.5 then
                2 * progress * progress

            else
                1 - (-2 * progress + 2) ^ 2 / 2


interpolateValue : Float -> AnimationValue -> AnimationValue -> AnimationValue
interpolateValue progress startValue targetValue =
    case ( startValue, targetValue ) of
        ( PositionAnimationValue start, PositionAnimationValue target ) ->
            PositionAnimationValue
                { x = start.x + progress * (target.x - start.x)
                , y = start.y + progress * (target.y - start.y)
                }

        ( RotationAnimationValue start, RotationAnimationValue target ) ->
            RotationAnimationValue (start + progress * (target - start))

        ( ScaleAnimationValue start, ScaleAnimationValue target ) ->
            ScaleAnimationValue
                { x = start.x + progress * (target.x - start.x)
                , y = start.y + progress * (target.y - start.y)
                }

        ( ColorAnimationValue _, ColorAnimationValue target ) ->
            -- For colors, we'll just snap to target for now
            -- Full color interpolation would require RGB conversion
            ColorAnimationValue target

        ( OpacityAnimationValue start, OpacityAnimationValue target ) ->
            OpacityAnimationValue (start + progress * (target - start))

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
            "translate(" ++ String.fromFloat position.x ++ "px, " ++ String.fromFloat position.y ++ "px)"

        Nothing ->
            "translate(0px, 0px)"
