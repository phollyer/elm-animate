module Anim.Internal.Property.Skew exposing
    ( Skew
    , default
    , distance
    , duration
    , fromRecord
    , fromTuple
    , getX
    , getY
    , interpolate
    , speed
    , toCssString
    , toRecord
    , toString
    , toTuple
    )

import Shared.TimeSpec as TimeSpec exposing (TimeSpec)



-- ============================================================
-- TYPES
-- ============================================================


type Skew
    = Skew { x : Float, y : Float }


default : Skew
default =
    Skew { x = 0, y = 0 }



-- ============================================================
-- CONSTRUCTORS
-- ============================================================


getX : Skew -> Float
getX (Skew values) =
    values.x


getY : Skew -> Float
getY (Skew values) =
    values.y


fromRecord : { x : Float, y : Float } -> Skew
fromRecord record =
    Skew { x = record.x, y = record.y }


fromTuple : ( Float, Float ) -> Skew
fromTuple ( x, y ) =
    Skew { x = x, y = y }


toTuple : Skew -> ( Float, Float )
toTuple (Skew values) =
    ( values.x, values.y )


toRecord : Skew -> { x : Float, y : Float }
toRecord (Skew values) =
    { x = values.x, y = values.y }



-- ============================================================
-- CONVERSIONS
-- ============================================================


toString : Skew -> String
toString skew =
    let
        ( x, y ) =
            toTuple skew
    in
    "Skew(x: " ++ String.fromFloat x ++ ", y: " ++ String.fromFloat y ++ ")"


toCssString : Skew -> String
toCssString (Skew values) =
    let
        parts =
            [ if values.x /= 0 then
                Just ("skewX(" ++ String.fromFloat values.x ++ "deg)")

              else
                Nothing
            , if values.y /= 0 then
                Just ("skewY(" ++ String.fromFloat values.y ++ "deg)")

              else
                Nothing
            ]
                |> List.filterMap identity
    in
    case parts of
        [] ->
            "skew(0deg, 0deg)"

        [ single ] ->
            single

        multiple ->
            String.join " " multiple



-- ============================================================
-- MATH
-- ============================================================


distance : Skew -> Skew -> Float
distance start end =
    let
        ( startX, startY ) =
            toTuple start

        ( endX, endY ) =
            toTuple end

        dx =
            endX - startX

        dy =
            endY - startY
    in
    sqrt (dx * dx + dy * dy)


speed : Float -> Float -> TimeSpec -> Float
speed =
    TimeSpec.speed


duration : Float -> TimeSpec -> Float
duration =
    TimeSpec.duration


interpolate : Float -> Skew -> Skew -> Skew
interpolate t start end =
    let
        ( startX, startY ) =
            toTuple start

        ( endX, endY ) =
            toTuple end
    in
    fromTuple
        ( startX + (endX - startX) * t
        , startY + (endY - startY) * t
        )
