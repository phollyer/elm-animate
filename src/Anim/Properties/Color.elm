module Anim.Properties.Color exposing (to, speed, duration, easing, delay)

{-| Color animation property functions.

Use these functions to configure color animations in the builder chain:

    Anim.init "my-element"
        |> Color.to (Hex "#ff0000")
        |> Color.speed 255
        |> animate portFunction


# Color Configuration

@docs to, speed, duration, easing, delay

-}

import Anim exposing (AnimBuilder)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Properties.Color exposing (Color(..))
import Anim.Timing.Easing exposing (Easing)



-- COLOR CONFIGURATION


{-| Set the target color for the current element.

    builder |> Color.to (Hex "#ff0000")

    builder |> Color.to (Rgb { r = 255, g = 0, b = 0 })

-}
to : Color -> AnimBuilder -> AnimBuilder
to targetColor builder =
    let
        colorConfig =
            Builder.ColorConfig targetColor
                { timing = Nothing
                , easing = Nothing
                , delay = Nothing
                }

        currentElement =
            Builder.getCurrentElement builder

        updatedElement =
            { currentElement | properties = colorConfig :: currentElement.properties }
    in
    Builder.updateCurrentElement updatedElement builder


{-| Set animation speed for color (color value units per second).

    builder |> Color.speed 255

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed unitsPerSecond builder =
    let
        timing =
            Speed unitsPerSecond
    in
    updateTiming timing builder


updateTiming : TimeSpec -> AnimBuilder -> AnimBuilder
updateTiming timing builder =
    let
        elementConfig =
            Builder.getCurrentElement builder

        updatedProperties =
            List.map (updateProperties (\config -> { config | timing = Just timing })) elementConfig.properties

        updatedElement =
            { elementConfig | properties = updatedProperties }
    in
    Builder.updateCurrentElement updatedElement builder


{-| Set animation duration for color (milliseconds).

    builder |> Color.duration 2000

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration milliseconds builder =
    let
        timing =
            Duration milliseconds
    in
    updateTiming timing builder


{-| Set easing function for color animation.

    builder |> Color.easing EaseInOut

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing easingFunction builder =
    let
        elementConfig =
            Builder.getCurrentElement builder

        updatedProperties =
            List.map (updateProperties (\config -> { config | easing = Just easingFunction })) elementConfig.properties

        updatedElement =
            { elementConfig | properties = updatedProperties }
    in
    Builder.updateCurrentElement updatedElement builder


{-| Set delay for color animation (milliseconds).

    builder |> Color.delay 500

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay milliseconds builder =
    let
        elementConfig =
            Builder.getCurrentElement builder

        updatedProperties =
            List.map (updateProperties (\config -> { config | delay = Just milliseconds })) elementConfig.properties

        updatedElement =
            { elementConfig | properties = updatedProperties }
    in
    Builder.updateCurrentElement updatedElement builder



-- HELPER FUNCTIONS


updateProperties : (Builder.UniversalPropertyData -> Builder.UniversalPropertyData) -> Builder.PropertyConfig -> Builder.PropertyConfig
updateProperties updateFn property =
    case property of
        Builder.ColorConfig value config ->
            Builder.ColorConfig value (updateFn config)

        other ->
            other
