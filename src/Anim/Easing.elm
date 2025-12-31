module Anim.Easing exposing
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
    , bezier
    , custom
    , toCSS, toWebAnimations, toFunction
    , encode
    , mapInternal
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


# Bezier Easing

@docs bezier


# Custom Easing

@docs custom


# Conversion Functions

@docs toCSS, toWebAnimations, toFunction


# Encoding

@docs encode


## Internal Mapping

You are unlikely to need this, it is used internally to map to the underlying easing functions.

@docs mapInternal

-}

import Anim.Internal.Timing.Easing as E
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


{-| Bezier easing function.
-}
bezier : Float -> Float -> Float -> Float -> Easing
bezier =
    Bezier



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
custom =
    Custom



-- ENCODING


{-| Encode easing for JSON serialization.
-}
encode : Easing -> Encode.Value
encode =
    mapInternal E.encode



-- CONVERSION FUNCTIONS


{-| Convert easing to CSS transition-timing-function value.
-}
toCSS : Easing -> String
toCSS =
    mapInternal (\e -> E.toCSS <| Just e)


{-| Convert easing to Web Animations API easing string.
-}
toWebAnimations : Easing -> String
toWebAnimations =
    mapInternal E.toWebAnimations


{-| Convert easing to a mathematical function for subscription-based animations.

This returns a function that takes a progress value from 0.0 to 1.0 and returns
the eased progress value.

-}
toFunction : Easing -> (Float -> Float)
toFunction =
    mapInternal E.toFunction


{-| Internal mapping function to convert Easing to underlying representation.
-}
mapInternal : (E.Easing -> a) -> Easing -> a
mapInternal fn =
    fn << toInternal


toInternal : Easing -> E.Easing
toInternal easing =
    case easing of
        Bezier p1x p1y p2x p2y ->
            E.Bezier p1x p1y p2x p2y

        Linear ->
            E.Linear

        Ease ->
            E.Ease

        EaseIn ->
            E.EaseIn

        EaseOut ->
            E.EaseOut

        EaseInOut ->
            E.EaseInOut

        SineIn ->
            E.SineIn

        SineOut ->
            E.SineOut

        SineInOut ->
            E.SineInOut

        QuadIn ->
            E.QuadIn

        QuadOut ->
            E.QuadOut

        QuadInOut ->
            E.QuadInOut

        CubicIn ->
            E.CubicIn

        CubicOut ->
            E.CubicOut

        CubicInOut ->
            E.CubicInOut

        QuartIn ->
            E.QuartIn

        QuartOut ->
            E.QuartOut

        QuartInOut ->
            E.QuartInOut

        QuintIn ->
            E.QuintIn

        QuintOut ->
            E.QuintOut

        QuintInOut ->
            E.QuintInOut

        ExpoIn ->
            E.ExpoIn

        ExpoOut ->
            E.ExpoOut

        ExpoInOut ->
            E.ExpoInOut

        CircIn ->
            E.CircIn

        CircOut ->
            E.CircOut

        CircInOut ->
            E.CircInOut

        BackIn ->
            E.BackIn

        BackOut ->
            E.BackOut

        BackInOut ->
            E.BackInOut

        ElasticIn ->
            E.ElasticIn

        ElasticOut ->
            E.ElasticOut

        ElasticInOut ->
            E.ElasticInOut

        BounceIn ->
            E.BounceIn

        BounceOut ->
            E.BounceOut

        BounceInOut ->
            E.BounceInOut

        Custom str ->
            E.Custom str
