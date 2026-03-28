module Anim.Internal.Builder.FontColor exposing
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
import Anim.Internal.Extra.Color as Color exposing (Color)


type alias ColorBuilder =
    ColorBuilder.ColorBuilder


config : ColorBuilder.ColorBuilderConfig
config =
    { propertyName = "fontColor"
    , extractExisting =
        \propertyConfig ->
            case propertyConfig of
                Builder.FontColorConfig cfg ->
                    Just cfg

                _ ->
                    Nothing
    , wrapConfig = Builder.FontColorConfig
    , extractBaseline = .fontColor
    , defaultColor = default
    }


default : Color
default =
    Color.black


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
