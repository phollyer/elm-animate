module Anim.Properties.Rotate exposing (to, speed, duration, easing, delay)

{-| Rotation animation property functions.

Use these functions to configure rotation animations in the builder chain:

    Anim.init "my-element"
        |> Rotate.to 180
        |> Rotate.speed 90
        |> animate portFunction


# Rotation Configuration

@docs to, speed, duration, easing, delay

-}

import Anim exposing (AnimBuilder)
import Anim.Internal.Builder as Builder exposing (PropertyConfig(..))
import Anim.Timing.Easing exposing (Easing)



-- ROTATION CONFIGURATION


{-| Set the target rotation angle for the current element (in degrees).

    builder |> Rotate.to 180

-}
to : RotationValue -> AnimBuilder -> AnimBuilder
to targetRotation (AnimBuilder builderData) =
    let
        rotateConfig =
            RotateConfig
                { target = targetRotation
                , timing = Nothing
                , easing = Nothing
                , delay = Nothing
                }

        currentElement =
            getCurrentElement builderData

        updatedElement =
            { currentElement | properties = rotateConfig :: currentElement.properties }

        updatedData =
            updateCurrentElement updatedElement builderData
    in
    AnimBuilder updatedData


{-| Set animation speed for rotation (degrees per second).

    builder |> Rotate.speed 90

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed degreesPerSecond (AnimBuilder builderData) =
    let
        timing =
            Speed degreesPerSecond

        updatedData =
            updateRotationTiming builderData timing
    in
    AnimBuilder updatedData


{-| Set animation duration for rotation (milliseconds).

    builder |> Rotate.duration 2000

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration milliseconds (AnimBuilder builderData) =
    let
        timing =
            Duration milliseconds

        updatedData =
            updateRotationTiming builderData timing
    in
    AnimBuilder updatedData


{-| Set easing function for rotation animation.

    builder |> Rotate.easing EaseInOut

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing easingFunction (AnimBuilder builderData) =
    let
        updatedData =
            updateRotationEasing builderData easingFunction
    in
    AnimBuilder updatedData


{-| Set delay for rotation animation (milliseconds).

    builder |> Rotate.delay 500

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay milliseconds (AnimBuilder builderData) =
    let
        updatedData =
            updateRotationDelay builderData milliseconds
    in
    AnimBuilder updatedData



-- HELPER FUNCTIONS


updateRotationTiming : BuilderData -> Timing -> BuilderData
updateRotationTiming builderData timing =
    let
        elementConfig =
            getCurrentElement builderData

        updatedProperties =
            List.map (updateRotationProperty (\config -> { config | timing = Just timing })) elementConfig.properties

        updatedElement =
            { elementConfig | properties = updatedProperties }
    in
    updateCurrentElement updatedElement builderData


updateRotationEasing : BuilderData -> Easing -> BuilderData
updateRotationEasing builderData easingFunction =
    let
        elementConfig =
            getCurrentElement builderData

        updatedProperties =
            List.map (updateRotationProperty (\config -> { config | easing = Just easingFunction })) elementConfig.properties

        updatedElement =
            { elementConfig | properties = updatedProperties }
    in
    updateCurrentElement updatedElement builderData


updateRotationDelay : BuilderData -> Int -> BuilderData
updateRotationDelay builderData delayMs =
    let
        elementConfig =
            getCurrentElement builderData

        updatedProperties =
            List.map (updateRotationProperty (\config -> { config | delay = Just delayMs })) elementConfig.properties

        updatedElement =
            { elementConfig | properties = updatedProperties }
    in
    updateCurrentElement updatedElement builderData


updateRotationProperty : ({ target : RotationValue, timing : Maybe Timing, easing : Maybe Easing, delay : Maybe Int } -> { target : RotationValue, timing : Maybe Timing, easing : Maybe Easing, delay : Maybe Int }) -> PropertyConfig -> PropertyConfig
updateRotationProperty updateFn property =
    case property of
        RotateConfig config ->
            RotateConfig (updateFn config)

        other ->
            other
