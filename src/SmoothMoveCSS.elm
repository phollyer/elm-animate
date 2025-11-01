module SmoothMoveCSS exposing
    ( Config
    , defaultConfig
    , Position
    , Timing(..)
    , Model
    , init
    , setPosition
    , animateTo
    , animateToX
    , animateToY
    , getPosition
    , transform
    , transformElement
    , transformPosition
    , transition
    , transitionWithDistance
    , transitionWithSpeed
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
  - Multiple element management with Model-based state


# Configuration

@docs Config
@docs defaultConfig
@docs Position
@docs Timing


# Model Management

@docs Model
@docs init
@docs setPosition
@docs animateTo
@docs animateToX
@docs animateToY
@docs getPosition


# CSS Generation

@docs transform
@docs transformElement
@docs transformPosition
@docs transition
@docs transitionWithDistance
@docs transitionWithSpeed
@docs calculateDuration


# CSS Transition Events

@docs onTransitionStart
@docs onTransitionEnd
@docs onTransitionRun
@docs onTransitionCancel

-}

import Dict exposing (Dict)
import Html exposing (Attribute)
import Html.Events exposing (on)
import Json.Decode as Decode


{-| Position type alias for X and Y coordinates
-}
type alias Position =
    { x : Float
    , y : Float
    }


{-| Animation timing configuration

Choose between speed-based or duration-based timing:

  - Speed: Animation speed in pixels per second (higher = faster)
  - Duration: Animation duration in milliseconds (higher = slower)

-}
type Timing
    = Speed Float
    | Duration Int


{-| Configuration for CSS-based animations

  - timing: Animation timing (Speed in pixels per second or Duration in milliseconds)
  - easing: CSS easing function ("ease-out", "cubic-bezier(0.4, 0.0, 0.2, 1)", etc.)

-}
type alias Config =
    { timing : Timing
    , easing : String
    }


{-| Default configuration with smooth easing
-}
defaultConfig : Config
defaultConfig =
    { timing = Duration 400
    , easing = "cubic-bezier(0.4, 0.0, 0.2, 1)" -- Material Design's "standard" easing
    }


{-| Model for tracking multiple element positions

Uses a Dict for O(1) position lookups and efficient management of many elements.

-}
type Model
    = Model (Dict String Position)


{-| Initialize an empty model with no element positions

    initialModel =
        init

-}
init : Model
init =
    Model Dict.empty


{-| Set the position for an element

If not set, the element defaults to (0,0):

    model
        |> setPosition "box1" 100 150
        |> setPosition "box2" 200 250

-}
setPosition : String -> Float -> Float -> Model -> Model
setPosition elementId x y (Model positions) =
    Model (Dict.insert elementId { x = x, y = y } positions)


{-| Update an element's position for CSS animation

This function updates the model state. Apply the position in your view with `transform`:

    -- In update
    AnimateBox ->
        { model | animations = animateTo "box" 300 200 model.animations }

    -- In view
    div
        [ style "transform" (transform "box" model.animations)
        , style "transition" (transition defaultConfig)
        ]
        [ text "Animated box" ]

-}
animateTo : String -> Float -> Float -> Model -> Model
animateTo elementId x y (Model positions) =
    Model (Dict.insert elementId { x = x, y = y } positions)


{-| Animate element horizontally to target X position

Only the X coordinate will change - Y position remains at current value.
Uses default configuration.

    model.animations = animateToX "box" 300 model.animations

-}
animateToX : String -> Float -> Model -> Model
animateToX elementId x (Model positions) =
    let
        currentPos =
            Dict.get elementId positions
                |> Maybe.withDefault { x = 0, y = 0 }
    in
    Model (Dict.insert elementId { x = x, y = currentPos.y } positions)


{-| Animate element vertically to target Y position

Only the Y coordinate will change - X position remains at current value.
Uses default configuration.

    model.animations = animateToY "box" 200 model.animations

-}
animateToY : String -> Float -> Model -> Model
animateToY elementId y (Model positions) =
    let
        currentPos =
            Dict.get elementId positions
                |> Maybe.withDefault { x = 0, y = 0 }
    in
    Model (Dict.insert elementId { x = currentPos.x, y = y } positions)


{-| Get the current position of an element

Returns `Nothing` if the element hasn't been positioned yet:

    case getPosition "box" model.animations of
        Just pos ->
            text ("Box is at " ++ String.fromFloat pos.x ++ ", " ++ String.fromFloat pos.y)

        Nothing ->
            text "Box position not set"

-}
getPosition : String -> Model -> Maybe Position
getPosition elementId (Model positions) =
    Dict.get elementId positions


{-| Generate CSS transform string for a specific element

    div
        [ style "transform" (transformElement "box" model.animations)
        , style "transition" (transition defaultConfig)
        ]
        [ text "Box" ]

-}
transformElement : String -> Model -> String
transformElement elementId (Model positions) =
    case Dict.get elementId positions of
        Just pos ->
            transformPosition pos

        Nothing ->
            transformPosition { x = 0, y = 0 }


{-| Create a CSS transform string for positioning

    div
        [ style "transform" (SmoothMoveCSS.transform 100 200) ]
        [ text "Positioned at (100, 200)" ]

-}
transform : Float -> Float -> String
transform x y =
    "translate(" ++ String.fromFloat x ++ "px, " ++ String.fromFloat y ++ "px)"


{-| Create a CSS transform string from a Position record

    let
        pos =
            { x = 150, y = 250 }
    in
    div
        [ style "transform" (SmoothMoveCSS.transformPosition pos) ]
        [ text "Positioned at (150, 250)" ]

-}
transformPosition : Position -> String
transformPosition pos =
    transform pos.x pos.y


{-| Generate CSS transition property with custom configuration

Creates a transition for the transform property with your configuration.
For default configuration, pass `defaultConfig`.

    div
        [ style "transform" (SmoothMoveCSS.transform targetX targetY)
        , style "transition" (SmoothMoveCSS.transition SmoothMoveCSS.defaultConfig)
        ]
        [ text "Animated element" ]

    -- Or with custom config
    customConfig =
        { defaultConfig | timing = Speed 200, easing = "ease-in-out" }

    div
        [ style "transform" (SmoothMoveCSS.transform targetX targetY)
        , style "transition" (SmoothMoveCSS.transition customConfig)
        ]
        [ text "Custom animated element" ]

-}
transition : Config -> String
transition config =
    transitionWithConfig config 0


{-| Generate CSS transition property with distance-based duration

Calculates duration based on the distance traveled and timing configuration.
Use this when you want the animation speed to feel consistent regardless of distance.

    let
        distance =
            sqrt ((targetX - currentX) ^ 2 + (targetY - currentY) ^ 2)
    in
    div
        [ style "transform" (SmoothMoveCSS.transform targetX targetY)
        , style "transition" (SmoothMoveCSS.transitionWithDistance distance defaultConfig)
        ]
        [ text "Animated element" ]

-}
transitionWithDistance : Float -> Config -> String
transitionWithDistance distance config =
    transitionWithConfig config distance


{-| Generate CSS transition property with speed-based timing

This is a convenience function for creating transitions with Speed-based timing.
Calculates the duration based on the distance and speed (pixels per second).

    let
        -- pixels to travel
        distance =
            100

        -- pixels per second
        speed =
            200
    in
    div
        [ style "transform" (SmoothMoveCSS.transform targetX targetY)
        , style "transition" (SmoothMoveCSS.transitionWithSpeed speed distance defaultConfig)
        ]
        [ text "Speed-based animated element" ]

-}
transitionWithSpeed : Float -> Float -> Config -> String
transitionWithSpeed speed distance config =
    let
        duration =
            (distance / speed) * 1000

        -- Convert to milliseconds
    in
    "transform " ++ String.fromFloat duration ++ "ms " ++ config.easing


{-| Calculate animation duration in milliseconds based on distance and timing config

Useful for coordinating animations or knowing when transitions will complete.


    duration =
        calculateDuration defaultConfig ( 100, 200 ) ( 300, 150 )

    -- Returns duration in milliseconds for moving from (100,200) to (300,150)

-}
calculateDuration : Config -> ( Float, Float ) -> ( Float, Float ) -> Float
calculateDuration config ( fromX, fromY ) ( toX, toY ) =
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
        , style "transition" (SmoothMoveCSS.transition SmoothMoveCSS.defaultConfig)
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
        , style "transition" (SmoothMoveCSS.transition SmoothMoveCSS.defaultConfig)
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
        , style "transition" (SmoothMoveCSS.transition SmoothMoveCSS.defaultConfig)
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
        , style "transition" (SmoothMoveCSS.transition SmoothMoveCSS.defaultConfig)
        , SmoothMoveCSS.onTransitionCancel TransitionCancelled
        ]
        [ text "Animated element" ]

-}
onTransitionCancel : msg -> Attribute msg
onTransitionCancel msg =
    on "transitioncancel" (Decode.succeed msg)
