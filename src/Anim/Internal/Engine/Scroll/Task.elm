module Anim.Internal.Engine.Scroll.Task exposing
    ( animateToPosition
    , scrollByWithConfig
    , scrollToCenterWithConfig
    , scrollToCoordinatesWithConfig
    , scrollToPercentageWithConfig
    , scrollToTopWithConfig
    , scrollToBottomWithConfig
    , scrollWithConfig
    )

{-| Merged internal task-based scroll implementations for both document and
container scrolling. Each function takes a `Container` parameter to determine
which DOM APIs to use.
-}

import Anim.Internal.AnimationCore exposing (animationStepsWithFrames)
import Anim.Internal.Engine.Scroll.Common exposing (Axis(..), Config)
import Anim.Internal.Engine.Scroll.Internal exposing (Container(..), Direction(..), getAxisDirection, getClampedPositions, getContainerInfo, getViewport, offsets, setViewport, timingToSpeed)
import Browser.Dom as Dom
import Task exposing (Task)


{-| Animate scroll to computed target position. Shared animation logic used by
all scroll functions.
-}
animateToPosition : Container -> Config -> { a | x : Float, y : Float } -> Float -> Float -> Task Dom.Error (List ())
animateToPosition container config viewport targetX targetY =
    case getAxisDirection config.axis of
        XDirection ->
            animationStepsWithFrames (timingToSpeed config.timing (abs (targetX - viewport.x))) config.easing viewport.x targetX
                |> List.map (\x -> setViewport container x viewport.y)
                |> Task.sequence

        YDirection ->
            animationStepsWithFrames (timingToSpeed config.timing (abs (targetY - viewport.y))) config.easing viewport.y targetY
                |> List.map (\y -> setViewport container viewport.x y)
                |> Task.sequence

        BothDirection ->
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
                    animationStepsWithFrames frames config.easing viewport.x targetX

                ySteps =
                    animationStepsWithFrames frames config.easing viewport.y targetY
            in
            case ( xSteps, ySteps ) of
                ( [], _ ) ->
                    ySteps
                        |> List.map (\y -> setViewport container viewport.x y)
                        |> Task.sequence

                ( _, [] ) ->
                    xSteps
                        |> List.map (\x -> setViewport container x viewport.y)
                        |> Task.sequence

                _ ->
                    List.map2 (\x y -> setViewport container x y) xSteps ySteps
                        |> Task.sequence


{-| Smooth scroll to an element within a container or document.
-}
scrollWithConfig : Container -> String -> Config -> Task Dom.Error (List ())
scrollWithConfig container elementId config =
    let
        getViewport_ =
            getViewport container

        getContainerInfo_ =
            getContainerInfo container

        performScrollTask { scene, viewport } { element } containerInfo =
            let
                ( clampedX, clampedY ) =
                    getClampedPositions element viewport scene containerInfo config
            in
            animateToPosition container config viewport clampedX clampedY
    in
    Task.map3 performScrollTask getViewport_ (Dom.getElement elementId) getContainerInfo_
        |> Task.andThen identity


{-| Smooth scroll to specific coordinates.
-}
scrollToCoordinatesWithConfig : Container -> Float -> Float -> Config -> Task Dom.Error (List ())
scrollToCoordinatesWithConfig container x y config =
    getViewport container
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
                animateToPosition container config viewport targetX targetY
            )


{-| Smooth scroll to the top.
-}
scrollToTopWithConfig : Container -> Config -> Task Dom.Error (List ())
scrollToTopWithConfig container config =
    getViewport container
        |> Task.andThen
            (\{ viewport } ->
                let
                    ( _, offsetY ) =
                        offsets container config.axis

                    targetY =
                        offsetY
                in
                animateToPosition container config viewport viewport.x targetY
            )


{-| Smooth scroll to the bottom.
-}
scrollToBottomWithConfig : Container -> Config -> Task Dom.Error (List ())
scrollToBottomWithConfig container config =
    getViewport container
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxY =
                        scene.height - viewport.height

                    ( _, offsetY ) =
                        offsets container config.axis

                    targetY =
                        maxY - offsetY
                in
                animateToPosition container config viewport viewport.x targetY
            )


{-| Smooth scroll to the center.
-}
scrollToCenterWithConfig : Container -> Config -> Task Dom.Error (List ())
scrollToCenterWithConfig container config =
    getViewport container
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
scrollToPercentageWithConfig : Container -> Float -> Float -> Config -> Task Dom.Error (List ())
scrollToPercentageWithConfig container percentageX percentageY config =
    getViewport container
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
scrollByWithConfig : Container -> Float -> Float -> Config -> Task Dom.Error (List ())
scrollByWithConfig container deltaX deltaY config =
    getViewport container
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
