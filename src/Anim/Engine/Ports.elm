module Anim.Engine.Ports exposing
    ( animate, animateBatch
    , ElementId
    , init, builder, AnimationState
    , duration, speed
    , easing
    , delay
    , getPosition, getCurrentStyles
    , htmlAttributes
    )

{-| Ports-based animation system for Anim.

This module converts AnimBuilder configurations to JavaScript Web Animations API calls
via Elm ports for maximum performance and browser compatibility.


# Animation Execution

@docs animate, animateBatch

@docs ElementId

@docs init, builder, AnimationState


# Global Settings

These settings will be used for all animations unless overridden on a per-animation basis.


## Timing

@docs duration, speed


## Easing

@docs easing


## Delay

@docs delay


# Animation Data

@docs getPosition, getCurrentStyles


# JavaScript Integration

@docs htmlAttributes

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Ports as InternalPorts
import Anim.Internal.Properties.Position exposing (Position)
import Anim.Timing.Easing as Easing exposing (Easing)
import Html
import Json.Encode as Encode


type alias AnimBuilder =
    Builder.AnimBuilder



-- ANIMATION STATE


{-| State for managing ports-based animations.
-}
type alias AnimationState =
    InternalPorts.AnimationState



-- ANIMATION EXECUTION


{-| The ID of the target element to animate.
-}
type alias ElementId =
    String


{-| Initialize empty animation builder.
-}
init : AnimationState
init =
    InternalPorts.init


{-| Turn the AnimationState into an AnimBuilder.

Use this to start new animations based on current state.

    -- Start a new animation based on current state
    newBuilder =
        model.animations
            |> Ports.builder
            |> Position.for "element"
            |> Position.to { x = 100, y = 200 }
            |> Position.build
            |> Ports.animate

-}
builder : AnimationState -> AnimBuilder
builder =
    InternalPorts.builder


{-| Execute stateful animation using JavaScript Web Animations API via ports.

Returns updated animation state and encoded animation data for ports.

    let
        ( newAnimationState, animationData ) =
            Ports.builder model.animationState
                |> Position.for "my-element"
                |> Position.to { x = 100, y = 200 }
                |> Position.speed 500
                |> Position.build
                |> Ports.animate model.animationState
    in
    ( { model | animationState = newAnimationState }
    , sendAnimationCommand animationData
    )

-}
animate : AnimationState -> AnimBuilder -> ( AnimationState, Encode.Value )
animate =
    InternalPorts.animate


{-| Execute animations using JavaScript Web Animations API via ports (stateless).

For state management and position continuity, use `animate` instead.

    Anim.init "my-element"
        |> Position.to { x = 100, y = 200 }
        |> Position.speed 500
        |> Ports.animateStateless sendAnimationCommand

The port function should have the signature:

    port sendAnimationCommand : Encode.Value -> Cmd msg

-}
animateStateless : (Encode.Value -> Cmd msg) -> AnimBuilder -> Cmd msg
animateStateless portFunction animBuilder =
    let
        processedData =
            Builder.processAnimationData animBuilder

        encodedData =
            Builder.encode processedData
    in
    portFunction encodedData


{-| Batch and send a List of animations in one go.

    createCircleAnimation index elementId =
        let
            angle =
                toFloat index * angleStep

            x =
                centerX + radius * cos angle

            y =
                centerY + radius * sin angle
        in
        Anim.init elementId
            |> Position.to { x = x, y = y }
            |> Position.duration 1000
            |> Position.easing Easing.easeInOut

    cmd1 =
        Anim.animateBatch animateElement <|
            [ createCircleAnimation 0 "element1"
            , createCircleAnimation 1 "element2"
            , createCircleAnimation 2 "element3"
            , createCircleAnimation 3 "element4"
            , createCircleAnimation 4 "element5"
            , createCircleAnimation 5 "element6"
            , createCircleAnimation 6 "element7"
            , createCircleAnimation 7 "element8"
            , createCircleAnimation 8 "element9"
            , createCircleAnimation 9 "element10"
            , createCircleAnimation 10 "element11"
            , createCircleAnimation 11 "element12"
            , createCircleAnimation 12 "element13"
            ]

-}
animateBatch : (Encode.Value -> Cmd msg) -> List AnimBuilder -> Cmd msg
animateBatch portFunction builders =
    builders
        |> List.map (animateStateless portFunction)
        |> Cmd.batch



-- ANIMATION DATA


{-| Get current position of an element.
-}
getPosition : String -> AnimationState -> Maybe Position
getPosition =
    InternalPorts.getPosition


{-| Get current styles for an element (for debugging/display purposes).
-}
getCurrentStyles : String -> AnimationState -> List ( String, String )
getCurrentStyles =
    InternalPorts.getCurrentStyles


{-| Set global duration in milliseconds (overrides any previous speed setting).

    Ports.init
        |> Ports.duration 1000
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Ports.animate

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalPorts.duration


{-| Set global speed in units per second (overrides any previous duration setting).

    Ports.init
        |> Ports.speed 100
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Ports.animate

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalPorts.speed


{-| Set global easing function.

    Ports.init
        |> Ports.easing EaseInOutQuad
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Ports.animate

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Easing.mapInternal InternalPorts.easing


{-| Set global delay in milliseconds.

    Ports.init
        |> Ports.delay 500
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Ports.animate

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalPorts.delay


{-| Generate HTML attributes for ports-based animations.

This function provides a way to add animation data attributes to elements,
which can be useful for debugging or JavaScript integration.

-}
htmlAttributes : String -> AnimationState -> List (Html.Attribute msg)
htmlAttributes =
    InternalPorts.htmlAttributes
