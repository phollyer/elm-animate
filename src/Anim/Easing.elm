module Anim.Easing exposing (Easing(..))

{-| Easing's for animations.

**Note**: All engines produce accurate easing curves using the easing functions from [elm-community/ease](https://package.elm-lang.org/packages/elm-community/easing-functions/latest/Ease).
Cubic Bezier approximations are used in the [CSS Engine](Anim-Engine-CSS#easing) for transform animations, which is a CSS limitation. However, the CSS Engine does produce
accurate easing curves for keyframe animations.


# Easing Type

@docs Easing

-}

-- EASING TYPE


{-| Easing functions for animations.
-}
type Easing
    = Bezier Float Float Float Float
    | Linear
    | BackIn
    | BackOut
    | BackInOut
    | BounceIn
    | BounceOut
    | BounceInOut
    | CircIn
    | CircOut
    | CircInOut
    | CubicIn
    | CubicOut
    | CubicInOut
    | Custom String
    | Ease
    | EaseIn
    | EaseInOut
    | EaseOut
    | ElasticIn
    | ElasticOut
    | ElasticInOut
    | ExpoIn
    | ExpoOut
    | ExpoInOut
    | QuadIn
    | QuadOut
    | QuadInOut
    | QuartIn
    | QuartOut
    | QuartInOut
    | QuintIn
    | QuintOut
    | QuintInOut
    | SineIn
    | SineOut
    | SineInOut
