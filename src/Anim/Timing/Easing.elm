module Anim.Timing.Easing exposing
    ( Easing(..)
    , linear, ease, easeIn, easeOut, easeInOut
    , easeInSine, easeOutSine, easeInOutSine
    , easeInQuad, easeOutQuad, easeInOutQuad
    , easeInCubic, easeOutCubic, easeInOutCubic
    , easeInQuart, easeOutQuart, easeInOutQuart
    , easeInQuint, easeOutQuint, easeInOutQuint
    , easeInExpo, easeOutExpo, easeInOutExpo
    , easeInCirc, easeOutCirc, easeInOutCirc
    , easeInBack, easeOutBack, easeInOutBack
    , easeInElastic, easeOutElastic, easeInOutElastic
    , easeInBounce, easeOutBounce, easeInOutBounce
    , custom
    , toCSS, toWebAnimations, toFunction, encode
    )

{-| Unified easing system for all Anim animation types.

This module provides a serializable easing type that works across CSS transitions,
Web Animations API via ports, and subscription-based animations.


# Easing Type

@docs Easing


# Basic Easing Functions

@docs linear, ease, easeIn, easeOut, easeInOut


# Sine Easing

@docs easeInSine, easeOutSine, easeInOutSine


# Quadratic Easing

@docs easeInQuad, easeOutQuad, easeInOutQuad


# Cubic Easing

@docs easeInCubic, easeOutCubic, easeInOutCubic


# Quartic Easing

@docs easeInQuart, easeOutQuart, easeInOutQuart


# Quintic Easing

@docs easeInQuint, easeOutQuint, easeInOutQuint


# Exponential Easing

@docs easeInExpo, easeOutExpo, easeInOutExpo


# Circular Easing

@docs easeInCirc, easeOutCirc, easeInOutCirc


# Back Easing

@docs easeInBack, easeOutBack, easeInOutBack


# Elastic Easing

@docs easeInElastic, easeOutElastic, easeInOutElastic


# Bounce Easing

@docs easeInBounce, easeOutBounce, easeInOutBounce


# Custom Easing

@docs custom


# Conversion Functions

@docs toCSS, toWebAnimations, toFunction, encode

-}

import Ease as E
import Json.Encode as Encode



-- EASING TYPE


{-| Easing functions for animations.
-}
type Easing
    = Bezier Float Float Float Float
    | Linear
    | Ease
    | EaseIn
    | EaseOut
    | EaseInOut
    | SineIn
    | SineOut
    | SineInOut
    | QuadIn
    | QuadOut
    | QuadInOut
    | CubicIn
    | CubicOut
    | CubicInOut
    | QuartIn
    | QuartOut
    | QuartInOut
    | QuintIn
    | QuintOut
    | QuintInOut
    | ExpoIn
    | ExpoOut
    | ExpoInOut
    | CircIn
    | CircOut
    | CircInOut
    | BackIn
    | BackOut
    | BackInOut
    | ElasticIn
    | ElasticOut
    | ElasticInOut
    | BounceIn
    | BounceOut
    | BounceInOut
    | Custom String


{-| Quintic ease in-out.
-}
quintInOut : Easing
quintInOut =
    QuintInOut



-- EXPONENTIAL EASING


{-| Exponential ease in.
-}
expoIn : Easing
expoIn =
    ExpoIn


{-| Exponential ease out.
-}
expoOut : Easing
expoOut =
    ExpoOut


{-| Exponential ease in-out.
-}
expoInOut : Easing
expoInOut =
    ExpoInOut



-- CIRCULAR EASING


{-| Circular ease in.
-}
circIn : Easing
circIn =
    CircIn


{-| Circular ease out.
-}
circOut : Easing
circOut =
    CircOut


{-| Circular ease in-out.
-}
circInOut : Easing
circInOut =
    CircInOut



-- BACK EASING


{-| Back ease in (overshoot at start).
-}
backIn : Easing
backIn =
    BackIn


{-| Back ease out (overshoot at end).
-}
backOut : Easing
backOut =
    BackOut


{-| Back ease in-out (overshoot at both ends).
-}
backInOut : Easing
backInOut =
    BackInOut



-- ELASTIC EASING


{-| Elastic ease in.
-}
elasticIn : Easing
elasticIn =
    ElasticIn


{-| Elastic ease out.
-}
elasticOut : Easing
elasticOut =
    ElasticOut


{-| Elastic ease in-out.
-}
elasticInOut : Easing
elasticInOut =
    ElasticInOut



-- BOUNCE EASING


{-| Bounce ease in.
-}
bounceIn : Easing
bounceIn =
    BounceIn


{-| Bounce ease out.
-}
bounceOut : Easing
bounceOut =
    BounceOut


{-| Bounce ease in-out.
-}
bounceInOut : Easing
bounceInOut =
    BounceInOut



-- CUSTOM EASING


{-| Custom easing using CSS cubic-bezier notation.

    custom "cubic-bezier(0.68, -0.55, 0.265, 1.55)"

-}
custom : String -> Easing
custom value =
    Custom value



-- CONVERSION FUNCTIONS


{-| Convert easing to CSS transition-timing-function value.
-}
toCSS : Easing -> String
toCSS easing =
    case easing of
        Bezier p1x p1y p2x p2y ->
            "cubic-bezier("
                ++ String.fromFloat p1x
                ++ ", "
                ++ String.fromFloat p1y
                ++ ", "
                ++ String.fromFloat p2x
                ++ ", "
                ++ String.fromFloat p2y
                ++ ")"

        Linear ->
            "linear"

        Ease ->
            "ease"

        EaseIn ->
            "ease-in"

        EaseOut ->
            "ease-out"

        EaseInOut ->
            "ease-in-out"

        EaseInSine ->
            "cubic-bezier(0.12, 0, 0.39, 0)"

        EaseOutSine ->
            "cubic-bezier(0.61, 1, 0.88, 1)"

        EaseInOutSine ->
            "cubic-bezier(0.37, 0, 0.63, 1)"

        EaseInQuad ->
            "cubic-bezier(0.11, 0, 0.5, 0)"

        EaseOutQuad ->
            "cubic-bezier(0.5, 1, 0.89, 1)"

        EaseInOutQuad ->
            "cubic-bezier(0.45, 0, 0.55, 1)"

        EaseInCubic ->
            "cubic-bezier(0.32, 0, 0.67, 0)"

        EaseOutCubic ->
            "cubic-bezier(0.33, 1, 0.68, 1)"

        EaseInOutCubic ->
            "cubic-bezier(0.65, 0, 0.35, 1)"

        EaseInQuart ->
            "cubic-bezier(0.5, 0, 0.75, 0)"

        EaseOutQuart ->
            "cubic-bezier(0.25, 1, 0.5, 1)"

        EaseInOutQuart ->
            "cubic-bezier(0.76, 0, 0.24, 1)"

        EaseInQuint ->
            "cubic-bezier(0.64, 0, 0.78, 0)"

        EaseOutQuint ->
            "cubic-bezier(0.22, 1, 0.36, 1)"

        EaseInOutQuint ->
            "cubic-bezier(0.83, 0, 0.17, 1)"

        EaseInExpo ->
            "cubic-bezier(0.7, 0, 0.84, 0)"

        EaseOutExpo ->
            "cubic-bezier(0.16, 1, 0.3, 1)"

        EaseInOutExpo ->
            "cubic-bezier(0.87, 0, 0.13, 1)"

        EaseInCirc ->
            "cubic-bezier(0.55, 0, 1, 0.45)"

        EaseOutCirc ->
            "cubic-bezier(0, 0.55, 0.45, 1)"

        EaseInOutCirc ->
            "cubic-bezier(0.85, 0, 0.15, 1)"

        EaseInBack ->
            "cubic-bezier(0.36, 0, 0.66, -0.56)"

        EaseOutBack ->
            "cubic-bezier(0.34, 1.56, 0.64, 1)"

        EaseInOutBack ->
            "cubic-bezier(0.68, -0.6, 0.32, 1.6)"

        -- Note: Elastic and bounce can't be perfectly represented with cubic-bezier
        -- Web Animations API could potentially support these with keyframes
        -- For now, using cubic-bezier approximations
        EaseInElastic ->
            "cubic-bezier(0.04, 0.04, 0.12, 0.96)"

        EaseOutElastic ->
            "cubic-bezier(0.88, 0.04, 0.96, 0.96)"

        EaseInOutElastic ->
            "cubic-bezier(0.04, 0.04, 0.96, 0.96)"

        EaseInBounce ->
            "cubic-bezier(0.04, 0.04, 0.12, 0.96)"

        EaseOutBounce ->
            "cubic-bezier(0.88, 0.04, 0.96, 0.96)"

        EaseInOutBounce ->
            "cubic-bezier(0.04, 0.04, 0.96, 0.96)"

        Custom value ->
            value


{-| Convert easing to Web Animations API easing string.
-}
toWebAnimations : Easing -> String
toWebAnimations easing =
    case easing of
        Bezier p1x p1y p2x p2y ->
            "cubic-bezier("
                ++ String.fromFloat p1x
                ++ ", "
                ++ String.fromFloat p1y
                ++ ", "
                ++ String.fromFloat p2x
                ++ ", "
                ++ String.fromFloat p2y
                ++ ")"

        Linear ->
            "linear"

        Ease ->
            "ease"

        EaseIn ->
            "ease-in"

        EaseOut ->
            "ease-out"

        EaseInOut ->
            "ease-in-out"

        -- Web Animations API supports more complex easing strings
        EaseInSine ->
            "cubic-bezier(0.12, 0, 0.39, 0)"

        EaseOutSine ->
            "cubic-bezier(0.61, 1, 0.88, 1)"

        EaseInOutSine ->
            "cubic-bezier(0.37, 0, 0.63, 1)"

        EaseInQuad ->
            "cubic-bezier(0.11, 0, 0.5, 0)"

        EaseOutQuad ->
            "cubic-bezier(0.5, 1, 0.89, 1)"

        EaseInOutQuad ->
            "cubic-bezier(0.45, 0, 0.55, 1)"

        EaseInCubic ->
            "cubic-bezier(0.32, 0, 0.67, 0)"

        EaseOutCubic ->
            "cubic-bezier(0.33, 1, 0.68, 1)"

        EaseInOutCubic ->
            "cubic-bezier(0.65, 0, 0.35, 1)"

        EaseInQuart ->
            "cubic-bezier(0.5, 0, 0.75, 0)"

        EaseOutQuart ->
            "cubic-bezier(0.25, 1, 0.5, 1)"

        EaseInOutQuart ->
            "cubic-bezier(0.76, 0, 0.24, 1)"

        EaseInQuint ->
            "cubic-bezier(0.64, 0, 0.78, 0)"

        EaseOutQuint ->
            "cubic-bezier(0.22, 1, 0.36, 1)"

        EaseInOutQuint ->
            "cubic-bezier(0.83, 0, 0.17, 1)"

        EaseInExpo ->
            "cubic-bezier(0.7, 0, 0.84, 0)"

        EaseOutExpo ->
            "cubic-bezier(0.16, 1, 0.3, 1)"

        EaseInOutExpo ->
            "cubic-bezier(0.87, 0, 0.13, 1)"

        EaseInCirc ->
            "cubic-bezier(0.55, 0, 1, 0.45)"

        EaseOutCirc ->
            "cubic-bezier(0, 0.55, 0.45, 1)"

        EaseInOutCirc ->
            "cubic-bezier(0.85, 0, 0.15, 1)"

        EaseInBack ->
            "cubic-bezier(0.36, 0, 0.66, -0.56)"

        EaseOutBack ->
            "cubic-bezier(0.34, 1.56, 0.64, 1)"

        EaseInOutBack ->
            "cubic-bezier(0.68, -0.6, 0.32, 1.6)"

        -- Web Animations API could potentially support these with keyframes
        -- For now, using cubic-bezier approximations
        EaseInElastic ->
            "cubic-bezier(0.04, 0.04, 0.12, 0.96)"

        EaseOutElastic ->
            "cubic-bezier(0.88, 0.04, 0.96, 0.96)"

        EaseInOutElastic ->
            "cubic-bezier(0.04, 0.04, 0.96, 0.96)"

        EaseInBounce ->
            "cubic-bezier(0.04, 0.04, 0.12, 0.96)"

        EaseOutBounce ->
            "cubic-bezier(0.88, 0.04, 0.96, 0.96)"

        EaseInOutBounce ->
            "cubic-bezier(0.04, 0.04, 0.96, 0.96)"

        Custom value ->
            value


{-| Convert easing to a mathematical function for subscription-based animations.

This returns a function that takes a progress value from 0.0 to 1.0 and returns
the eased progress value.

-}
toFunction : Easing -> (Float -> Float)
toFunction easing =
    case easing of
        Bezier p1x p1y p2x p2y ->
            E.bezier p1x p1y p2x p2y

        Linear ->
            E.linear

        Ease ->
            E.inOutQuad

        EaseIn ->
            E.inQuad

        EaseOut ->
            E.outQuad

        EaseInOut ->
            E.inOutQuad

        EaseInSine ->
            E.inSine

        EaseOutSine ->
            E.outSine

        EaseInOutSine ->
            E.inOutSine

        EaseInQuad ->
            E.inQuad

        EaseOutQuad ->
            E.outQuad

        EaseInOutQuad ->
            E.inOutQuad

        EaseInCubic ->
            E.inCubic

        EaseOutCubic ->
            E.outCubic

        EaseInOutCubic ->
            E.inOutCubic

        EaseInQuart ->
            E.inQuart

        EaseOutQuart ->
            E.outQuart

        EaseInOutQuart ->
            E.inOutQuart

        EaseInQuint ->
            E.inQuint

        EaseOutQuint ->
            E.outQuint

        EaseInOutQuint ->
            E.inOutQuint

        EaseInExpo ->
            E.inExpo

        EaseOutExpo ->
            E.outExpo

        EaseInOutExpo ->
            E.inOutExpo

        EaseInCirc ->
            E.inCirc

        EaseOutCirc ->
            E.outCirc

        EaseInOutCirc ->
            E.inOutCirc

        EaseInBack ->
            E.inBack

        EaseOutBack ->
            E.outBack

        EaseInOutBack ->
            E.inOutBack

        EaseInElastic ->
            E.inElastic

        EaseOutElastic ->
            E.outElastic

        EaseInOutElastic ->
            E.inOutElastic

        EaseInBounce ->
            E.inBounce

        EaseOutBounce ->
            E.outBounce

        EaseInOutBounce ->
            E.inOutBounce

        Custom _ ->
            -- For custom CSS strings, fallback to ease-in-out
            E.inOutQuad



-- HELPER FUNCTIONS FOR MATHEMATICAL IMPLEMENTATIONS


{-| Encode easing for JSON serialization (used by Ports system).
-}
encode : Easing -> Encode.Value
encode easing =
    case easing of
        Bezier p1x p1y p2x p2y ->
            Encode.object
                [ ( "type", Encode.string "bezier" )
                , ( "p1x", Encode.float p1x )
                , ( "p1y", Encode.float p1y )
                , ( "p2x", Encode.float p2x )
                , ( "p2y", Encode.float p2y )
                ]

        Linear ->
            Encode.string "linear"

        Ease ->
            Encode.string "ease"

        EaseIn ->
            Encode.string "ease-in"

        EaseOut ->
            Encode.string "ease-out"

        EaseInOut ->
            Encode.string "ease-in-out"

        EaseInSine ->
            Encode.string "ease-in-sine"

        EaseOutSine ->
            Encode.string "ease-out-sine"

        EaseInOutSine ->
            Encode.string "ease-in-out-sine"

        EaseInQuad ->
            Encode.string "ease-in-quad"

        EaseOutQuad ->
            Encode.string "ease-out-quad"

        EaseInOutQuad ->
            Encode.string "ease-in-out-quad"

        EaseInCubic ->
            Encode.string "ease-in-cubic"

        EaseOutCubic ->
            Encode.string "ease-out-cubic"

        EaseInOutCubic ->
            Encode.string "ease-in-out-cubic"

        EaseInQuart ->
            Encode.string "ease-in-quart"

        EaseOutQuart ->
            Encode.string "ease-out-quart"

        EaseInOutQuart ->
            Encode.string "ease-in-out-quart"

        EaseInQuint ->
            Encode.string "ease-in-quint"

        EaseOutQuint ->
            Encode.string "ease-out-quint"

        EaseInOutQuint ->
            Encode.string "ease-in-out-quint"

        EaseInExpo ->
            Encode.string "ease-in-expo"

        EaseOutExpo ->
            Encode.string "ease-out-expo"

        EaseInOutExpo ->
            Encode.string "ease-in-out-expo"

        EaseInCirc ->
            Encode.string "ease-in-circ"

        EaseOutCirc ->
            Encode.string "ease-out-circ"

        EaseInOutCirc ->
            Encode.string "ease-in-out-circ"

        EaseInBack ->
            Encode.string "ease-in-back"

        EaseOutBack ->
            Encode.string "ease-out-back"

        EaseInOutBack ->
            Encode.string "ease-in-out-back"

        EaseInElastic ->
            Encode.string "ease-in-elastic"

        EaseOutElastic ->
            Encode.string "ease-out-elastic"

        EaseInOutElastic ->
            Encode.string "ease-in-out-elastic"

        EaseInBounce ->
            Encode.string "ease-in-bounce"

        EaseOutBounce ->
            Encode.string "ease-out-bounce"

        EaseInOutBounce ->
            Encode.string "ease-in-out-bounce"

        Custom value ->
            Encode.object
                [ ( "type", Encode.string "custom" )
                , ( "value", Encode.string value )
                ]
