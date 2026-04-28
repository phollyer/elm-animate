module Anim.Internal.Property.PerspectiveOrigin exposing
    ( PerspectiveOrigin
    , Unit(..)
    , default
    , distance
    , duration
    , fromRecord
    , getUnit
    , getX
    , getY
    , interpolate
    , speed
    , toCssString
    , toRecord
    , toTuple
    )

import Shared.TimeSpec as TimeSpec exposing (TimeSpec)



-- ============================================================
-- TYPES
-- ============================================================


type PerspectiveOrigin
    = Percent { x : Float, y : Float }
    | Px { x : Float, y : Float }


type Unit
    = PercentUnit
    | PxUnit


default : PerspectiveOrigin
default =
    Percent { x = 50, y = 50 }



-- ============================================================
-- CONSTRUCTORS
-- ============================================================


fromRecord : Unit -> { x : Float, y : Float } -> PerspectiveOrigin
fromRecord unit rec =
    case unit of
        PercentUnit ->
            Percent rec

        PxUnit ->
            Px rec


toRecord : PerspectiveOrigin -> { x : Float, y : Float }
toRecord origin =
    case origin of
        Percent rec ->
            rec

        Px rec ->
            rec


toTuple : PerspectiveOrigin -> ( Float, Float )
toTuple origin =
    case origin of
        Percent { x, y } ->
            ( x, y )

        Px { x, y } ->
            ( x, y )


getX : PerspectiveOrigin -> Float
getX origin =
    case origin of
        Percent { x } ->
            x

        Px { x } ->
            x


getY : PerspectiveOrigin -> Float
getY origin =
    case origin of
        Percent { y } ->
            y

        Px { y } ->
            y


getUnit : PerspectiveOrigin -> Unit
getUnit origin =
    case origin of
        Percent _ ->
            PercentUnit

        Px _ ->
            PxUnit



-- ============================================================
-- CONVERSIONS
-- ============================================================


toCssString : PerspectiveOrigin -> String
toCssString origin =
    case origin of
        Percent { x, y } ->
            String.fromFloat x ++ "% " ++ String.fromFloat y ++ "%"

        Px { x, y } ->
            String.fromFloat x ++ "px " ++ String.fromFloat y ++ "px"



-- ============================================================
-- MATH
-- ============================================================


distance : PerspectiveOrigin -> PerspectiveOrigin -> Float
distance start end =
    let
        ( sx, sy ) =
            toTuple start

        ( ex, ey ) =
            toTuple end

        dx =
            ex - sx

        dy =
            ey - sy
    in
    sqrt (dx * dx + dy * dy)


speed : Float -> Float -> TimeSpec -> Float
speed =
    TimeSpec.speed


duration : Float -> TimeSpec -> Float
duration =
    TimeSpec.duration


interpolate : Float -> PerspectiveOrigin -> PerspectiveOrigin -> PerspectiveOrigin
interpolate t start end =
    let
        ( sx, sy ) =
            toTuple start

        ( ex, ey ) =
            toTuple end

        ix =
            sx + (ex - sx) * t

        iy =
            sy + (ey - sy) * t
    in
    case end of
        Percent _ ->
            Percent { x = ix, y = iy }

        Px _ ->
            Px { x = ix, y = iy }
