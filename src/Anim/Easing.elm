module Anim.Easing exposing (Easing(..))

{-|


# Easing Type


## Standard Easings:

These use the easing functions from [elm-community/ease](https://package.elm-lang.org/packages/elm-community/easing-functions/latest/Ease).

For complex easings like Back, Bounce, and Elastic, there are also Custom and Advanced versions available.


## Custom Easings:

If the standard complex easings don't fit your needs, you can use the custom versions.
Each one takes a `Float` parameter to adjust the behavior.

  - `Back*Custom strength`: Adjust overshoot amount
  - `Bounce*Custom strength`: Adjust bounce intensity
  - `Elastic*Custom strength`: Adjust oscillation intensity


## Advanced Easings:

If the standard and custom complex easings are not sufficient, you can use the advanced versions.
Each one takes a record with multiple parameters for more control.

  - `Back*Advanced { overshoot }`: Full control over overshoot behavior
  - `Bounce*Advanced { bounces, amplitude, decay }`:
      - `bounces : Int`: Number of bounces
          - Higher values = more bounces
          - Lower values = fewer bounces
      - `amplitude : Float`: Initial bounce height
          - Lower values = smaller bounces
          - Higher values = larger bounces
      - `decay : Float`: Rate of bounce height reduction
          - Lower values = slower decay (bounces stay larger longer)
          - Higher values = faster decay (bounces shrink quicker)
  - `Elastic*Advanced { elasticity, amplitude, decay }`:
      - `elasticity : Float`: Affects the number of oscillations
          - Higher values = more oscillations
          - Lower values = fewer oscillations
      - `amplitude : Float`: Affects the oscillation height
          - Lower values = smaller oscillations
          - Higher values = larger oscillations
      - `decay : Float`: Affects the rate of oscillation height reduction
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
    | BackInOutCustom ( Float, Float )
    | BackInAdvanced { overshoot : Float }
    | BackOutAdvanced { overshoot : Float }
    | BackInOutAdvanced { in_ : { overshoot : Float }, out : { overshoot : Float } }
    | BounceIn
    | BounceOut
    | BounceInOut
    | BounceInCustom Float
    | BounceOutCustom Float
    | BounceInOutCustom ( Float, Float )
    | BounceInAdvanced { bounces : Int, amplitude : Float, decay : Float }
    | BounceOutAdvanced { bounces : Int, amplitude : Float, decay : Float }
    | BounceInOutAdvanced { in_ : { bounces : Int, amplitude : Float, decay : Float }, out : { bounces : Int, amplitude : Float, decay : Float } }
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
    | ElasticInOutCustom ( Float, Float )
    | ElasticInAdvanced { elasticity : Float, amplitude : Float, decay : Float }
    | ElasticOutAdvanced { elasticity : Float, amplitude : Float, decay : Float }
    | ElasticInOutAdvanced { in_ : { elasticity : Float, amplitude : Float, decay : Float }, out : { elasticity : Float, amplitude : Float, decay : Float } }
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
