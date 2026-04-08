module Anim.Internal.Engine.Animation.Sub.AnimGroup exposing
    ( AnimGroup
    , Animation(..)
    , PropertyAnimation
    , init
    )

import Anim.Extra.TransformOrder as TransformOrder exposing (TransformOrder)
import Anim.Internal.Builder exposing (Iterations(..))
import Anim.Internal.Extra.Color exposing (Color(..))
import Anim.Internal.Property.Opacity exposing (Opacity)
import Anim.Internal.Property.Rotate exposing (Rotate)
import Anim.Internal.Property.Scale exposing (Scale)
import Anim.Internal.Property.Size exposing (Size)
import Anim.Internal.Property.Translate exposing (Translate)


type alias AnimGroup =
    { properties : List PropertyAnimation
    , isComplete : Bool
    , isPaused : Bool
    , transformOrder : List TransformOrder
    , iterationCount : Iterations
    , currentIteration : Int
    }


init : AnimGroup
init =
    { properties = []
    , isComplete = False
    , isPaused = False
    , transformOrder = TransformOrder.default
    , iterationCount = Once
    , currentIteration = 0
    }


type alias PropertyAnimation =
    { propertyType : String
    , startValue : Animation
    , endValue : Animation
    , easingFunction : Float -> Float
    , delayMs : Float
    , isComplete : Bool
    , totalDurationMs : Float
    , elapsedMs : Float
    }


type Animation
    = TranslateAnimation Translate
    | RotateAnimation Rotate
    | ScaleAnimation Scale
    | BackgroundColorAnimation Color
    | FontColorAnimation Color
    | OpacityAnimation Opacity
    | SizeAnimation Size
