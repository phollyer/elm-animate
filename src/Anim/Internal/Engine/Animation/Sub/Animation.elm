module Anim.Internal.Engine.Animation.Sub.Animation exposing
    ( Animation(..)
    , PropertyAnimation
    , Timing
    , foldTiming
    , mapTiming
    , reset
    , reverse
    , stop
    , toPropertyKey
    )

import Anim.Internal.Builder exposing (Iterations(..))
import Anim.Internal.Extra.Color exposing (Color)
import Anim.Internal.PropertyBuilder.Opacity exposing (Opacity)
import Anim.Internal.PropertyBuilder.Rotate exposing (Rotate)
import Anim.Internal.PropertyBuilder.Scale exposing (Scale)
import Anim.Internal.PropertyBuilder.Size exposing (Size)
import Anim.Internal.PropertyBuilder.Translate exposing (Translate)


type Animation
    = Translate (PropertyAnimation Translate)
    | Rotate (PropertyAnimation Rotate)
    | Scale (PropertyAnimation Scale)
    | BackgroundColor (PropertyAnimation Color)
    | FontColor (PropertyAnimation Color)
    | Opacity (PropertyAnimation Opacity)
    | Size (PropertyAnimation Size)


type alias PropertyAnimation property =
    { start : property
    , end : property
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


type alias Timing =
    { elapsedMs : Float
    , isComplete : Bool
    , totalDurationMs : Float
    , delayMs : Float
    }


reset : Animation -> Animation
reset =
    mapTiming
        (\t ->
            { t
                | isComplete = False
                , elapsedMs = 0
            }
        )


reverse : Animation -> Animation
reverse anim =
    let
        swap a =
            { a | start = a.end, end = a.start }
    in
    case anim of
        Translate a ->
            Translate (swap a)

        Rotate a ->
            Rotate (swap a)

        Scale a ->
            Scale (swap a)

        BackgroundColor a ->
            BackgroundColor (swap a)

        FontColor a ->
            FontColor (swap a)

        Opacity a ->
            Opacity (swap a)

        Size a ->
            Size (swap a)


stop : Animation -> Animation
stop =
    mapTiming
        (\t ->
            { t
                | isComplete = True
                , elapsedMs = t.totalDurationMs + t.delayMs
            }
        )


toTiming : PropertyAnimation a -> Timing
toTiming anim =
    { elapsedMs = anim.elapsedMs
    , isComplete = anim.isComplete
    , totalDurationMs = anim.totalDurationMs
    , delayMs = anim.delayMs
    }


mapTiming : (Timing -> Timing) -> Animation -> Animation
mapTiming f anim =
    let
        apply a =
            applyTiming (f (toTiming a)) a
    in
    case anim of
        Translate a ->
            Translate (apply a)

        Rotate a ->
            Rotate (apply a)

        Scale a ->
            Scale (apply a)

        BackgroundColor a ->
            BackgroundColor (apply a)

        FontColor a ->
            FontColor (apply a)

        Opacity a ->
            Opacity (apply a)

        Size a ->
            Size (apply a)


applyTiming : Timing -> PropertyAnimation a -> PropertyAnimation a
applyTiming timing anim =
    { anim
        | elapsedMs = timing.elapsedMs
        , isComplete = timing.isComplete
        , totalDurationMs = timing.totalDurationMs
        , delayMs = timing.delayMs
    }


foldTiming : (Timing -> b) -> Animation -> b
foldTiming f anim =
    case anim of
        Translate a ->
            f (toTiming a)

        Rotate a ->
            f (toTiming a)

        Scale a ->
            f (toTiming a)

        BackgroundColor a ->
            f (toTiming a)

        FontColor a ->
            f (toTiming a)

        Opacity a ->
            f (toTiming a)

        Size a ->
            f (toTiming a)
