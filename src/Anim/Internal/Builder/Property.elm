module Anim.Internal.Builder.Property exposing
    ( add
    , applyGlobalDefaults
    , createFor
    , defaultConfig
    , replace
    , upsert
    , withDelay
    , withDuration
    , withEasing
    , withSpeed
    )

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))


type alias Config a =
    { start : Maybe a
    , end : a
    , easing : Maybe Easing
    , delay : Maybe Int
    , timing : Maybe TimeSpec
    , distance : Float
    }


defaultConfig : a -> Config a
defaultConfig defaultEnd =
    { start = Nothing
    , end = defaultEnd
    , distance = 0
    , timing = Nothing
    , delay = Nothing
    , easing = Nothing
    }


createFor : String -> (Builder.PropertyConfig -> Maybe (Config a)) -> (Builder.ElementEndStates -> Maybe a) -> Config a -> String -> AnimBuilder -> Config a
createFor propertyName extractExisting extractBaseline defaultConfig_ elementId builder =
    let
        -- First check if we have a baseline (current animated state) for this element.
        -- When a target element is set (e.g., via forElement "cube"), prefer the composite
        -- key baseline ("cube:cubeAnim") over the plain key ("cubeAnim"), since the
        -- composite entry reflects the most recent animation end state for that element.
        baselineValue =
            let
                compositeBaseline =
                    Builder.getTargetElement builder
                        |> Maybe.andThen
                            (\target ->
                                builder
                                    |> Builder.getElementBaseline (Builder.makeCompositeKey target elementId)
                                    |> Maybe.andThen extractBaseline
                            )
            in
            case compositeBaseline of
                Just _ ->
                    compositeBaseline

                Nothing ->
                    builder
                        |> Builder.getElementBaseline elementId
                        |> Maybe.andThen extractBaseline

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
                    | start =
                        -- Use baseline if available, otherwise fall back to config.end
                        case baselineValue of
                            Just baseline ->
                                Just baseline

                            Nothing ->
                                Just config.end
                    , end =
                        config.end
                    , easing = Nothing
                    , delay = Nothing
                    , timing = Nothing
                    , distance = 0
                }

        Nothing ->
            let
                targetValue =
                    builder
                        |> Builder.getElementTarget elementId
                        |> Maybe.andThen extractBaseline
            in
            case ( baselineValue, targetValue ) of
                ( Just baseline, Just target ) ->
                    applyGlobalDefaults builder { defaultConfig_ | start = Just baseline, end = target }

                ( Just baseline, Nothing ) ->
                    applyGlobalDefaults builder { defaultConfig_ | start = Just baseline, end = baseline }

                ( Nothing, Just target ) ->
                    applyGlobalDefaults builder { defaultConfig_ | start = Just target, end = target }

                ( Nothing, Nothing ) ->
                    applyGlobalDefaults builder defaultConfig_


withSpeed :
    Float
    -> { config | timing : Maybe TimeSpec }
    -> { config | timing : Maybe TimeSpec }
withSpeed value config =
    { config | timing = Just <| Speed value }


withDuration :
    Int
    -> { config | timing : Maybe TimeSpec }
    -> { config | timing : Maybe TimeSpec }
withDuration ms config =
    { config | timing = Just <| Duration ms }


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
                    Builder.getTimeSpec builder
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
        ( Builder.TranslateConfig _, Builder.TranslateConfig _ ) ->
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
