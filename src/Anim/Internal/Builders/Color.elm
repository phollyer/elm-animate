module Anim.Internal.Builders.Color exposing
    ( ColorBuilder
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
import Anim.Internal.Properties.Color as Color exposing (Color(..))
import Anim.Internal.Timing.Delay exposing (Delay)
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))



{- COLOR CONFIGURATION BUILDER -}
{- Usage:

   Anim.init
       |> Color.for "my-element"
       |> Color.from (Color.rgba 255 0 0 1)
       |> Color.to (Color.rgba 0 0 255 1)
       |> Color.duration 2000
       |> Color.easing Easing.easeInOut
       |> Color.delay (Delay.millis 500)
       |> Color.build
       |> Anim.animate
-}


type ColorBuilder
    = ColorBuilder ColorConfig AnimBuilder


for : String -> AnimBuilder -> ColorBuilder
for elementId builder =
    let
        existingConfig =
            case Builder.getElementConfig elementId builder of
                Just { properties } ->
                    properties
                        |> List.filterMap
                            (\prop ->
                                case prop of
                                    Builder.ColorConfig config ->
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
                    PropertyBuilder.applyGlobalDefaults builder config

                Nothing ->
                    PropertyBuilder.applyGlobalDefaults builder defaultConfig
    in
    ColorBuilder newConfig (Builder.for elementId builder)


build : ColorBuilder -> AnimBuilder
build (ColorBuilder config builder) =
    let
        newColorConfig =
            Builder.ColorConfig config
    in
    PropertyBuilder.upsert newColorConfig builder


type alias ColorConfig =
    { startAt : Maybe Color
    , endAt : Color
    , duration : Int
    , speed : Float
    , distance : Float
    , timing : Maybe TimeSpec
    , delay : Maybe Delay
    , easing : Maybe Easing
    }


defaultConfig : ColorConfig
defaultConfig =
    { startAt = Nothing
    , endAt = Color.rgb255 0 0 0
    , duration = 0
    , speed = 0
    , distance = 0
    , timing = Nothing
    , delay = Nothing
    , easing = Nothing
    }


from : Color -> ColorBuilder -> ColorBuilder
from color (ColorBuilder config builder) =
    ColorBuilder { config | startAt = Just color } builder


to : Color -> ColorBuilder -> ColorBuilder
to color (ColorBuilder config builder) =
    ColorBuilder { config | endAt = color } builder


speed : Float -> ColorBuilder -> ColorBuilder
speed spd (ColorBuilder config builder) =
    ColorBuilder
        { config
            | speed = spd
            , timing =
                Just <|
                    Speed spd
        }
        builder


duration : Int -> ColorBuilder -> ColorBuilder
duration ms (ColorBuilder config builder) =
    ColorBuilder
        { config
            | duration = ms
            , timing =
                Just <|
                    Duration ms
        }
        builder


easing : Easing -> ColorBuilder -> ColorBuilder
easing ease (ColorBuilder config builder) =
    ColorBuilder { config | easing = Just ease } builder


delay : Delay -> ColorBuilder -> ColorBuilder
delay dly (ColorBuilder config builder) =
    ColorBuilder { config | delay = Just dly } builder
