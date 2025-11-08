module Anim.Properties.Scale exposing (to, speed, duration, easing, delay)

{-| Scale animation property functions.

Use these functions to configure scale animations in the builder chain:

    Anim.init "my-element"
        |> Scale.to { x = 1.5, y = 1.5 }
        |> Scale.speed 2.0
        |> animate portFunction


# Scale Configuration

@docs to, speed, duration, easing, delay

-}

import Anim exposing (AnimBuilder)
import Anim.Timing.Easing exposing (Easing)



-- SCALE CONFIGURATION


{-| Set the target scale for the current element.

    builder |> Scale.to { x = 1.5, y = 1.5 }

-}
to : ScaleValue -> AnimBuilder -> AnimBuilder
to targetScale (AnimBuilder builderData) =
    let
        scaleConfig =
            ScaleConfig
                { target = targetScale
                , timing = Nothing
                , easing = Nothing
                , delay = Nothing
                }

        currentElement =
            getCurrentElement builderData

        updatedElement =
            { currentElement | properties = scaleConfig :: currentElement.properties }

        updatedData =
            updateCurrentElement updatedElement builderData
    in
    AnimBuilder updatedData


{-| Set animation speed for scale (scale units per second).

    builder |> Scale.speed 2.0

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed unitsPerSecond (AnimBuilder builderData) =
    let
        timing =
            Speed unitsPerSecond

        updatedData =
            updateScaleTiming builderData timing
    in
    AnimBuilder updatedData


{-| Set animation duration for scale (milliseconds).

    builder |> Scale.duration 2000

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration milliseconds (AnimBuilder builderData) =
    let
        timing =
            Duration milliseconds

        updatedData =
            updateScaleTiming builderData timing
    in
    AnimBuilder updatedData


{-| Set easing function for scale animation.

    builder |> Scale.easing EaseInOut

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing easingFunction (AnimBuilder builderData) =
    let
        updatedData =
            updateScaleEasing builderData easingFunction
    in
    AnimBuilder updatedData


{-| Set delay for scale animation (milliseconds).

    builder |> Scale.delay 500

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay milliseconds (AnimBuilder builderData) =
    let
        updatedData =
            updateScaleDelay builderData milliseconds
    in
    AnimBuilder updatedData



-- HELPER FUNCTIONS


updateScaleTiming : BuilderData -> Timing -> BuilderData
updateScaleTiming builderData timing =
    let
        elementConfig =
            getCurrentElement builderData

        updatedProperties =
            List.map (updateScaleProperty (\config -> { config | timing = Just timing })) elementConfig.properties

        updatedElement =
            { elementConfig | properties = updatedProperties }
    in
    updateCurrentElement updatedElement builderData


updateScaleEasing : BuilderData -> Easing -> BuilderData
updateScaleEasing builderData easingFunction =
    let
        elementConfig =
            getCurrentElement builderData

        updatedProperties =
            List.map (updateScaleProperty (\config -> { config | easing = Just easingFunction })) elementConfig.properties

        updatedElement =
            { elementConfig | properties = updatedProperties }
    in
    updateCurrentElement updatedElement builderData


updateScaleDelay : BuilderData -> Int -> BuilderData
updateScaleDelay builderData delayMs =
    let
        elementConfig =
            getCurrentElement builderData

        updatedProperties =
            List.map (updateScaleProperty (\config -> { config | delay = Just delayMs })) elementConfig.properties

        updatedElement =
            { elementConfig | properties = updatedProperties }
    in
    updateCurrentElement updatedElement builderData


updateScaleProperty : ({ target : ScaleValue, timing : Maybe Timing, easing : Maybe Easing, delay : Maybe Int } -> { target : ScaleValue, timing : Maybe Timing, easing : Maybe Easing, delay : Maybe Int }) -> PropertyConfig -> PropertyConfig
updateScaleProperty updateFn property =
    case property of
        ScaleConfig config ->
            ScaleConfig (updateFn config)

        other ->
            other
