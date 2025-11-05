module Anim.Internal exposing
    ( animationToMilliseconds
    , animationToPixelsPerSecond
    , calculateDistance
    , easingToEaseFunction
    , easingToString
    , getAnimationEasing
    , getAnimationTarget
    , getAnimationTiming
    )

{-| Internal helper functions shared between Anim modules.
-}

import Anim exposing (Animation, AnimationTarget(..), EasePreset(..), Easing(..), Position, Timing(..), getAnimationData, getEasing, getTarget, getTiming)
import Ease



-- ANIMATION DATA EXTRACTION


{-| Get animation target from Animation.
-}
getAnimationTarget : Animation -> AnimationTarget
getAnimationTarget =
    getTarget


{-| Get animation timing from Animation.
-}
getAnimationTiming : Animation -> Timing
getAnimationTiming =
    getTiming


{-| Get animation easing from Animation.
-}
getAnimationEasing : Animation -> Easing
getAnimationEasing =
    getEasing



-- NEW ANIMATION-BASED CONVERSION UTILITIES


{-| Convert animation to milliseconds for CSS transitions and Web Animations API.
Uses appropriate calculation for each timing type, with fallback handling.
-}
animationToMilliseconds : Animation -> Float -> Float
animationToMilliseconds animation distance =
    let
        timing =
            getAnimationTiming animation
    in
    case timing of
        Duration milliseconds ->
            toFloat milliseconds

        PixelsPerSecond pps ->
            max 100 (distance * 1000 / pps)

        DegreesPerSecond dps ->
            max 100 (distance * 1000 / dps)

        ColorStepsPerSecond cps ->
            max 100 (distance * 1000 / cps)

        OpacityPerSecond ops ->
            max 100 (distance * 1000 / ops)

        ScalePerSecond sps ->
            max 100 (distance * 1000 / sps)

        DimensionsPerSecond dps ->
            max 100 (distance * 1000 / dps)

        FiltersPerSecond fps ->
            max 100 (distance * 1000 / fps)


{-| Convert animation to pixels per second for subscription-based animations.
-}
animationToPixelsPerSecond : Animation -> Float -> Float
animationToPixelsPerSecond animation distance =
    let
        timing =
            getAnimationTiming animation
    in
    case timing of
        Duration milliseconds ->
            -- Convert duration to pixels per second: distance / (duration in seconds)
            distance / (toFloat milliseconds / 1000)

        PixelsPerSecond pps ->
            pps

        -- For non-pixel timing types, treat them as generic units per second
        DegreesPerSecond dps ->
            dps

        ColorStepsPerSecond cps ->
            cps

        OpacityPerSecond ops ->
            ops

        ScalePerSecond sps ->
            sps

        DimensionsPerSecond dps ->
            dps

        FiltersPerSecond fps ->
            fps



-- LEGACY TIMING CONVERSION UTILITIES (FOR BACKWARD COMPATIBILITY)


{-| Convert timing configuration to milliseconds for CSS transitions and Web Animations API.
Uses appropriate calculation for each timing type, with fallback handling.
-}
timingToMilliseconds : Timing -> Float -> Float
timingToMilliseconds timing distance =
    case timing of
        Duration milliseconds ->
            toFloat milliseconds

        PixelsPerSecond pps ->
            max 100 (distance * 1000 / pps)

        DegreesPerSecond dps ->
            max 100 (distance * 1000 / dps)

        ColorStepsPerSecond cps ->
            max 100 (distance * 1000 / cps)

        OpacityPerSecond ops ->
            max 100 (distance * 1000 / ops)

        ScalePerSecond sps ->
            max 100 (distance * 1000 / sps)

        DimensionsPerSecond dps ->
            max 100 (distance * 1000 / dps)

        FiltersPerSecond fps ->
            max 100 (distance * 1000 / fps)


{-| Convert timing configuration to pixels per second for subscription-based animations.
This is used primarily for position-based animations in CSS/Ports modules.
-}
timingToPixelsPerSecond : Timing -> Float -> Float
timingToPixelsPerSecond timing distance =
    case timing of
        Duration milliseconds ->
            distance / (toFloat milliseconds / 1000)

        PixelsPerSecond pps ->
            pps

        DegreesPerSecond dps ->
            dps

        ColorStepsPerSecond cps ->
            cps

        OpacityPerSecond ops ->
            ops

        ScalePerSecond sps ->
            sps

        DimensionsPerSecond dps ->
            dps

        FiltersPerSecond fps ->
            fps



-- DISTANCE CALCULATIONS


{-| Calculate Euclidean distance between two positions.
-}
calculateDistance : Position -> Position -> Float
calculateDistance from to =
    let
        dx =
            to.x - from.x

        dy =
            to.y - from.y
    in
    sqrt (dx * dx + dy * dy)



-- EASING CONVERSION UTILITIES


{-| Convert unified Easing type to CSS easing string for CSS transitions and Web Animations API.
-}
easingToString : Easing -> String
easingToString easing =
    case easing of
        EaseString string ->
            string

        EasePreset preset ->
            case preset of
                Linear ->
                    "linear"

                EaseOut ->
                    "ease-out"

                EaseIn ->
                    "ease-in"

                EaseInOut ->
                    "ease-in-out"

        EaseFunction _ ->
            -- Default fallback for EaseFunction when used in CSS/Ports context
            "ease-out"


{-| Convert unified Easing type to elm-community/easing-functions for subscription-based animations.
-}
easingToEaseFunction : Easing -> Ease.Easing
easingToEaseFunction easing =
    case easing of
        EaseFunction easeFunction ->
            easeFunction

        EasePreset preset ->
            case preset of
                Linear ->
                    Ease.linear

                EaseOut ->
                    Ease.outQuint

                EaseIn ->
                    Ease.inQuint

                EaseInOut ->
                    Ease.inOutQuint

        EaseString _ ->
            -- Default fallback for EaseString when used in Sub context
            Ease.outQuint
