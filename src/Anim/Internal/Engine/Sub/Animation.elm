module Anim.Internal.Engine.Sub.Animation exposing
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
import Anim.Internal.Property.Opacity exposing (Opacity)
import Anim.Internal.Property.PerspectiveOrigin exposing (PerspectiveOrigin)
import Anim.Internal.Property.Rotate exposing (Rotate)
import Anim.Internal.Property.Scale exposing (Scale)
import Anim.Internal.Property.Size exposing (Size)
import Anim.Internal.Property.Skew exposing (Skew)
import Anim.Internal.Property.Translate exposing (Translate)



-- ============================================================
-- TYPES
-- ============================================================


type Animation
    = CustomProperty String String (PropertyAnimation Float)
    | CustomColorProperty String (PropertyAnimation Color)
    | Opacity (PropertyAnimation Opacity)
    | PerspectiveOrigin (PropertyAnimation PerspectiveOrigin)
    | Rotate (PropertyAnimation Rotate)
    | Scale (PropertyAnimation Scale)
    | Size (PropertyAnimation Size)
    | Skew (PropertyAnimation Skew)
    | Translate (PropertyAnimation Translate)


type alias PropertyAnimation property =
    { start : property
    , end : property
    , easingFunction : Float -> Float
    , delayMs : Float
    , isComplete : Bool
    , totalDurationMs : Float
    , elapsedMs : Float
    }



-- ============================================================
-- QUERIES
-- ============================================================


toPropertyKey : Animation -> String
toPropertyKey prop =
    case prop of
        Translate _ ->
            "translate"

        Rotate _ ->
            "rotate"

        Skew _ ->
            "skew"

        Scale _ ->
            "scale"

        Opacity _ ->
            "opacity"

        PerspectiveOrigin _ ->
            "perspectiveOrigin"

        Size _ ->
            "size"

        CustomProperty cssName _ _ ->
            "custom:" ++ cssName

        CustomColorProperty cssName _ ->
            "customColor:" ++ cssName



-- ============================================================
-- TIMING
-- ============================================================


type alias Timing =
    { elapsedMs : Float
    , isComplete : Bool
    , totalDurationMs : Float
    , delayMs : Float
    }



-- ============================================================
-- MODIFY
-- ============================================================


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

        Skew a ->
            Skew (swap a)

        Scale a ->
            Scale (swap a)

        Opacity a ->
            Opacity (swap a)

        PerspectiveOrigin a ->
            PerspectiveOrigin (swap a)

        Size a ->
            Size (swap a)

        CustomProperty cssName unit a ->
            CustomProperty cssName unit (swap a)

        CustomColorProperty cssName a ->
            CustomColorProperty cssName (swap a)


stop : Animation -> Animation
stop =
    mapTiming
        (\t ->
            { t
                | isComplete = True
                , elapsedMs = t.totalDurationMs + t.delayMs
            }
        )



-- ============================================================
-- HELPERS
-- ============================================================


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

        Skew a ->
            Skew (apply a)

        Scale a ->
            Scale (apply a)

        Opacity a ->
            Opacity (apply a)

        PerspectiveOrigin a ->
            PerspectiveOrigin (apply a)

        Size a ->
            Size (apply a)

        CustomProperty cssName unit a ->
            CustomProperty cssName unit (apply a)

        CustomColorProperty cssName a ->
            CustomColorProperty cssName (apply a)


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
        CustomProperty _ _ a ->
            f (toTiming a)

        CustomColorProperty _ a ->
            f (toTiming a)

        Opacity a ->
            f (toTiming a)

        PerspectiveOrigin a ->
            f (toTiming a)

        Rotate a ->
            f (toTiming a)

        Scale a ->
            f (toTiming a)

        Size a ->
            f (toTiming a)

        Skew a ->
            f (toTiming a)

        Translate a ->
            f (toTiming a)
