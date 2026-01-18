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

import Anim.Easing exposing (Easing(..))
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
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


createFor : (Builder.PropertyConfig -> Maybe (Config a)) -> (Builder.ElementEndStates -> Maybe a) -> Config a -> String -> AnimBuilder -> Config a
createFor extractExisting extractBaseline defaultConfig_ elementId builder =
    let
        -- First check if we have a baseline (current animated state) for this element
        baselineValue =
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
                        -- CRITICAL: Also update end with baseline so property builders
                        -- (like Position.toX) copy from current animated values, not stale end values
                        case baselineValue of
                            Just baseline ->
                                baseline

                            Nothing ->
                                config.end
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
            -- New animation, check for baseline as starting point
            case baselineValue of
                Just baseline ->
                    applyGlobalDefaults builder { defaultConfig_ | start = Just baseline, end = baseline }

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
    let
        -- Auto-adjust bounce easings based on velocity before upserting
        adjustedConfig =
            adjustBounceEasing propertyConfig
    in
    case find (configsMatch adjustedConfig) builder of
        Just _ ->
            replace adjustedConfig builder

        Nothing ->
            add adjustedConfig builder


{-| Automatically adjust bounce and elastic easing strength based on animation velocity.
This creates realistic physics where faster movements produce bigger bounces and stronger oscillations.
-}
adjustBounceEasing : Builder.PropertyConfig -> Builder.PropertyConfig
adjustBounceEasing propertyConfig =
    case propertyConfig of
        Builder.PositionConfig config ->
            Builder.PositionConfig (adjustConfigEasing config)

        Builder.ScaleConfig config ->
            Builder.ScaleConfig (adjustConfigEasing config)

        Builder.RotateConfig config ->
            Builder.RotateConfig (adjustConfigEasing config)

        Builder.SizeConfig config ->
            Builder.SizeConfig (adjustConfigEasing config)

        Builder.OpacityConfig config ->
            Builder.OpacityConfig (adjustConfigEasing config)

        Builder.BackgroundColorConfig config ->
            Builder.BackgroundColorConfig (adjustConfigEasing config)

        Builder.FontColorConfig config ->
            Builder.FontColorConfig (adjustConfigEasing config)


{-| Adjust easing in a config if it's a custom bounce or elastic easing.
-}
adjustConfigEasing : { config | distance : Float, speed : Float, duration : Int, easing : Maybe Easing } -> { config | distance : Float, speed : Float, duration : Int, easing : Maybe Easing }
adjustConfigEasing config =
    case config.easing of
        Just (BounceOutCustom baseStrength) ->
            { config | easing = Just (BounceOutCustom (calculateAdjustedStrength baseStrength config)) }

        Just (BounceInCustom baseStrength) ->
            { config | easing = Just (BounceInCustom (calculateAdjustedStrength baseStrength config)) }

        Just (BounceInOutCustom ( baseStrengthIn, baseStrengthOut )) ->
            { config
                | easing =
                    Just
                        (BounceInOutCustom
                            ( calculateAdjustedStrength baseStrengthIn config
                            , calculateAdjustedStrength baseStrengthOut config
                            )
                        )
            }

        Just (ElasticOutCustom baseStrength) ->
            { config | easing = Just (ElasticOutCustom (calculateAdjustedStrength baseStrength config)) }

        Just (ElasticInCustom baseStrength) ->
            { config | easing = Just (ElasticInCustom (calculateAdjustedStrength baseStrength config)) }

        Just (ElasticInOutCustom ( baseStrengthIn, baseStrengthOut )) ->
            { config
                | easing =
                    Just
                        (ElasticInOutCustom
                            ( calculateAdjustedStrength baseStrengthIn config
                            , calculateAdjustedStrength baseStrengthOut config
                            )
                        )
            }

        _ ->
            config


{-| Calculate adjusted strength based on animation velocity.
Higher velocity animations get stronger effects for realistic physics.

For bounces: Higher velocity → bigger bounces (kinetic energy conversion)
For elastic: Higher velocity → stronger oscillations (spring compression)

Formula:

  - Calculate velocity = distance / duration (units per second)
  - Normalize velocity to 0-1 range (typical range varies by property type)
  - Blend base strength with velocity influence
  - Higher velocity → higher effective strength → bigger bounces/oscillations

-}
calculateAdjustedStrength : Float -> { config | distance : Float, speed : Float, duration : Int } -> Float
calculateAdjustedStrength baseStrength config =
    let
        -- Calculate animation duration from speed if available
        animDuration =
            if config.distance > 0 && config.speed > 0 then
                config.distance / config.speed * 1000

            else
                toFloat config.duration

        -- Calculate velocity in units per second
        velocity =
            if animDuration > 0 then
                config.distance / animDuration * 1000

            else
                0

        -- Normalize velocity to 0-1 range
        -- Typical range: 50-500 units/s for smooth animations
        -- (works for px, degrees, scale factors, opacity, RGB distance)
        -- 100 units/s = weak, 300 units/s = medium, 500+ = strong
        normalizedVelocity =
            clamp 0 1 (velocity / 500)

        -- Blend base strength with velocity influence
        -- 70% base strength, 30% velocity influence
        -- This preserves user intent while adding physics correlation
        velocityInfluence =
            0.3 * normalizedVelocity

        adjustedStrength =
            (baseStrength * 0.7) + velocityInfluence

        -- Clamp final value to valid range
        finalStrength =
            clamp 0.1 1.0 adjustedStrength
    in
    finalStrength


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
