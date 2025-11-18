module Anim.Internal.Builders.Scale exposing
    ( ScaleBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , fromX
    , fromXY
    , fromY
    , speed
    , toX
    , toXY
    , toY
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))



{- Scale CONFIGURATION BUILDER -}
{- Usage:

   Anim.init
       |> Scale.for "my-element"
       |> Scale.from (Scale.fromTuple (0, 0))
       |> Scale.to (Scale.fromTuple (100, 200))
       |> Scale.duration 2000
       |> Scale.easing Easing.easeInOut
       |> Scale.delay (Delay.millis 500)
       |> Scale.build
       |> Anim.animate
-}


type ScaleBuilder
    = ScaleBuilder ScaleConfig AnimBuilder


for : String -> AnimBuilder -> ScaleBuilder
for elementId builder =
    let
        existingConfig =
            case Builder.getElementConfig elementId builder of
                Just { properties } ->
                    properties
                        |> List.filterMap
                            (\prop ->
                                case prop of
                                    Builder.ScaleConfig config ->
                                        Just config

                                    _ ->
                                        Nothing
                            )
                        |> List.head

                _ ->
                    Nothing

        newConfig =
            case existingConfig of
                Just config ->
                    PropertyBuilder.applyGlobalDefaults builder <|
                        { config
                            | startAt = Just config.endAt
                            , easing = Nothing
                            , delay = Nothing
                            , timing = Nothing
                            , duration = 0
                            , speed = 0
                            , distance = 0
                        }

                Nothing ->
                    PropertyBuilder.applyGlobalDefaults builder defaultConfig
    in
    ScaleBuilder newConfig (Builder.for elementId builder)


build : ScaleBuilder -> AnimBuilder
build (ScaleBuilder config builder) =
    let
        newScaleConfig =
            Builder.ScaleConfig config
    in
    PropertyBuilder.upsert newScaleConfig builder


type alias ScaleConfig =
    { startAt : Maybe Scale
    , endAt : Scale
    , duration : Int -- Millis
    , speed : Float -- Pixels per second
    , distance : Float -- Pixels
    , timing : Maybe TimeSpec
    , easing : Maybe Easing
    , delay : Maybe Int
    }


defaultConfig : ScaleConfig
defaultConfig =
    { startAt = Nothing
    , endAt = Scale.fromTuple ( 0, 0 )
    , duration = 0
    , speed = 0
    , distance = 0
    , timing = Nothing
    , easing = Nothing
    , delay = Nothing
    }


fromXY : Float -> Float -> ScaleBuilder -> ScaleBuilder
fromXY scaleX scaleY (ScaleBuilder config builder) =
    ScaleBuilder
        { config
            | startAt =
                Just <|
                    Scale.fromTuple ( scaleX, scaleY )
        }
        builder


fromX : Float -> ScaleBuilder -> ScaleBuilder
fromX scaleX (ScaleBuilder config builder) =
    let
        startPos =
            case config.startAt of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTuple ( 1, 1 )
    in
    ScaleBuilder
        { config
            | startAt =
                Just <|
                    Scale.fromTuple ( scaleX, Scale.getY startPos )
        }
        builder


fromY : Float -> ScaleBuilder -> ScaleBuilder
fromY scaleY (ScaleBuilder config builder) =
    let
        startPos =
            case config.startAt of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTuple ( 1, 1 )
    in
    ScaleBuilder
        { config
            | startAt =
                Just <|
                    Scale.fromTuple ( Scale.getX startPos, scaleY )
        }
        builder


toXY : Float -> Float -> ScaleBuilder -> ScaleBuilder
toXY scaleX scaleY (ScaleBuilder config builder) =
    let
        startPos =
            case config.startAt of
                Just opacity_ ->
                    opacity_

                Nothing ->
                    Scale.fromTuple ( 1, 1 )

        scale =
            Scale.fromTuple ( scaleX, scaleY )
    in
    ScaleBuilder
        { config
            | endAt = scale
            , distance = Scale.distance startPos scale
            , startAt = Just startPos
        }
        builder


toX : Float -> ScaleBuilder -> ScaleBuilder
toX scaleX (ScaleBuilder config builder) =
    let
        startPos =
            case config.startAt of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTuple ( 1, 1 )

        scale =
            Scale.fromTuple ( scaleX, Scale.getY startPos )
    in
    ScaleBuilder
        { config
            | endAt = scale
            , distance = Scale.distance startPos scale
        }
        builder


toY : Float -> ScaleBuilder -> ScaleBuilder
toY scaleY (ScaleBuilder config builder) =
    let
        startPos =
            case config.startAt of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTuple ( 1, 1 )

        scale =
            Scale.fromTuple ( Scale.getX startPos, scaleY )
    in
    ScaleBuilder
        { config
            | endAt = scale
            , distance = Scale.distance startPos scale
        }
        builder


speed : Float -> ScaleBuilder -> ScaleBuilder
speed value (ScaleBuilder config builder) =
    ScaleBuilder
        { config
            | speed = value
            , timing =
                Just <|
                    Speed value
        }
        builder


duration : Int -> ScaleBuilder -> ScaleBuilder
duration ms (ScaleBuilder config builder) =
    ScaleBuilder
        { config
            | duration = ms
            , timing =
                Just <|
                    Duration ms
        }
        builder


easing : Easing -> ScaleBuilder -> ScaleBuilder
easing easing_ (ScaleBuilder config builder) =
    ScaleBuilder { config | easing = Just easing_ } builder


delay : Int -> ScaleBuilder -> ScaleBuilder
delay delay_ (ScaleBuilder config builder) =
    ScaleBuilder { config | delay = Just delay_ } builder
