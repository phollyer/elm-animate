module Anim.Internal.Properties.Size exposing
    ( Size
    , add
    , distance
    , duration
    , encode
    , fromTuple
    , h
    , interpolate
    , scale
    , speed
    , subtract
    , toCssString
    , toRecord
    , toString
    , toTuple
    , w
    )

import Anim.Internal.Timing.TimeSpec as TimeSpec exposing (TimeSpec(..))
import Json.Encode as Encode



{- UTILITY FUNCTIONS FOR THE PUBLIC Size TYPE, AND ITS API -}


type Size
    = Size { w : Float, h : Float }


w : Size -> Float
w (Size dimensions) =
    dimensions.w


h : Size -> Float
h (Size dimensions) =
    dimensions.h


fromTuple : ( Float, Float ) -> Size
fromTuple ( width, height ) =
    Size { w = width, h = height }


toTuple : Size -> ( Float, Float )
toTuple (Size dimensions) =
    ( dimensions.w, dimensions.h )


toRecord : Size -> { w : Float, h : Float }
toRecord (Size dimensions) =
    dimensions


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
speed distance_ duration_ timeSpec =
    case timeSpec of
        TimeSpec.Duration ms ->
            if ms == 0 then
                distance_ * duration_ * 1000

            else
                distance_ / (Basics.toFloat ms / 1000)

        TimeSpec.Speed unitsPerSecond ->
            unitsPerSecond


duration : Float -> TimeSpec -> Float
duration distance_ timeSpec =
    case timeSpec of
        TimeSpec.Duration ms ->
            Basics.toFloat ms

        TimeSpec.Speed unitsPerSecond ->
            distance_ / unitsPerSecond * 1000


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


encode : Size -> Encode.Value
encode size =
    let
        ( width, height ) =
            toTuple size
    in
    Encode.object
        [ ( "w", Encode.float width )
        , ( "h", Encode.float height )
        ]
