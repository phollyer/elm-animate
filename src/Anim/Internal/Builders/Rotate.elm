module Anim.Internal.Builders.Rotate exposing
    ( RotateBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , from
    , fromX
    , fromXYZ
    , fromY
    , fromZ
    , perspective
    , speed
    , to
    , toX
    , toXYZ
    , toY
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
    let
        startPos =
            case config.start of
                Just rotation_ ->
                    rotation_

                Nothing ->
                    Rotate.fromTriple ( 0.0, 0.0, 0.0 )
    in
    RotateBuilder
        { config
            | end = rotation
            , distance = Rotate.distance startPos rotation
            , start = Just startPos
        }
        builder


to : Rotate -> RotateBuilder -> RotateBuilder
to rotation (RotateBuilder config builder) =
    RotateBuilder { config | end = rotation } builder


fromX : Float -> RotateBuilder -> RotateBuilder
fromX x (RotateBuilder config builder) =
    let
        existingY =
            Maybe.withDefault 0 (Maybe.map Rotate.rotateY config.start)

        existingZ =
            Maybe.withDefault 0 (Maybe.map Rotate.rotateZ config.start)
    in
    RotateBuilder { config | start = Just (Rotate.fromTriple ( x, existingY, existingZ )) } builder


fromY : Float -> RotateBuilder -> RotateBuilder
fromY y (RotateBuilder config builder) =
    let
        existingX =
            Maybe.withDefault 0 (Maybe.map Rotate.rotateX config.start)

        existingZ =
            Maybe.withDefault 0 (Maybe.map Rotate.rotateZ config.start)
    in
    RotateBuilder { config | start = Just (Rotate.fromTriple ( existingX, y, existingZ )) } builder


fromZ : Float -> RotateBuilder -> RotateBuilder
fromZ z (RotateBuilder config builder) =
    let
        existingX =
            Maybe.withDefault 0 (Maybe.map Rotate.rotateX config.start)

        existingY =
            Maybe.withDefault 0 (Maybe.map Rotate.rotateY config.start)
    in
    RotateBuilder { config | start = Just (Rotate.fromTriple ( existingX, existingY, z )) } builder


fromXYZ : Float -> Float -> Float -> RotateBuilder -> RotateBuilder
fromXYZ x y z (RotateBuilder config builder) =
    RotateBuilder { config | start = Just (Rotate.fromTriple ( x, y, z )) } builder


toX : Float -> RotateBuilder -> RotateBuilder
toX x (RotateBuilder config builder) =
    to (Rotate.fromTriple ( x, Rotate.rotateY config.end, Rotate.rotateZ config.end )) (RotateBuilder config builder)


toY : Float -> RotateBuilder -> RotateBuilder
toY y (RotateBuilder config builder) =
    to (Rotate.fromTriple ( Rotate.rotateX config.end, y, Rotate.rotateZ config.end )) (RotateBuilder config builder)


toZ : Float -> RotateBuilder -> RotateBuilder
toZ z (RotateBuilder config builder) =
    to (Rotate.fromTriple ( Rotate.rotateX config.end, Rotate.rotateY config.end, z )) (RotateBuilder config builder)


toXYZ : Float -> Float -> Float -> RotateBuilder -> RotateBuilder
toXYZ x y z (RotateBuilder config builder) =
    to (Rotate.fromTriple ( x, y, z )) (RotateBuilder config builder)


speed : Float -> RotateBuilder -> RotateBuilder
speed value (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.withSpeed value config) builder


duration : Int -> RotateBuilder -> RotateBuilder
duration ms (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.withDuration ms config) builder


easing : Easing -> RotateBuilder -> RotateBuilder
easing easing_ (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.withEasing easing_ config) builder


delay : Int -> RotateBuilder -> RotateBuilder
delay delay_ (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.withDelay delay_ config) builder


perspective : String -> Float -> RotateBuilder -> RotateBuilder
perspective containerId value (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.withPerspective containerId value config) builder
