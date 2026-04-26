module Scroll.Internal.Engine.Sub exposing
    ( AnimEvent(..)
    , AnimMsg(..)
    , AnimState
    , ScrollBuilder
    , animate
    , anyRunning
    , delay
    , duration
    , easing
    , getScrollPosition
    , getScrollPositionX
    , getScrollPositionY
    , init
    , isRunning
    , pause
    , reset
    , restart
    , resume
    , speed
    , stop
    , subscriptions
    , update
    )

{-| Internal implementation for subscription-based scroll animations.

This module provides the core functionality for the Scroll engine, handling
frame-based scroll animations with state management.

-}

import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Dom as Dom
import Browser.Events
import Dict exposing (Dict)
import Easing exposing (Easing(..))
import Internal.Easing as Easing
import Scroll.Internal.Engine.Internal as ScrollInternal exposing (Container(..))
import Scroll.Internal.Engine.ScrollTarget as ScrollTarget exposing (Axis(..), ScrollTarget)
import Scroll.Internal.ScrollBuilder as SB
import Task



-- ============================================================
-- TYPES
-- ============================================================


type alias ScrollBuilder =
    SB.ScrollBuilder


{-| Scroll animation configuration
-}
type alias ScrollAnimationConfig =
    { containerId : Container
    , targetX : Float
    , targetY : Float
    , axis : Axis
    , timeSpec : TimeSpec
    , easing : Easing
    , delay : Int
    }


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
    , pendingEvents : List AnimEvent
    }


{-| Main animation state
-}
type AnimState
    = AnimState AnimationData


{-| Animation messages
-}
type AnimMsg
    = AnimationFrame Float
    | DomQueriesCompleted String ScrollTarget ScrollBuilder DomQueryResult
    | NoOp


{-| Scroll animation lifecycle events.
-}
type AnimEvent
    = Started String
    | Ended String
    | Progress String { x : Float, y : Float } Float
    | Stopped String
    | Paused String
    | Resumed String
    | Restarted String


{-| Result of DOM queries for scroll animation setup
-}
type alias DomQueryResult =
    { viewport : Dom.Viewport
    , containerElement : Maybe Dom.Element
    , targetElement : Maybe Dom.Element
    }



-- ============================================================
-- HELPERS
-- ============================================================


{-| Convert speed (pixels per second) to duration based on distance.
-}
speedToDuration : Float -> Float -> Int
speedToDuration speedPxPerSec distance =
    if speedPxPerSec <= 0 then
        400

    else
        round (distance * 1000 / speedPxPerSec)



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Initialize empty scroll animation state.
-}
init : AnimState
init =
    AnimState
        { animations = Dict.empty
        , nextId = 1
        , pendingEvents = []
        }



-- ============================================================
-- PLAYBACK SETTINGS
-- ============================================================


duration : Int -> ScrollBuilder -> ScrollBuilder
duration ms =
    SB.setDuration ms


speed : Float -> ScrollBuilder -> ScrollBuilder
speed pxPerSec =
    SB.setSpeed pxPerSec


{-| Set global easing function.
-}
easing : Easing -> ScrollBuilder -> ScrollBuilder
easing easingFn =
    SB.setEasing easingFn


{-| Set global delay in milliseconds.
-}
delay : Int -> ScrollBuilder -> ScrollBuilder
delay ms =
    SB.setDelay ms



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Create scroll animation from AnimBuilder.
-}
animate : (AnimMsg -> msg) -> AnimState -> (ScrollBuilder -> ScrollBuilder) -> ( AnimState, Cmd msg )
animate toMsg _ buildAnimation =
    let
        scrollBuilder =
            buildAnimation SB.init

        scrollTargets =
            SB.getScrollTargets scrollBuilder

        initAnimState =
            AnimState
                { animations = Dict.empty
                , nextId = 1
                , pendingEvents = []
                }

        domQueries =
            scrollTargets
                |> List.indexedMap
                    (\index scrollTarget ->
                        let
                            animId =
                                String.fromInt (index + 1)

                            container =
                                ScrollInternal.toContainer (ScrollTarget.getContainerId scrollTarget)

                            targetType =
                                ScrollTarget.getTargetType scrollTarget

                            handleResult result =
                                case result of
                                    Ok domResult ->
                                        toMsg (DomQueriesCompleted animId scrollTarget scrollBuilder domResult)

                                    Err _ ->
                                        toMsg NoOp
                        in
                        case targetType of
                            ScrollTarget.Element elementId ->
                                Task.map3
                                    (\viewport containerEl element ->
                                        { viewport = viewport
                                        , containerElement = containerEl
                                        , targetElement = Just element
                                        }
                                    )
                                    (ScrollInternal.getViewport container)
                                    (ScrollInternal.getContainerInfo container)
                                    (Dom.getElement elementId)
                                    |> Task.attempt handleResult

                            _ ->
                                Task.map2
                                    (\viewport containerEl ->
                                        { viewport = viewport
                                        , containerElement = containerEl
                                        , targetElement = Nothing
                                        }
                                    )
                                    (ScrollInternal.getViewport container)
                                    (ScrollInternal.getContainerInfo container)
                                    |> Task.attempt handleResult
                    )
    in
    ( initAnimState, Cmd.batch domQueries )


{-| Create scroll animation from DOM query results.
-}
createScrollAnimationFromDom : ScrollBuilder -> ScrollTarget -> DomQueryResult -> Dom.Element -> ScrollAnimation
createScrollAnimationFromDom scrollBuilder scrollTarget domResult element =
    let
        viewport =
            domResult.viewport

        baseConfig =
            createScrollAnimationConfig scrollBuilder scrollTarget

        ( offsetX, offsetY ) =
            ScrollTarget.getOffset scrollTarget

        startPosition =
            { x = viewport.viewport.x, y = viewport.viewport.y }

        elementContentPosition =
            case domResult.containerElement of
                Just containerEl ->
                    { x = (element.element.x - containerEl.element.x) + viewport.viewport.x - offsetX
                    , y = (element.element.y - containerEl.element.y) + viewport.viewport.y - offsetY
                    }

                Nothing ->
                    { x = element.element.x + viewport.viewport.x - offsetX
                    , y = element.element.y + viewport.viewport.y - offsetY
                    }

        targetPosition =
            case ScrollTarget.getTargetType scrollTarget of
                ScrollTarget.Element _ ->
                    { x = elementContentPosition.x
                    , y = elementContentPosition.y
                    }

                ScrollTarget.Coordinates x y ->
                    { x = x, y = y }

                _ ->
                    startPosition

        clampedTarget =
            { x = clamp 0 (viewport.scene.width - viewport.viewport.width) targetPosition.x
            , y = clamp 0 (viewport.scene.height - viewport.viewport.height) targetPosition.y
            }

        config =
            { baseConfig | targetX = clampedTarget.x, targetY = clampedTarget.y }

        distance =
            calculateDistance config.axis startPosition.x startPosition.y clampedTarget.x clampedTarget.y

        actualDuration =
            case SB.getTimeSpecWithDefault scrollBuilder of
                Duration ms ->
                    ms

                Speed pxPerSec ->
                    speedToDuration pxPerSec distance

        delayMs =
            toFloat (SB.getDelayWithDefault scrollBuilder)
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
createScrollAnimationFromViewport : ScrollBuilder -> ScrollTarget -> Dom.Viewport -> ScrollAnimation
createScrollAnimationFromViewport scrollBuilder scrollTarget viewport =
    let
        config =
            createScrollAnimationConfig scrollBuilder scrollTarget

        startPosition =
            { x = viewport.viewport.x, y = viewport.viewport.y }

        targetPosition =
            { x = ScrollTarget.getTargetX scrollTarget
            , y = ScrollTarget.getTargetY scrollTarget
            }

        distance =
            calculateDistance config.axis startPosition.x startPosition.y targetPosition.x targetPosition.y

        actualDuration =
            case SB.getTimeSpecWithDefault scrollBuilder of
                Duration ms ->
                    ms

                Speed pxPerSec ->
                    speedToDuration pxPerSec distance

        delayMs =
            toFloat (SB.getDelayWithDefault scrollBuilder)
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
createScrollAnimationConfig : ScrollBuilder -> ScrollTarget -> ScrollAnimationConfig
createScrollAnimationConfig scrollBuilder scrollTarget =
    { containerId = ScrollInternal.toContainer (ScrollTarget.getContainerId scrollTarget)
    , targetX = ScrollTarget.getTargetX scrollTarget
    , targetY = ScrollTarget.getTargetY scrollTarget
    , axis = ScrollTarget.getAxis scrollTarget
    , timeSpec = SB.getTimeSpecWithDefault scrollBuilder
    , easing = SB.getEasingWithDefault scrollBuilder
    , delay = SB.getDelayWithDefault scrollBuilder
    }


{-| Calculate distance for animation based on axis.
-}
calculateDistance : Axis -> Float -> Float -> Float -> Float -> Float
calculateDistance axis startX startY targetX targetY =
    case axis of
        X ->
            abs (targetX - startX)

        Y ->
            abs (targetY - startY)

        Both ->
            sqrt ((targetX - startX) ^ 2 + (targetY - startY) ^ 2)



-- ============================================================
-- UPDATE
-- ============================================================


{-| Update scroll animation state with animation frame.
-}
update : (AnimMsg -> msg) -> AnimMsg -> AnimState -> ( AnimState, List AnimEvent, Cmd msg )
update toMsg msg (AnimState animData) =
    case msg of
        AnimationFrame deltaMs ->
            let
                ( updatedAnimations, scrollCommands, frameEvents ) =
                    Dict.foldl
                        (\animId anim ( accAnims, accCmds, accEvents ) ->
                            if anim.isPaused then
                                ( Dict.insert animId anim accAnims, accCmds, accEvents )

                            else
                                let
                                    updatedAnim =
                                        updateScrollAnimation deltaMs anim

                                    cid =
                                        containerToString updatedAnim.config.containerId

                                    scrollCmd =
                                        ScrollInternal.setViewport updatedAnim.config.containerId updatedAnim.currentX updatedAnim.currentY
                                            |> Task.attempt (\_ -> toMsg NoOp)

                                    progressEvent =
                                        Progress cid
                                            { x = updatedAnim.currentX, y = updatedAnim.currentY }
                                            updatedAnim.progress
                                in
                                if updatedAnim.progress < 1.0 then
                                    ( Dict.insert animId updatedAnim accAnims
                                    , scrollCmd :: accCmds
                                    , progressEvent :: accEvents
                                    )

                                else
                                    let
                                        completedAnim =
                                            { updatedAnim | isPaused = True }
                                    in
                                    ( Dict.insert animId completedAnim accAnims
                                    , scrollCmd :: accCmds
                                    , Ended cid :: progressEvent :: accEvents
                                    )
                        )
                        ( Dict.empty, [], [] )
                        animData.animations

                allEvents =
                    animData.pendingEvents ++ List.reverse frameEvents
            in
            ( AnimState { animData | animations = updatedAnimations, pendingEvents = [] }
            , allEvents
            , Cmd.batch scrollCommands
            )

        DomQueriesCompleted animId scrollTarget scrollBuilder domResult ->
            let
                animation =
                    case domResult.targetElement of
                        Just element ->
                            createScrollAnimationFromDom scrollBuilder scrollTarget domResult element

                        Nothing ->
                            createScrollAnimationFromViewport scrollBuilder scrollTarget domResult.viewport

                hasDistance =
                    calculateDistance animation.config.axis animation.startX animation.startY animation.config.targetX animation.config.targetY > 0

                cid =
                    containerToString animation.config.containerId

                ( updatedAnimations, newPendingEvents ) =
                    if hasDistance then
                        ( Dict.insert animId animation animData.animations
                        , animData.pendingEvents ++ [ Started cid ]
                        )

                    else
                        ( animData.animations, animData.pendingEvents )
            in
            ( AnimState { animData | animations = updatedAnimations, pendingEvents = newPendingEvents }
            , []
            , Cmd.none
            )

        NoOp ->
            ( AnimState animData, [], Cmd.none )


{-| Update a single scroll animation.
-}
updateScrollAnimation : Float -> ScrollAnimation -> ScrollAnimation
updateScrollAnimation deltaMs animation =
    if not animation.delayComplete then
        let
            newElapsedMs =
                animation.elapsedMs + deltaMs
        in
        if newElapsedMs >= animation.delayMs then
            { animation | delayComplete = True, elapsedMs = 0.0 }

        else
            { animation | elapsedMs = newElapsedMs }

    else
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



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions toMsg animState =
    if anyRunning animState |> Maybe.withDefault False then
        Browser.Events.onAnimationFrameDelta (AnimationFrame >> toMsg)

    else
        Sub.none



-- ============================================================
-- STATE QUERIES
-- ============================================================


{-| Check if any scroll animations are currently running (not paused).
-}
anyRunning : AnimState -> Maybe Bool
anyRunning (AnimState animData) =
    if Dict.isEmpty animData.animations then
        Nothing

    else
        animData.animations
            |> Dict.values
            |> List.any (\anim -> not anim.isPaused)
            |> Just



-- ============================================================
-- POSITION QUERIES
-- ============================================================


{-| Get current scroll position for a specific container.
-}
getScrollPosition : String -> AnimState -> Maybe { x : Float, y : Float }
getScrollPosition containerId (AnimState animData) =
    animData.animations
        |> Dict.values
        |> List.filter (\anim -> containerMatches containerId anim.config.containerId)
        |> List.head
        |> Maybe.map (\anim -> { x = anim.currentX, y = anim.currentY })


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


{-| Check if container matches a string ID.
-}
containerMatches : String -> Container -> Bool
containerMatches id container =
    case container of
        DocumentBody ->
            id == "document" || id == "body"

        Container elementId ->
            id == elementId


{-| Convert a Container to its string representation.
-}
containerToString : Container -> String
containerToString container =
    case container of
        DocumentBody ->
            "document"

        Container cid ->
            cid


{-| Check if a specific container is currently animating.
-}
isRunning : String -> AnimState -> Maybe Bool
isRunning containerId (AnimState animData) =
    if Dict.isEmpty animData.animations then
        Nothing

    else
        animData.animations
            |> Dict.values
            |> List.any (\anim -> containerMatches containerId anim.config.containerId)
            |> Just



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


{-| Stop scroll animation for a specific container by jumping to end position.
-}
stop : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
stop containerId toMsg (AnimState animData) =
    let
        ( updatedAnimations, scrollCmds, newPendingEvents ) =
            Dict.foldl
                (\animId anim ( accAnims, accCmds, accEvents ) ->
                    if containerMatches containerId anim.config.containerId then
                        let
                            scrollCmd =
                                ScrollInternal.setViewport anim.config.containerId anim.config.targetX anim.config.targetY
                                    |> Task.attempt (\_ -> toMsg NoOp)

                            cid =
                                containerToString anim.config.containerId
                        in
                        ( accAnims, scrollCmd :: accCmds, accEvents ++ [ Stopped cid ] )

                    else
                        ( Dict.insert animId anim accAnims, accCmds, accEvents )
                )
                ( Dict.empty, [], animData.pendingEvents )
                animData.animations
    in
    ( AnimState { animData | animations = updatedAnimations, pendingEvents = newPendingEvents }
    , Cmd.batch scrollCmds
    )


{-| Pause scroll animation for a specific container.
-}
pause : String -> AnimState -> AnimState
pause containerId (AnimState animData) =
    let
        ( updatedAnimations, newPendingEvents ) =
            Dict.foldl
                (\animId anim ( accAnims, accEvents ) ->
                    if containerMatches containerId anim.config.containerId && not anim.isPaused then
                        ( Dict.insert animId { anim | isPaused = True } accAnims
                        , accEvents ++ [ Paused (containerToString anim.config.containerId) ]
                        )

                    else
                        ( Dict.insert animId anim accAnims, accEvents )
                )
                ( Dict.empty, animData.pendingEvents )
                animData.animations
    in
    AnimState { animData | animations = updatedAnimations, pendingEvents = newPendingEvents }


{-| Resume scroll animation for a specific container.
-}
resume : String -> AnimState -> AnimState
resume containerId (AnimState animData) =
    let
        ( updatedAnimations, newPendingEvents ) =
            Dict.foldl
                (\animId anim ( accAnims, accEvents ) ->
                    if containerMatches containerId anim.config.containerId && anim.isPaused then
                        ( Dict.insert animId { anim | isPaused = False } accAnims
                        , accEvents ++ [ Resumed (containerToString anim.config.containerId) ]
                        )

                    else
                        ( Dict.insert animId anim accAnims, accEvents )
                )
                ( Dict.empty, animData.pendingEvents )
                animData.animations
    in
    AnimState { animData | animations = updatedAnimations, pendingEvents = newPendingEvents }


{-| Reset scroll animation for a specific container.
-}
reset : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
reset containerId toMsg (AnimState animData) =
    let
        ( updatedAnimations, scrollCmds ) =
            Dict.foldl
                (\animId anim ( accAnims, accCmds ) ->
                    if containerMatches containerId anim.config.containerId then
                        let
                            scrollCmd =
                                ScrollInternal.setViewport anim.config.containerId anim.startX anim.startY
                                    |> Task.attempt (\_ -> toMsg NoOp)

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


{-| Restart scroll animation for a specific container.
-}
restart : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart containerId toMsg (AnimState animData) =
    let
        ( updatedAnimations, scrollCmds, newPendingEvents ) =
            Dict.foldl
                (\animId anim ( accAnims, accCmds, accEvents ) ->
                    if containerMatches containerId anim.config.containerId then
                        let
                            scrollCmd =
                                ScrollInternal.setViewport anim.config.containerId anim.startX anim.startY
                                    |> Task.attempt (\_ -> toMsg NoOp)

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
                        ( Dict.insert animId updatedAnim accAnims
                        , scrollCmd :: accCmds
                        , accEvents ++ [ Restarted (containerToString anim.config.containerId) ]
                        )

                    else
                        ( Dict.insert animId anim accAnims, accCmds, accEvents )
                )
                ( Dict.empty, [], animData.pendingEvents )
                animData.animations
    in
    ( AnimState { animData | animations = updatedAnimations, pendingEvents = newPendingEvents }
    , Cmd.batch scrollCmds
    )
