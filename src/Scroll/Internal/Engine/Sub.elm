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
import Easing exposing (Easing(..))
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

        initAnimState =
            ScrollState
                { scrolls = Dict.empty
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
                                scrollTarget
                                    |> ScrollTarget.getContainerId
                                    |> Container.toContainer

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
    ( initAnimState, Cmd.batch domQueries )


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
update fromInternalEvent toMsg msg (ScrollState animData) =
    case msg of
        ScrollFrame deltaMs ->
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
                                        Dom.setViewport updatedAnim.config.containerId updatedAnim.currentX updatedAnim.currentY
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
                        animData.scrolls

                allEvents =
                    animData.pendingEvents ++ List.reverse frameEvents
            in
            ( ScrollState { animData | scrolls = updatedAnimations, pendingEvents = [] }
            , List.map fromInternalEvent allEvents
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
                        ( Dict.insert animId animation animData.scrolls
                        , animData.pendingEvents ++ [ Started cid ]
                        )

                    else
                        ( animData.scrolls, animData.pendingEvents )
            in
            ( ScrollState { animData | scrolls = updatedAnimations, pendingEvents = newPendingEvents }
            , []
            , Cmd.none
            )

        NoOp ->
            ( ScrollState animData, [], Cmd.none )


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


subscriptions : (ScrollMsg -> msg) -> ScrollState -> Sub msg
subscriptions toMsg animState =
    if anyRunning animState |> Maybe.withDefault False then
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
-- ANIMATION CONTROL
-- ============================================================


{-| Stop scroll animation for a specific container by jumping to end position.
-}
stop : String -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )
stop containerId toMsg (ScrollState animData) =
    let
        ( updatedAnimations, scrollCmds, newPendingEvents ) =
            Dict.foldl
                (\animId anim ( accAnims, accCmds, accEvents ) ->
                    if containerMatches containerId anim.config.containerId then
                        let
                            scrollCmd =
                                Dom.setViewport anim.config.containerId anim.config.targetX anim.config.targetY
                                    |> Task.attempt (\_ -> toMsg NoOp)

                            cid =
                                containerToString anim.config.containerId
                        in
                        ( accAnims, scrollCmd :: accCmds, accEvents ++ [ Stopped cid ] )

                    else
                        ( Dict.insert animId anim accAnims, accCmds, accEvents )
                )
                ( Dict.empty, [], animData.pendingEvents )
                animData.scrolls
    in
    ( ScrollState { animData | scrolls = updatedAnimations, pendingEvents = newPendingEvents }
    , Cmd.batch scrollCmds
    )


{-| Pause scroll animation for a specific container.
-}
pause : String -> ScrollState -> ScrollState
pause containerId (ScrollState animData) =
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
                animData.scrolls
    in
    ScrollState { animData | scrolls = updatedAnimations, pendingEvents = newPendingEvents }


{-| Resume scroll animation for a specific container.
-}
resume : String -> ScrollState -> ScrollState
resume containerId (ScrollState animData) =
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
                animData.scrolls
    in
    ScrollState { animData | scrolls = updatedAnimations, pendingEvents = newPendingEvents }


{-| Reset scroll animation for a specific container.
-}
reset : String -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )
reset containerId toMsg (ScrollState animData) =
    let
        ( updatedAnimations, scrollCmds ) =
            Dict.foldl
                (\animId anim ( accAnims, accCmds ) ->
                    if containerMatches containerId anim.config.containerId then
                        let
                            scrollCmd =
                                Dom.setViewport anim.config.containerId anim.startX anim.startY
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
                animData.scrolls
    in
    ( ScrollState { animData | scrolls = updatedAnimations }
    , Cmd.batch scrollCmds
    )


{-| Restart scroll animation for a specific container.
-}
restart : String -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )
restart containerId toMsg (ScrollState animData) =
    let
        ( updatedAnimations, scrollCmds, newPendingEvents ) =
            Dict.foldl
                (\animId anim ( accAnims, accCmds, accEvents ) ->
                    if containerMatches containerId anim.config.containerId then
                        let
                            scrollCmd =
                                Dom.setViewport anim.config.containerId anim.startX anim.startY
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
                animData.scrolls
    in
    ( ScrollState { animData | scrolls = updatedAnimations, pendingEvents = newPendingEvents }
    , Cmd.batch scrollCmds
    )



-- ============================================================
-- PLAYBACK SETTINGS
-- ============================================================


duration : Int -> ScrollBuilder -> ScrollBuilder
duration =
    SB.setDuration


speed : Float -> ScrollBuilder -> ScrollBuilder
speed =
    SB.setSpeed


easing : Easing -> ScrollBuilder -> ScrollBuilder
easing =
    SB.setEasing


delay : Int -> ScrollBuilder -> ScrollBuilder
delay =
    SB.setDelay



-- ============================================================
-- STATE QUERIES
-- ============================================================


{-| Check if any scroll animations are currently running (not paused).
-}
anyRunning : ScrollState -> Maybe Bool
anyRunning (ScrollState animData) =
    if Dict.isEmpty animData.scrolls then
        Nothing

    else
        animData.scrolls
            |> Dict.values
            |> List.any (\anim -> not anim.isPaused)
            |> Just



-- ============================================================
-- POSITION QUERIES
-- ============================================================


{-| Get current scroll position for a specific container.
-}
getScrollPosition : String -> ScrollState -> Maybe { x : Float, y : Float }
getScrollPosition containerId (ScrollState animData) =
    animData.scrolls
        |> Dict.values
        |> List.filter (\anim -> containerMatches containerId anim.config.containerId)
        |> List.head
        |> Maybe.map (\anim -> { x = anim.currentX, y = anim.currentY })


{-| Get current horizontal scroll position for a specific container.
-}
getScrollPositionX : String -> ScrollState -> Maybe Float
getScrollPositionX containerId animState =
    getScrollPosition containerId animState
        |> Maybe.map .x


{-| Get current vertical scroll position for a specific container.
-}
getScrollPositionY : String -> ScrollState -> Maybe Float
getScrollPositionY containerId animState =
    getScrollPosition containerId animState
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
isRunning containerId (ScrollState animData) =
    if Dict.isEmpty animData.scrolls then
        Nothing

    else
        animData.scrolls
            |> Dict.values
            |> List.any (\anim -> containerMatches containerId anim.config.containerId)
            |> Just
