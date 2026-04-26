module Scroll.Internal.Engine.Task exposing
    ( ScrollError(..)
    , animate
    , attempt
    , buildConfig
    , routeScrollTarget
    )

{- This module contains code derived from SmoothScroll by Linus Schoemaker and Ruben Lie King (2019).
   The createSteps function implements frame-based interpolation logic from the original work.

-}

import Browser.Dom as Dom
import Ease
import Easing exposing (Easing(..))
import Scroll.Internal.Engine.Internal as Internal exposing (Container, Direction(..))
import Scroll.Internal.Engine.ScrollTarget as ScrollTarget
import Scroll.Internal.ScrollBuilder as SB
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



-- ============================================================
-- TRIGGER
-- ============================================================


animate : (ScrollBuilder -> ScrollBuilder) -> Task ScrollError (List ScrollOk)
animate buildAnimation =
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
buildConfig : SB.ScrollBuilder -> Internal.Config
buildConfig scrollBuilder =
    { timing = SB.getTimeSpecWithDefault scrollBuilder
    , easing =
        SB.getEasing scrollBuilder
            |> Maybe.withDefault Linear
            |> InternalEasing.toFunction 1000.0
    , axis = Internal.Both
    }



-- ============================================================
-- ROUTING
-- ============================================================


{-| Route a ScrollTarget to the appropriate scroll Task based on its target type.
-}
routeScrollTarget : ScrollTarget.ScrollTarget -> Internal.Config -> Task Dom.Error (List ())
routeScrollTarget target config =
    let
        container =
            Internal.toContainer (ScrollTarget.getContainerId target)

        ( offsetX, offsetY ) =
            ScrollTarget.getOffset target

        updatedConfig =
            { config | axis = targetAxisToConfig (ScrollTarget.getAxis target) offsetX offsetY }
    in
    case ScrollTarget.getTargetType target of
        ScrollTarget.Element elementId ->
            scroll container elementId updatedConfig

        ScrollTarget.Coordinates x y ->
            scrollToCoordinates container x y updatedConfig

        ScrollTarget.Delta dx dy ->
            scrollBy container dx dy updatedConfig

        ScrollTarget.Percentage px py ->
            scrollToPercentage container px py ( offsetX, offsetY ) updatedConfig


targetAxisToConfig : ScrollTarget.Axis -> Float -> Float -> Internal.Axis
targetAxisToConfig targetAxis offsetX offsetY =
    case targetAxis of
        ScrollTarget.X ->
            Internal.XWithOffset offsetX

        ScrollTarget.Y ->
            Internal.YWithOffset offsetY

        ScrollTarget.Both ->
            Internal.BothWithOffset offsetX offsetY



-- ============================================================
-- SCROLL TASKS
-- ============================================================


{-| Smooth scroll to an element within a container or document.
-}
scroll : Container -> String -> Internal.Config -> Task Dom.Error (List ())
scroll container elementId config =
    let
        getViewport_ =
            Internal.getViewport container

        getContainerInfo_ =
            Internal.getContainerInfo container

        performScrollTask { scene, viewport } { element } containerInfo =
            let
                ( clampedX, clampedY ) =
                    Internal.getClampedPositions element viewport scene containerInfo config
            in
            animateToPosition container config viewport clampedX clampedY
    in
    Task.map3 performScrollTask getViewport_ (Dom.getElement elementId) getContainerInfo_
        |> Task.andThen identity


scrollBy : Container -> Float -> Float -> Internal.Config -> Task Dom.Error (List ())
scrollBy container deltaX deltaY config =
    Internal.getViewport container
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    ( offsetX, offsetY ) =
                        Internal.offsets container config.axis

                    targetX =
                        (viewport.x + deltaX + offsetX)
                            |> max 0
                            |> min (scene.width - viewport.width)

                    targetY =
                        (viewport.y + deltaY + offsetY)
                            |> max 0
                            |> min (scene.height - viewport.height)
                in
                animateToPosition container config viewport targetX targetY
            )


scrollToPercentage : Container -> Float -> Float -> ( Float, Float ) -> Internal.Config -> Task Dom.Error (List ())
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
                animateToPosition container config viewport targetX targetY
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


animateToPosition : Container -> Internal.Config -> { a | x : Float, y : Float } -> Float -> Float -> Task Dom.Error (List ())
animateToPosition container config viewport targetX targetY =
    case Internal.getAxisDirection config.axis of
        XDirection ->
            createSteps (Internal.timingToSpeed config.timing (abs (targetX - viewport.x))) config.easing viewport.x targetX
                |> List.map (\x -> Internal.setViewport container x viewport.y)
                |> Task.sequence

        YDirection ->
            createSteps (Internal.timingToSpeed config.timing (abs (targetY - viewport.y))) config.easing viewport.y targetY
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
                    Basics.max 1 (Internal.timingToSpeed config.timing maxDistance)

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


createSteps : Int -> Ease.Easing -> Float -> Float -> List Float
createSteps frames easing start stop =
    let
        diff =
            abs <| start - stop

        framesFloat =
            toFloat frames

        -- Use (frames - 1) as divisor so progress ranges from 0.0 to 1.0 exactly
        -- Frame 0: 0/(frames-1) = 0.0, Frame (frames-1): (frames-1)/(frames-1) = 1.0
        weights =
            List.map (\i -> easing (toFloat i / (framesFloat - 1))) (List.range 0 (frames - 1))

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
    if frames <= 0 || start == stop then
        []

    else
        finalSteps


scrollToCoordinates : Container -> Float -> Float -> Internal.Config -> Task Dom.Error (List ())
scrollToCoordinates container x y config =
    Internal.getViewport container
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    ( offsetX, offsetY ) =
                        Internal.offsets container config.axis

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
                animateToPosition container config viewport targetX targetY
            )
