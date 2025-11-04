module Anim.Internal exposing
    ( calculateDistance
    , easingToEaseFunction
    , easingToString
    , timingToMilliseconds
    , timingToPixelsPerSecond
    )

{-| Internal helper functions shared between Anim modules.
-}

import Anim exposing (EasePreset(..), Easing(..), Timing(..))
import Ease



-- CORE TYPES


{-| Position type for X and Y coordinates in pixels.
-}
type alias Position =
    { x : Float
    , y : Float
    }



-- TIMING CONVERSION UTILITIES


{-| Convert timing configuration to milliseconds for CSS transitions and Web Animations API.
-}
timingToMilliseconds : Timing -> Float -> Float
timingToMilliseconds timing distance =
    case timing of
        Speed pixelsPerSecond ->
            -- Convert pixels per second to milliseconds: (distance / speed) * 1000
            (distance / pixelsPerSecond) * 1000

        Duration milliseconds ->
            toFloat milliseconds


{-| Convert timing configuration to pixels per second for subscription-based animations.
-}
timingToPixelsPerSecond : Timing -> Float -> Float
timingToPixelsPerSecond timing distance =
    case timing of
        Speed pixelsPerSecond ->
            pixelsPerSecond

        Duration milliseconds ->
            -- Convert duration to pixels per second: distance / (duration in seconds)
            distance / (toFloat milliseconds / 1000)



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
