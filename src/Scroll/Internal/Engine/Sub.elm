module Scroll.Internal.Engine.Sub exposing
    ( ScrollEvent(..)
    , ScrollMsg(..)
    , ScrollState
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
    , scroll
    , speed
    , stop
    , subscriptions
    , update
    )

import Browser.Events exposing (onAnimationFrameDelta)
import Dict exposing (Dict)
import Motion.Easing as Easing exposing (Easing(..))
import Scroll.Internal.ScrollBuilder as SB exposing (ScrollBuilder)
import Scroll.Internal.Shared.Container as Container exposing (Container(..))
import Scroll.Internal.Shared.Dom as Dom
import Scroll.Internal.Shared.ScrollTarget as ScrollTarget exposing (Axis(..), ScrollTarget)
import Shared.Easing as Easing
import Shared.TimeSpec exposing (TimeSpec(..))
import Task



-- ============================================================
-- TYPES
-- ============================================================


type ScrollState
    = ScrollState ScrollData


type alias ScrollData =
    { scrolls : Dict String ScrollAnimation
    , pendingEvents : List ScrollEvent
    }


type alias ScrollAnimation =
    { config : ScrollConfig
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


type alias ScrollConfig =
    { containerId : Container
    , targetX : Float
    , targetY : Float
    , axis : Axis
    , timeSpec : TimeSpec
    , easing : Easing
    , delay : Int
    }



-- ============================================================
-- INITIALIZE
-- ============================================================


init : ScrollState
init =
    ScrollState
        { scrolls = Dict.empty
        , pendingEvents = []
        }



-- ============================================================
-- TRIGGER
-- ============================================================


scroll : (ScrollMsg -> msg) -> ScrollState -> (ScrollBuilder -> ScrollBuilder) -> ( ScrollState, Cmd msg )
scroll toMsg _ buildAnimation =
    let
        scrollBuilder =
            buildAnimation SB.init

        scrollTargets =
            SB.getScrollTargets scrollBuilder

        initScrollState =
            ScrollState
                { scrolls = Dict.empty
                , pendingEvents = []
                }

        domQueries =
            scrollTargets
                |> List.indexedMap
                    (\index scrollTarget ->
                        let
                            scrollId =
                                String.fromInt (index + 1)

                            container =
                                scrollTarget
                                    |> ScrollTarget.getContainerId
                                    |> Container.toContainer

                            targetType =
                                ScrollTarget.getTargetType scrollTarget

                            handleResult result =
                                case result of
                                    Ok domResult ->
                                        toMsg (DomQueriesCompleted scrollId scrollTarget scrollBuilder domResult)

                                    Err _ ->
                                        toMsg NoOp
                        in
                        case targetType of
                            ScrollTarget.Element elementId ->
                                Task.attempt handleResult <|
                                    Task.map3
                                        (\viewport containerEl element ->
                                            { viewport = viewport
                                            , containerElement = containerEl
                                            , targetElement = Just element
                                            }
                                        )
                                        (Dom.getViewport container)
                                        (Dom.getContainerInfo container)
                                        (Dom.getElement elementId)

                            _ ->
                                Task.attempt handleResult <|
                                    Task.map2
                                        (\viewport containerEl ->
                                            { viewport = viewport
                                            , containerElement = containerEl
                                            , targetElement = Nothing
                                            }
                                        )
                                        (Dom.getViewport container)
                                        (Dom.getContainerInfo container)
                    )
    in
    ( initScrollState, Cmd.batch domQueries )


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


speedToDuration : Float -> Float -> Int
speedToDuration speedPxPerSec distance =
    round (distance * 1000 / speedPxPerSec)


createScrollAnimationConfig : ScrollBuilder -> ScrollTarget -> ScrollConfig
createScrollAnimationConfig scrollBuilder scrollTarget =
    { containerId = Container.toContainer (ScrollTarget.getContainerId scrollTarget)
    , targetX = ScrollTarget.getTargetX scrollTarget
    , targetY = ScrollTarget.getTargetY scrollTarget
    , axis = ScrollTarget.getAxis scrollTarget
    , timeSpec = SB.getTimeSpecWithDefault scrollBuilder
    , easing = SB.getEasingWithDefault scrollBuilder
    , delay = SB.getDelayWithDefault scrollBuilder
    }


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


type ScrollMsg
    = ScrollFrame Float
    | DomQueriesCompleted String ScrollTarget ScrollBuilder DomQueryResult
    | NoOp


type alias DomQueryResult =
    { viewport : Dom.Viewport
    , containerElement : Maybe Dom.Element
    , targetElement : Maybe Dom.Element
    }


update : (ScrollEvent -> a) -> (ScrollMsg -> msg) -> ScrollMsg -> ScrollState -> ( ScrollState, List a, Cmd msg )
update fromInternalEvent toMsg msg (ScrollState scrollData) =
    case msg of
        ScrollFrame deltaMs ->
            let
                ( updatedScrolls, scrollCommands, frameEvents ) =
                    Dict.foldl
                        (\scrollId scrollAnim ( accScrolls, accCmds, accEvents ) ->
                            if scrollAnim.isPaused then
                                ( Dict.insert scrollId scrollAnim accScrolls, accCmds, accEvents )

                            else
                                let
                                    updatedScroll =
                                        updateScrollAnimation deltaMs scrollAnim

                                    cid =
                                        containerToString updatedScroll.config.containerId

                                    scrollCmd =
                                        Dom.setViewport updatedScroll.config.containerId updatedScroll.currentX updatedScroll.currentY
                                            |> Task.attempt (\_ -> toMsg NoOp)

                                    progressEvent =
                                        Progress cid
                                            { x = updatedScroll.currentX, y = updatedScroll.currentY }
                                            updatedScroll.progress
                                in
                                if updatedScroll.progress < 1.0 then
                                    ( Dict.insert scrollId updatedScroll accScrolls
                                    , scrollCmd :: accCmds
                                    , progressEvent :: accEvents
                                    )

                                else
                                    let
                                        completedScroll =
                                            { updatedScroll | isPaused = True }
                                    in
                                    ( Dict.insert scrollId completedScroll accScrolls
                                    , scrollCmd :: accCmds
                                    , Ended cid :: progressEvent :: accEvents
                                    )
                        )
                        ( Dict.empty, [], [] )
                        scrollData.scrolls

                allEvents =
                    scrollData.pendingEvents ++ List.reverse frameEvents
            in
            ( ScrollState { scrollData | scrolls = updatedScrolls, pendingEvents = [] }
            , List.map fromInternalEvent allEvents
            , Cmd.batch scrollCommands
            )

        DomQueriesCompleted scrollId scrollTarget scrollBuilder domResult ->
            let
                scrollAnimation =
                    case domResult.targetElement of
                        Just element ->
                            createScrollAnimationFromDom scrollBuilder scrollTarget domResult element

                        Nothing ->
                            createScrollAnimationFromViewport scrollBuilder scrollTarget domResult.viewport

                hasDistance =
                    calculateDistance scrollAnimation.config.axis scrollAnimation.startX scrollAnimation.startY scrollAnimation.config.targetX scrollAnimation.config.targetY > 0

                cid =
                    containerToString scrollAnimation.config.containerId

                ( updatedScrolls, newPendingEvents ) =
                    if hasDistance then
                        ( Dict.insert scrollId scrollAnimation scrollData.scrolls
                        , scrollData.pendingEvents ++ [ Started cid ]
                        )

                    else
                        ( scrollData.scrolls, scrollData.pendingEvents )
            in
            ( ScrollState { scrollData | scrolls = updatedScrolls, pendingEvents = newPendingEvents }
            , []
            , Cmd.none
            )

        NoOp ->
            ( ScrollState scrollData, [], Cmd.none )


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
                Easing.toFunction animation.config.easing

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


subscriptions : (ScrollMsg -> msg) -> ScrollState -> Sub msg
subscriptions toMsg scrollState =
    if anyRunning scrollState |> Maybe.withDefault False then
        onAnimationFrameDelta (ScrollFrame >> toMsg)

    else
        Sub.none



-- ============================================================
-- EVENTS
-- ============================================================


type ScrollEvent
    = Started String
    | Ended String
    | Progress String { x : Float, y : Float } Float
    | Stopped String
    | Paused String
    | Resumed String
    | Restarted String



-- ============================================================
-- CONTROLS
-- ============================================================


{-| Stop scroll animation for a specific container by jumping to end position.
-}
stop : String -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )
stop containerId toMsg (ScrollState scrollData) =
    let
        ( updatedScrolls, scrollCmds, newPendingEvents ) =
            Dict.foldl
                (\scrollId scrollAnim ( accScrolls, accCmds, accEvents ) ->
                    if containerMatches containerId scrollAnim.config.containerId then
                        let
                            scrollCmd =
                                Dom.setViewport scrollAnim.config.containerId scrollAnim.config.targetX scrollAnim.config.targetY
                                    |> Task.attempt (\_ -> toMsg NoOp)

                            cid =
                                containerToString scrollAnim.config.containerId
                        in
                        ( accScrolls, scrollCmd :: accCmds, accEvents ++ [ Stopped cid ] )

                    else
                        ( Dict.insert scrollId scrollAnim accScrolls, accCmds, accEvents )
                )
                ( Dict.empty, [], scrollData.pendingEvents )
                scrollData.scrolls
    in
    ( ScrollState { scrollData | scrolls = updatedScrolls, pendingEvents = newPendingEvents }
    , Cmd.batch scrollCmds
    )


{-| Pause scroll animation for a specific container.
-}
pause : String -> ScrollState -> ScrollState
pause containerId (ScrollState scrollData) =
    let
        ( updatedScrolls, newPendingEvents ) =
            Dict.foldl
                (\scrollId scrollAnim ( accScrolls, accEvents ) ->
                    if containerMatches containerId scrollAnim.config.containerId && not scrollAnim.isPaused then
                        ( Dict.insert scrollId { scrollAnim | isPaused = True } accScrolls
                        , accEvents ++ [ Paused (containerToString scrollAnim.config.containerId) ]
                        )

                    else
                        ( Dict.insert scrollId scrollAnim accScrolls, accEvents )
                )
                ( Dict.empty, scrollData.pendingEvents )
                scrollData.scrolls
    in
    ScrollState { scrollData | scrolls = updatedScrolls, pendingEvents = newPendingEvents }


{-| Resume scroll animation for a specific container.
-}
resume : String -> ScrollState -> ScrollState
resume containerId (ScrollState scrollData) =
    let
        ( updatedScrolls, newPendingEvents ) =
            Dict.foldl
                (\scrollId scrollAnim ( accScrolls, accEvents ) ->
                    if containerMatches containerId scrollAnim.config.containerId && scrollAnim.isPaused then
                        ( Dict.insert scrollId { scrollAnim | isPaused = False } accScrolls
                        , accEvents ++ [ Resumed (containerToString scrollAnim.config.containerId) ]
                        )

                    else
                        ( Dict.insert scrollId scrollAnim accScrolls, accEvents )
                )
                ( Dict.empty, scrollData.pendingEvents )
                scrollData.scrolls
    in
    ScrollState { scrollData | scrolls = updatedScrolls, pendingEvents = newPendingEvents }


{-| Reset scroll animation for a specific container.
-}
reset : String -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )
reset containerId toMsg (ScrollState scrollData) =
    let
        ( updatedScrolls, scrollCmds ) =
            Dict.foldl
                (\scrollId scrollAnim ( accScrolls, accCmds ) ->
                    if containerMatches containerId scrollAnim.config.containerId then
                        let
                            scrollCmd =
                                Dom.setViewport scrollAnim.config.containerId scrollAnim.startX scrollAnim.startY
                                    |> Task.attempt (\_ -> toMsg NoOp)

                            updatedScroll =
                                { scrollAnim
                                    | currentX = scrollAnim.startX
                                    , currentY = scrollAnim.startY
                                    , progress = 0.0
                                    , elapsedMs = 0.0
                                    , delayComplete = scrollAnim.delayMs == 0.0
                                    , isPaused = True
                                }
                        in
                        ( Dict.insert scrollId updatedScroll accScrolls, scrollCmd :: accCmds )

                    else
                        ( Dict.insert scrollId scrollAnim accScrolls, accCmds )
                )
                ( Dict.empty, [] )
                scrollData.scrolls
    in
    ( ScrollState { scrollData | scrolls = updatedScrolls }
    , Cmd.batch scrollCmds
    )


{-| Restart scroll animation for a specific container.
-}
restart : String -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )
restart containerId toMsg (ScrollState scrollData) =
    let
        ( updatedScrolls, scrollCmds, newPendingEvents ) =
            Dict.foldl
                (\scrollId scrollAnim ( accScrolls, accCmds, accEvents ) ->
                    if containerMatches containerId scrollAnim.config.containerId then
                        let
                            scrollCmd =
                                Dom.setViewport scrollAnim.config.containerId scrollAnim.startX scrollAnim.startY
                                    |> Task.attempt (\_ -> toMsg NoOp)

                            updatedScroll =
                                { scrollAnim
                                    | currentX = scrollAnim.startX
                                    , currentY = scrollAnim.startY
                                    , progress = 0.0
                                    , elapsedMs = 0.0
                                    , delayComplete = scrollAnim.delayMs == 0.0
                                    , isPaused = False
                                }
                        in
                        ( Dict.insert scrollId updatedScroll accScrolls
                        , scrollCmd :: accCmds
                        , accEvents ++ [ Restarted (containerToString scrollAnim.config.containerId) ]
                        )

                    else
                        ( Dict.insert scrollId scrollAnim accScrolls, accCmds, accEvents )
                )
                ( Dict.empty, [], scrollData.pendingEvents )
                scrollData.scrolls
    in
    ( ScrollState { scrollData | scrolls = updatedScrolls, pendingEvents = newPendingEvents }
    , Cmd.batch scrollCmds
    )



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> ScrollBuilder -> ScrollBuilder
delay =
    SB.setDelay


duration : Int -> ScrollBuilder -> ScrollBuilder
duration =
    SB.setDuration


speed : Float -> ScrollBuilder -> ScrollBuilder
speed =
    SB.setSpeed



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> ScrollBuilder -> ScrollBuilder
easing =
    SB.setEasing



-- ============================================================
-- STATE QUERIES
-- ============================================================


{-| Check if any scroll animations are currently running (not paused).
-}
anyRunning : ScrollState -> Maybe Bool
anyRunning (ScrollState scrollData) =
    if Dict.isEmpty scrollData.scrolls then
        Nothing

    else
        scrollData.scrolls
            |> Dict.values
            |> List.any (\scrollAnim -> not scrollAnim.isPaused)
            |> Just



-- ============================================================
-- POSITION QUERIES
-- ============================================================


{-| Get current scroll position for a specific container.
-}
getScrollPosition : String -> ScrollState -> Maybe { x : Float, y : Float }
getScrollPosition containerId (ScrollState scrollData) =
    scrollData.scrolls
        |> Dict.values
        |> List.filter (\scrollAnim -> containerMatches containerId scrollAnim.config.containerId)
        |> List.head
        |> Maybe.map (\scrollAnim -> { x = scrollAnim.currentX, y = scrollAnim.currentY })


{-| Get current horizontal scroll position for a specific container.
-}
getScrollPositionX : String -> ScrollState -> Maybe Float
getScrollPositionX containerId scrollState =
    getScrollPosition containerId scrollState
        |> Maybe.map .x


{-| Get current vertical scroll position for a specific container.
-}
getScrollPositionY : String -> ScrollState -> Maybe Float
getScrollPositionY containerId scrollState =
    getScrollPosition containerId scrollState
        |> Maybe.map .y


{-| Check if container matches a string ID.
-}
containerMatches : String -> Container -> Bool
containerMatches id container =
    case container of
        Document ->
            id == "document" || id == "body"

        Container elementId ->
            id == elementId


{-| Convert a Container to its string representation.
-}
containerToString : Container -> String
containerToString container =
    case container of
        Document ->
            "document"

        Container cid ->
            cid


{-| Check if a specific container is currently animating.
-}
isRunning : String -> ScrollState -> Maybe Bool
isRunning containerId (ScrollState scrollData) =
    if Dict.isEmpty scrollData.scrolls then
        Nothing

    else
        scrollData.scrolls
            |> Dict.values
            |> List.any (\scrollAnim -> containerMatches containerId scrollAnim.config.containerId)
            |> Just
