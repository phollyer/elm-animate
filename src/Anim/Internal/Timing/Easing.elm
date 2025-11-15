module Anim.Internal.Timing.Easing exposing
    ( Easing(..)
    , linear, ease, easeIn, easeOut, easeInOut
    , sineIn, sineOut, sineInOut
    , quadIn, quadOut, quadInOut
    , cubicIn, cubicOut, cubicInOut
    , quartIn, quartOut, quartInOut
    , quintIn, quintOut, quintInOut
    , expoIn, expoOut, expoInOut
    , circIn, circOut, circInOut
    , backIn, backOut, backInOut
    , elasticIn, elasticOut, elasticInOut
    , bounceIn, bounceOut, bounceInOut
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

@docs sineIn, sineOut, sineInOut


# Quadratic Easing

@docs quadIn, quadOut, quadInOut


# Cubic Easing

@docs cubicIn, cubicOut, cubicInOut


# Quartic Easing

@docs quartIn, quartOut, quartInOut


# Quintic Easing

@docs quintIn, quintOut, quintInOut


# Exponential Easing

@docs expoIn, expoOut, expoInOut


# Circular Easing

@docs circIn, circOut, circInOut


# Back Easing

@docs backIn, backOut, backInOut


# Elastic Easing

@docs elasticIn, elasticOut, elasticInOut


# Bounce Easing

@docs bounceIn, bounceOut, bounceInOut


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



-- BASIC EASING FUNCTIONS


{-| Linear easing.
-}
linear : Easing
linear =
    Linear


{-| Standard ease (cubic-bezier(0.25, 0.1, 0.25, 1)).
-}
ease : Easing
ease =
    Ease


{-| Ease in (cubic-bezier(0.42, 0, 1, 1)).
-}
easeIn : Easing
easeIn =
    EaseIn


{-| Ease out (cubic-bezier(0, 0, 0.58, 1)).
-}
easeOut : Easing
easeOut =
    EaseOut


{-| Ease in-out (cubic-bezier(0.42, 0, 0.58, 1)).
-}
easeInOut : Easing
easeInOut =
    EaseInOut



-- SINE EASING


{-| Sine ease in.
-}
sineIn : Easing
sineIn =
    SineIn


{-| Sine ease out.
-}
sineOut : Easing
sineOut =
    SineOut


{-| Sine ease in-out.
-}
sineInOut : Easing
sineInOut =
    SineInOut



-- QUADRATIC EASING


{-| Quadratic ease in.
-}
quadIn : Easing
quadIn =
    QuadIn


{-| Quadratic ease out.
-}
quadOut : Easing
quadOut =
    QuadOut


{-| Quadratic ease in-out.
-}
quadInOut : Easing
quadInOut =
    QuadInOut



-- CUBIC EASING


{-| Cubic ease in.
-}
cubicIn : Easing
cubicIn =
    CubicIn


{-| Cubic ease out.
-}
cubicOut : Easing
cubicOut =
    CubicOut


{-| Cubic ease in-out.
-}
cubicInOut : Easing
cubicInOut =
    CubicInOut



-- QUARTIC EASING


{-| Quartic ease in.
-}
quartIn : Easing
quartIn =
    QuartIn


{-| Quartic ease out.
-}
quartOut : Easing
quartOut =
    QuartOut


{-| Quartic ease in-out.
-}
quartInOut : Easing
quartInOut =
    QuartInOut



-- QUINTIC EASING


{-| Quintic ease in.
-}
quintIn : Easing
quintIn =
    QuintIn


{-| Quintic ease out.
-}
quintOut : Easing
quintOut =
    QuintOut


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
toCSS : Maybe Easing -> String
toCSS maybeEasing =
    case maybeEasing of
        Just easing ->
            easingToCSS easing

        Nothing ->
            "ease"


easingToCSS : Easing -> String
easingToCSS easing =
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

        SineIn ->
            "cubic-bezier(0.12, 0, 0.39, 0)"

        SineOut ->
            "cubic-bezier(0.61, 1, 0.88, 1)"

        SineInOut ->
            "cubic-bezier(0.37, 0, 0.63, 1)"

        QuadIn ->
            "cubic-bezier(0.11, 0, 0.5, 0)"

        QuadOut ->
            "cubic-bezier(0.5, 1, 0.89, 1)"

        QuadInOut ->
            "cubic-bezier(0.45, 0, 0.55, 1)"

        CubicIn ->
            "cubic-bezier(0.32, 0, 0.67, 0)"

        CubicOut ->
            "cubic-bezier(0.33, 1, 0.68, 1)"

        CubicInOut ->
            "cubic-bezier(0.65, 0, 0.35, 1)"

        QuartIn ->
            "cubic-bezier(0.5, 0, 0.75, 0)"

        QuartOut ->
            "cubic-bezier(0.25, 1, 0.5, 1)"

        QuartInOut ->
            "cubic-bezier(0.76, 0, 0.24, 1)"

        QuintIn ->
            "cubic-bezier(0.64, 0, 0.78, 0)"

        QuintOut ->
            "cubic-bezier(0.22, 1, 0.36, 1)"

        QuintInOut ->
            "cubic-bezier(0.83, 0, 0.17, 1)"

        ExpoIn ->
            "cubic-bezier(0.7, 0, 0.84, 0)"

        ExpoOut ->
            "cubic-bezier(0.16, 1, 0.3, 1)"

        ExpoInOut ->
            "cubic-bezier(0.87, 0, 0.13, 1)"

        CircIn ->
            "cubic-bezier(0.55, 0, 1, 0.45)"

        CircOut ->
            "cubic-bezier(0, 0.55, 0.45, 1)"

        CircInOut ->
            "cubic-bezier(0.85, 0, 0.15, 1)"

        BackIn ->
            "cubic-bezier(0.36, 0, 0.66, -0.56)"

        BackOut ->
            "cubic-bezier(0.34, 1.56, 0.64, 1)"

        BackInOut ->
            "cubic-bezier(0.68, -0.6, 0.32, 1.6)"

        -- Note: Elastic and bounce are complex easing functions that require mathematical implementation
        -- These cubic-bezier approximations provide similar visual character for CSS compatibility
        ElasticIn ->
            "cubic-bezier(0.175, 0.885, 0.320, 1.275)"

        ElasticOut ->
            "cubic-bezier(0.680, -0.550, 0.265, 1.550)"

        ElasticInOut ->
            "cubic-bezier(0.680, -0.550, 0.265, 1.550)"

        BounceIn ->
            "cubic-bezier(0.600, 0.040, 0.980, 0.335)"

        BounceOut ->
            "cubic-bezier(0.175, 0.885, 0.320, 1.275)"

        BounceInOut ->
            "cubic-bezier(0.680, -0.550, 0.265, 1.550)"

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
        SineIn ->
            "cubic-bezier(0.12, 0, 0.39, 0)"

        SineOut ->
            "cubic-bezier(0.61, 1, 0.88, 1)"

        SineInOut ->
            "cubic-bezier(0.37, 0, 0.63, 1)"

        QuadIn ->
            "cubic-bezier(0.11, 0, 0.5, 0)"

        QuadOut ->
            "cubic-bezier(0.5, 1, 0.89, 1)"

        QuadInOut ->
            "cubic-bezier(0.45, 0, 0.55, 1)"

        CubicIn ->
            "cubic-bezier(0.32, 0, 0.67, 0)"

        CubicOut ->
            "cubic-bezier(0.67, 0, 0.32, 1)"

        CubicInOut ->
            "cubic-bezier(0.65, 0, 0.35, 1)"

        QuartIn ->
            "cubic-bezier(0.5, 0, 0.75, 0)"

        QuartOut ->
            "cubic-bezier(0.25, 1, 0.5, 1)"

        QuartInOut ->
            "cubic-bezier(0.76, 0, 0.24, 1)"

        QuintIn ->
            "cubic-bezier(0.64, 0, 0.78, 0)"

        QuintOut ->
            "cubic-bezier(0.22, 1, 0.36, 1)"

        QuintInOut ->
            "cubic-bezier(0.83, 0, 0.17, 1)"

        ExpoIn ->
            "cubic-bezier(0.7, 0, 0.84, 0)"

        ExpoOut ->
            "cubic-bezier(0.16, 1, 0.3, 1)"

        ExpoInOut ->
            "cubic-bezier(0.87, 0, 0.13, 1)"

        CircIn ->
            "cubic-bezier(0.55, 0, 1, 0.45)"

        CircOut ->
            "cubic-bezier(0, 0.55, 0.45, 1)"

        CircInOut ->
            "cubic-bezier(0.85, 0, 0.15, 1)"

        BackIn ->
            "cubic-bezier(0.36, 0, 0.66, -0.56)"

        BackOut ->
            "cubic-bezier(0.34, 1.56, 0.64, 1)"

        BackInOut ->
            "cubic-bezier(0.68, -0.6, 0.32, 1.6)"

        -- Web Animations API could potentially support these with keyframes
        -- For now, using cubic-bezier approximations that provide similar visual character
        ElasticIn ->
            "cubic-bezier(0.175, 0.885, 0.320, 1.275)"

        ElasticOut ->
            "cubic-bezier(0.680, -0.550, 0.265, 1.550)"

        ElasticInOut ->
            "cubic-bezier(0.680, -0.550, 0.265, 1.550)"

        BounceIn ->
            "cubic-bezier(0.600, 0.040, 0.980, 0.335)"

        BounceOut ->
            "cubic-bezier(0.175, 0.885, 0.320, 1.275)"

        BounceInOut ->
            "cubic-bezier(0.680, -0.550, 0.265, 1.550)"

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

        SineIn ->
            E.inSine

        SineOut ->
            E.outSine

        SineInOut ->
            E.inOutSine

        QuadIn ->
            E.inQuad

        QuadOut ->
            E.outQuad

        QuadInOut ->
            E.inOutQuad

        CubicIn ->
            E.inCubic

        CubicOut ->
            E.outCubic

        CubicInOut ->
            E.inOutCubic

        QuartIn ->
            E.inQuart

        QuartOut ->
            E.outQuart

        QuartInOut ->
            E.inOutQuart

        QuintIn ->
            E.inQuint

        QuintOut ->
            E.outQuint

        QuintInOut ->
            E.inOutQuint

        ExpoIn ->
            E.inExpo

        ExpoOut ->
            E.outExpo

        ExpoInOut ->
            E.inOutExpo

        CircIn ->
            E.inCirc

        CircOut ->
            E.outCirc

        CircInOut ->
            E.inOutCirc

        BackIn ->
            E.inBack

        BackOut ->
            E.outBack

        BackInOut ->
            E.inOutBack

        ElasticIn ->
            E.inElastic

        ElasticOut ->
            E.outElastic

        ElasticInOut ->
            E.inOutElastic

        BounceIn ->
            E.inBounce

        BounceOut ->
            E.outBounce

        BounceInOut ->
            E.inOutBounce

        Custom _ ->
            -- For custom CSS strings, fallback to ease-in-out
            E.inOutQuad



-- HELPER FUNCTIONS FOR MATHEMATICAL IMPLEMENTATIONS


{-| Encode easing for JSON serialization (used by Ports system).
-}
encode : Easing -> Encode.Value
encode easing =
    Encode.object
        [ ( "easing"
          , Encode.string <|
                toWebAnimations easing
          )
        ]
