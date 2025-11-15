module Anim.Internal.Builders.Color exposing
    ( Builder
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
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec)



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


type Builder
    = Builder ColorConfig AnimBuilder


for : String -> AnimBuilder -> Builder
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
    in
    case existingConfig of
        Just config ->
            Builder (applyGlobalDefaults builder config) builder

        Nothing ->
            Builder (applyGlobalDefaults builder defaultConfig) (Builder.for elementId builder)


applyGlobalDefaults : AnimBuilder -> ColorConfig -> ColorConfig
applyGlobalDefaults builder config =
    { config
        | easing = Builder.getEasing builder
        , delay = Builder.getDelay builder
        , timing = Builder.getTimespec builder
    }


build : Builder -> AnimBuilder
build (Builder config builder) =
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


from : Color -> Builder -> Builder
from color (Builder config builder) =
    Builder { config | startAt = Just color } builder


to : Color -> Builder -> Builder
to color (Builder config builder) =
    Builder { config | endAt = color } builder


speed : Float -> Builder -> Builder
speed spd (Builder config builder) =
    Builder { config | speed = spd } builder


duration : Int -> Builder -> Builder
duration ms (Builder config builder) =
    Builder { config | duration = ms } builder


easing : Easing -> Builder -> Builder
easing ease (Builder config builder) =
    Builder { config | easing = Just ease } builder


delay : Delay -> Builder -> Builder
delay dly (Builder config builder) =
    Builder { config | delay = Just dly } builder
