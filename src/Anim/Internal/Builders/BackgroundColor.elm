module Anim.Internal.Builders.BackgroundColor exposing
    ( ColorBuilder
    , build
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
import Anim.Internal.Builders.Color as Color
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Color exposing (Color)


type alias ColorBuilder =
    Color.ColorBuilder


config : Color.ColorBuilderConfig
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
    , defaultColor = BackgroundColor.default
    }


for : String -> AnimBuilder -> ColorBuilder
for =
    Color.for config


build : ColorBuilder -> AnimBuilder
build =
    Color.build config


init : Color -> ColorBuilder -> ColorBuilder
init =
    Color.init


from : Color -> ColorBuilder -> ColorBuilder
from =
    Color.from


to : Color -> ColorBuilder -> ColorBuilder
to =
    Color.to config


speed : Float -> ColorBuilder -> ColorBuilder
speed =
    Color.speed


duration : Int -> ColorBuilder -> ColorBuilder
duration =
    Color.duration


easing : Easing -> ColorBuilder -> ColorBuilder
easing =
    Color.easing


delay : Int -> ColorBuilder -> ColorBuilder
delay =
    Color.delay
