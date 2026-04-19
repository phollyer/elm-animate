module Anim.Internal.PropertyBuilder.Size exposing
    ( Size
    , add
    , default
    , distance
    , duration
    , fromRecord
    , fromTuple
    , h
    , heightToCssString
    , interpolate
    , scale
    , speed
    , subtract
    , toCssString
    , toRecord
    , toString
    , toTuple
    , w
    , widthToCssString
    )

import Anim.Internal.Timing.TimeSpec as TimeSpec exposing (TimeSpec)



-- ============================================================
-- TYPES
-- ============================================================


type Size
    = Size { w : Float, h : Float }


default : Size
default =
    Size { w = 0, h = 0 }



-- ============================================================
-- CONSTRUCTORS
-- ============================================================


w : Size -> Float
w (Size dimensions) =
    dimensions.w


h : Size -> Float
h (Size dimensions) =
    dimensions.h


fromRecord : { width : Float, height : Float } -> Size
fromRecord record =
    Size { w = record.width, h = record.height }


fromTuple : ( Float, Float ) -> Size
fromTuple ( width, height ) =
    Size { w = width, h = height }


toTuple : Size -> ( Float, Float )
toTuple (Size dimensions) =
    ( dimensions.w, dimensions.h )


toRecord : Size -> { width : Float, height : Float }
toRecord (Size dimensions) =
    { width = dimensions.w, height = dimensions.h }



-- ============================================================
-- CONVERSIONS
-- ============================================================


toString : Size -> String
toString size =
    let
        ( width, height ) =
            toTuple size
    in
    "(" ++ String.fromFloat width ++ ", " ++ String.fromFloat height ++ ")"


toCssString : Size -> String
toCssString size =
    let
        ( width, height ) =
            toTuple size
    in
    "width: " ++ String.fromFloat width ++ "px; height: " ++ String.fromFloat height ++ "px"


widthToCssString : Size -> String
widthToCssString (Size dimensions) =
    String.fromFloat dimensions.w ++ "px"


heightToCssString : Size -> String
heightToCssString (Size dimensions) =
    String.fromFloat dimensions.h ++ "px"



-- ============================================================
-- MATH
-- ============================================================


distance : Size -> Size -> Float
distance (Size start) (Size end) =
    let
        dw =
            end.w - start.w

        dh =
            end.h - start.h
    in
    sqrt (dw * dw + dh * dh)


speed : Float -> Float -> TimeSpec -> Float
speed =
    TimeSpec.speed


duration : Float -> TimeSpec -> Float
duration =
    TimeSpec.duration


interpolate : Float -> Size -> Size -> Size
interpolate t (Size start) (Size endSize) =
    Size
        { w = start.w + (endSize.w - start.w) * t
        , h = start.h + (endSize.h - start.h) * t
        }


add : Size -> Size -> Size
add (Size a) (Size b) =
    Size { w = a.w + b.w, h = a.h + b.h }


subtract : Size -> Size -> Size
subtract (Size a) (Size b) =
    Size { w = a.w - b.w, h = a.h - b.h }


scale : Float -> Size -> Size
scale factor (Size dimensions) =
    Size { w = dimensions.w * factor, h = dimensions.h * factor }
