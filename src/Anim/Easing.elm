module Anim.Easing exposing (Easing(..))

{-| Easing's for animations.

**Note**: All engines produce accurate easing curves using the easing functions from [elm-community/ease](https://package.elm-lang.org/packages/elm-community/easing-functions/latest/Ease).
Cubic Bezier approximations are used in the [CSS Engine](Anim-Engine-CSS#easing) for transform animations, which is a CSS limitation. However, the CSS Engine does produce
accurate easing curves for keyframe animations.


# Easing Type

For complex easings like Back\*, Bounce\* and Elastic\*, there are multiple options:


## Standard Easings:

These use the easing functions from [elm-community/ease](https://package.elm-lang.org/packages/elm-community/easing-functions/latest/Ease).

  - `BackIn`, `BackOut`, `BackInOut`: Predefined back easings
  - `BounceIn`, `BounceOut`, `BounceInOut`: Predefined bounce easings
  - `ElasticIn`, `ElasticOut`, `ElasticInOut`: Predefined elastic easings


## Custom Easings:

These take a `Float` parameter to adjust the behavior.

  - `Back*Custom strength`: Adjust overshoot amount (0.1-3.0)
  - `Bounce*Custom strength`: Adjust bounce intensity (0.1-1.0)
  - `Elastic*Custom strength`: Adjust oscillation intensity (0.1-1.0)


## Advanced Easings:

These take a record with multiple parameters for full control.

  - `Back*Advanced { overshoot }`: Full control over overshoot behavior
  - `Bounce*Advanced { bounces, amplitude, decay }`:
      - `bounces`: Number of bounces (1-10)
          - Higher values = more bounces
          - Lower values = fewer bounces
      - `amplitude`: Initial bounce height (0.0-1.0)
          - Lower values = smaller bounces
          - Higher values = larger bounces
      - `decay`: Rate of bounce height reduction (0.0-1.0)
          - Lower values = slower decay (bounces stay larger longer)
          - Higher values = faster decay (bounces shrink quicker)
  - `Elastic*Advanced { frequency, amplitude, decay }`:
      - `frequency`: Number of oscillations (1.0-10.0)
          - Higher values = more oscillations
          - Lower values = fewer oscillations
      - `amplitude`: Initial oscillation height (0.0-1.0)
          - Lower values = smaller oscillations
          - Higher values = larger oscillations
      - `decay`: Rate of oscillation height reduction (0.0-1.0)
          - Lower values = slower decay (oscillations stay larger longer)
          - Higher values = faster decay (oscillations shrink quicker)

@docs Easing

-}

-- EASING TYPE


{-| Easing functions for animations.
-}
type Easing
    = BackIn
    | BackOut
    | BackInOut
    | BackInCustom Float
    | BackOutCustom Float
    | BackInOutCustom Float
    | BackInAdvanced { overshoot : Float }
    | BackOutAdvanced { overshoot : Float }
    | BackInOutAdvanced { overshoot : Float }
    | BounceIn
    | BounceOut
    | BounceInOut
    | BounceInCustom Float
    | BounceOutCustom Float
    | BounceInOutCustom Float
    | BounceInAdvanced { bounces : Int, amplitude : Float, decay : Float }
    | BounceOutAdvanced { bounces : Int, amplitude : Float, decay : Float }
    | BounceInOutAdvanced { bounces : Int, amplitude : Float, decay : Float }
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
    | ElasticInCustom Float
    | ElasticOutCustom Float
    | ElasticInOutCustom Float
    | ElasticInAdvanced { frequency : Float, amplitude : Float, decay : Float }
    | ElasticOutAdvanced { frequency : Float, amplitude : Float, decay : Float }
    | ElasticInOutAdvanced { frequency : Float, amplitude : Float, decay : Float }
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
