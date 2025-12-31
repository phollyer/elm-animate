module Anim.Internal.Builders.Position exposing
    ( PositionBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , fromX
    , fromXY
    , fromXYZ
    , fromY
    , fromZ
    , perspective
    , speed
    , to
    , toX
    , toXY
    , toXYZ
    , toY
    , toZ
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))



{- POSITION CONFIGURATION BUILDER -}
{- Usage:

   Anim.init
       |> Position.for "my-element"
       |> Position.from (Position.fromTuple (0, 0))
       |> Position.to (Position.fromTuple (100, 200))
       |> Position.duration 2000
       |> Position.easing Easing.easeInOut
       |> Position.delay (Delay.millis 500)
       |> Position.build
       |> Anim.animate
-}


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


fromXY : Float -> Float -> PositionBuilder -> PositionBuilder
fromXY x y (PositionBuilder config builder) =
    PositionBuilder { config | start = Just (Position.fromTuple ( x, y )) } builder


fromXYZ : Float -> Float -> Float -> PositionBuilder -> PositionBuilder
fromXYZ x y z (PositionBuilder config builder) =
    PositionBuilder { config | start = Just (Position.fromTriple ( x, y, z )) } builder


fromX : Float -> PositionBuilder -> PositionBuilder
fromX x (PositionBuilder config builder) =
    let
        existingY =
            Maybe.withDefault 0 (Maybe.map Position.y config.start)

        existingZ =
            Maybe.withDefault 0 (Maybe.map Position.z config.start)
    in
    PositionBuilder { config | start = Just (Position.fromTriple ( x, existingY, existingZ )) } builder


fromY : Float -> PositionBuilder -> PositionBuilder
fromY y (PositionBuilder config builder) =
    let
        existingX =
            Maybe.withDefault 0 (Maybe.map Position.x config.start)

        existingZ =
            Maybe.withDefault 0 (Maybe.map Position.z config.start)
    in
    PositionBuilder { config | start = Just (Position.fromTriple ( existingX, y, existingZ )) } builder


fromZ : Float -> PositionBuilder -> PositionBuilder
fromZ z (PositionBuilder config builder) =
    let
        existingX =
            Maybe.withDefault 0 (Maybe.map Position.x config.start)

        existingY =
            Maybe.withDefault 0 (Maybe.map Position.y config.start)
    in
    PositionBuilder { config | start = Just (Position.fromTriple ( existingX, existingY, z )) } builder


to : Position -> PositionBuilder -> PositionBuilder
to position (PositionBuilder config builder) =
    let
        startPos =
            case config.start of
                Just pos ->
                    pos

                Nothing ->
                    Position.fromTriple ( 0, 0, 0 )
    in
    PositionBuilder
        { config
            | end = position
            , distance = Position.distance startPos position
            , start = Just startPos
        }
        builder


toX : Float -> PositionBuilder -> PositionBuilder
toX x (PositionBuilder config builder) =
    to (Position.fromTriple ( x, Position.y config.end, Position.z config.end )) (PositionBuilder config builder)


toY : Float -> PositionBuilder -> PositionBuilder
toY y (PositionBuilder config builder) =
    to (Position.fromTriple ( Position.x config.end, y, Position.z config.end )) (PositionBuilder config builder)


toZ : Float -> PositionBuilder -> PositionBuilder
toZ z (PositionBuilder config builder) =
    to (Position.fromTriple ( Position.x config.end, Position.y config.end, z )) (PositionBuilder config builder)


toXY : Float -> Float -> PositionBuilder -> PositionBuilder
toXY x y (PositionBuilder config builder) =
    to (Position.fromTriple ( x, y, Position.z config.end )) (PositionBuilder config builder)


toXYZ : Float -> Float -> Float -> PositionBuilder -> PositionBuilder
toXYZ x y z (PositionBuilder config builder) =
    to (Position.fromTriple ( x, y, z )) (PositionBuilder config builder)


speed : Float -> PositionBuilder -> PositionBuilder
speed value (PositionBuilder config builder) =
    PositionBuilder (PropertyBuilder.withSpeed value config) builder


duration : Int -> PositionBuilder -> PositionBuilder
duration ms (PositionBuilder config builder) =
    PositionBuilder (PropertyBuilder.withDuration ms config) builder


easing : Easing -> PositionBuilder -> PositionBuilder
easing easing_ (PositionBuilder config builder) =
    PositionBuilder (PropertyBuilder.withEasing easing_ config) builder


delay : Int -> PositionBuilder -> PositionBuilder
delay delay_ (PositionBuilder config builder) =
    PositionBuilder (PropertyBuilder.withDelay delay_ config) builder


perspective : String -> Float -> PositionBuilder -> PositionBuilder
perspective containerId value (PositionBuilder config builder) =
    PositionBuilder (PropertyBuilder.withPerspective containerId value config) builder
