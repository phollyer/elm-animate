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
import Anim.Internal.Properties.BackgroundColor as BackgroundColor exposing (Color(..))
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))


type ColorBuilder
    = ColorBuilder (Builder.AnimationConfig Color) AnimBuilder


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
                                    Builder.BackgroundColorConfig config ->
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
                            , perspective = Nothing
                            , timing = Nothing
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , isDirty = False
                        }

                Nothing ->
                    PropertyBuilder.applyGlobalDefaults builder defaultConfig
    in
    ColorBuilder newConfig (Builder.for elementId builder)


build : ColorBuilder -> AnimBuilder
build (ColorBuilder config builder) =
    let
        newColorConfig =
            Builder.BackgroundColorConfig config
    in
    PropertyBuilder.upsert newColorConfig builder


type alias ColorConfig =
    Builder.AnimationConfig Color


defaultConfig : ColorConfig
defaultConfig =
    { startAt = Nothing
    , endAt = BackgroundColor.rgb255 0 0 0
    , duration = 0
    , speed = 0
    , distance = 0
    , timing = Nothing
    , delay = Nothing
    , easing = Nothing
    , perspective = Nothing
    , isDirty = False
    }


from : Color -> ColorBuilder -> ColorBuilder
from color (ColorBuilder config builder) =
    ColorBuilder { config | startAt = Just color } builder


to : Color -> ColorBuilder -> ColorBuilder
to color (ColorBuilder config builder) =
    let
        startPos =
            case config.startAt of
                Just opacity_ ->
                    opacity_

                Nothing ->
                    BackgroundColor.rgb255 0 0 0
    in
    ColorBuilder
        { config
            | endAt = color
            , distance = BackgroundColor.distance startPos color
            , startAt = Just startPos
        }
        builder


speed : Float -> ColorBuilder -> ColorBuilder
speed spd (ColorBuilder config builder) =
    let
        -- Black to white distance is exactly √(255² + 255² + 255²) ≈ 441.67
        maxColorDistance =
            441.67

        rgbDistancePerSecond =
            spd * maxColorDistance
    in
    ColorBuilder
        { config
            | speed = rgbDistancePerSecond
            , timing =
                Just <|
                    Speed rgbDistancePerSecond
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


delay : Int -> ColorBuilder -> ColorBuilder
delay dly (ColorBuilder config builder) =
    ColorBuilder
        { config
            | delay =
                Just <|
                    dly
        }
        builder
