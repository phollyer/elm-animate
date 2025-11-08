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



-- The rest of the module content (type Easing, all functions, etc.) should be appended here from the previously validated, working version.
{-| Quadratic ease out.

{-| Unified easing system for all Anim animation types.-}

easeOutQuad : Easing

This module provides a serializable easing type that works across CSS transitions,easeOutQuad =

Web Animations API via ports, and subscription-based animations.    EaseOutQuad





# Easing Type{-| Quadratic ease in-out.

-}

@docs EasingeaseInOutQuad : Easing

easeInOutQuad =

    EaseInOutQuad

# Basic Easing Functions



@docs linear, ease, easeIn, easeOut, easeInOut

-- CUBIC EASING



# Sine Easing

{-| Cubic ease in.

@docs easeInSine, easeOutSine, easeInOutSine-}

easeInCubic : Easing

easeInCubic =

# Quadratic Easing    EaseInCubic



@docs easeInQuad, easeOutQuad, easeInOutQuad

{-| Cubic ease out.

-}

# Cubic EasingeaseOutCubic : Easing

easeOutCubic =

@docs easeInCubic, easeOutCubic, easeInOutCubic    EaseOutCubic





# Quartic Easing{-| Cubic ease in-out.

-}

@docs easeInQuart, easeOutQuart, easeInOutQuarteaseInOutCubic : Easing

easeInOutCubic =

    EaseInOutCubic

# Quintic Easing



@docs easeInQuint, easeOutQuint, easeInOutQuint

-- QUARTIC EASING



# Exponential Easing

{-| Quartic ease in.

@docs easeInExpo, easeOutExpo, easeInOutExpo-}

easeInQuart : Easing

easeInQuart =

# Circular Easing    EaseInQuart



@docs easeInCirc, easeOutCirc, easeInOutCirc

{-| Quartic ease out.

-}

# Back EasingeaseOutQuart : Easing

easeOutQuart =

@docs easeInBack, easeOutBack, easeInOutBack    EaseOutQuart





# Elastic Easing{-| Quartic ease in-out.

-}

@docs easeInElastic, easeOutElastic, easeInOutElasticeaseInOutQuart : Easing

easeInOutQuart =

    EaseInOutQuart

# Bounce Easing



@docs easeInBounce, easeOutBounce, easeInOutBounce

-- QUINTIC EASING



# Custom Easing

{-| Quintic ease in.

@docs custom-}

easeInQuint : Easing

easeInQuint =

# Conversion Functions    EaseInQuint



@docs toCSS, toWebAnimations, toFunction, encode

{-| Quintic ease out.

-}-}

easeOutQuint : Easing

import Ease as EeaseOutQuint =

import Json.Encode as Encode    EaseOutQuint



{-| Quintic ease in-out.
-}
easeInOutQuint : Easing
easeInOutQuint =
    EaseInOutQuint



-- EXPONENTIAL EASING


{-| Exponential ease in.
-}
easeInExpo : Easing
easeInExpo =
    EaseInExpo


{-| Exponential ease out.
-}
easeOutExpo : Easing
easeOutExpo =
    EaseOutExpo


{-| Exponential ease in-out.
-}
easeInOutExpo : Easing
easeInOutExpo =
    EaseInOutExpo



-- CIRCULAR EASING


{-| Circular ease in.
-}
easeInCirc : Easing
easeInCirc =
    EaseInCirc


{-| Circular ease out.
-}
easeOutCirc : Easing
easeOutCirc =
    EaseOutCirc


{-| Circular ease in-out.
-}
easeInOutCirc : Easing
easeInOutCirc =
    EaseInOutCirc



-- BACK EASING


{-| Back ease in (overshoot at start).
-}
easeInBack : Easing
easeInBack =
    EaseInBack


{-| Back ease out (overshoot at end).
-}
easeOutBack : Easing
easeOutBack =
    EaseOutBack


{-| Back ease in-out (overshoot at both ends).
-}
easeInOutBack : Easing
easeInOutBack =
    EaseInOutBack



-- ELASTIC EASING


{-| Elastic ease in.
-}
easeInElastic : Easing
easeInElastic =
    EaseInElastic


{-| Elastic ease out.
-}
easeOutElastic : Easing
easeOutElastic =
    EaseOutElastic


{-| Elastic ease in-out.
-}
easeInOutElastic : Easing
easeInOutElastic =
    EaseInOutElastic



-- BOUNCE EASING


{-| Bounce ease in.
-}
easeInBounce : Easing
easeInBounce =
    EaseInBounce


{-| Bounce ease out.
-}
easeOutBounce : Easing
easeOutBounce =
    EaseOutBounce


{-| Bounce ease in-out.
-}
easeInOutBounce : Easing
easeInOutBounce =
    EaseInOutBounce



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
        -- These are approximations - for true elastic/bounce, use Web Animations API
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


easeInFunction : Float -> Float
easeInFunction t =
    t * t


easeOutFunction : Float -> Float
easeOutFunction t =
    1 - (1 - t) * (1 - t)


easeInOutFunction : Float -> Float
easeInOutFunction t =
    E.inOutQuad t


backIn : Float -> Float
backIn t =
    let
        c1 =
            1.70158

        c3 =
            c1 + 1
    in
    c3 * t * t * t - c1 * t * t


backOut : Float -> Float
backOut t =
    let
        c1 =
            1.70158

        c3 =
            c1 + 1
    in
    1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2


backInOut : Float -> Float
backInOut t =
    let
        c1 =
            1.70158

        c2 =
            c1 * 1.525
    in
    if t < 0.5 then
        ((2 * t) ^ 2 * ((c2 + 1) * 2 * t - c2)) / 2

    else
        ((2 * t - 2) ^ 2 * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2


elasticIn : Float -> Float
elasticIn t =
    let
        c4 =
            (2 * pi) / 3
    in
    if t == 0 then
        0

    else if t == 1 then
        1

    else
        -(2 ^ (10 * (t - 1))) * sin ((t - 1) * c4)


elasticOut : Float -> Float
elasticOut t =
    let
        c4 =
            (2 * pi) / 3
    in
    if t == 0 then
        0

    else if t == 1 then
        1

    else
        2 ^ (-10 * t) * sin (t * c4) + 1


elasticInOut : Float -> Float
elasticInOut t =
    let
        c5 =
            (2 * pi) / 4.5
    in
    if t == 0 then
        0

    else if t == 1 then
        1

    else if t < 0.5 then
        -(2 ^ (20 * t - 10) * sin ((20 * t - 11.125) * c5)) / 2

    else
        (2 ^ (-20 * t + 10) * sin ((20 * t - 11.125) * c5)) / 2 + 1


bounceOut : Float -> Float
bounceOut t =
    let
        n1 =
            7.5625

        d1 =
            2.75
    in
    if t < 1 / d1 then
        n1 * t * t

    else if t < 2 / d1 then
        n1 * (t - 1.5 / d1) * (t - 1.5 / d1) + 0.75

    else if t < 2.5 / d1 then
        n1 * (t - 2.25 / d1) * (t - 2.25 / d1) + 0.9375

    else
        n1 * (t - 2.625 / d1) * (t - 2.625 / d1) + 0.984375


bounceIn : Float -> Float
bounceIn t =
    1 - bounceOut (1 - t)


bounceInOut : Float -> Float
bounceInOut t =
    if t < 0.5 then
        (1 - bounceOut (1 - 2 * t)) / 2

    else
        (1 + bounceOut (2 * t - 1)) / 2


{-| Encode easing for JSON serialization (used by Ports system).
-}
encode : Easing -> Encode.Value
encode easing =
    case easing of
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
