module Anim.Internal.Scroll exposing
    ( AnimBuilder
    , AnimMsg(..)
    , AnimState
    , addScrollTarget
    , animate
    , anyRunning
    , builder
    , delay
    , duration
    , easing
    , getContainer
    , getContainerDuration
    , getDefaultSettings
    , getDuration
    , getScrollPosition
    , getScrollPositionX
    , getScrollPositionXY
    , getScrollPositionY
    , getScrollTargets
    , init
    , isRunning
    , pause
    , pauseContainer
    , reset
    , resetContainer
    , restart
    , restartContainer
    , resume
    , resumeContainer
    , setAxis
    , setContainer
    , setOffset
    , setOffsetX
    , setOffsetY
    , speed
    , stop
    , stopContainer
    , subscriptions
    , toCmd
    , update
    )

{-| Internal implementation for subscription-based scroll animations.

This module provides the core functionality for the Scroll engine, handling
frame-based scroll animations with state management.

-}

import Anim.Extra.Easing exposing (Easing(..))
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
    , isPaused : Bool
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
type AnimMsg
    = AnimationFrame Float
    | DomQueriesCompleted String ScrollTarget AnimBuilder DomQueryResult
    | NoOp


{-| Result of DOM queries for scroll animation setup
-}
type alias DomQueryResult =
    { viewport : Dom.Viewport
    , containerElement : Maybe Dom.Element -- For container scrolling, the container's position
    , targetElement : Maybe Dom.Element -- For element scrolling, the target's position
    }


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


toCmd : (String -> msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg
toCmd toMsg buildAnimation =
    let
        animBuilder =
            buildAnimation Builder.init

        scrollTargets =
            getScrollTargets animBuilder

        defaultSettings =
            getDefaultSettings animBuilder

        -- Create scroll config from default settings
        -- Note: We use 1000ms (1 second) as baseline duration for easing function
        -- The actual animation duration is determined later based on distance and speed/duration
        config =
            { timing =
                case defaultSettings.timeSpec of
                    Speed s ->
                        ScrollCommon.Speed s

                    Duration d ->
                        ScrollCommon.Duration d
            , easing = Easing.toFunction 1000.0 defaultSettings.easing
            , axis = ScrollCommon.Both
            }

        -- Create a command for each scroll target
        createScrollCmd target =
            let
                containerType =
                    ScrollTarget.getContainerId target

                targetType =
                    ScrollTarget.getTargetType target

                -- Generate identifier for this scroll target
                targetId =
                    case targetType of
                        ScrollTarget.Element elementId ->
                            elementId

                        ScrollTarget.Coordinates x y ->
                            containerType ++ ":coordinates:" ++ String.fromFloat x ++ "," ++ String.fromFloat y

                        ScrollTarget.Top ->
                            containerType ++ ":top"

                        ScrollTarget.Bottom ->
                            containerType ++ ":bottom"

                        ScrollTarget.Center ->
                            containerType ++ ":center"

                        ScrollTarget.Percentage x y ->
                            containerType ++ ":percentage:" ++ String.fromFloat (x * 100) ++ "," ++ String.fromFloat (y * 100)

                        ScrollTarget.Delta dx dy ->
                            containerType ++ ":delta:" ++ String.fromFloat dx ++ "," ++ String.fromFloat dy

                completionMsg =
                    toMsg targetId
            in
            case ( containerType, targetType ) of
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

                ( "document", ScrollTarget.Delta dx dy ) ->
                    DocumentCmd.scrollByWithConfig dx dy completionMsg config

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

                ( containerId, ScrollTarget.Delta dx dy ) ->
                    ContainerCmd.scrollByWithConfig containerId dx dy completionMsg config

                _ ->
                    Cmd.none
    in
    scrollTargets
        |> List.map createScrollCmd
        |> Cmd.batch


{-| Create scroll animation from AnimBuilder.
-}
animate : (AnimMsg -> msg) -> AnimState -> (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )
animate toMsg _ buildAnimation =
    let
        animBuilder =
            buildAnimation Builder.init

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
                                -- Query viewport, container element (for container scrolling), and target element
                                if containerId == "document" then
                                    -- Document scrolling - just need viewport and target element
                                    Task.map2
                                        (\viewport element ->
                                            { viewport = viewport
                                            , containerElement = Nothing
                                            , targetElement = Just element
                                            }
                                        )
                                        Dom.getViewport
                                        (Dom.getElement elementId)
                                        |> Task.attempt
                                            (\result ->
                                                case result of
                                                    Ok domResult ->
                                                        toMsg (DomQueriesCompleted animId scrollTarget animBuilder domResult)

                                                    Err _ ->
                                                        toMsg NoOp
                                            )

                                else
                                    -- Container scrolling - need viewport, container element, and target element
                                    Task.map3
                                        (\viewport containerEl element ->
                                            { viewport = viewport
                                            , containerElement = Just containerEl
                                            , targetElement = Just element
                                            }
                                        )
                                        (Dom.getViewportOf containerId)
                                        (Dom.getElement containerId)
                                        (Dom.getElement elementId)
                                        |> Task.attempt
                                            (\result ->
                                                case result of
                                                    Ok domResult ->
                                                        toMsg (DomQueriesCompleted animId scrollTarget animBuilder domResult)

                                                    Err _ ->
                                                        toMsg NoOp
                                            )

                            _ ->
                                -- For coordinates and other target types, just query viewport
                                (if containerId == "document" then
                                    Dom.getViewport

                                 else
                                    Dom.getViewportOf containerId
                                )
                                    |> Task.map
                                        (\viewport ->
                                            { viewport = viewport
                                            , containerElement = Nothing
                                            , targetElement = Nothing
                                            }
                                        )
                                    |> Task.attempt
                                        (\result ->
                                            case result of
                                                Ok domResult ->
                                                    toMsg (DomQueriesCompleted animId scrollTarget animBuilder domResult)

                                                Err _ ->
                                                    toMsg NoOp
                                        )
                    )
    in
    ( initAnimState, Cmd.batch domQueries )


{-| Create scroll animation from DOM query results.
-}
createScrollAnimationFromDom : AnimBuilder -> ScrollTarget -> DomQueryResult -> Dom.Element -> ScrollAnimation
createScrollAnimationFromDom animBuilder scrollTarget domResult element =
    let
        viewport =
            domResult.viewport

        baseConfig =
            createScrollAnimationConfig animBuilder scrollTarget

        startPosition =
            { x = viewport.viewport.x, y = viewport.viewport.y }

        -- Calculate element's position relative to the scrollable content
        -- For document scrolling: element position = browser position + current scroll
        -- For container scrolling: element position = (element browser pos - container browser pos) + container scroll
        elementContentPosition =
            case domResult.containerElement of
                Just containerEl ->
                    -- Container scrolling: convert browser-relative to container-content-relative
                    { x = (element.element.x - containerEl.element.x) + viewport.viewport.x
                    , y = (element.element.y - containerEl.element.y) + viewport.viewport.y
                    }

                Nothing ->
                    -- Document scrolling: convert browser-relative to document-relative
                    { x = element.element.x + viewport.viewport.x
                    , y = element.element.y + viewport.viewport.y
                    }

        targetPosition =
            case ScrollTarget.getTargetType scrollTarget of
                ScrollTarget.Element _ ->
                    -- Scroll to bring element to top-left of viewport
                    { x = elementContentPosition.x
                    , y = elementContentPosition.y
                    }

                ScrollTarget.Coordinates x y ->
                    { x = x, y = y }

                _ ->
                    startPosition

        -- Clamp target position to valid scroll range
        clampedTarget =
            { x = clamp 0 (viewport.scene.width - viewport.viewport.width) targetPosition.x
            , y = clamp 0 (viewport.scene.height - viewport.viewport.height) targetPosition.y
            }

        -- Update config with calculated target position
        config =
            { baseConfig | targetX = clampedTarget.x, targetY = clampedTarget.y }

        distance =
            calculateDistance config.axis startPosition.x startPosition.y clampedTarget.x clampedTarget.y

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
    , isPaused = False
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
    , isPaused = False
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
update : (AnimMsg -> msg) -> AnimMsg -> AnimState -> ( AnimState, Cmd msg )
update toMsg msg (AnimState animData) =
    case msg of
        AnimationFrame deltaMs ->
            let
                ( updatedAnimations, scrollCommands ) =
                    Dict.foldl
                        (\animId anim ( accAnims, accCmds ) ->
                            -- Skip paused animations - keep them in state but don't update
                            if anim.isPaused then
                                ( Dict.insert animId anim accAnims, accCmds )

                            else
                                let
                                    updatedAnim =
                                        updateScrollAnimation deltaMs anim

                                    -- Issue scroll command for both ongoing and completing animations
                                    scrollCmd =
                                        case updatedAnim.config.containerId of
                                            DocumentBody ->
                                                Dom.setViewport updatedAnim.currentX updatedAnim.currentY
                                                    |> Task.attempt (\_ -> toMsg NoOp)

                                            ElementId containerId ->
                                                Dom.setViewportOf containerId updatedAnim.currentX updatedAnim.currentY
                                                    |> Task.attempt (\_ -> toMsg NoOp)
                                in
                                if updatedAnim.progress < 1.0 then
                                    ( Dict.insert animId updatedAnim accAnims, scrollCmd :: accCmds )

                                else
                                    -- Animation complete - keep it paused at progress=1 for reset/restart
                                    let
                                        completedAnim =
                                            { updatedAnim | isPaused = True }
                                    in
                                    ( Dict.insert animId completedAnim accAnims, scrollCmd :: accCmds )
                        )
                        ( Dict.empty, [] )
                        animData.animations
            in
            ( AnimState { animData | animations = updatedAnimations }
            , Cmd.batch scrollCommands
            )

        DomQueriesCompleted animId scrollTarget animBuilder domResult ->
            let
                animation =
                    case domResult.targetElement of
                        Just element ->
                            createScrollAnimationFromDom animBuilder scrollTarget domResult element

                        Nothing ->
                            createScrollAnimationFromViewport animBuilder scrollTarget domResult.viewport

                -- Only add animation if there's actual distance to scroll
                hasDistance =
                    calculateDistance animation.config.axis animation.startX animation.startY animation.config.targetX animation.config.targetY > 0

                updatedAnimations =
                    if hasDistance then
                        Dict.insert animId animation animData.animations

                    else
                        animData.animations
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

            easingFunction =
                Easing.toFunction animation.durationMs animation.config.easing

            easedProgress =
                easingFunction progress

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


subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions toMsg animState =
    if anyRunning animState then
        Browser.Events.onAnimationFrameDelta (AnimationFrame >> toMsg)

    else
        Sub.none



-- QUERYING ANIMATION STATE


{-| Check if any scroll animations are currently running (not paused).
-}
anyRunning : AnimState -> Bool
anyRunning (AnimState animData) =
    animData.animations
        |> Dict.values
        |> List.any (\anim -> not anim.isPaused)


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
isRunning : String -> AnimState -> Bool
isRunning containerId (AnimState animData) =
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



-- ANIMATION CONTROLS


{-| Stop all scroll animations by jumping to their end positions.
Animations are marked complete and scroll to their targets immediately.
-}
stop : (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
stop toMsg (AnimState animData) =
    let
        ( updatedAnimations, scrollCmds ) =
            Dict.foldl
                (\_ anim ( accAnims, accCmds ) ->
                    let
                        scrollCmd =
                            scrollToPosition toMsg anim.config.containerId anim.config.targetX anim.config.targetY
                    in
                    -- Animation completes, don't keep it
                    ( accAnims, scrollCmd :: accCmds )
                )
                ( Dict.empty, [] )
                animData.animations
    in
    ( AnimState { animData | animations = updatedAnimations }
    , Cmd.batch scrollCmds
    )


{-| Stop scroll animation for a specific container by jumping to end position.
-}
stopContainer : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
stopContainer containerId toMsg (AnimState animData) =
    let
        ( updatedAnimations, scrollCmds ) =
            Dict.foldl
                (\animId anim ( accAnims, accCmds ) ->
                    if containerIdMatches containerId anim.config.containerId then
                        let
                            scrollCmd =
                                scrollToPosition toMsg anim.config.containerId anim.config.targetX anim.config.targetY
                        in
                        -- Animation completes, don't keep it
                        ( accAnims, scrollCmd :: accCmds )

                    else
                        ( Dict.insert animId anim accAnims, accCmds )
                )
                ( Dict.empty, [] )
                animData.animations
    in
    ( AnimState { animData | animations = updatedAnimations }
    , Cmd.batch scrollCmds
    )


{-| Pause all scroll animations.
Paused animations retain their current position and progress.
-}
pause : AnimState -> AnimState
pause (AnimState animData) =
    let
        updatedAnimations =
            Dict.map (\_ anim -> { anim | isPaused = True }) animData.animations
    in
    AnimState { animData | animations = updatedAnimations }


{-| Pause scroll animation for a specific container.
-}
pauseContainer : String -> AnimState -> AnimState
pauseContainer containerId (AnimState animData) =
    let
        updatedAnimations =
            Dict.map
                (\_ anim ->
                    if containerIdMatches containerId anim.config.containerId then
                        { anim | isPaused = True }

                    else
                        anim
                )
                animData.animations
    in
    AnimState { animData | animations = updatedAnimations }


{-| Resume all paused scroll animations.
-}
resume : AnimState -> AnimState
resume (AnimState animData) =
    let
        updatedAnimations =
            Dict.map (\_ anim -> { anim | isPaused = False }) animData.animations
    in
    AnimState { animData | animations = updatedAnimations }


{-| Resume scroll animation for a specific container.
-}
resumeContainer : String -> AnimState -> AnimState
resumeContainer containerId (AnimState animData) =
    let
        updatedAnimations =
            Dict.map
                (\_ anim ->
                    if containerIdMatches containerId anim.config.containerId then
                        { anim | isPaused = False }

                    else
                        anim
                )
                animData.animations
    in
    AnimState { animData | animations = updatedAnimations }


{-| Reset all scroll animations to their starting positions.
Animations return to progress 0, scroll to start immediately, and remain paused.
-}
reset : (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
reset toMsg (AnimState animData) =
    let
        ( updatedAnimations, scrollCmds ) =
            Dict.foldl
                (\animId anim ( accAnims, accCmds ) ->
                    let
                        scrollCmd =
                            scrollToPosition toMsg anim.config.containerId anim.startX anim.startY

                        updatedAnim =
                            { anim
                                | currentX = anim.startX
                                , currentY = anim.startY
                                , progress = 0.0
                                , elapsedMs = 0.0
                                , delayComplete = anim.delayMs == 0.0
                                , isPaused = True
                            }
                    in
                    ( Dict.insert animId updatedAnim accAnims, scrollCmd :: accCmds )
                )
                ( Dict.empty, [] )
                animData.animations
    in
    ( AnimState { animData | animations = updatedAnimations }
    , Cmd.batch scrollCmds
    )


{-| Reset scroll animation for a specific container.
-}
resetContainer : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resetContainer containerId toMsg (AnimState animData) =
    let
        ( updatedAnimations, scrollCmds ) =
            Dict.foldl
                (\animId anim ( accAnims, accCmds ) ->
                    if containerIdMatches containerId anim.config.containerId then
                        let
                            scrollCmd =
                                scrollToPosition toMsg anim.config.containerId anim.startX anim.startY

                            updatedAnim =
                                { anim
                                    | currentX = anim.startX
                                    , currentY = anim.startY
                                    , progress = 0.0
                                    , elapsedMs = 0.0
                                    , delayComplete = anim.delayMs == 0.0
                                    , isPaused = True
                                }
                        in
                        ( Dict.insert animId updatedAnim accAnims, scrollCmd :: accCmds )

                    else
                        ( Dict.insert animId anim accAnims, accCmds )
                )
                ( Dict.empty, [] )
                animData.animations
    in
    ( AnimState { animData | animations = updatedAnimations }
    , Cmd.batch scrollCmds
    )


{-| Restart all scroll animations from their starting positions.
Animations scroll to start immediately and begin playing.
-}
restart : (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart toMsg (AnimState animData) =
    let
        ( updatedAnimations, scrollCmds ) =
            Dict.foldl
                (\animId anim ( accAnims, accCmds ) ->
                    let
                        scrollCmd =
                            scrollToPosition toMsg anim.config.containerId anim.startX anim.startY

                        updatedAnim =
                            { anim
                                | currentX = anim.startX
                                , currentY = anim.startY
                                , progress = 0.0
                                , elapsedMs = 0.0
                                , delayComplete = anim.delayMs == 0.0
                                , isPaused = False
                            }
                    in
                    ( Dict.insert animId updatedAnim accAnims, scrollCmd :: accCmds )
                )
                ( Dict.empty, [] )
                animData.animations
    in
    ( AnimState { animData | animations = updatedAnimations }
    , Cmd.batch scrollCmds
    )


{-| Restart scroll animation for a specific container.
-}
restartContainer : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restartContainer containerId toMsg (AnimState animData) =
    let
        ( updatedAnimations, scrollCmds ) =
            Dict.foldl
                (\animId anim ( accAnims, accCmds ) ->
                    if containerIdMatches containerId anim.config.containerId then
                        let
                            scrollCmd =
                                scrollToPosition toMsg anim.config.containerId anim.startX anim.startY

                            updatedAnim =
                                { anim
                                    | currentX = anim.startX
                                    , currentY = anim.startY
                                    , progress = 0.0
                                    , elapsedMs = 0.0
                                    , delayComplete = anim.delayMs == 0.0
                                    , isPaused = False
                                }
                        in
                        ( Dict.insert animId updatedAnim accAnims, scrollCmd :: accCmds )

                    else
                        ( Dict.insert animId anim accAnims, accCmds )
                )
                ( Dict.empty, [] )
                animData.animations
    in
    ( AnimState { animData | animations = updatedAnimations }
    , Cmd.batch scrollCmds
    )


{-| Issue a scroll command to move to a specific position.
-}
scrollToPosition : (AnimMsg -> msg) -> ContainerId -> Float -> Float -> Cmd msg
scrollToPosition toMsg containerId x y =
    case containerId of
        DocumentBody ->
            Dom.setViewport x y
                |> Task.attempt (\_ -> toMsg NoOp)

        ElementId elementId ->
            Dom.setViewportOf elementId x y
                |> Task.attempt (\_ -> toMsg NoOp)



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


{-| Get default settings from AnimBuilder for toCmd/toTask implementations.
-}
getDefaultSettings : AnimBuilder -> { timeSpec : TimeSpec, easing : Easing, offset : Float }
getDefaultSettings animBuilder =
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
