module Anim.Easing exposing (Easing(..))

{-| Easing functions for animations.


## Standard Easings

  - `BackIn`, `BackOut`, `BackInOut`
  - `BounceIn`, `BounceOut`, `BounceInOut`
  - `CircIn`, `CircOut`, `CircInOut`
  - `CubicBezier x1 y1 x2 y2`
  - `CubicIn`, `CubicOut`, `CubicInOut`
  - `Ease`, `EaseIn`, `EaseOut`, `EaseInOut`
  - `ElasticIn`, `ElasticOut`, `ElasticInOut`
  - `ExpoIn`, `ExpoOut`, `ExpoInOut`
  - `Linear`
  - `QuadIn`, `QuadOut`, `QuadInOut`
  - `QuartIn`, `QuartOut`, `QuartInOut`
  - `QuintIn`, `QuintOut`, `QuintInOut`
  - `SineIn`, `SineOut`, `SineInOut`

These all use the easing functions from [elm-community/ease](https://package.elm-lang.org/packages/elm-community/easing-functions/latest/Ease).


## Custom Easings

  - `BackInCustom`, `BackOutCustom`, `BackInOutCustom`
  - `BounceInCustom`, `BounceOutCustom`, `BounceInOutCustom`
  - `ElasticInCustom`, `ElasticOutCustom`, `ElasticInOutCustom`

These are variations of the standard complex easings that allow you to customize their behavior.

**Note**: These easings are generated such that the transition time (from A -> B) matches the specified animation duration. Any oscillations or bounces
are calculated based on `strength` and velocity (from A -> B) and then either prepended or appended to the transition phase as appropriate.
This provides a smoother and more natural effect than squashing all oscillations or bounces, along with the transition, into the animation duration.


### Back\*Custom

`BackInCustom` & `BackOutCustom` both take a single `strength : Float` parameter that adjusts the overshoot amount.
Higher values result in more overshoot, while lower values result in less overshoot.

`BackInOutCustom` takes a tuple `(inStrength : Float, outStrength : Float)` to adjust overshoot for both phases independently.


### Bounce\*Custom

`BounceInCustom` & `BounceOutCustom` both take a single `strength : Float` parameter that adjusts the bounce intensity.
Higher values result in more intense bounces, while lower values result in gentler bounces.

`BounceInOutCustom` takes a tuple `(inStrength : Float, outStrength : Float)` to adjust bounce intensity for both phases independently.


### Elastic\*Custom

`ElasticInCustom` & `ElasticOutCustom` both take a single `strength : Float` parameter that adjusts the oscillation intensity.
Higher values result in more intense oscillations, while lower values result in gentler oscillations.

`ElasticInOutCustom` takes a tuple `(inStrength : Float, outStrength : Float)` to adjust oscillation intensity for both phases independently.


## Advanced Easings

  - `BounceInAdvanced`, `BounceOutAdvanced`, `BounceInOutAdvanced`
  - `ElasticInAdvanced`, `ElasticOutAdvanced`, `ElasticInOutAdvanced`

These are further variations of the standard complex easings that provide more granular control.
Each one takes a record with multiple fields.

**Note**: These easings are generated such that the transition time (from A -> B) matches the specified animation duration. Any oscillations or bounces
are calculated based on the provided parameters and velocity (from A -> B) and then either prepended or appended to the transition phase as appropriate.
This provides a smoother and more natural effect than squashing all oscillations or bounces, along with the transition, into the animation duration.


### Bounce\*Advanced

`BounceInAdvanced` & `BounceOutAdvanced` both take a record with three fields:

  - `bounces : Int`: Number of bounces
  - `amplitude : Float`: Bounce intensity
      - Lower values = smaller bounces
      - Higher values = larger bounces
  - `decay : Float`: Rate of bounce height reduction
      - Lower values = slower decay (bounces stay larger longer)
      - Higher values = faster decay (bounces shrink quicker)

`BounceInOutAdvanced` takes a record with two fields:

  - `in_ : { bounces, amplitude, decay }`: Parameters for the "in" phase
  - `out : { bounces, amplitude, decay }`: Parameters for the "out" phase


### Elastic\*Advanced

`ElasticInAdvanced`, `ElasticOutAdvanced` both take a record with three fields:

  - `elasticity : Float`: Controls the springiness of the oscillation
      - Lower values = stiffer spring (less oscillation)
      - Higher values = more elastic spring (more oscillation)
  - `amplitude : Float`: Oscillation intensity
      - Lower values = smaller oscillations
      - Higher values = larger oscillations
  - `decay : Float`: Rate of oscillation height reduction
      - Lower values = slower decay (oscillations stay larger longer)
      - Higher values = faster decay (oscillations shrink quicker)

`ElasticInOutAdvanced` takes a record with two fields:

  - `in_ : { elasticity, amplitude, decay }`: Parameters for the "in" phase
  - `out : { elasticity, amplitude, decay }`: Parameters for the "out" phase


# Easing Type

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
