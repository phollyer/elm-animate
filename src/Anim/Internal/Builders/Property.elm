module Anim.Internal.Builders.Property exposing
    ( add
    , applyGlobalDefaults
    , replace
    , upsert
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec)


applyGlobalDefaults :
    AnimBuilder
    -> { c | easing : Maybe Easing, delay : Maybe Int, timing : Maybe TimeSpec }
    -> { c | easing : Maybe Easing, delay : Maybe Int, timing : Maybe TimeSpec }
applyGlobalDefaults builder config =
    { config
        | easing =
            case config.easing of
                Just easing_ ->
                    Just easing_

                Nothing ->
                    Builder.getEasing builder
        , delay =
            case config.delay of
                Just delay_ ->
                    Just delay_

                Nothing ->
                    Builder.getDelay builder
        , timing =
            case config.timing of
                Just timing_ ->
                    Just timing_

                Nothing ->
                    Builder.getTimespec builder
    }


add : Builder.PropertyConfig -> AnimBuilder -> AnimBuilder
add propertyConfig builder =
    let
        currentElement =
            Builder.getCurrentElementConfig builder

        updatedElement =
            { currentElement | properties = currentElement.properties ++ [ propertyConfig ] }
    in
    Builder.updateCurrentElement updatedElement builder


replace : Builder.PropertyConfig -> AnimBuilder -> AnimBuilder
replace propertyConfig builder =
    let
        currentElement =
            Builder.getCurrentElementConfig builder

        updatedProperties =
            List.map
                (\p ->
                    if configsMatch p propertyConfig then
                        propertyConfig

                    else
                        p
                )
                currentElement.properties

        updatedElement =
            { currentElement | properties = updatedProperties }
    in
    Builder.updateCurrentElement updatedElement builder


upsert : Builder.PropertyConfig -> AnimBuilder -> AnimBuilder
upsert propertyConfig builder =
    case find (configsMatch propertyConfig) builder of
        Just _ ->
            replace propertyConfig builder

        Nothing ->
            add propertyConfig builder


find : (Builder.PropertyConfig -> Bool) -> AnimBuilder -> Maybe Builder.PropertyConfig
find predicate builder =
    let
        currentElement =
            Builder.getCurrentElementConfig builder
    in
    List.head (List.filter predicate currentElement.properties)


configsMatch : Builder.PropertyConfig -> Builder.PropertyConfig -> Bool
configsMatch prop1 prop2 =
    case ( prop1, prop2 ) of
        ( Builder.PositionConfig _, Builder.PositionConfig _ ) ->
            True

        ( Builder.RotateConfig _, Builder.RotateConfig _ ) ->
            True

        ( Builder.ScaleConfig _, Builder.ScaleConfig _ ) ->
            True

        ( Builder.ColorConfig _, Builder.ColorConfig _ ) ->
            True

        ( Builder.OpacityConfig _, Builder.OpacityConfig _ ) ->
            True

        _ ->
            False
