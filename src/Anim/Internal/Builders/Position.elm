module Anim.Internal.Builders.Position exposing
    ( PositionBuilder
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

import Anim.Easing exposing (Easing)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))


type PositionBuilder
    = PositionBuilder (Builder.AnimationConfig Position) AnimBuilder


for : String -> AnimBuilder -> PositionBuilder
for elementId builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.PositionConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.createFor extractExisting defaultConfig elementId builder
    in
    PositionBuilder config (Builder.for elementId builder)


build : PositionBuilder -> AnimBuilder
build (PositionBuilder config builder) =
    PropertyBuilder.upsert (Builder.PositionConfig config) builder


type alias PositionConfig =
    Builder.AnimationConfig Position


defaultConfig : PositionConfig
defaultConfig =
    PropertyBuilder.defaultConfig <|
        Position.fromTriple ( 0, 0, 0 )


from : Position -> PositionBuilder -> PositionBuilder
from position (PositionBuilder config builder) =
    PositionBuilder { config | start = Just position } builder


fromXYZ : Float -> Float -> Float -> PositionBuilder -> PositionBuilder
fromXYZ x y z =
    from (Position.fromTriple ( x, y, z ))


fromXY : Float -> Float -> PositionBuilder -> PositionBuilder
fromXY x y (PositionBuilder config builder) =
    let
        z =
            Maybe.withDefault 0 <|
                Maybe.map Position.z config.start
    in
    fromXYZ x y z <|
        PositionBuilder config builder


fromXZ : Float -> Float -> PositionBuilder -> PositionBuilder
fromXZ x z (PositionBuilder config builder) =
    let
        y =
            Maybe.withDefault 0 (Maybe.map Position.y config.start)
    in
    fromXYZ x y z <|
        PositionBuilder config builder


fromX : Float -> PositionBuilder -> PositionBuilder
fromX x (PositionBuilder config builder) =
    let
        y =
            Maybe.withDefault 0 (Maybe.map Position.y config.start)

        z =
            Maybe.withDefault 0 (Maybe.map Position.z config.start)
    in
    fromXYZ x y z <|
        PositionBuilder config builder


fromYZ : Float -> Float -> PositionBuilder -> PositionBuilder
fromYZ y z (PositionBuilder config builder) =
    let
        x =
            Maybe.withDefault 0 (Maybe.map Position.x config.start)
    in
    fromXYZ x y z <|
        PositionBuilder config builder


fromY : Float -> PositionBuilder -> PositionBuilder
fromY y (PositionBuilder config builder) =
    let
        x =
            Maybe.withDefault 0 (Maybe.map Position.x config.start)

        z =
            Maybe.withDefault 0 (Maybe.map Position.z config.start)
    in
    fromXYZ x y z <|
        PositionBuilder config builder


fromZ : Float -> PositionBuilder -> PositionBuilder
fromZ z (PositionBuilder config builder) =
    let
        x =
            Maybe.withDefault 0 (Maybe.map Position.x config.start)

        y =
            Maybe.withDefault 0 (Maybe.map Position.y config.start)
    in
    fromXYZ x y z <|
        PositionBuilder config builder


to : Position -> PositionBuilder -> PositionBuilder
to position (PositionBuilder config builder) =
    let
        startPos =
            case config.start of
                Just s ->
                    s

                Nothing ->
                    Position.fromTriple ( 0, 0, 0 )
    in
    PositionBuilder
        { config
            | start = Just startPos
            , end = position
            , distance = Position.distance startPos position
        }
        builder


toXYZ : Float -> Float -> Float -> PositionBuilder -> PositionBuilder
toXYZ x y z (PositionBuilder config builder) =
    to (Position.fromTriple ( x, y, z )) <|
        PositionBuilder config builder


toXY : Float -> Float -> PositionBuilder -> PositionBuilder
toXY x y (PositionBuilder config builder) =
    let
        z =
            Position.z config.end
    in
    toXYZ x y z <|
        PositionBuilder config builder


toXZ : Float -> Float -> PositionBuilder -> PositionBuilder
toXZ x z (PositionBuilder config builder) =
    let
        y =
            Position.y config.end
    in
    toXYZ x y z <|
        PositionBuilder config builder


toX : Float -> PositionBuilder -> PositionBuilder
toX x (PositionBuilder config builder) =
    let
        y =
            Position.y config.end

        z =
            Position.z config.end
    in
    toXYZ x y z <|
        PositionBuilder config builder


toYZ : Float -> Float -> PositionBuilder -> PositionBuilder
toYZ y z (PositionBuilder config builder) =
    let
        x =
            Position.x config.end
    in
    toXYZ x y z <|
        PositionBuilder config builder


toY : Float -> PositionBuilder -> PositionBuilder
toY y (PositionBuilder config builder) =
    let
        x =
            Position.x config.end

        z =
            Position.z config.end
    in
    toXYZ x y z <|
        PositionBuilder config builder


toZ : Float -> PositionBuilder -> PositionBuilder
toZ z (PositionBuilder config builder) =
    let
        x =
            Position.x config.end

        y =
            Position.y config.end
    in
    toXYZ x y z <|
        PositionBuilder config builder


delay : Int -> PositionBuilder -> PositionBuilder
delay delay_ (PositionBuilder config builder) =
    PositionBuilder (PropertyBuilder.withDelay delay_ config) builder


duration : Int -> PositionBuilder -> PositionBuilder
duration ms (PositionBuilder config builder) =
    PositionBuilder (PropertyBuilder.withDuration ms config) builder


speed : Float -> PositionBuilder -> PositionBuilder
speed value (PositionBuilder config builder) =
    PositionBuilder (PropertyBuilder.withSpeed value config) builder


easing : Easing -> PositionBuilder -> PositionBuilder
easing easing_ (PositionBuilder config builder) =
    PositionBuilder (PropertyBuilder.withEasing easing_ config) builder


perspective : String -> Float -> PositionBuilder -> PositionBuilder
perspective containerId value (PositionBuilder config builder) =
    PositionBuilder (PropertyBuilder.withPerspective containerId value config) builder
