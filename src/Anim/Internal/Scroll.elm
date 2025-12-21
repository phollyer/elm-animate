module Anim.Internal.Scroll exposing
    ( AnimBuilder
    , AnimationMsg(..)
    , AnimationState
    , addScrollTarget
    , animate
    , builder
    , delay
    , duration
    , easing
    , getContainer
    , getDuration
    , getGlobalSettings
    , getScrollPosition
    , getScrollPositionX
    , getScrollPositionXY
    , getScrollPositionY
    , getScrollTargets
    , htmlAttributes
    , init
    , isAnimationRunning
    , setAxis
    , setContainer
    , speed
    , update
    )

{-| Internal implementation for subscription-based scroll animations.

This module provides the core functionality for the Scroll engine, handling
frame-based scroll animations with state management.

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.ScrollTarget as ScrollTarget exposing (ScrollTarget)
import Anim.Internal.Timing.Easing as Easing exposing (Easing(..))
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Dom as Dom
import Dict exposing (Dict)
import Html
import Html.Attributes


type alias AnimBuilder =
    Builder.AnimBuilder


{-| Container identification - either document body or element ID
-}
type ContainerId
    = DocumentBody
    | ElementId String


{-| Scroll animation configuration
-}
type alias ScrollAnimationConfig =
    { containerId : ContainerId
    , targetX : Float
    , targetY : Float
    , axis : ScrollAxis
    , timeSpec : TimeSpec
    , easing : Easing
    , delay : Int
    }


{-| Scroll axis configuration
-}
type ScrollAxis
    = X
    | Y
    | Both


{-| Individual scroll animation state
-}
type alias ScrollAnimation =
    { config : ScrollAnimationConfig
    , startX : Float
    , startY : Float
    , currentX : Float
    , currentY : Float
    , progress : Float
    , durationMs : Float
    , elapsedMs : Float
    , delayMs : Float
    , delayComplete : Bool
    }


{-| Container for all scroll animations
-}
type alias AnimationData =
    { animations : Dict String ScrollAnimation
    , nextId : Int
    }


{-| Main animation state
-}
type AnimationState
    = AnimationState AnimationData


{-| Animation messages
-}
type AnimationMsg
    = AnimationFrame Float
    | DomElementReceived String (Result Dom.Error Dom.Element)
    | ViewportReceived String (Result Dom.Error Dom.Viewport)


{-| Convert speed (pixels per second) to duration based on distance.
-}
speedToDuration : Float -> Float -> Int
speedToDuration speedPxPerSec distance =
    if speedPxPerSec <= 0 then
        400
        -- Default duration

    else
        round (distance * 1000 / speedPxPerSec)



-- INITIALIZATION


{-| Initialize empty scroll animation state.
-}
init : AnimationState
init =
    AnimationState
        { animations = Dict.empty
        , nextId = 1
        }


{-| Turn the AnimationState into an AnimBuilder.
-}
builder : AnimationState -> AnimBuilder
builder _ =
    Builder.init


setAxis : ScrollTarget.Axis -> AnimBuilder -> AnimBuilder
setAxis axis animBuilder =
    Builder.mapScrollTargets
        (\(ScrollTarget.ScrollTarget data) ->
            ScrollTarget.ScrollTarget { data | axis = axis }
        )
        animBuilder



-- GLOBAL SETTINGS
{- Set global duration in milliseconds. -}


duration : Int -> AnimBuilder -> AnimBuilder
duration ms =
    Builder.duration ms



{- Set global speed in pixels per second. -}


speed : Float -> AnimBuilder -> AnimBuilder
speed pxPerSec =
    Builder.speed pxPerSec


{-| Set global easing function.
-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing easingFn =
    Builder.easing easingFn


{-| Set global delay in milliseconds.
-}
delay : Int -> AnimBuilder -> AnimBuilder
delay ms =
    Builder.delay ms


{-| Add a scroll target to the animation builder.
-}
addScrollTarget : ScrollTarget -> AnimBuilder -> AnimBuilder
addScrollTarget scrollTarget animBuilder =
    Builder.addScrollTarget scrollTarget animBuilder


{-| Set the container for scroll animations.
-}
setContainer : String -> AnimBuilder -> AnimBuilder
setContainer containerId animBuilder =
    Builder.setScrollContainer containerId animBuilder



-- ANIMATION EXECUTION


{-| Create scroll animation from AnimBuilder.
-}
animate : AnimBuilder -> AnimationState
animate animBuilder =
    let
        animData =
            { animations = Dict.empty
            , nextId = 1
            }

        scrollTargets =
            Builder.getScrollTargets animBuilder

        newAnimations =
            List.foldl
                (\scrollTarget acc ->
                    createScrollAnimation animBuilder scrollTarget
                        |> Maybe.map (\anim -> Dict.insert (String.fromInt animData.nextId) anim acc)
                        |> Maybe.withDefault acc
                )
                animData.animations
                scrollTargets

        newNextId =
            animData.nextId + List.length scrollTargets
    in
    AnimationState
        { animData
            | animations = newAnimations
            , nextId = newNextId
        }


{-| Create a single scroll animation from builder and scroll target.
-}
createScrollAnimation : AnimBuilder -> ScrollTarget -> Maybe ScrollAnimation
createScrollAnimation animBuilder scrollTarget =
    let
        config =
            createScrollAnimationConfig animBuilder scrollTarget

        -- For now, we'll start with current scroll position as (0, 0)
        -- In a real implementation, we'd query the DOM for current position
        startPosition =
            { x = 0, y = 0 }

        distance =
            calculateDistance config.axis startPosition.x startPosition.y config.targetX config.targetY

        actualDuration =
            case Builder.getTimeSpec animBuilder of
                Duration ms ->
                    ms

                Speed pxPerSec ->
                    speedToDuration pxPerSec distance

        delayMs =
            toFloat (Builder.getDelay animBuilder |> Maybe.withDefault 0)
    in
    Just
        { config = config
        , startX = startPosition.x
        , startY = startPosition.y
        , currentX = startPosition.x
        , currentY = startPosition.y
        , progress = 0.0
        , durationMs = toFloat actualDuration
        , elapsedMs = 0.0
        , delayMs = delayMs
        , delayComplete = delayMs == 0.0
        }


{-| Create scroll animation configuration from builder and target.
-}
createScrollAnimationConfig : AnimBuilder -> ScrollTarget -> ScrollAnimationConfig
createScrollAnimationConfig animBuilder scrollTarget =
    { containerId = ElementId (ScrollTarget.getContainerId scrollTarget)
    , targetX = ScrollTarget.getTargetX scrollTarget
    , targetY = ScrollTarget.getTargetY scrollTarget
    , axis = convertAxis (ScrollTarget.getAxis scrollTarget)
    , timeSpec = Builder.getTimeSpec animBuilder
    , easing = Builder.getEasingWithDefault animBuilder
    , delay = Builder.getDelayWithDefault animBuilder
    }


{-| Convert ScrollTarget axis to internal axis.
-}
convertAxis : ScrollTarget.Axis -> ScrollAxis
convertAxis axis =
    case axis of
        ScrollTarget.X ->
            X

        ScrollTarget.Y ->
            Y

        ScrollTarget.Both ->
            Both


{-| Calculate distance for animation based on axis.
-}
calculateDistance : ScrollAxis -> Float -> Float -> Float -> Float -> Float
calculateDistance axis startX startY targetX targetY =
    case axis of
        X ->
            abs (targetX - startX)

        Y ->
            abs (targetY - startY)

        Both ->
            sqrt ((targetX - startX) ^ 2 + (targetY - startY) ^ 2)



-- ANIMATION MANAGEMENT


{-| Update scroll animation state with animation frame.
-}
update : AnimationMsg -> AnimationState -> AnimationState
update msg (AnimationState animData) =
    case msg of
        AnimationFrame deltaMs ->
            let
                updatedAnimations =
                    Dict.map (\_ -> updateScrollAnimation deltaMs) animData.animations

                -- Remove completed animations
                activeAnimations =
                    Dict.filter (\_ anim -> anim.progress < 1.0) updatedAnimations
            in
            AnimationState { animData | animations = activeAnimations }

        DomElementReceived animId (Ok element) ->
            let
                updatedAnimations =
                    Dict.update animId
                        (Maybe.map
                            (\anim ->
                                { anim
                                    | startX = element.element.x
                                    , startY = element.element.y
                                    , currentX = element.element.x
                                    , currentY = element.element.y
                                }
                            )
                        )
                        animData.animations
            in
            AnimationState { animData | animations = updatedAnimations }

        DomElementReceived animId (Err _) ->
            -- Handle DOM error (remove failed animation)
            AnimationState { animData | animations = Dict.remove animId animData.animations }

        ViewportReceived animId (Ok viewport) ->
            -- Update animation with actual viewport scroll position
            let
                updatedAnimations =
                    Dict.update animId
                        (Maybe.map
                            (\anim ->
                                { anim
                                    | startX = viewport.viewport.x
                                    , startY = viewport.viewport.y
                                    , currentX = viewport.viewport.x
                                    , currentY = viewport.viewport.y
                                }
                            )
                        )
                        animData.animations
            in
            AnimationState { animData | animations = updatedAnimations }

        ViewportReceived animId (Err _) ->
            -- Handle viewport error (remove failed animation)
            AnimationState { animData | animations = Dict.remove animId animData.animations }


{-| Update a single scroll animation.
-}
updateScrollAnimation : Float -> ScrollAnimation -> ScrollAnimation
updateScrollAnimation deltaMs animation =
    if not animation.delayComplete then
        -- Still in delay phase
        let
            newElapsedMs =
                animation.elapsedMs + deltaMs
        in
        if newElapsedMs >= animation.delayMs then
            { animation | delayComplete = True, elapsedMs = 0.0 }

        else
            { animation | elapsedMs = newElapsedMs }

    else
        -- Animation phase
        let
            newElapsedMs =
                animation.elapsedMs + deltaMs

            progress =
                min 1.0 (newElapsedMs / animation.durationMs)

            easedProgress =
                Easing.toFunction animation.config.easing progress

            newCurrentX =
                case animation.config.axis of
                    Y ->
                        animation.startX

                    _ ->
                        animation.startX + (animation.config.targetX - animation.startX) * easedProgress

            newCurrentY =
                case animation.config.axis of
                    X ->
                        animation.startY

                    _ ->
                        animation.startY + (animation.config.targetY - animation.startY) * easedProgress
        in
        { animation
            | elapsedMs = newElapsedMs
            , progress = progress
            , currentX = newCurrentX
            , currentY = newCurrentY
        }



-- QUERYING ANIMATION STATE


{-| Check if any scroll animations are currently running.
-}
isAnimationRunning : AnimationState -> Bool
isAnimationRunning (AnimationState animData) =
    not (Dict.isEmpty animData.animations)


{-| Get the duration of currently running scroll animations.
-}
getDuration : AnimationState -> Maybe Int
getDuration (AnimationState animData) =
    animData.animations
        |> Dict.values
        |> List.head
        |> Maybe.map (\anim -> round anim.durationMs)



-- QUERYING SCROLL POSITION


{-| Get current scroll position for a specific container.
-}
getScrollPosition : String -> AnimationState -> Maybe { x : Float, y : Float }
getScrollPosition containerId (AnimationState animData) =
    animData.animations
        |> Dict.values
        |> List.filter (\anim -> containerIdMatches containerId anim.config.containerId)
        |> List.head
        |> Maybe.map (\anim -> { x = anim.currentX, y = anim.currentY })


{-| Get current scroll position as a tuple for a specific container.
-}
getScrollPositionXY : String -> AnimationState -> Maybe ( Float, Float )
getScrollPositionXY containerId animState =
    getScrollPosition containerId animState
        |> Maybe.map (\pos -> ( pos.x, pos.y ))


{-| Get current horizontal scroll position for a specific container.
-}
getScrollPositionX : String -> AnimationState -> Maybe Float
getScrollPositionX containerId animState =
    getScrollPosition containerId animState
        |> Maybe.map .x


{-| Get current vertical scroll position for a specific container.
-}
getScrollPositionY : String -> AnimationState -> Maybe Float
getScrollPositionY containerId animState =
    getScrollPosition containerId animState
        |> Maybe.map .y


{-| Check if container ID matches.
-}
containerIdMatches : String -> ContainerId -> Bool
containerIdMatches id containerId =
    case containerId of
        DocumentBody ->
            id == "document" || id == "body"

        ElementId elementId ->
            id == elementId



-- CSS GENERATION


{-| Generate HTML attributes for scroll containers.
-}
htmlAttributes : String -> AnimationState -> List (Html.Attribute msg)
htmlAttributes containerId animState =
    case getScrollPosition containerId animState of
        Just position ->
            -- Add data attributes for current scroll position
            [ Html.Attributes.attribute "data-scroll-x" (String.fromFloat position.x)
            , Html.Attributes.attribute "data-scroll-y" (String.fromFloat position.y)
            , Html.Attributes.attribute "data-scrolling" "true"
            ]

        Nothing ->
            [ Html.Attributes.attribute "data-scrolling" "false"
            ]


{-| Attach data attributes to your scrollable container elements:

  - `data-scroll-x`, `data-scroll-y`: Current scroll position
  - `data-scrolling`: Animation state (true/false)

Use for CSS styling, debugging, or custom JS integrations. Optional utility—ignore if not needed.

-}



{- Get scroll targets from AnimBuilder for toCmd/toTask implementations. -}


getScrollTargets : AnimBuilder -> List ScrollTarget
getScrollTargets animBuilder =
    Builder.getScrollTargets animBuilder


{-| Get global settings from AnimBuilder for toCmd/toTask implementations.
-}
getGlobalSettings : AnimBuilder -> { timeSpec : TimeSpec, easing : Easing.Easing, offset : Float }
getGlobalSettings animBuilder =
    let
        timeSpec =
            Builder.getTimeSpec animBuilder

        builderEasing =
            Builder.getEasing animBuilder |> Maybe.withDefault Easing.Linear
    in
    { timeSpec = timeSpec
    , easing = builderEasing
    , offset = 0.0 -- Default offset
    }


{-| Get container from AnimBuilder for toCmd/toTask implementations.
-}
getContainer : AnimBuilder -> String
getContainer animBuilder =
    Builder.getScrollContainer animBuilder
