module Anim.Internal.Builders.Rotate exposing
    ( RotateBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , from
    , fromX
    , fromXY
    , fromXYZ
    , fromXZ
    , fromY
    , fromYZ
    , fromZ
    , perspective
    , speed
    , to
    , toX
    , toXY
    , toXYZ
    , toXZ
    , toY
    , toYZ
    , toZ
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))



{- Rotation CONFIGURATION BUILDER -}
{- Usage:

   Anim.init
      |> Rotation.for "my-element"
      |> Rotation.from 0
      |> Rotation.to 360
      |> Rotation.duration 2000
      |> Rotation.easing Easing.easeInOut
      |> Rotation.delay (Delay.millis 500)
      |> Rotation.build
      |> Anim.animate
-}


type RotateBuilder
    = RotateBuilder (Builder.AnimationConfig Rotate) AnimBuilder


for : String -> AnimBuilder -> RotateBuilder
for elementId builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.RotateConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.createFor extractExisting defaultConfig elementId builder
    in
    RotateBuilder config (Builder.for elementId builder)


build : RotateBuilder -> AnimBuilder
build (RotateBuilder config builder) =
    PropertyBuilder.upsert (Builder.RotateConfig config) builder


type alias RotateConfig =
    Builder.AnimationConfig Rotate


defaultConfig : RotateConfig
defaultConfig =
    PropertyBuilder.defaultConfig <|
        Rotate.fromTriple ( 0.0, 0.0, 0.0 )


from : Rotate -> RotateBuilder -> RotateBuilder
from rotation (RotateBuilder config builder) =
    RotateBuilder { config | start = Just rotation } builder


fromXYZ : Float -> Float -> Float -> RotateBuilder -> RotateBuilder
fromXYZ x y z =
    from (Rotate.fromTriple ( x, y, z ))


fromXY : Float -> Float -> RotateBuilder -> RotateBuilder
fromXY x y (RotateBuilder config builder) =
    let
        z =
            config.start
                |> Maybe.map Rotate.rotateZ
                |> Maybe.withDefault 0
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromXZ : Float -> Float -> RotateBuilder -> RotateBuilder
fromXZ x z (RotateBuilder config builder) =
    let
        y =
            config.start
                |> Maybe.map Rotate.rotateY
                |> Maybe.withDefault 0
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromX : Float -> RotateBuilder -> RotateBuilder
fromX x (RotateBuilder config builder) =
    let
        y =
            config.start
                |> Maybe.map Rotate.rotateY
                |> Maybe.withDefault 0

        z =
            config.start
                |> Maybe.map Rotate.rotateZ
                |> Maybe.withDefault 0
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromYZ : Float -> Float -> RotateBuilder -> RotateBuilder
fromYZ y z (RotateBuilder config builder) =
    let
        x =
            config.start
                |> Maybe.map Rotate.rotateX
                |> Maybe.withDefault 0
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromY : Float -> RotateBuilder -> RotateBuilder
fromY y (RotateBuilder config builder) =
    let
        x =
            config.start
                |> Maybe.map Rotate.rotateX
                |> Maybe.withDefault 0

        z =
            config.start
                |> Maybe.map Rotate.rotateZ
                |> Maybe.withDefault 0
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromZ : Float -> RotateBuilder -> RotateBuilder
fromZ z (RotateBuilder config builder) =
    let
        x =
            config.start
                |> Maybe.map Rotate.rotateX
                |> Maybe.withDefault 0

        y =
            config.start
                |> Maybe.map Rotate.rotateY
                |> Maybe.withDefault 0
    in
    fromXYZ x y z <|
        RotateBuilder config builder


to : Rotate -> RotateBuilder -> RotateBuilder
to endRotation (RotateBuilder config builder) =
    let
        startRotation =
            case config.start of
                Just s ->
                    s

                Nothing ->
                    Rotate.fromTriple ( 0, 0, 0 )
    in
    RotateBuilder
        { config
            | start = Just startRotation
            , end = endRotation
            , distance = Rotate.distance startRotation endRotation
        }
        builder


toXYZ : Float -> Float -> Float -> RotateBuilder -> RotateBuilder
toXYZ x y z =
    to (Rotate.fromTriple ( x, y, z ))


toXY : Float -> Float -> RotateBuilder -> RotateBuilder
toXY x y (RotateBuilder config builder) =
    let
        z =
            Rotate.rotateZ config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toXZ : Float -> Float -> RotateBuilder -> RotateBuilder
toXZ x z (RotateBuilder config builder) =
    let
        y =
            Rotate.rotateY config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toX : Float -> RotateBuilder -> RotateBuilder
toX x (RotateBuilder config builder) =
    let
        y =
            Rotate.rotateY config.end

        z =
            Rotate.rotateZ config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toYZ : Float -> Float -> RotateBuilder -> RotateBuilder
toYZ y z (RotateBuilder config builder) =
    let
        x =
            Rotate.rotateX config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toY : Float -> RotateBuilder -> RotateBuilder
toY y (RotateBuilder config builder) =
    let
        x =
            Rotate.rotateX config.end

        z =
            Rotate.rotateZ config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toZ : Float -> RotateBuilder -> RotateBuilder
toZ z (RotateBuilder config builder) =
    let
        x =
            Rotate.rotateX config.end

        y =
            Rotate.rotateY config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


delay : Int -> RotateBuilder -> RotateBuilder
delay delay_ (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.withDelay delay_ config) builder


duration : Int -> RotateBuilder -> RotateBuilder
duration ms (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.withDuration ms config) builder


speed : Float -> RotateBuilder -> RotateBuilder
speed value (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.withSpeed value config) builder


easing : Easing -> RotateBuilder -> RotateBuilder
easing easing_ (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.withEasing easing_ config) builder


perspective : String -> Float -> RotateBuilder -> RotateBuilder
perspective containerId value (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.withPerspective containerId value config) builder
