module Anim.Internal.PropertyBuilder.Rotate exposing
    ( Rotate
    , add
    , default
    , distance
    , duration
    , fromFloat
    , fromRecord
    , fromTriple
    , interpolate
    , rotateX
    , rotateY
    , rotateZ
    , scale
    , speed
    , subtract
    , toCssPropertyValue
    , toCssString
    , toFloat
    , toRecord
    , toString
    , toTriple
    , zero
    )

import Anim.Internal.Extra.Coordinate3D as Coordinate3D
import Shared.TimeSpec as TimeSpec exposing (TimeSpec)



-- ============================================================
-- TYPES
-- ============================================================


type Rotate
    = Rotate { x : Float, y : Float, z : Float }


default : Rotate
default =
    Rotate { x = 0, y = 0, z = 0 }


{-| Support interface for generic 3D coordinate operations
-}
support : Coordinate3D.Coordinate3DSupport Rotate
support =
    { zero = default
    , fromRecord = Rotate
    , toRecord = \(Rotate angles) -> angles
    , add = \(Rotate a) (Rotate b) -> Rotate { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
    , subtract = \(Rotate a) (Rotate b) -> Rotate { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
    , scale = \factor (Rotate angles) -> Rotate { x = angles.x * factor, y = angles.y * factor, z = angles.z * factor }
    }



-- ============================================================
-- ACCESSORS
-- ============================================================


toFloat : Rotate -> Float
toFloat (Rotate angles) =
    angles.z


rotateX : Rotate -> Float
rotateX (Rotate angles) =
    angles.x


rotateY : Rotate -> Float
rotateY (Rotate angles) =
    angles.y


rotateZ : Rotate -> Float
rotateZ (Rotate angles) =
    angles.z



-- ============================================================
-- CONVERSIONS
-- ============================================================


toString : Rotate -> String
toString (Rotate angles) =
    String.fromFloat angles.z


toCssString : Rotate -> String
toCssString (Rotate angles) =
    let
        parts =
            [ if angles.x /= 0 then
                Just ("rotateX(" ++ String.fromFloat angles.x ++ "deg)")

              else
                Nothing
            , if angles.y /= 0 then
                Just ("rotateY(" ++ String.fromFloat angles.y ++ "deg)")

              else
                Nothing
            , if angles.z /= 0 then
                Just ("rotateZ(" ++ String.fromFloat angles.z ++ "deg)")

              else
                Nothing
            ]
                |> List.filterMap identity
    in
    if List.isEmpty parts then
        "rotateZ(0deg)"

    else
        String.join " " parts


toCssPropertyValue : Rotate -> String
toCssPropertyValue (Rotate angles) =
    let
        hasX =
            angles.x /= 0

        hasY =
            angles.y /= 0

        hasZ =
            angles.z /= 0

        activeAxes =
            ( hasX, hasY, hasZ )
    in
    case activeAxes of
        ( False, False, False ) ->
            "0deg"

        ( True, False, False ) ->
            "x " ++ String.fromFloat angles.x ++ "deg"

        ( False, True, False ) ->
            "y " ++ String.fromFloat angles.y ++ "deg"

        ( False, False, True ) ->
            String.fromFloat angles.z ++ "deg"

        _ ->
            -- Multi-axis: convert Euler XYZ to axis-angle representation
            eulerToAxisAngle angles


eulerToAxisAngle : { x : Float, y : Float, z : Float } -> String
eulerToAxisAngle angles =
    let
        -- Convert degrees to radians
        toRad deg =
            deg * pi / 180

        rx =
            toRad angles.x

        ry =
            toRad angles.y

        rz =
            toRad angles.z

        -- Build rotation matrix from Euler XYZ
        cx =
            cos rx

        sx =
            sin rx

        cy =
            cos ry

        sy =
            sin ry

        cz =
            cos rz

        sz =
            sin rz

        -- Rotation matrix elements (R = Rz * Ry * Rx)
        m00 =
            cy * cz

        m01 =
            sx * sy * cz - cx * sz

        m10 =
            cy * sz

        m11 =
            sx * sy * sz + cx * cz

        m22 =
            cx * cy

        -- Extract angle from trace: trace = m00 + m11 + m22
        trace =
            m00 + m11 + m22

        angleDeg =
            acos (clamp -1 1 ((trace - 1) / 2)) * 180 / pi
    in
    if abs angleDeg < 0.001 then
        "0deg"

    else if abs (angleDeg - 180) < 0.001 then
        -- 180 degree rotation: extract axis from (R + I) / 2
        let
            m02 =
                sy

            m12 =
                -sx * cy

            m20 =
                -sy * cz + sx * cy * sz

            m21 =
                -sy * sz - sx * cy * cz

            ax =
                sqrt (clamp 0 1 ((m00 + 1) / 2))

            ay =
                sqrt (clamp 0 1 ((m11 + 1) / 2))

            az =
                sqrt (clamp 0 1 ((m22 + 1) / 2))

            -- Determine signs from off-diagonal elements
            axSigned =
                if m02 + m20 < 0 then
                    -ax

                else
                    ax

            aySigned =
                if m12 + m21 < 0 then
                    -ay

                else
                    ay
        in
        formatAxisAngle axSigned aySigned az angleDeg

    else
        -- General case: extract axis from skew-symmetric part
        let
            m02 =
                sy

            m20 =
                -sy * cz + sx * cy * sz

            m12 =
                -sx * cy

            m21 =
                -sy * sz - sx * cy * cz

            sinAngle =
                sin (angleDeg * pi / 180)

            ax =
                (m21 - m12) / (2 * sinAngle)

            ay =
                (m02 - m20) / (2 * sinAngle)

            az =
                (m10 - m01) / (2 * sinAngle)
        in
        formatAxisAngle ax ay az angleDeg


formatAxisAngle : Float -> Float -> Float -> Float -> String
formatAxisAngle ax ay az angleDeg =
    let
        len =
            sqrt (ax * ax + ay * ay + az * az)

        ( nx, ny, nz ) =
            if len > 0.0001 then
                ( ax / len, ay / len, az / len )

            else
                ( 0, 0, 1 )

        roundTo4 v =
            Basics.toFloat (round (v * 10000)) / 10000
    in
    String.fromFloat (roundTo4 nx)
        ++ " "
        ++ String.fromFloat (roundTo4 ny)
        ++ " "
        ++ String.fromFloat (roundTo4 nz)
        ++ " "
        ++ String.fromFloat (Basics.toFloat (round (angleDeg * 100)) / 100)
        ++ "deg"



-- ============================================================
-- CONSTRUCTORS
-- ============================================================


fromFloat : Float -> Rotate
fromFloat angle =
    Rotate { x = angle, y = angle, z = angle }


fromRecord : { x : Float, y : Float, z : Float } -> Rotate
fromRecord =
    Coordinate3D.fromRecord support


toRecord : Rotate -> { x : Float, y : Float, z : Float }
toRecord =
    Coordinate3D.toRecord support


fromTriple : ( Float, Float, Float ) -> Rotate
fromTriple =
    Coordinate3D.fromTriple support


toTriple : Rotate -> ( Float, Float, Float )
toTriple =
    Coordinate3D.toTriple support


zero : Rotate
zero =
    Rotate { x = 0, y = 0, z = 0 }



-- ============================================================
-- MATH
-- ============================================================


add : Rotate -> Rotate -> Rotate
add =
    Coordinate3D.add support


subtract : Rotate -> Rotate -> Rotate
subtract =
    Coordinate3D.subtract support


interpolate : Float -> Rotate -> Rotate -> Rotate
interpolate =
    Coordinate3D.interpolate support


distance : Rotate -> Rotate -> Float
distance =
    Coordinate3D.distance support


speed : Float -> Float -> TimeSpec -> Float
speed =
    TimeSpec.speed


duration : Float -> TimeSpec -> Float
duration =
    TimeSpec.duration


scale : Float -> Rotate -> Rotate
scale =
    Coordinate3D.scale support
