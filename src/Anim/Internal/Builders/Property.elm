module Anim.Internal.Builders.Property exposing
    ( delay
    , easing
    , timeSpec
    , to
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Timing.Delay exposing (Delay)
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec)


to : Builder.PropertyConfig -> AnimBuilder -> AnimBuilder
to propertyConfig builder =
    let
        currentElement =
            Builder.getCurrentElement builder

        updatedElement =
            { currentElement | properties = propertyConfig :: currentElement.properties }
    in
    Builder.updateCurrentElement updatedElement builder


type alias UpdatePropertySpecFn =
    (Builder.AnimSpec -> Builder.AnimSpec) -> Builder.PropertyConfig -> Builder.PropertyConfig


delay : UpdatePropertySpecFn -> Delay -> AnimBuilder -> AnimBuilder
delay updateFn delay_ builder =
    let
        propertySpecFn =
            \spec -> { spec | delay = Just delay_ }
    in
    updateCurrentElement updateFn propertySpecFn builder


easing : UpdatePropertySpecFn -> Easing -> AnimBuilder -> AnimBuilder
easing updateFn easingFunction builder =
    let
        propertySpecFn =
            \spec -> { spec | easing = Just easingFunction }
    in
    updateCurrentElement updateFn propertySpecFn builder


timeSpec : UpdatePropertySpecFn -> TimeSpec -> AnimBuilder -> AnimBuilder
timeSpec updateFn timeSpec_ builder =
    let
        propertySpecFn =
            \spec -> { spec | timing = Just timeSpec_ }
    in
    updateCurrentElement updateFn propertySpecFn builder


updateCurrentElement : UpdatePropertySpecFn -> (Builder.AnimSpec -> Builder.AnimSpec) -> AnimBuilder -> AnimBuilder
updateCurrentElement updateFn propertySpecFn builder =
    let
        elementConfig =
            Builder.getCurrentElement builder

        updatedProperties =
            List.map (updateFn propertySpecFn) elementConfig.properties

        updatedElement =
            { elementConfig | properties = updatedProperties }
    in
    Builder.updateCurrentElement updatedElement builder
