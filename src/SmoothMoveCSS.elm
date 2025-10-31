module SmoothMoveCSS exposing
    ( Config
    , defaultConfig
    , Timing(..)
    , Axis(..)
    , transform
    , transition
    , transitionWithDistance
    , calculateDuration
    , onTransitionStart
    , onTransitionEnd
    , onTransitionRun
    , onTransitionCancel
    )

{-| A CSS-based animation library that leverages native browser transitions for smooth element movement.

This module generates CSS properties for transitions, letting the browser handle all animation logic:

  - Better performance through native browser optimization
  - Smooth animations even when JavaScript is busy
  - Automatic easing handled by CSS
  - Less CPU usage compared to frame-based animation
  - No state management required


# Configuration

@docs Config
@docs defaultConfig
@docs Timing
@docs Axis


# CSS Generation

@docs transform
@docs transition
@docs transitionWithDistance
@docs calculateDuration


# CSS Transition Events

@docs onTransitionStart
@docs onTransitionEnd
@docs onTransitionRun
@docs onTransitionCancel

-}

import Html exposing (Attribute)
import Html.Events exposing (on)
import Json.Decode as Decode


{-| Animation timing configuration

Choose between speed-based or duration-based timing:

  - Speed: Animation speed in pixels per second (higher = faster)
  - Duration: Animation duration in milliseconds (higher = slower)

-}
type Timing
    = Speed Float
    | Duration Int


{-| Animation axis constraint
-}
type Axis
    = X
    | Y
    | Both


{-| Configuration for CSS-based animations

  - axis: Movement axis (X, Y, or Both) - currently unused but kept for API consistency
  - timing: Animation timing (Speed in pixels per second or Duration in milliseconds)
  - easing: CSS easing function ("ease-out", "cubic-bezier(0.4, 0.0, 0.2, 1)", etc.)

-}
type alias Config =
    { axis : Axis
    , timing : Timing
    , easing : String
    }


{-| Default configuration with smooth easing
-}
defaultConfig : Config
defaultConfig =
    { axis = Both
    , timing = Duration 400
    , easing = "cubic-bezier(0.4, 0.0, 0.2, 1)" -- Material Design's "standard" easing
    }


{-| Create a CSS transform string for positioning

    div
        [ style "transform" (SmoothMoveCSS.transform 100 200) ]
        [ text "Positioned at (100, 200)" ]

-}
transform : Float -> Float -> String
transform x y =
    "translate(" ++ String.fromFloat x ++ "px, " ++ String.fromFloat y ++ "px)"


{-| Generate CSS transition property with default timing

Creates a transition for the transform property with default configuration.

    div
        [ style "transform" (SmoothMoveCSS.transform targetX targetY)
        , style "transition" SmoothMoveCSS.transition
        ]
        [ text "Animated element" ]

-}
transition : String
transition =
    transitionWithConfig defaultConfig 0


{-| Generate CSS transition property with distance-based duration

Calculates duration based on the distance traveled and timing configuration.
Use this when you want the animation speed to feel consistent regardless of distance.

    let
        distance =
            sqrt ((targetX - currentX) ^ 2 + (targetY - currentY) ^ 2)
    in
    div
        [ style "transform" (SmoothMoveCSS.transform targetX targetY)
        , style "transition" (SmoothMoveCSS.transitionWithDistance defaultConfig distance)
        ]
        [ text "Animated element" ]

-}
transitionWithDistance : Config -> Float -> String
transitionWithDistance config distance =
    transitionWithConfig config distance


{-| Calculate animation duration in milliseconds based on distance and timing config

Useful for coordinating animations or knowing when transitions will complete.


    duration =
        calculateDuration defaultConfig 100 200 300 150

    -- Returns duration in milliseconds for moving from (100,200) to (300,150)

-}
calculateDuration : Config -> Float -> Float -> Float -> Float -> Float
calculateDuration config fromX fromY toX toY =
    let
        distance =
            sqrt ((toX - fromX) ^ 2 + (toY - fromY) ^ 2)
    in
    timingToMilliseconds config.timing distance


{-| Internal helper to generate transition property
-}
transitionWithConfig : Config -> Float -> String
transitionWithConfig config distance =
    let
        duration =
            timingToMilliseconds config.timing distance
    in
    "transform " ++ String.fromFloat duration ++ "ms " ++ config.easing


{-| Convert timing configuration to milliseconds for CSS transitions
-}
timingToMilliseconds : Timing -> Float -> Float
timingToMilliseconds timing distance =
    case timing of
        Speed pixelsPerSecond ->
            if pixelsPerSecond <= 0 then
                400
                -- Fallback to default duration

            else
                -- Convert pixels per second to duration: distance / speed = seconds, then * 1000 for ms
                max 50 ((distance / pixelsPerSecond) * 1000)

        -- Minimum 50ms duration
        Duration milliseconds ->
            max 50 (toFloat milliseconds)



-- CSS TRANSITION EVENT HANDLERS


{-| Listen for when a CSS transition starts

    div
        [ style "transform" (SmoothMoveCSS.transform x y)
        , style "transition" SmoothMoveCSS.transition
        , SmoothMoveCSS.onTransitionStart TransitionStarted
        ]
        [ text "Animated element" ]

-}
onTransitionStart : msg -> Attribute msg
onTransitionStart msg =
    on "transitionstart" (Decode.succeed msg)


{-| Listen for when a CSS transition completes

    div
        [ style "transform" (SmoothMoveCSS.transform x y)
        , style "transition" SmoothMoveCSS.transition
        , SmoothMoveCSS.onTransitionEnd TransitionCompleted
        ]
        [ text "Animated element" ]

This is the most commonly used transition event for coordinating animations
or updating UI state when animations finish.

-}
onTransitionEnd : msg -> Attribute msg
onTransitionEnd msg =
    on "transitionend" (Decode.succeed msg)


{-| Listen for when a CSS transition is created (even if delayed)

This event fires when a transition is created, even if it has a delay.
It fires before transitionstart.

    div
        [ style "transform" (SmoothMoveCSS.transform x y)
        , style "transition" SmoothMoveCSS.transition
        , SmoothMoveCSS.onTransitionRun TransitionCreated
        ]
        [ text "Animated element" ]

-}
onTransitionRun : msg -> Attribute msg
onTransitionRun msg =
    on "transitionrun" (Decode.succeed msg)


{-| Listen for when a CSS transition is cancelled

This happens when a transition is interrupted before completion,
such as when the element is removed or another transition starts.

    div
        [ style "transform" (SmoothMoveCSS.transform x y)
        , style "transition" SmoothMoveCSS.transition
        , SmoothMoveCSS.onTransitionCancel TransitionCancelled
        ]
        [ text "Animated element" ]

-}
onTransitionCancel : msg -> Attribute msg
onTransitionCancel msg =
    on "transitioncancel" (Decode.succeed msg)
