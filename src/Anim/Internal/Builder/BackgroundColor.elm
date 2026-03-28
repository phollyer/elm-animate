module Anim.Internal.Builder.BackgroundColor exposing
    ( ColorBuilder
    , build
    , default
    , delay
    , duration
    , easing
    , for
    , from
    , init
    , speed
    , to
    )

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Color as ColorBuilder
import Anim.Internal.Property.Color as Color exposing (Color)


type alias ColorBuilder =
    ColorBuilder.ColorBuilder


config : ColorBuilder.ColorBuilderConfig
config =
    { propertyName = "backgroundColor"
    , extractExisting =
        \propertyConfig ->
            case propertyConfig of
                Builder.BackgroundColorConfig cfg ->
                    Just cfg

                _ ->
                    Nothing
    , wrapConfig = Builder.BackgroundColorConfig
    , extractBaseline = .backgroundColor
    , defaultColor = default
    }


default : Color
default =
    Color.fromRGBA { r = 255, g = 255, b = 255, a = 0 }


for : String -> AnimBuilder -> ColorBuilder
for =
    ColorBuilder.for config


build : ColorBuilder -> AnimBuilder
build =
    ColorBuilder.build config


init : Color -> ColorBuilder -> ColorBuilder
init =
    ColorBuilder.init


from : Color -> ColorBuilder -> ColorBuilder
from =
    ColorBuilder.from


to : Color -> ColorBuilder -> ColorBuilder
to =
    ColorBuilder.to config


speed : Float -> ColorBuilder -> ColorBuilder
speed =
    ColorBuilder.speed


duration : Int -> ColorBuilder -> ColorBuilder
duration =
    ColorBuilder.duration


easing : Easing -> ColorBuilder -> ColorBuilder
easing =
    ColorBuilder.easing


delay : Int -> ColorBuilder -> ColorBuilder
delay =
    ColorBuilder.delay
