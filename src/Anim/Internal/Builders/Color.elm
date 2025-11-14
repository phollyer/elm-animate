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


type ColorBuilder
    = ColorBuilder ColorConfig AnimBuilder


for : String -> AnimBuilder -> ColorBuilder
for elementId builder =
    ColorBuilder defaultConfig (Builder.for elementId builder)


build : ColorBuilder -> AnimBuilder
build (ColorBuilder config builder) =
    let
        currentElement =
            Builder.getCurrentElement builder

        newColorConfig =
            Builder.ColorConfig config

        addProp =
            newColorConfig :: currentElement.properties

        replaceProp =
            currentElement.properties
                |> List.map
                    (\p ->
                        case p of
                            Builder.ColorConfig _ ->
                                newColorConfig

                            _ ->
                                p
                    )

        findProp : List Builder.PropertyConfig -> List Builder.PropertyConfig
        findProp =
            List.filterMap
                (\p ->
                    case p of
                        Builder.ColorConfig c ->
                            Just (Builder.ColorConfig c)

                        _ ->
                            Nothing
                )

        upsertProp : List Builder.PropertyConfig -> List Builder.PropertyConfig
        upsertProp props =
            case props of
                [] ->
                    addProp

                [ Builder.ColorConfig _ ] ->
                    replaceProp

                _ ->
                    replaceProp

        updatedElement =
            { currentElement
                | properties =
                    currentElement.properties
                        |> findProp
                        |> upsertProp
            }
    in
    Builder.updateCurrentElement updatedElement builder


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
    ColorBuilder { config | speed = spd } builder


duration : Int -> ColorBuilder -> ColorBuilder
duration ms (ColorBuilder config builder) =
    ColorBuilder { config | duration = ms } builder


easing : Easing -> ColorBuilder -> ColorBuilder
easing ease (ColorBuilder config builder) =
    ColorBuilder { config | easing = Just ease } builder


delay : Delay -> ColorBuilder -> ColorBuilder
delay dly (ColorBuilder config builder) =
    ColorBuilder { config | delay = Just dly } builder
