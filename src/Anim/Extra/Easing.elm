module Anim.Extra.Easing exposing (Easing(..))

{-| Easing functions for animations.

Use them to create smooth and natural animations.


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
