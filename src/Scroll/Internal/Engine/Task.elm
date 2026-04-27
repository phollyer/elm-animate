module Scroll.Internal.Engine.Task exposing
    ( ScrollError(..)
    , attempt
    , buildConfig
    , routeScrollTarget
    , scroll
    )

{- Portions of this module are derived from smooth-scroll by Linus Schoemaker and Ruben Lie King.
   Copyright (c) 2019, Linus Schoemaker, 2019, Ruben Lie King
   Licensed under the BSD 3-Clause License.
-}

import Browser.Dom as Dom
import Ease
import Easing exposing (Easing(..))
import Scroll.Internal.ScrollBuilder as SB
import Scroll.Internal.Shared.Container as Container exposing (Container(..))
import Scroll.Internal.Shared.Dom as Internal
import Scroll.Internal.Shared.ScrollTarget as ScrollTarget
import Shared.Easing as InternalEasing
import Shared.TimeSpec exposing (TimeSpec(..))
import Task exposing (Task)



-- ============================================================
-- TYPES
-- ============================================================


type alias ScrollBuilder =
    SB.ScrollBuilder


type ScrollError
    = ScrollError
        { containerId : String
        , targetElementId : Maybe String
        , domError : Dom.Error
        }


type alias ScrollOk =
    { containerId : String
    , targetElementId : Maybe String
    }


type alias Config =
    { timing : TimeSpec
    , easing : Float -> Float
    , axis : Axis
    }


type Axis
    = X
    | Y
    | Both
    | XWithOffset XOffsetFloat
    | YWithOffset YOffsetFloat
    | BothWithOffset XOffsetFloat YOffsetFloat


type Direction
    = XDirection
    | YDirection
    | BothDirections


type alias XOffsetFloat =
    Float


type alias YOffsetFloat =
    Float



-- ============================================================
-- TRIGGER
-- ============================================================


scroll : (ScrollBuilder -> ScrollBuilder) -> Task ScrollError (List ScrollOk)
scroll buildAnimation =
    let
        scrollBuilder =
            buildAnimation SB.init

        scrollTargets =
            SB.getScrollTargets scrollBuilder

        config =
            buildConfig scrollBuilder

        createScrollTask target =
            let
                containerId =
                    ScrollTarget.getContainerId target

                targetElementId =
                    ScrollTarget.getTargetElement target

                scrollResult =
                    { containerId = containerId
                    , targetElementId = targetElementId
                    }
            in
            routeScrollTarget target config
                |> Task.map (\_ -> scrollResult)
                |> Task.mapError
                    (\domError ->
                        ScrollError
                            { containerId = containerId
                            , targetElementId = targetElementId
                            , domError = domError
                            }
                    )

        sequenceFailFast tasks =
            case tasks of
                [] ->
                    Task.succeed []

                first :: rest ->
                    first
                        |> Task.andThen
                            (\result ->
                                sequenceFailFast rest
                                    |> Task.map (\remaining -> result :: remaining)
                            )
    in
    scrollTargets
        |> List.map createScrollTask
        |> sequenceFailFast


attempt : (ScrollBuilder -> ScrollBuilder) -> Task Never (List (Result ScrollError ScrollOk))
attempt buildAnimation =
    let
        scrollBuilder =
            buildAnimation SB.init

        scrollTargets =
            SB.getScrollTargets scrollBuilder

        config =
            buildConfig scrollBuilder

        createScrollTask target =
            let
                containerId =
                    ScrollTarget.getContainerId target

                targetElementId =
                    ScrollTarget.getTargetElement target

                scrollResult =
                    { containerId = containerId
                    , targetElementId = targetElementId
                    }
            in
            routeScrollTarget target config
                |> Task.map (\_ -> scrollResult)
                |> Task.mapError
                    (\domError ->
                        ScrollError
                            { containerId = containerId
                            , targetElementId = targetElementId
                            , domError = domError
                            }
                    )

        attemptTask task =
            task
                |> Task.map Ok
                |> Task.onError (Err >> Task.succeed)
    in
    scrollTargets
        |> List.map createScrollTask
        |> List.map attemptTask
        |> Task.sequence



-- ============================================================
-- CONFIG
-- ============================================================


{-| Build a scroll Config from a ScrollBuilder.
-}
buildConfig : SB.ScrollBuilder -> Config
buildConfig scrollBuilder =
    { timing = SB.getTimeSpecWithDefault scrollBuilder
    , easing =
        SB.getEasing scrollBuilder
            |> Maybe.withDefault Linear
            |> InternalEasing.toFunction 1000.0
    , axis = Both
    }



-- ============================================================
-- ROUTING
-- ============================================================


{-| Route a ScrollTarget to the appropriate scroll Task based on its target type.
-}
routeScrollTarget : ScrollTarget.ScrollTarget -> Config -> Task Dom.Error (List ())
routeScrollTarget target config =
    let
        container =
            target
                |> ScrollTarget.getContainerId
                |> Container.toContainer

        ( offsetX, offsetY ) =
            ScrollTarget.getOffset target

        updatedConfig =
            { config | axis = targetAxisToConfig (ScrollTarget.getAxis target) offsetX offsetY }
    in
    case ScrollTarget.getTargetType target of
        ScrollTarget.Element elementId ->
            scrollToTarget container elementId updatedConfig

        ScrollTarget.Coordinates x y ->
            scrollToCoordinates container x y updatedConfig

        ScrollTarget.Delta dx dy ->
            scrollBy container dx dy updatedConfig

        ScrollTarget.Percentage px py ->
            scrollToPercentage container px py ( offsetX, offsetY ) updatedConfig


targetAxisToConfig : ScrollTarget.Axis -> Float -> Float -> Axis
targetAxisToConfig targetAxis offsetX offsetY =
    case targetAxis of
        ScrollTarget.X ->
            XWithOffset offsetX

        ScrollTarget.Y ->
            YWithOffset offsetY

        ScrollTarget.Both ->
            BothWithOffset offsetX offsetY



-- ============================================================
-- SCROLL TASKS
-- ============================================================


{-| Smooth scroll to an element within a container or document.
-}
scrollToTarget : Container -> String -> Config -> Task Dom.Error (List ())
scrollToTarget container elementId config =
    let
        getViewport_ =
            Internal.getViewport container

        getContainerInfo_ =
            Internal.getContainerInfo container

        performScrollTask { scene, viewport } { element } containerInfo =
            let
                ( clampedX, clampedY ) =
                    getClampedPositions element viewport scene containerInfo config
            in
            scrollToPosition container config viewport clampedX clampedY
    in
    Task.map3 performScrollTask getViewport_ (Dom.getElement elementId) getContainerInfo_
        |> Task.andThen identity


scrollBy : Container -> Float -> Float -> Config -> Task Dom.Error (List ())
scrollBy container deltaX deltaY config =
    Internal.getViewport container
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    ( offsetX, offsetY ) =
                        offsets container config.axis

                    targetX =
                        (viewport.x + deltaX + offsetX)
                            |> max 0
                            |> min (scene.width - viewport.width)

                    targetY =
                        (viewport.y + deltaY + offsetY)
                            |> max 0
                            |> min (scene.height - viewport.height)
                in
                scrollToPosition container config viewport targetX targetY
            )


scrollToPercentage : Container -> Float -> Float -> ( Float, Float ) -> Config -> Task Dom.Error (List ())
scrollToPercentage container percentageX percentageY ( offsetX, offsetY ) config =
    Internal.getViewport container
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width

                    maxY =
                        scene.height - viewport.height

                    targetX =
                        applyDirectionalOffset maxX percentageX offsetX
                            |> max 0
                            |> min maxX

                    targetY =
                        applyDirectionalOffset maxY percentageY offsetY
                            |> max 0
                            |> min maxY
                in
                scrollToPosition container config viewport targetX targetY
            )


applyDirectionalOffset : Float -> Float -> Float -> Float
applyDirectionalOffset maxScroll percentage offset =
    if percentage <= 0.5 then
        maxScroll * percentage + offset

    else
        maxScroll * percentage - offset



-- ============================================================
-- ANIMATION
-- ============================================================


scrollToPosition : Container -> Config -> { a | x : Float, y : Float } -> Float -> Float -> Task Dom.Error (List ())
scrollToPosition container config viewport targetX targetY =
    case getAxisDirection config.axis of
        XDirection ->
            createSteps (timingToSpeed config.timing (abs (targetX - viewport.x))) config.easing viewport.x targetX
                |> List.map (\x -> Internal.setViewport container x viewport.y)
                |> Task.sequence

        YDirection ->
            createSteps (timingToSpeed config.timing (abs (targetY - viewport.y))) config.easing viewport.y targetY
                |> List.map (\y -> Internal.setViewport container viewport.x y)
                |> Task.sequence

        BothDirections ->
            let
                xDistance =
                    abs (viewport.x - targetX)

                yDistance =
                    abs (viewport.y - targetY)

                maxDistance =
                    max xDistance yDistance

                frames =
                    Basics.max 1 (timingToSpeed config.timing maxDistance)

                xSteps =
                    createSteps frames config.easing viewport.x targetX

                ySteps =
                    createSteps frames config.easing viewport.y targetY
            in
            case ( xSteps, ySteps ) of
                ( [], _ ) ->
                    ySteps
                        |> List.map (\y -> Internal.setViewport container viewport.x y)
                        |> Task.sequence

                ( _, [] ) ->
                    xSteps
                        |> List.map (\x -> Internal.setViewport container x viewport.y)
                        |> Task.sequence

                _ ->
                    List.map2 (\x y -> Internal.setViewport container x y) xSteps ySteps
                        |> Task.sequence


{-| Extract the basic axis direction from axis configuration, ignoring offsets.
-}
getAxisDirection : Axis -> Direction
getAxisDirection axis =
    case axis of
        X ->
            XDirection

        Y ->
            YDirection

        Both ->
            BothDirections

        XWithOffset _ ->
            XDirection

        YWithOffset _ ->
            YDirection

        BothWithOffset _ _ ->
            BothDirections


createSteps : Int -> Ease.Easing -> Float -> Float -> List Float
createSteps frames easing start stop =
    let
        diff =
            abs (start - stop)

        framesFloat =
            toFloat frames

        -- Use (frames - 1) as divisor so progress ranges from 0.0 to 1.0 exactly
        -- Clamped to min 1.0 to avoid division by zero when frames = 1
        -- Frame 0: 0/(frames-1) = 0.0, Frame (frames-1): (frames-1)/(frames-1) = 1.0
        weights =
            List.map (\i -> easing (toFloat i / max 1.0 (framesFloat - 1))) (List.range 0 (frames - 1))

        operator =
            if start > stop then
                (-)

            else
                (+)

        steps_ =
            List.map (\weight -> operator start (weight * diff)) weights

        -- Ensure the final step is exactly the target value
        -- This fixes issues where easing functions don't return exactly 1.0 at progress=1.0
        finalSteps =
            case List.reverse steps_ of
                [] ->
                    []

                _ :: rest ->
                    List.reverse (stop :: rest)
    in
    if start == stop then
        []

    else
        finalSteps


scrollToCoordinates : Container -> Float -> Float -> Config -> Task Dom.Error (List ())
scrollToCoordinates container x y config =
    Internal.getViewport container
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    ( offsetX, offsetY ) =
                        offsets container config.axis

                    maxX =
                        scene.width - viewport.width

                    maxY =
                        scene.height - viewport.height

                    targetX =
                        (x + offsetX)
                            |> max 0
                            |> min maxX

                    targetY =
                        (y + offsetY)
                            |> max 0
                            |> min maxY
                in
                scrollToPosition container config viewport targetX targetY
            )



-- ============================================================
-- CALCULATIONS
-- ============================================================


{-| Calculate clamped scroll positions to ensure they stay within bounds.
-}
getClampedPositions : { a | x : Float, y : Float, height : Float, width : Float } -> { a | x : Float, y : Float, height : Float, width : Float } -> { a | width : Float, height : Float } -> Maybe Dom.Element -> Config -> CoordinatePair
getClampedPositions element viewport scene container config =
    let
        ( targetX, targetY ) =
            getTargetPositions element viewport container config
    in
    ( targetX
        |> min (scene.width - viewport.width)
        |> max 0
    , targetY
        |> min (scene.height - viewport.height)
        |> max 0
    )


{-| Calculate target scroll positions based on element position and container.
-}
getTargetPositions : { a | x : Float, y : Float } -> { a | x : Float, y : Float } -> Maybe Dom.Element -> Config -> CoordinatePair
getTargetPositions element viewport container config =
    let
        offsetX =
            getOffsetX config.axis

        offsetY =
            getOffsetY config.axis
    in
    case container of
        Nothing ->
            ( viewport.x + element.x - offsetX
            , viewport.y + element.y - offsetY
            )

        Just containerInfo ->
            ( viewport.x + element.x - offsetX - containerInfo.element.x
            , viewport.y + element.y - offsetY - containerInfo.element.y
            )


{-| Get offsets for a container. Document scrolling uses axis offsets;
container scrolling uses zero offsets.
-}
offsets : Container -> Axis -> ( Float, Float )
offsets container axis =
    case container of
        Document ->
            ( getOffsetX axis, getOffsetY axis )

        Container _ ->
            ( 0, 0 )


getOffsetX : Axis -> XOffsetFloat
getOffsetX axis =
    case axis of
        X ->
            0.0

        Y ->
            0.0

        Both ->
            0.0

        XWithOffset offset ->
            offset

        YWithOffset _ ->
            0.0

        BothWithOffset offsetX _ ->
            offsetX


getOffsetY : Axis -> YOffsetFloat
getOffsetY axis =
    case axis of
        X ->
            0.0

        Y ->
            0.0

        Both ->
            0.0

        XWithOffset _ ->
            0.0

        YWithOffset offset ->
            offset

        BothWithOffset _ offsetY ->
            offsetY


type alias CoordinatePair =
    ( Float, Float )



-- ============================================================
-- TIMING
-- ============================================================


type alias Distance =
    Float


type alias Frames =
    Int


timingToSpeed : TimeSpec -> Distance -> Frames
timingToSpeed timing distance =
    case timing of
        Speed pixelsPerSecond ->
            -- Convert pixels per second to frame divider
            -- Assuming 60fps, we want: frames = distance / (pixelsPerSecond / 60)
            max 1 (round (distance * 60 / pixelsPerSecond))

        Duration milliseconds ->
            -- Convert duration in milliseconds to frame count
            -- Assuming 60fps: frames = (milliseconds / 1000) * 60 = milliseconds * 0.06
            max 1 (round (toFloat milliseconds * 0.06))
