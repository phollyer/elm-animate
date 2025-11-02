module Scroll.Document.Task exposing
    ( scroll, scrollWithConfig, jump, jumpWithConfig
    , scrollIntoView, scrollIntoViewWithConfig, jumpIntoView, jumpIntoViewWithConfig
    , scrollToTop, scrollToTopWithConfig, jumpToTop, jumpToTopWithConfig
    , scrollToBottom, scrollToBottomWithConfig, jumpToBottom, jumpToBottomWithConfig
    , scrollToLeftEdge, scrollToLeftEdgeWithConfig, jumpToLeftEdge, jumpToLeftEdgeWithConfig
    , scrollToRightEdge, scrollToRightEdgeWithConfig, jumpToRightEdge, jumpToRightEdgeWithConfig
    )

{-| Document scrolling tasks for smooth animations. These functions scroll the main document body.


# Element-Targeting Functions

@docs scroll, scrollWithConfig, jump, jumpWithConfig


# Bring Into View Functions

Bring an element into view using minimal movement.

If an element is below the viewport, it will only scroll up enough to make it fully visible, accounting for its height.
If the element is taller than the viewport, it will align the top of the element with the top of the viewport.
The same logic applies for horizontal scrolling, with the left edge equating to the top.

@docs scrollIntoView, scrollIntoViewWithConfig, jumpIntoView, jumpIntoViewWithConfig


# Position-Targeting Functions


## Top

@docs scrollToTop, scrollToTopWithConfig, jumpToTop, jumpToTopWithConfig


## Bottom

@docs scrollToBottom, scrollToBottomWithConfig, jumpToBottom, jumpToBottomWithConfig


## Left Edge

@docs scrollToLeftEdge, scrollToLeftEdgeWithConfig, jumpToLeftEdge, jumpToLeftEdgeWithConfig


## Right Edge

@docs scrollToRightEdge, scrollToRightEdgeWithConfig, jumpToRightEdge, jumpToRightEdgeWithConfig

-}

import Browser.Dom as Dom
import Internal.AnimationCore exposing (animationSteps, animationStepsWithFrames)
import Scroll exposing (Axis(..), Config, Container(..), TargetId, defaultConfig)
import Scroll.Internal exposing (calculateScrollIntoView, getClampedPositions, getContainerInfo, getViewport, timingToSpeed)
import Task exposing (Task)


{-| Smooth scroll to element in document.
-}
scroll : TargetId -> Task Dom.Error (List ())
scroll elementId =
    scrollWithConfig elementId defaultConfig


{-| Smooth scroll to element in document with custom configuration.
-}
scrollWithConfig : TargetId -> Config -> Task Dom.Error (List ())
scrollWithConfig id config =
    let
        getViewport_ =
            getViewport DocumentBody

        getContainerInfo_ =
            getContainerInfo DocumentBody

        performScrollTask { scene, viewport } { element } containerInfo =
            let
                ( clampedX, clampedY ) =
                    getClampedPositions element viewport scene containerInfo config

                setViewportTask =
                    case config.axis of
                        X ->
                            animationSteps (timingToSpeed config.timing (abs (clampedX - viewport.x))) config.easing viewport.x clampedX
                                |> List.map (\x -> Dom.setViewport x viewport.y)
                                |> Task.sequence

                        Y ->
                            animationSteps (timingToSpeed config.timing (abs (clampedY - viewport.y))) config.easing viewport.y clampedY
                                |> List.map (\y -> Dom.setViewport viewport.x y)
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
                                        |> List.map (\y -> Dom.setViewport viewport.x y)
                                        |> Task.sequence

                                ( _, [] ) ->
                                    -- No vertical movement needed, only animate X
                                    xSteps
                                        |> List.map (\x -> Dom.setViewport x viewport.y)
                                        |> Task.sequence

                                _ ->
                                    List.map2 Dom.setViewport xSteps ySteps
                                        |> Task.sequence
            in
            setViewportTask
    in
    Task.map3 performScrollTask getViewport_ (Dom.getElement id) getContainerInfo_
        |> Task.andThen identity


{-| Jump instantly to element in document.
-}
jump : TargetId -> Task Dom.Error ()
jump elementId =
    jumpWithConfig elementId defaultConfig


{-| Jump instantly to element in document with custom configuration.
-}
jumpWithConfig : TargetId -> Config -> Task Dom.Error ()
jumpWithConfig id config =
    let
        getViewport_ =
            getViewport DocumentBody

        getContainerInfo_ =
            getContainerInfo DocumentBody

        performJumpTask { scene, viewport } { element } containerInfo =
            let
                ( clampedX, clampedY ) =
                    getClampedPositions element viewport scene containerInfo config

                setViewportTask =
                    case config.axis of
                        X ->
                            Dom.setViewport clampedX viewport.y

                        Y ->
                            Dom.setViewport viewport.x clampedY

                        Both ->
                            Dom.setViewport clampedX clampedY
            in
            setViewportTask
    in
    Task.map3 performJumpTask getViewport_ (Dom.getElement id) getContainerInfo_
        |> Task.andThen identity


{-| -}
scrollIntoView : TargetId -> Task Dom.Error (List ())
scrollIntoView elementId =
    scrollIntoViewWithConfig elementId defaultConfig


{-| -}
scrollIntoViewWithConfig : TargetId -> Config -> Task Dom.Error (List ())
scrollIntoViewWithConfig elementId config =
    let
        getViewport_ =
            getViewport DocumentBody

        getContainerInfo_ =
            getContainerInfo DocumentBody

        performScrollTask { scene, viewport } { element } containerInfo =
            let
                ( clampedX, clampedY ) =
                    calculateScrollIntoView element viewport scene containerInfo config

                setViewportTask =
                    case config.axis of
                        X ->
                            animationSteps (timingToSpeed config.timing (abs (clampedX - viewport.x))) config.easing viewport.x clampedX
                                |> List.map (\x -> Dom.setViewport x viewport.y)
                                |> Task.sequence

                        Y ->
                            animationSteps (timingToSpeed config.timing (abs (clampedY - viewport.y))) config.easing viewport.y clampedY
                                |> List.map (\y -> Dom.setViewport viewport.x y)
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
                                        |> List.map (\y -> Dom.setViewport viewport.x y)
                                        |> Task.sequence

                                ( _, [] ) ->
                                    -- No vertical movement needed, only animate X
                                    xSteps
                                        |> List.map (\x -> Dom.setViewport x viewport.y)
                                        |> Task.sequence

                                _ ->
                                    List.map2 Dom.setViewport xSteps ySteps
                                        |> Task.sequence
            in
            setViewportTask
    in
    Task.map3 performScrollTask getViewport_ (Dom.getElement elementId) getContainerInfo_
        |> Task.andThen identity


{-| -}
jumpIntoView : TargetId -> Task Dom.Error ()
jumpIntoView elementId =
    jumpIntoViewWithConfig elementId defaultConfig


{-| -}
jumpIntoViewWithConfig : TargetId -> Config -> Task Dom.Error ()
jumpIntoViewWithConfig elementId config =
    let
        getViewport_ =
            getViewport DocumentBody

        getContainerInfo_ =
            getContainerInfo DocumentBody

        performJumpTask { scene, viewport } { element } containerInfo =
            let
                ( clampedX, clampedY ) =
                    calculateScrollIntoView element viewport scene containerInfo config

                setViewportTask =
                    case config.axis of
                        X ->
                            Dom.setViewport clampedX viewport.y

                        Y ->
                            Dom.setViewport viewport.x clampedY

                        Both ->
                            Dom.setViewport clampedX clampedY
            in
            setViewportTask
    in
    Task.map3 performJumpTask getViewport_ (Dom.getElement elementId) getContainerInfo_
        |> Task.andThen identity


{-| Smooth scroll to top of document.
-}
scrollToTop : Task Dom.Error (List ())
scrollToTop =
    scrollToTopWithConfig defaultConfig


{-| Smooth scroll to top of document with custom configuration.
-}
scrollToTopWithConfig : Config -> Task Dom.Error (List ())
scrollToTopWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ viewport } ->
                let
                    steps =
                        animationSteps (timingToSpeed config.timing (abs viewport.y)) config.easing viewport.y 0
                in
                steps
                    |> List.map (\y -> Dom.setViewport viewport.x y)
                    |> Task.sequence
            )


{-| Smooth scroll to bottom of document.
-}
scrollToBottom : Task Dom.Error (List ())
scrollToBottom =
    scrollToBottomWithConfig defaultConfig


{-| Smooth scroll to bottom of document with custom configuration.
-}
scrollToBottomWithConfig : Config -> Task Dom.Error (List ())
scrollToBottomWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxY =
                        scene.height - viewport.height

                    steps =
                        animationSteps (timingToSpeed config.timing (abs (maxY - viewport.y))) config.easing viewport.y maxY
                in
                steps
                    |> List.map (\y -> Dom.setViewport viewport.x y)
                    |> Task.sequence
            )


{-| Smooth scroll to left edge of document.
-}
scrollToLeftEdge : Task Dom.Error (List ())
scrollToLeftEdge =
    scrollToLeftEdgeWithConfig defaultConfig


{-| Smooth scroll to left edge of document with custom configuration.
-}
scrollToLeftEdgeWithConfig : Config -> Task Dom.Error (List ())
scrollToLeftEdgeWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ viewport } ->
                let
                    steps =
                        animationSteps (timingToSpeed config.timing (abs viewport.x)) config.easing viewport.x 0
                in
                steps
                    |> List.map (\x -> Dom.setViewport x viewport.y)
                    |> Task.sequence
            )


{-| Smooth scroll to right edge of document.
-}
scrollToRightEdge : Task Dom.Error (List ())
scrollToRightEdge =
    scrollToRightEdgeWithConfig defaultConfig


{-| Smooth scroll to right edge of document with custom configuration.
-}
scrollToRightEdgeWithConfig : Config -> Task Dom.Error (List ())
scrollToRightEdgeWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width

                    steps =
                        animationSteps (timingToSpeed config.timing (abs (maxX - viewport.x))) config.easing viewport.x maxX
                in
                steps
                    |> List.map (\x -> Dom.setViewport x viewport.y)
                    |> Task.sequence
            )


{-| Jump instantly to top of document.
-}
jumpToTop : Task Dom.Error ()
jumpToTop =
    jumpToTopWithConfig defaultConfig


{-| Jump instantly to top of document with custom configuration.
-}
jumpToTopWithConfig : Config -> Task Dom.Error ()
jumpToTopWithConfig _ =
    Dom.getViewport
        |> Task.andThen (\{ viewport } -> Dom.setViewport viewport.x 0)


{-| Jump instantly to bottom of document.
-}
jumpToBottom : Task Dom.Error ()
jumpToBottom =
    jumpToBottomWithConfig defaultConfig


{-| Jump instantly to bottom of document with custom configuration.
-}
jumpToBottomWithConfig : Config -> Task Dom.Error ()
jumpToBottomWithConfig _ =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxY =
                        scene.height - viewport.height
                in
                Dom.setViewport viewport.x maxY
            )


{-| Jump instantly to left edge of document.
-}
jumpToLeftEdge : Task Dom.Error ()
jumpToLeftEdge =
    jumpToLeftEdgeWithConfig defaultConfig


{-| Jump instantly to left edge of document with custom configuration.
-}
jumpToLeftEdgeWithConfig : Config -> Task Dom.Error ()
jumpToLeftEdgeWithConfig _ =
    Dom.getViewport
        |> Task.andThen (\{ viewport } -> Dom.setViewport 0 viewport.y)


{-| Jump instantly to right edge of document.
-}
jumpToRightEdge : Task Dom.Error ()
jumpToRightEdge =
    jumpToRightEdgeWithConfig defaultConfig


{-| Jump instantly to right edge of document with custom configuration.
-}
jumpToRightEdgeWithConfig : Config -> Task Dom.Error ()
jumpToRightEdgeWithConfig _ =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width
                in
                Dom.setViewport maxX viewport.y
            )
