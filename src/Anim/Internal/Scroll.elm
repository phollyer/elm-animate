module Anim.Internal.Scroll exposing
    ( AnimBuilder
    , AnimState
    , AnimationMsg(..)
    , addScrollTarget
    , animate
    , builder
    , delay
    , duration
    , easing
    , getContainer
    , getContainerDuration
    , getDuration
    , getGlobalSettings
    , getScrollPosition
    , getScrollPositionX
    , getScrollPositionXY
    , getScrollPositionY
    , getScrollTargets
    , init
    , isAnimationRunning
    , isContainerAnimating
    , setAxis
    , setContainer
    , setOffset
    , setOffsetX
    , setOffsetY
    , speed
    , subscriptions
    , toCmd
    , update
    )

{-| Internal implementation for subscription-based scroll animations.

This module provides the core functionality for the Scroll engine, handling
frame-based scroll animations with state management.

-}

import Anim.Easing exposing (Easing(..))
import Anim.Internal.Builder as Builder
import Anim.Internal.Easing as Easing
import Anim.Internal.Properties.ScrollTarget as ScrollTarget exposing (ScrollTarget)
import Anim.Internal.Scroll.Common as ScrollCommon
import Anim.Internal.Scroll.Container.Cmd as ContainerCmd
import Anim.Internal.Scroll.Document.Cmd as DocumentCmd
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Dom as Dom
import Browser.Events
import Dict exposing (Dict)
import Task


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
type AnimState
    = AnimState AnimationData


{-| Animation messages
-}
type AnimationMsg
    = AnimationFrame Float
    | DomQueriesCompleted String ScrollTarget AnimBuilder Dom.Viewport (Maybe Dom.Element)
    | NoOp


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
init : AnimState
init =
    AnimState
        { animations = Dict.empty
        , nextId = 1
        }


{-| Turn the AnimState into an AnimBuilder.
-}
builder : AnimState -> AnimBuilder
builder _ =
    Builder.init


setAxis : ScrollTarget.Axis -> AnimBuilder -> AnimBuilder
setAxis axis animBuilder =
    Builder.mapScrollTargets
        (\(ScrollTarget.ScrollTarget data) ->
            ScrollTarget.ScrollTarget { data | axis = axis }
        )
        animBuilder


setOffsetX : Float -> AnimBuilder -> AnimBuilder
setOffsetX offset animBuilder =
    Builder.mapScrollTargets
        (\(ScrollTarget.ScrollTarget data) ->
            ScrollTarget.ScrollTarget { data | offset = ( offset, Tuple.second data.offset ) }
        )
        animBuilder


setOffsetY : Float -> AnimBuilder -> AnimBuilder
setOffsetY offset animBuilder =
    Builder.mapScrollTargets
        (\(ScrollTarget.ScrollTarget data) ->
            ScrollTarget.ScrollTarget { data | offset = ( Tuple.first data.offset, offset ) }
        )
        animBuilder


setOffset : ( Float, Float ) -> AnimBuilder -> AnimBuilder
setOffset ( offsetX, offsetY ) animBuilder =
    Builder.mapScrollTargets
        (\(ScrollTarget.ScrollTarget data) ->
            ScrollTarget.ScrollTarget { data | offset = ( offsetX, offsetY ) }
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


toCmd : msg -> AnimBuilder -> Cmd msg
toCmd completionMsg animBuilder =
    let
        scrollTargets =
            getScrollTargets animBuilder

        globalSettings =
            getGlobalSettings animBuilder

        -- Create scroll config from global settings
        config =
            { timing =
                case globalSettings.timeSpec of
                    Speed s ->
                        ScrollCommon.Speed s

                    Duration d ->
                        ScrollCommon.Duration d
            , easing = Easing.toFunction globalSettings.easing
            , axis = ScrollCommon.Both
            }

        -- Create a command for each scroll target
        createScrollCmd target =
            let
                containerType =
                    ScrollTarget.getContainerId target
            in
            case ( containerType, ScrollTarget.getTargetType target ) of
                ( "document", ScrollTarget.Element elementId ) ->
                    DocumentCmd.scrollWithConfig elementId completionMsg config

                ( "document", ScrollTarget.Coordinates x y ) ->
                    DocumentCmd.scrollToCoordinatesWithConfig x y completionMsg config

                ( "document", ScrollTarget.Top ) ->
                    DocumentCmd.scrollToTopWithConfig completionMsg config

                ( "document", ScrollTarget.Bottom ) ->
                    DocumentCmd.scrollToBottomWithConfig completionMsg config

                ( "document", ScrollTarget.Center ) ->
                    DocumentCmd.scrollToCenterWithConfig completionMsg config

                ( containerId, ScrollTarget.Element elementId ) ->
                    ContainerCmd.scrollWithConfig containerId elementId completionMsg config

                ( containerId, ScrollTarget.Coordinates x y ) ->
                    ContainerCmd.scrollToCoordinatesWithConfig containerId x y completionMsg config

                ( containerId, ScrollTarget.Top ) ->
                    ContainerCmd.scrollToTopWithConfig containerId completionMsg config

                ( containerId, ScrollTarget.Bottom ) ->
                    ContainerCmd.scrollToBottomWithConfig containerId completionMsg config

                ( containerId, ScrollTarget.Center ) ->
                    ContainerCmd.scrollToCenterWithConfig containerId completionMsg config

                _ ->
                    Cmd.none
    in
    scrollTargets
        |> List.map createScrollCmd
        |> Cmd.batch


{-| Create scroll animation from AnimBuilder.
-}
animate : (AnimationMsg -> msg) -> AnimBuilder -> ( AnimState, Cmd msg )
animate toMsg animBuilder =
    let
        scrollTargets =
            Builder.getScrollTargets animBuilder

        initAnimState =
            AnimState
                { animations = Dict.empty
                , nextId = 1
                }

        -- Create DOM query commands for each scroll target
        domQueries =
            scrollTargets
                |> List.indexedMap
                    (\index scrollTarget ->
                        let
                            animId =
                                String.fromInt (index + 1)

                            containerId =
                                ScrollTarget.getContainerId scrollTarget

                            targetType =
                                ScrollTarget.getTargetType scrollTarget
                        in
                        case targetType of
                            ScrollTarget.Element elementId ->
                                -- Query both viewport and target element
                                Task.map2 Tuple.pair
                                    (if containerId == "document" then
                                        Dom.getViewport

                                     else
                                        Dom.getViewportOf containerId
                                    )
                                    (Dom.getElement elementId)
                                    |> Task.attempt
                                        (\result ->
                                            case result of
                                                Ok ( viewport, element ) ->
                                                    toMsg (DomQueriesCompleted animId scrollTarget animBuilder viewport (Just element))

                                                Err _ ->
                                                    toMsg NoOp
                                         -- Ignore errors
                                        )

                            _ ->
                                -- For coordinates and other target types, just query viewport
                                (if containerId == "document" then
                                    Dom.getViewport

                                 else
                                    Dom.getViewportOf containerId
                                )
                                    |> Task.attempt
                                        (\result ->
                                            case result of
                                                Ok viewport ->
                                                    toMsg (DomQueriesCompleted animId scrollTarget animBuilder viewport Nothing)

                                                Err _ ->
                                                    toMsg NoOp
                                        )
                    )
    in
    ( initAnimState, Cmd.batch domQueries )


{-| Create scroll animation from DOM query results.
-}
createScrollAnimationFromDom : AnimBuilder -> ScrollTarget -> Dom.Viewport -> Dom.Element -> ScrollAnimation
createScrollAnimationFromDom animBuilder scrollTarget viewport element =
    let
        config =
            createScrollAnimationConfig animBuilder scrollTarget

        startPosition =
            { x = viewport.viewport.x, y = viewport.viewport.y }

        targetPosition =
            case ScrollTarget.getTargetType scrollTarget of
                ScrollTarget.Element _ ->
                    -- Calculate target position based on element location
                    { x = element.element.x - viewport.scene.width / 2 + element.element.width / 2
                    , y = element.element.y - viewport.scene.height / 2 + element.element.height / 2
                    }

                ScrollTarget.Coordinates x y ->
                    { x = x, y = y }

                _ ->
                    startPosition

        distance =
            calculateDistance config.axis startPosition.x startPosition.y targetPosition.x targetPosition.y

        actualDuration =
            case Builder.getTimeSpec animBuilder of
                Duration ms ->
                    ms

                Speed pxPerSec ->
                    speedToDuration pxPerSec distance

        delayMs =
            toFloat (Builder.getDelay animBuilder |> Maybe.withDefault 0)
    in
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


{-| Create scroll animation from viewport only (for coordinate scrolling).
-}
createScrollAnimationFromViewport : AnimBuilder -> ScrollTarget -> Dom.Viewport -> ScrollAnimation
createScrollAnimationFromViewport animBuilder scrollTarget viewport =
    let
        config =
            createScrollAnimationConfig animBuilder scrollTarget

        startPosition =
            { x = viewport.viewport.x, y = viewport.viewport.y }

        targetPosition =
            { x = ScrollTarget.getTargetX scrollTarget
            , y = ScrollTarget.getTargetY scrollTarget
            }

        distance =
            calculateDistance config.axis startPosition.x startPosition.y targetPosition.x targetPosition.y

        actualDuration =
            case Builder.getTimeSpec animBuilder of
                Duration ms ->
                    ms

                Speed pxPerSec ->
                    speedToDuration pxPerSec distance

        delayMs =
            toFloat (Builder.getDelay animBuilder |> Maybe.withDefault 0)
    in
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
update : (AnimationMsg -> msg) -> AnimationMsg -> AnimState -> ( AnimState, Cmd msg )
update toMsg msg (AnimState animData) =
    case msg of
        AnimationFrame deltaMs ->
            let
                ( updatedAnimations, scrollCommands ) =
                    Dict.foldl
                        (\animId anim ( accAnims, accCmds ) ->
                            let
                                updatedAnim =
                                    updateScrollAnimation deltaMs anim

                                scrollCmd =
                                    if updatedAnim.progress < 1.0 then
                                        -- Perform scroll operation during animation
                                        case updatedAnim.config.containerId of
                                            DocumentBody ->
                                                Dom.setViewport updatedAnim.currentX updatedAnim.currentY
                                                    |> Task.attempt (\_ -> toMsg NoOp)

                                            ElementId containerId ->
                                                Dom.setViewportOf containerId updatedAnim.currentX updatedAnim.currentY
                                                    |> Task.attempt (\_ -> toMsg NoOp)

                                    else
                                        Cmd.none
                            in
                            if updatedAnim.progress < 1.0 then
                                ( Dict.insert animId updatedAnim accAnims, scrollCmd :: accCmds )

                            else
                                ( accAnims, accCmds )
                        )
                        ( Dict.empty, [] )
                        animData.animations
            in
            ( AnimState { animData | animations = updatedAnimations }
            , Cmd.batch scrollCommands
            )

        DomQueriesCompleted animId scrollTarget animBuilder viewport maybeElement ->
            let
                animation =
                    case maybeElement of
                        Just element ->
                            createScrollAnimationFromDom animBuilder scrollTarget viewport element

                        Nothing ->
                            createScrollAnimationFromViewport animBuilder scrollTarget viewport

                updatedAnimations =
                    Dict.insert animId animation animData.animations
            in
            ( AnimState { animData | animations = updatedAnimations }
            , Cmd.none
            )

        NoOp ->
            ( AnimState animData, Cmd.none )


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


subscriptions : (AnimationMsg -> msg) -> AnimState -> Sub msg
subscriptions toMsg animationState =
    if isAnimationRunning animationState then
        Browser.Events.onAnimationFrameDelta (AnimationFrame >> toMsg)

    else
        Sub.none



-- QUERYING ANIMATION STATE


{-| Check if any scroll animations are currently running.
-}
isAnimationRunning : AnimState -> Bool
isAnimationRunning (AnimState animData) =
    not (Dict.isEmpty animData.animations)


{-| Get the maximum duration of currently running scroll animations.
Returns the longest duration when multiple animations are running.
-}
getDuration : AnimState -> Maybe Int
getDuration (AnimState animData) =
    animData.animations
        |> Dict.values
        |> List.map .durationMs
        |> List.maximum
        |> Maybe.map round



-- QUERYING SCROLL POSITION


{-| Get current scroll position for a specific container.
-}
getScrollPosition : String -> AnimState -> Maybe { x : Float, y : Float }
getScrollPosition containerId (AnimState animData) =
    animData.animations
        |> Dict.values
        |> List.filter (\anim -> containerIdMatches containerId anim.config.containerId)
        |> List.head
        |> Maybe.map (\anim -> { x = anim.currentX, y = anim.currentY })


{-| Get current scroll position as a tuple for a specific container.
-}
getScrollPositionXY : String -> AnimState -> Maybe ( Float, Float )
getScrollPositionXY containerId animState =
    getScrollPosition containerId animState
        |> Maybe.map (\pos -> ( pos.x, pos.y ))


{-| Get current horizontal scroll position for a specific container.
-}
getScrollPositionX : String -> AnimState -> Maybe Float
getScrollPositionX containerId animState =
    getScrollPosition containerId animState
        |> Maybe.map .x


{-| Get current vertical scroll position for a specific container.
-}
getScrollPositionY : String -> AnimState -> Maybe Float
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


{-| Check if a specific container is currently animating.
-}
isContainerAnimating : String -> AnimState -> Bool
isContainerAnimating containerId (AnimState animData) =
    animData.animations
        |> Dict.values
        |> List.any (\anim -> containerIdMatches containerId anim.config.containerId)


{-| Get the duration for a specific container's animation.
-}
getContainerDuration : String -> AnimState -> Maybe Int
getContainerDuration containerId (AnimState animData) =
    animData.animations
        |> Dict.values
        |> List.filter (\anim -> containerIdMatches containerId anim.config.containerId)
        |> List.head
        |> Maybe.map (\anim -> round anim.durationMs)



-- HELPER FUNCTIONS


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
getGlobalSettings : AnimBuilder -> { timeSpec : TimeSpec, easing : Easing, offset : Float }
getGlobalSettings animBuilder =
    let
        timeSpec =
            Builder.getTimeSpec animBuilder

        builderEasing =
            Builder.getEasing animBuilder |> Maybe.withDefault Linear
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
