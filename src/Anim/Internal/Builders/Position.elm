module Anim.Internal.Builders.Position exposing
    ( to, speed, duration, easing, delay
    , Position
    )

{-| Position animation property functions.

Use these functions to configure position animations in the builder chain:

    Anim.init "my-element"
        |> Position.to { x = 100, y = 200 }
        |> Position.speed 500
        |> animate portFunction


# Position Configuration

@doc Position

@docs to, speed, duration, easing, delay

-}

import Anim.Internal.Builder as Builder exposing (AnimBuilder, PropertyConfig(..), TimeSpec(..))
import Anim.Internal.Properties.Position as Position
import Anim.Timing.Easing exposing (Easing)



-- POSITION CONFIGURATION


{-| 2D position type.
-}
type alias Position =
    Position.Position


{-| Set the target position for the current element.

    builder |> Position.to { x = 100, y = 200 }

-}
to : Position -> AnimBuilder -> AnimBuilder
to targetPosition builder =
    let
        positionConfig =
            PositionConfig targetPosition
                { timing = Nothing
                , easing = Nothing
                , delay = Nothing
                }

        currentElement =
            Builder.getCurrentElement builder

        updatedElement =
            { currentElement | properties = positionConfig :: currentElement.properties }
    in
    Builder.updateCurrentElement updatedElement builder


{-| Set animation speed for position (pixels per second).

    builder |> Position.speed 500

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed pixelsPerSecond builder =
    let
        timing =
            Speed pixelsPerSecond
    in
    updatePositionTiming timing builder


{-| Set animation duration for position (milliseconds).

    builder |> Position.duration 2000

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration milliseconds builder =
    let
        timing =
            Duration milliseconds
    in
    updatePositionTiming timing builder


{-| Set easing function for position animation.

    builder |> Position.easing Ease.inOutQuad

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing easingFunction builder =
    let
        elementConfig =
            Builder.getCurrentElement builder

        updatedProperties =
            List.map (updatePositionValue (\config -> { config | easing = Just easingFunction })) elementConfig.properties

        updatedElement =
            { elementConfig | properties = updatedProperties }
    in
    Builder.updateCurrentElement updatedElement builder


{-| Set delay for position animation (milliseconds).

    builder |> Position.delay 500

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay milliseconds builder =
    let
        elementConfig =
            Builder.getCurrentElement builder

        updatedProperties =
            List.map (updatePositionValue (\config -> { config | delay = Just milliseconds })) elementConfig.properties

        updatedElement =
            { elementConfig | properties = updatedProperties }
    in
    Builder.updateCurrentElement updatedElement builder



-- HELPER FUNCTIONS


updatePositionTiming : TimeSpec -> AnimBuilder -> AnimBuilder
updatePositionTiming timing builder =
    let
        elementConfig =
            Builder.getCurrentElement builder

        updatedProperties =
            List.map (updatePositionValue (\config -> { config | timing = Just timing })) elementConfig.properties

        updatedElement =
            { elementConfig | properties = updatedProperties }
    in
    Builder.updateCurrentElement updatedElement builder


updatePositionValue : (Builder.UniversalPropertyData -> Builder.UniversalPropertyData) -> PropertyConfig -> PropertyConfig
updatePositionValue updateFn property =
    case property of
        PositionConfig position config ->
            PositionConfig position (updateFn config)

        other ->
            other
