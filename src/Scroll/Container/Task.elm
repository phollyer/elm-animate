module Scroll.Container.Task exposing
    ( scroll, scrollWithConfig, jump, jumpWithConfig
    , scrollToTop, scrollToTopWithConfig, scrollToBottom, scrollToBottomWithConfig
    , scrollToLeftEdge, scrollToLeftEdgeWithConfig, scrollToRightEdge, scrollToRightEdgeWithConfig
    , jumpToTop, jumpToTopWithConfig, jumpToBottom, jumpToBottomWithConfig
    , jumpToLeftEdge, jumpToLeftEdgeWithConfig, jumpToRightEdge, jumpToRightEdgeWithConfig
    )

{-| Container scrolling tasks for smooth animations. These functions scroll within specific DOM containers.


# Element-Targeting Functions

@docs scroll, scrollWithConfig, jump, jumpWithConfig


# Position-Targeting Functions

@docs scrollToTop, scrollToTopWithConfig, scrollToBottom, scrollToBottomWithConfig
@docs scrollToLeftEdge, scrollToLeftEdgeWithConfig, scrollToRightEdge, scrollToRightEdgeWithConfig


# Jump Functions (Instant Movement)

@docs jumpToTop, jumpToTopWithConfig, jumpToBottom, jumpToBottomWithConfig
@docs jumpToLeftEdge, jumpToLeftEdgeWithConfig, jumpToRightEdge, jumpToRightEdgeWithConfig

-}

import Browser.Dom as Dom
import Internal.AnimationCore exposing (animationSteps, animationStepsWithFrames)
import Scroll exposing (Axis(..), Config, Container(..), ElementId, defaultConfig)
import Scroll.Internal exposing (getClampedPositions, getContainerInfo, getViewport, timingToSpeed)
import Task exposing (Task)


{-| Smooth scroll to element within a container.
-}
scroll : ElementId -> ElementId -> Task Dom.Error (List ())
scroll containerId elementId =
    scrollWithConfig containerId elementId defaultConfig


{-| Smooth scroll to element within a container with custom configuration.
-}
scrollWithConfig : ElementId -> ElementId -> Config -> Task Dom.Error (List ())
scrollWithConfig containerId elementId config =
    let
        getViewport_ =
            getViewport (Container containerId)

        getContainerInfo_ =
            getContainerInfo (Container containerId)

        performScrollTask { scene, viewport } { element } containerInfo =
            let
                ( clampedX, clampedY ) =
                    getClampedPositions element viewport scene containerInfo config

                setViewportTask =
                    case config.axis of
                        X ->
                            animationSteps (timingToSpeed config.timing (abs (clampedX - viewport.x))) config.easing viewport.x clampedX
                                |> List.map (\x -> Dom.setViewportOf containerId x viewport.y)
                                |> Task.sequence

                        Y ->
                            animationSteps (timingToSpeed config.timing (abs (clampedY - viewport.y))) config.easing viewport.y clampedY
                                |> List.map (\y -> Dom.setViewportOf containerId viewport.x y)
                                |> Task.sequence

                        Both ->
                            let
                                -- Calculate the maximum distance to determine frame count
                                xDistance =
                                    abs (viewport.x - clampedX)

                                yDistance =
                                    abs (viewport.y - clampedY)

                                maxDistance =
                                    max xDistance yDistance

                                -- Use the same frame count for both axes to ensure synchronization
                                frames =
                                    Basics.max 1 (timingToSpeed config.timing maxDistance)

                                -- Generate synchronized steps
                                xSteps =
                                    animationStepsWithFrames frames config.easing viewport.x clampedX

                                ySteps =
                                    animationStepsWithFrames frames config.easing viewport.y clampedY
                            in
                            case ( xSteps, ySteps ) of
                                ( [], _ ) ->
                                    -- No horizontal movement needed, only animate Y
                                    ySteps
                                        |> List.map (\y -> Dom.setViewportOf containerId viewport.x y)
                                        |> Task.sequence

                                ( _, [] ) ->
                                    -- No vertical movement needed, only animate X
                                    xSteps
                                        |> List.map (\x -> Dom.setViewportOf containerId x viewport.y)
                                        |> Task.sequence

                                _ ->
                                    List.map2 (Dom.setViewportOf containerId) xSteps ySteps
                                        |> Task.sequence
            in
            setViewportTask
    in
    Task.map3 performScrollTask getViewport_ (Dom.getElement elementId) getContainerInfo_
        |> Task.andThen identity


{-| Jump instantly to element within a container.
-}
jump : ElementId -> ElementId -> Task Dom.Error ()
jump containerId elementId =
    jumpWithConfig containerId elementId defaultConfig


{-| Jump instantly to element within a container with custom configuration.
-}
jumpWithConfig : ElementId -> ElementId -> Config -> Task Dom.Error ()
jumpWithConfig containerId elementId config =
    let
        getViewport_ =
            getViewport (Container containerId)

        getContainerInfo_ =
            getContainerInfo (Container containerId)

        performJumpTask { scene, viewport } { element } containerInfo =
            let
                ( clampedX, clampedY ) =
                    getClampedPositions element viewport scene containerInfo config

                setViewportTask =
                    case config.axis of
                        X ->
                            Dom.setViewportOf containerId clampedX viewport.y

                        Y ->
                            Dom.setViewportOf containerId viewport.x clampedY

                        Both ->
                            Dom.setViewportOf containerId clampedX clampedY
            in
            setViewportTask
    in
    Task.map3 performJumpTask getViewport_ (Dom.getElement elementId) getContainerInfo_
        |> Task.andThen identity


{-| Smooth scroll to top of container.
-}
scrollToTop : ElementId -> Task Dom.Error (List ())
scrollToTop containerId =
    scrollToTopWithConfig containerId defaultConfig


{-| Smooth scroll to top of container with custom configuration.
-}
scrollToTopWithConfig : ElementId -> Config -> Task Dom.Error (List ())
scrollToTopWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ viewport } ->
                let
                    steps =
                        animationSteps (timingToSpeed config.timing (abs viewport.y)) config.easing viewport.y 0
                in
                steps
                    |> List.map (\y -> Dom.setViewportOf containerId viewport.x y)
                    |> Task.sequence
            )


{-| Smooth scroll to bottom of container.
-}
scrollToBottom : ElementId -> Task Dom.Error (List ())
scrollToBottom containerId =
    scrollToBottomWithConfig containerId defaultConfig


{-| Smooth scroll to bottom of container with custom configuration.
-}
scrollToBottomWithConfig : ElementId -> Config -> Task Dom.Error (List ())
scrollToBottomWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxY =
                        scene.height - viewport.height

                    steps =
                        animationSteps (timingToSpeed config.timing (abs (maxY - viewport.y))) config.easing viewport.y maxY
                in
                steps
                    |> List.map (\y -> Dom.setViewportOf containerId viewport.x y)
                    |> Task.sequence
            )


{-| Smooth scroll to left edge of container.
-}
scrollToLeftEdge : ElementId -> Task Dom.Error (List ())
scrollToLeftEdge containerId =
    scrollToLeftEdgeWithConfig containerId defaultConfig


{-| Smooth scroll to left edge of container with custom configuration.
-}
scrollToLeftEdgeWithConfig : ElementId -> Config -> Task Dom.Error (List ())
scrollToLeftEdgeWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ viewport } ->
                let
                    steps =
                        animationSteps (timingToSpeed config.timing (abs viewport.x)) config.easing viewport.x 0
                in
                steps
                    |> List.map (\x -> Dom.setViewportOf containerId x viewport.y)
                    |> Task.sequence
            )


{-| Smooth scroll to right edge of container.
-}
scrollToRightEdge : ElementId -> Task Dom.Error (List ())
scrollToRightEdge containerId =
    scrollToRightEdgeWithConfig containerId defaultConfig


{-| Smooth scroll to right edge of container with custom configuration.
-}
scrollToRightEdgeWithConfig : ElementId -> Config -> Task Dom.Error (List ())
scrollToRightEdgeWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width

                    steps =
                        animationSteps (timingToSpeed config.timing (abs (maxX - viewport.x))) config.easing viewport.x maxX
                in
                steps
                    |> List.map (\x -> Dom.setViewportOf containerId x viewport.y)
                    |> Task.sequence
            )


{-| Jump instantly to top of container.
-}
jumpToTop : ElementId -> Task Dom.Error ()
jumpToTop containerId =
    jumpToTopWithConfig containerId defaultConfig


{-| Jump instantly to top of container with custom configuration.
-}
jumpToTopWithConfig : ElementId -> Config -> Task Dom.Error ()
jumpToTopWithConfig containerId _ =
    Dom.getViewportOf containerId
        |> Task.andThen (\{ viewport } -> Dom.setViewportOf containerId viewport.x 0)


{-| Jump instantly to bottom of container.
-}
jumpToBottom : ElementId -> Task Dom.Error ()
jumpToBottom containerId =
    jumpToBottomWithConfig containerId defaultConfig


{-| Jump instantly to bottom of container with custom configuration.
-}
jumpToBottomWithConfig : ElementId -> Config -> Task Dom.Error ()
jumpToBottomWithConfig containerId _ =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxY =
                        scene.height - viewport.height
                in
                Dom.setViewportOf containerId viewport.x maxY
            )


{-| Jump instantly to left edge of container.
-}
jumpToLeftEdge : ElementId -> Task Dom.Error ()
jumpToLeftEdge containerId =
    jumpToLeftEdgeWithConfig containerId defaultConfig


{-| Jump instantly to left edge of container with custom configuration.
-}
jumpToLeftEdgeWithConfig : ElementId -> Config -> Task Dom.Error ()
jumpToLeftEdgeWithConfig containerId _ =
    Dom.getViewportOf containerId
        |> Task.andThen (\{ viewport } -> Dom.setViewportOf containerId 0 viewport.y)


{-| Jump instantly to right edge of container.
-}
jumpToRightEdge : ElementId -> Task Dom.Error ()
jumpToRightEdge containerId =
    jumpToRightEdgeWithConfig containerId defaultConfig


{-| Jump instantly to right edge of container with custom configuration.
-}
jumpToRightEdgeWithConfig : ElementId -> Config -> Task Dom.Error ()
jumpToRightEdgeWithConfig containerId _ =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width
                in
                Dom.setViewportOf containerId maxX viewport.y
            )
