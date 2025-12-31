module Anim.Internal.Builders.Property exposing
    ( add
    , applyGlobalDefaults
    , createFor
    , defaultConfig
    , replace
    , upsert
    , withDelay
    , withDuration
    , withEasing
    , withPerspective
    , withSpeed
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))


type alias Config a =
    { start : Maybe a
    , end : a
    , easing : Maybe Easing
    , delay : Maybe Int
    , perspective : Maybe { containerId : String, value : Float }
    , timing : Maybe TimeSpec
    , duration : Int
    , speed : Float
    , distance : Float
    , isDirty : Bool
    }


defaultConfig : a -> Config a
defaultConfig defaultEnd =
    { start = Nothing
    , end = defaultEnd
    , duration = 0
    , speed = 0
    , distance = 0
    , timing = Nothing
    , delay = Nothing
    , easing = Nothing
    , perspective = Nothing
    , isDirty = False
    }


createFor : (Builder.PropertyConfig -> Maybe (Config a)) -> Config a -> String -> AnimBuilder -> Config a
createFor extractExisting defaultConfig_ elementId builder =
    let
        existingConfig =
            builder
                |> Builder.getElementConfig elementId
                |> Maybe.andThen
                    (\{ properties } ->
                        properties
                            |> List.filterMap extractExisting
                            |> List.head
                    )
    in
    case existingConfig of
        Just config ->
            applyGlobalDefaults builder
                { config
                    | start = Just config.end
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
            applyGlobalDefaults builder defaultConfig_


withSpeed :
    Float
    -> { config | speed : Float, timing : Maybe TimeSpec }
    -> { config | speed : Float, timing : Maybe TimeSpec }
withSpeed value config =
    { config
        | speed = value
        , timing = Just <| Speed value
    }


withDuration :
    Int
    -> { config | duration : Int, timing : Maybe TimeSpec }
    -> { config | duration : Int, timing : Maybe TimeSpec }
withDuration ms config =
    { config
        | duration = ms
        , timing = Just <| Duration ms
    }


withEasing :
    Easing
    -> { config | easing : Maybe Easing }
    -> { config | easing : Maybe Easing }
withEasing easing_ config =
    { config | easing = Just easing_ }


withDelay :
    Int
    -> { config | delay : Maybe Int }
    -> { config | delay : Maybe Int }
withDelay delay_ config =
    { config | delay = Just delay_ }


withPerspective :
    String
    -> Float
    -> { config | perspective : Maybe { containerId : String, value : Float } }
    -> { config | perspective : Maybe { containerId : String, value : Float } }
withPerspective containerId value config =
    { config | perspective = Just { containerId = containerId, value = value } }


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
            List.filter (not << configsMatch propertyConfig) currentElement.properties
                ++ [ propertyConfig ]

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

        ( Builder.BackgroundColorConfig _, Builder.BackgroundColorConfig _ ) ->
            True

        ( Builder.OpacityConfig _, Builder.OpacityConfig _ ) ->
            True

        ( Builder.SizeConfig _, Builder.SizeConfig _ ) ->
            True

        _ ->
            False
