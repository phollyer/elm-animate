module Anim.Internal.Engine.Scroll.Task exposing
    ( ScrollError(..)
    , animate
    , buildConfig
    , routeScrollTarget
    )

{- This module contains code derived from SmoothScroll by Linus Schoemaker and Ruben Lie King (2019).
   The createSteps function implements frame-based interpolation logic from the original work.

-}

import Anim.Extra.Easing exposing (Easing(..))
import Anim.Internal.Builder as InternalBuilder
import Anim.Internal.Engine.Scroll.Internal as ScrollInternal exposing (Container(..), Direction(..))
import Anim.Internal.Engine.Scroll.ScrollTarget as ScrollTarget
import Anim.Internal.Extra.Easing as InternalEasing
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Dom as Dom
import Ease
import Task exposing (Task)



-- ============================================================
-- TYPES
-- ============================================================


type alias AnimBuilder =
    InternalBuilder.AnimBuilder


type ScrollError
    = ScrollError
        { containerId : String
        , targetElementId : Maybe String
        , domError : Dom.Error
        }


type alias ScrollOk =
    { containerId : String
    , targetElementId : Maybe String
    , targetDescription : String
    }



-- ============================================================
-- TRIGGER
-- ============================================================


animate : (AnimBuilder -> AnimBuilder) -> Task ScrollError ScrollOk
animate buildAnimation =
    let
        animBuilder =
            buildAnimation <|
                InternalBuilder.init []

        scrollTargets =
            InternalBuilder.getScrollTargets animBuilder

        config =
            buildConfig animBuilder

        createScrollTask target =
            let
                containerId =
                    ScrollTarget.getContainerId target

                targetElementId =
                    ScrollTarget.getTargetElement target

                targetDescription =
                    case ScrollTarget.getTargetType target of
                        ScrollTarget.Element id ->
                            "element '" ++ id ++ "'"

                        ScrollTarget.Coordinates x y ->
                            "coordinates (" ++ String.fromFloat x ++ ", " ++ String.fromFloat y ++ ")"

                        ScrollTarget.Percentage x y ->
                            "percentage (" ++ String.fromFloat (x * 100) ++ "%, " ++ String.fromFloat (y * 100) ++ "%)"

                        ScrollTarget.Delta dx dy ->
                            "delta (" ++ String.fromFloat dx ++ ", " ++ String.fromFloat dy ++ ")"

                scrollResult =
                    { containerId = containerId
                    , targetElementId = targetElementId
                    , targetDescription = targetDescription
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

        sequenceTasks tasks =
            case tasks of
                [] ->
                    Task.succeed
                        { containerId = ""
                        , targetElementId = Nothing
                        , targetDescription = "No scroll target"
                        }

                [ single ] ->
                    single

                first :: rest ->
                    Task.andThen (\_ -> sequenceTasks rest) first
    in
    scrollTargets
        |> List.map createScrollTask
        |> sequenceTasks



-- ============================================================
-- CONFIG
-- ============================================================


{-| Build a scroll Config from an AnimBuilder.
-}
buildConfig : InternalBuilder.AnimBuilder -> ScrollInternal.Config
buildConfig animBuilder =
    { timing = InternalBuilder.getTimeSpecWithDefault animBuilder
    , easing =
        InternalBuilder.getEasing animBuilder
            |> Maybe.withDefault Linear
            |> InternalEasing.toFunction 1000.0
    , axis = ScrollInternal.Both
    }



-- ============================================================
-- ROUTING
-- ============================================================


{-| Route a ScrollTarget to the appropriate scroll Task based on its target type.
-}
routeScrollTarget : ScrollTarget.ScrollTarget -> ScrollInternal.Config -> Task Dom.Error (List ())
routeScrollTarget target config =
    let
        container =
            ScrollInternal.toContainer (ScrollTarget.getContainerId target)

        offset =
            ScrollTarget.getOffset target

        updatedConfig =
            { config | axis = targetAxisToConfig (ScrollTarget.getAxis target) }
    in
    case ScrollTarget.getTargetType target of
        ScrollTarget.Element elementId ->
            scroll container elementId updatedConfig

        ScrollTarget.Coordinates x y ->
            scrollToCoordinates container x y updatedConfig

        ScrollTarget.Delta dx dy ->
            scrollBy container dx dy updatedConfig

        ScrollTarget.Percentage px py ->
            scrollToPercentage container px py offset updatedConfig


targetAxisToConfig : ScrollTarget.Axis -> ScrollInternal.Axis
targetAxisToConfig targetAxis =
    case targetAxis of
        ScrollTarget.X ->
            ScrollInternal.X

        ScrollTarget.Y ->
            ScrollInternal.Y

        ScrollTarget.Both ->
            ScrollInternal.Both



-- ============================================================
-- SCROLL TASKS
-- ============================================================


{-| Smooth scroll to an element within a container or document.
-}
scroll : Container -> String -> ScrollInternal.Config -> Task Dom.Error (List ())
scroll container elementId config =
    let
        getViewport_ =
            ScrollInternal.getViewport container

        getContainerInfo_ =
            ScrollInternal.getContainerInfo container

        performScrollTask { scene, viewport } { element } containerInfo =
            let
                ( clampedX, clampedY ) =
                    ScrollInternal.getClampedPositions element viewport scene containerInfo config
            in
            animateToPosition container config viewport clampedX clampedY
    in
    Task.map3 performScrollTask getViewport_ (Dom.getElement elementId) getContainerInfo_
        |> Task.andThen identity


scrollBy : Container -> Float -> Float -> ScrollInternal.Config -> Task Dom.Error (List ())
scrollBy container deltaX deltaY config =
    ScrollInternal.getViewport container
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    ( offsetX, offsetY ) =
                        ScrollInternal.offsets container config.axis

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


scrollToPercentage : Container -> Float -> Float -> ( Float, Float ) -> ScrollInternal.Config -> Task Dom.Error (List ())
scrollToPercentage container percentageX percentageY ( offsetX, offsetY ) config =
    ScrollInternal.getViewport container
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


animateToPosition : Container -> ScrollInternal.Config -> { a | x : Float, y : Float } -> Float -> Float -> Task Dom.Error (List ())
animateToPosition container config viewport targetX targetY =
    case ScrollInternal.getAxisDirection config.axis of
        XDirection ->
            createSteps (ScrollInternal.timingToSpeed config.timing (abs (targetX - viewport.x))) config.easing viewport.x targetX
                |> List.map (\x -> ScrollInternal.setViewport container x viewport.y)
                |> Task.sequence

        YDirection ->
            createSteps (ScrollInternal.timingToSpeed config.timing (abs (targetY - viewport.y))) config.easing viewport.y targetY
                |> List.map (\y -> ScrollInternal.setViewport container viewport.x y)
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
                    Basics.max 1 (ScrollInternal.timingToSpeed config.timing maxDistance)

                xSteps =
                    createSteps frames config.easing viewport.x targetX

                ySteps =
                    createSteps frames config.easing viewport.y targetY
            in
            case ( xSteps, ySteps ) of
                ( [], _ ) ->
                    ySteps
                        |> List.map (\y -> ScrollInternal.setViewport container viewport.x y)
                        |> Task.sequence

                ( _, [] ) ->
                    xSteps
                        |> List.map (\x -> ScrollInternal.setViewport container x viewport.y)
                        |> Task.sequence

                _ ->
                    List.map2 (\x y -> ScrollInternal.setViewport container x y) xSteps ySteps
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


scrollToCoordinates : Container -> Float -> Float -> ScrollInternal.Config -> Task Dom.Error (List ())
scrollToCoordinates container x y config =
    ScrollInternal.getViewport container
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    ( offsetX, offsetY ) =
                        ScrollInternal.offsets container config.axis

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
