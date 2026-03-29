module Anim.Internal.Engine.Scroll.Task exposing
    ( ScrollError(..)
    , animate
    , animateToPosition
    , scrollByWithConfig
    , scrollToBottomWithConfig
    , scrollToCenterWithConfig
    , scrollToCoordinatesWithConfig
    , scrollToPercentageWithConfig
    , scrollToTopWithConfig
    , scrollWithConfig
    )

import Anim.Extra.Easing exposing (Easing(..))
import Anim.Internal.AnimationCore exposing (animationStepsWithFrames)
import Anim.Internal.Builder as InternalBuilder
import Anim.Internal.Engine.Scroll.Internal as ScrollInternal exposing (Container(..), Direction(..))
import Anim.Internal.Engine.Scroll.ScrollTarget as ScrollTarget
import Anim.Internal.Extra.Easing as InternalEasing
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Dom as Dom
import Task exposing (Task)


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


animate : (AnimBuilder -> AnimBuilder) -> Task ScrollError ScrollOk
animate buildAnimation =
    let
        animBuilder =
            buildAnimation InternalBuilder.init

        scrollTargets =
            InternalBuilder.getScrollTargets animBuilder

        defaultSettings =
            getDefaultSettings animBuilder

        config =
            { timing =
                case defaultSettings.timeSpec of
                    Speed s ->
                        Speed s

                    Duration d ->
                        Duration d
            , easing = InternalEasing.toFunction 1000.0 defaultSettings.easing
            , axis = ScrollInternal.Both
            }

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

                        ScrollTarget.Top ->
                            "top"

                        ScrollTarget.Bottom ->
                            "bottom"

                        ScrollTarget.Center ->
                            "center"

                        ScrollTarget.Percentage x y ->
                            "percentage (" ++ String.fromFloat (x * 100) ++ "%, " ++ String.fromFloat (y * 100) ++ "%)"

                        ScrollTarget.Delta dx dy ->
                            "delta (" ++ String.fromFloat dx ++ ", " ++ String.fromFloat dy ++ ")"

                scrollResult =
                    { containerId = containerId
                    , targetElementId = targetElementId
                    , targetDescription = targetDescription
                    }

                baseTask =
                    let
                        container =
                            if containerId == "document" then
                                DocumentBody

                            else
                                Container containerId
                    in
                    case ScrollTarget.getTargetType target of
                        ScrollTarget.Element elementId ->
                            scrollWithConfig container elementId config

                        ScrollTarget.Coordinates x y ->
                            scrollToCoordinatesWithConfig container x y config

                        ScrollTarget.Top ->
                            scrollToTopWithConfig container config

                        ScrollTarget.Bottom ->
                            scrollToBottomWithConfig container config

                        ScrollTarget.Center ->
                            scrollToCenterWithConfig container config

                        ScrollTarget.Percentage px py ->
                            scrollToPercentageWithConfig container px py config

                        ScrollTarget.Delta dx dy ->
                            scrollByWithConfig container dx dy config
            in
            baseTask
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
                        { containerId = "document"
                        , targetElementId = Nothing
                        , targetDescription = "No scroll target"
                        }

                [ single ] ->
                    single

                first :: rest ->
                    first
                        |> Task.andThen (\_ -> sequenceTasks rest)
    in
    scrollTargets
        |> List.map createScrollTask
        |> sequenceTasks


{-| Get default settings from AnimBuilder for Task implementations.
-}
getDefaultSettings : InternalBuilder.AnimBuilder -> { timeSpec : TimeSpec, easing : Easing, offset : Float }
getDefaultSettings animBuilder =
    let
        timeSpec =
            InternalBuilder.getTimeSpecWithDefault animBuilder

        builderEasing =
            InternalBuilder.getEasing animBuilder |> Maybe.withDefault Linear
    in
    { timeSpec = timeSpec
    , easing = builderEasing
    , offset = 0.0
    }


{-| Animate scroll to computed target position. Shared animation logic used by
all scroll functions.
-}
animateToPosition : Container -> ScrollInternal.Config -> { a | x : Float, y : Float } -> Float -> Float -> Task Dom.Error (List ())
animateToPosition container config viewport targetX targetY =
    case ScrollInternal.getAxisDirection config.axis of
        XDirection ->
            animationStepsWithFrames (ScrollInternal.timingToSpeed config.timing (abs (targetX - viewport.x))) config.easing viewport.x targetX
                |> List.map (\x -> ScrollInternal.setViewport container x viewport.y)
                |> Task.sequence

        YDirection ->
            animationStepsWithFrames (ScrollInternal.timingToSpeed config.timing (abs (targetY - viewport.y))) config.easing viewport.y targetY
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
                    animationStepsWithFrames frames config.easing viewport.x targetX

                ySteps =
                    animationStepsWithFrames frames config.easing viewport.y targetY
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


{-| Smooth scroll to an element within a container or document.
-}
scrollWithConfig : Container -> String -> ScrollInternal.Config -> Task Dom.Error (List ())
scrollWithConfig container elementId config =
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


{-| Smooth scroll to specific coordinates.
-}
scrollToCoordinatesWithConfig : Container -> Float -> Float -> ScrollInternal.Config -> Task Dom.Error (List ())
scrollToCoordinatesWithConfig container x y config =
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


{-| Smooth scroll to the top.
-}
scrollToTopWithConfig : Container -> ScrollInternal.Config -> Task Dom.Error (List ())
scrollToTopWithConfig container config =
    ScrollInternal.getViewport container
        |> Task.andThen
            (\{ viewport } ->
                let
                    ( _, offsetY ) =
                        ScrollInternal.offsets container config.axis

                    targetY =
                        offsetY
                in
                animateToPosition container config viewport viewport.x targetY
            )


{-| Smooth scroll to the bottom.
-}
scrollToBottomWithConfig : Container -> ScrollInternal.Config -> Task Dom.Error (List ())
scrollToBottomWithConfig container config =
    ScrollInternal.getViewport container
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxY =
                        scene.height - viewport.height

                    ( _, offsetY ) =
                        ScrollInternal.offsets container config.axis

                    targetY =
                        maxY - offsetY
                in
                animateToPosition container config viewport viewport.x targetY
            )


{-| Smooth scroll to the center.
-}
scrollToCenterWithConfig : Container -> ScrollInternal.Config -> Task Dom.Error (List ())
scrollToCenterWithConfig container config =
    ScrollInternal.getViewport container
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    centerX =
                        (scene.width - viewport.width) / 2

                    centerY =
                        (scene.height - viewport.height) / 2
                in
                scrollToCoordinatesWithConfig container centerX centerY config
            )


{-| Smooth scroll to a percentage position. Percentages are 0.0 to 1.0.
-}
scrollToPercentageWithConfig : Container -> Float -> Float -> ScrollInternal.Config -> Task Dom.Error (List ())
scrollToPercentageWithConfig container percentageX percentageY config =
    ScrollInternal.getViewport container
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width

                    maxY =
                        scene.height - viewport.height

                    targetX =
                        maxX * percentageX

                    targetY =
                        maxY * percentageY
                in
                scrollToCoordinatesWithConfig container targetX targetY config
            )


{-| Smooth scroll by a relative offset from the current position.
-}
scrollByWithConfig : Container -> Float -> Float -> ScrollInternal.Config -> Task Dom.Error (List ())
scrollByWithConfig container deltaX deltaY config =
    ScrollInternal.getViewport container
        |> Task.andThen
            (\{ viewport } ->
                let
                    targetX =
                        viewport.x + deltaX

                    targetY =
                        viewport.y + deltaY
                in
                scrollToCoordinatesWithConfig container targetX targetY config
            )
