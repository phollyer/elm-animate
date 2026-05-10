module Easing exposing (Easing(..))

{-| Easing functions for animations and scrolls.

Use them to create smooth and natural movement.

If you don't set an easing function, the defaults are:

  - Animations: `EaseInOut`, which is a good general-purpose easing.
  - Scrolls: `QuintOut`, which gives a nice smooth scroll effect, with a natural "settling into place" feel.

📖 See [Easing Documentation](https://phollyer.github.io/elm-motion/animation/concepts/easing/) in the docs for more info.


# Easing Type

@docs Easing

-}


{-| -}
type Easing
    = BackIn
    | BackOut
    | BackInOut
    | BackInCustom Float
    | BackOutCustom Float
    | BackInOutCustom ( Float, Float )
    | BounceIn
    | BounceOut
    | BounceInOut
    | CircIn
    | CircOut
    | CircInOut
    | CubicBezier Float Float Float Float
    | CubicIn
    | CubicOut
    | CubicInOut
    | Ease
    | EaseIn
    | EaseOut
    | EaseInOut
    | ElasticIn
    | ElasticOut
    | ElasticInOut
    | ExpoIn
    | ExpoOut
    | ExpoInOut
    | Linear
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
