module Anim.Internal.Engine.Animation.Sub.Animation exposing (..)

import Anim.Internal.Builder exposing (Iterations(..))
import Anim.Internal.Extra.Color exposing (Color)
import Anim.Internal.Property.Opacity exposing (Opacity)
import Anim.Internal.Property.Rotate exposing (Rotate)
import Anim.Internal.Property.Scale exposing (Scale)
import Anim.Internal.Property.Size exposing (Size)
import Anim.Internal.Property.Translate exposing (Translate)


type Animation
    = Translate (PropertyAnimation Translate)
    | Rotate (PropertyAnimation Rotate)
    | Scale (PropertyAnimation Scale)
    | BackgroundColor (PropertyAnimation Color)
    | FontColor (PropertyAnimation Color)
    | Opacity (PropertyAnimation Opacity)
    | Size (PropertyAnimation Size)


type alias PropertyAnimation property =
    { startValue : property
    , endValue : property
    , easingFunction : Float -> Float
    , delayMs : Float
    , isComplete : Bool
    , totalDurationMs : Float
    , elapsedMs : Float
    }


toPropertyKey : Animation -> String
toPropertyKey prop =
    case prop of
        Translate _ ->
            "translate"

        Rotate _ ->
            "rotate"

        Scale _ ->
            "scale"

        BackgroundColor _ ->
            "backgroundColor"

        FontColor _ ->
            "fontColor"

        Opacity _ ->
            "opacity"

        Size _ ->
            "size"
