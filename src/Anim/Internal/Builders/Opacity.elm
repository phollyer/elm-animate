module Anim.Internal.Builders.Opacity exposing
    ( OpacityBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , from
    , speed
    , to
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Timing.Delay exposing (Delay)
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))



{- OPACITY CONFIGURATION BUILDER -}
{- Usage:

   Anim.init
       |> Opacity.for "my-element"
       |> Opacity.from (Opacity.rgba 255 0 0 1)
       |> Opacity.to (Opacity.rgba 0 0 255 1)
       |> Opacity.duration 2000
       |> Opacity.easing Easing.easeInOut
       |> Opacity.delay (Delay.millis 500)
       |> Opacity.build
       |> Anim.animate

-}


type OpacityBuilder
    = OpacityBuilder OpacityConfig AnimBuilder


for : String -> AnimBuilder -> OpacityBuilder
for elementId builder =
    let
        existingConfig =
            case Builder.getElementConfig elementId builder of
                Just { properties } ->
                    properties
                        |> List.filterMap
                            (\prop ->
                                case prop of
                                    Builder.OpacityConfig config ->
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
    OpacityBuilder newConfig (Builder.for elementId builder)


build : OpacityBuilder -> AnimBuilder
build (OpacityBuilder config builder) =
    let
        newOpacityConfig =
            Builder.OpacityConfig config
    in
    PropertyBuilder.upsert newOpacityConfig builder


type alias OpacityConfig =
    { startAt : Maybe Opacity
    , endAt : Opacity
    , duration : Int -- Millis
    , speed : Float -- Opacity units per second
    , distance : Float -- Opacity units
    , timing : Maybe TimeSpec
    , easing : Maybe Easing
    , delay : Maybe Delay
    }


defaultConfig : OpacityConfig
defaultConfig =
    { startAt = Nothing
    , endAt = Opacity.fromFloat 1
    , duration = 0
    , speed = 0
    , distance = 0
    , timing = Nothing
    , easing = Nothing
    , delay = Nothing
    }


from : Opacity -> OpacityBuilder -> OpacityBuilder
from opacity (OpacityBuilder config builder) =
    OpacityBuilder { config | startAt = Just opacity } builder


to : Opacity -> OpacityBuilder -> OpacityBuilder
to opacity (OpacityBuilder config builder) =
    let
        startPos =
            case config.startAt of
                Just opacity_ ->
                    opacity_

                Nothing ->
                    Opacity.fromFloat 1
    in
    OpacityBuilder
        { config
            | endAt = opacity
            , distance = Opacity.distance startPos opacity
            , startAt = Just startPos
        }
        builder


speed : Float -> OpacityBuilder -> OpacityBuilder
speed spd (OpacityBuilder config builder) =
    OpacityBuilder
        { config
            | speed = spd
            , timing =
                Just <|
                    Speed spd
        }
        builder


duration : Int -> OpacityBuilder -> OpacityBuilder
duration dur (OpacityBuilder config builder) =
    OpacityBuilder
        { config
            | duration = dur
            , timing =
                Just <|
                    Duration dur
        }
        builder


easing : Easing -> OpacityBuilder -> OpacityBuilder
easing ease (OpacityBuilder config builder) =
    OpacityBuilder { config | easing = Just ease } builder


delay : Delay -> OpacityBuilder -> OpacityBuilder
delay dly (OpacityBuilder config builder) =
    OpacityBuilder { config | delay = Just dly } builder
