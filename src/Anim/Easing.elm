module Anim.Easing exposing (Easing(..))

{-| Easing's for animations.

**Note**: If accurate physics-based easing is required (like bounce or elastic), you need to consider your Engine choice.

  - **CSS Engine**:
      - **Transforms**: Uses approximations via cubic-bezier curves - this is a CSS limitation.
      - **Keyframe Animations**: Accurate easing curves using the functions from the [Elm-Community/Ease](https://package.elm-lang.org/packages/elm-community/ease/latest/) package.


# Easing Type

@docs Easing

-}

-- EASING TYPE


{-| Easing functions for animations.

Use the constructors directly:

    -- Linear easing
    Position.easing Linear

    -- Ease in-out
    Opacity.easing EaseInOut

    -- Custom bezier curve
    Scale.easing (Bezier 0.68 -0.55 0.265 1.55)

    -- Bounce effect
    Position.easing BounceOut

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
