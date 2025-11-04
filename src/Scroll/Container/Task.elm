module Scroll.Container.Task exposing
    ( ContainerId, TargetId
    , scroll, scrollWithConfig, jump, jumpWithConfig
    , scrollIntoView, scrollIntoViewWithConfig, jumpIntoView, jumpIntoViewWithConfig
    , scrollToTop, scrollToTopWithConfig, jumpToTop, jumpToTopWithConfig
    , scrollToBottom, scrollToBottomWithConfig, jumpToBottom, jumpToBottomWithConfig
    , scrollToLeftEdge, scrollToLeftEdgeWithConfig, jumpToLeftEdge, jumpToLeftEdgeWithConfig
    , scrollToRightEdge, scrollToRightEdgeWithConfig, jumpToRightEdge, jumpToRightEdgeWithConfig
    , scrollToTopLeft, scrollToTopLeftWithConfig, jumpToTopLeft, jumpToTopLeftWithConfig
    , scrollToTopRight, scrollToTopRightWithConfig, jumpToTopRight, jumpToTopRightWithConfig
    , scrollToBottomLeft, scrollToBottomLeftWithConfig, jumpToBottomLeft, jumpToBottomLeftWithConfig
    , scrollToBottomRight, scrollToBottomRightWithConfig, jumpToBottomRight, jumpToBottomRightWithConfig
    , scrollToCenter, scrollToCenterWithConfig, jumpToCenter, jumpToCenterWithConfig
    , scrollToCenterX, scrollToCenterXWithConfig, jumpToCenterX, jumpToCenterXWithConfig
    , scrollToCenterY, scrollToCenterYWithConfig, jumpToCenterY, jumpToCenterYWithConfig
    , XCoordinate, YCoordinate
    , scrollToCoordinates, scrollToCoordinatesWithConfig, jumpToCoordinates, jumpToCoordinatesWithConfig
    , scrollToCoordinateX, scrollToCoordinateXWithConfig, jumpToCoordinateX, jumpToCoordinateXWithConfig
    , scrollToCoordinateY, scrollToCoordinateYWithConfig, jumpToCoordinateY, jumpToCoordinateYWithConfig
    , PercX, PercY
    , scrollToPercentage, scrollToPercentageWithConfig, jumpToPercentage, jumpToPercentageWithConfig
    , scrollToPercentageX, scrollToPercentageXWithConfig, jumpToPercentageX, jumpToPercentageXWithConfig
    , scrollToPercentageY, scrollToPercentageYWithConfig, jumpToPercentageY, jumpToPercentageYWithConfig
    , ScrollDeltaX, ScrollDeltaY
    , scrollBy, scrollByWithConfig, jumpBy, jumpByWithConfig
    , scrollByX, scrollByXWithConfig, jumpByX, jumpByXWithConfig
    , scrollByY, scrollByYWithConfig, jumpByY, jumpByYWithConfig
    , ViewportMultiplierX, ViewportMultiplierY
    , scrollByViewportSize, scrollByViewportSizeWithConfig, jumpByViewportSize, jumpByViewportSizeWithConfig
    , scrollByViewportSizeX, scrollByViewportSizeXWithConfig, jumpByViewportSizeX, jumpByViewportSizeXWithConfig
    , scrollByViewportSizeY, scrollByViewportSizeYWithConfig, jumpByViewportSizeY, jumpByViewportSizeYWithConfig
    )

{-| This module provides smooth scrolling operations for DOM containers using Tasks.

**Use this module when you need:**

  - Error handling for container scroll operations
  - Task composition and chaining
  - Fine-grained control over scroll completion

**Use [Scroll.Container.Cmd](Scroll.Container.Cmd) instead when you want:**

  - Simple 'fire-and-forget' scroll commands
  - Integration with standard Elm architecture

**For document-based scrolling, see:**

  - [Scroll.Document.Task](Scroll.Document.Task)
  - [Scroll.Document.Cmd](Scroll.Document.Cmd)


# Documentation Index

  - **[Element-Targeting Functions](#element-targeting-functions)** - Scroll to elements by ID within containers
  - **[Bring Into View Functions](#bring-into-view-functions)** - Minimal movement to show elements within containers
  - **[Position-Targeting Functions](#position-targeting-functions)** - Scroll to specific positions within containers
      - [Edges](#edges) - Top, bottom, left, and right edges of containers
      - [Corners](#corners) - All four corner positions within containers
      - [Center Positioning](#center-positioning) - Center elements within container viewport
      - **[Advanced Positioning Functions](#advanced-positioning-functions)** - Sophisticated positioning
          - [Coordinate Targeting](#coordinate-targeting) - Direct coordinate positioning
          - [Percentage-Based Positioning](#percentage-based-positioning) - Position by percentage
          - [Relative Movement](#relative-movement) - Move by pixel amounts or viewport sizes


# Element-Targeting Functions

@docs ContainerId, TargetId
@docs scroll, scrollWithConfig, jump, jumpWithConfig


# Bring Into View Functions

Bring an element into view within a container using minimal movement.

If the bottom of the target element is below the container's viewport, it will scroll up enough to make it fully visible, so
it's bottom edge will line up with the bottom edge of the container's viewport.

If the element is taller than the container's viewport, it's top edge will align with the top of the container's viewport.
The same logic applies for horizontal scrolling, with the left edge equating to the top.

So if an element is taller and wider than the container's viewport, the top-left corner of the element will be aligned with
the top-left corner of the container's viewport.

@docs scrollIntoView, scrollIntoViewWithConfig, jumpIntoView, jumpIntoViewWithConfig

_[↑ Bring Into View Functions](#bring-into-view-functions) | [↑ Documentation Index](#documentation-index)_


# Position-Targeting Functions


## Edges

Use these functions to scroll or jump to specific edges of the container.

These functions ignore the `axis` field in the [Config](Scroll#Config) because they will always scroll on the required axis
to reach the target edge.


## Top

@docs scrollToTop, scrollToTopWithConfig, jumpToTop, jumpToTopWithConfig


## Bottom

@docs scrollToBottom, scrollToBottomWithConfig, jumpToBottom, jumpToBottomWithConfig


## Left Edge

@docs scrollToLeftEdge, scrollToLeftEdgeWithConfig, jumpToLeftEdge, jumpToLeftEdgeWithConfig


## Right Edge

@docs scrollToRightEdge, scrollToRightEdgeWithConfig, jumpToRightEdge, jumpToRightEdgeWithConfig

_[↑ Edges](#edges) | [↑ Position-Targeting Functions](#position-targeting-functions) | [↑ Documentation Index](#documentation-index)_


## Corners

Use these functions to scroll or jump to the four corners of the container.

These functions ignore the `axis` field in the [Config](Scroll#Config) because they will always scroll on both axes
to reach the target corner.


### Top-Left Corner

@docs scrollToTopLeft, scrollToTopLeftWithConfig, jumpToTopLeft, jumpToTopLeftWithConfig


### Top-Right Corner

@docs scrollToTopRight, scrollToTopRightWithConfig, jumpToTopRight, jumpToTopRightWithConfig


### Bottom-Left Corner

@docs scrollToBottomLeft, scrollToBottomLeftWithConfig, jumpToBottomLeft, jumpToBottomLeftWithConfig


### Bottom-Right Corner

@docs scrollToBottomRight, scrollToBottomRightWithConfig, jumpToBottomRight, jumpToBottomRightWithConfig

_[↑ Corners](#corners) | [↑ Position-Targeting Functions](#position-targeting-functions) | [↑ Documentation Index](#documentation-index)_


## Center Positioning

Use these functions to scroll or jump to center positions within the container.


### Both Axes

@docs scrollToCenter, scrollToCenterWithConfig, jumpToCenter, jumpToCenterWithConfig


### X Axis Only

@docs scrollToCenterX, scrollToCenterXWithConfig, jumpToCenterX, jumpToCenterXWithConfig


### Y Axis Only

@docs scrollToCenterY, scrollToCenterYWithConfig, jumpToCenterY, jumpToCenterYWithConfig

_[↑ Center Positioning](#center-positioning) | [↑ Position-Targeting Functions](#position-targeting-functions) | [↑ Documentation Index](#documentation-index)_


# Advanced Positioning Functions


## Coordinate Targeting

Scroll or jump to specific pixel coordinates within the container. Coordinates are automatically clamped to valid ranges.

@docs XCoordinate, YCoordinate


### Both Axes

@docs scrollToCoordinates, scrollToCoordinatesWithConfig, jumpToCoordinates, jumpToCoordinatesWithConfig


### X Axis Only

@docs scrollToCoordinateX, scrollToCoordinateXWithConfig, jumpToCoordinateX, jumpToCoordinateXWithConfig


### Y Axis Only

@docs scrollToCoordinateY, scrollToCoordinateYWithConfig, jumpToCoordinateY, jumpToCoordinateYWithConfig

_[↑ Coordinate Targeting](#coordinate-targeting) | [↑ Advanced Positioning Functions](#advanced-positioning-functions) | [↑ Documentation Index](#documentation-index)_


## Percentage-Based Positioning

Position within the container using percentages (0-100). Values outside this range are automatically clamped.

@docs PercX, PercY


### Both Axes

@docs scrollToPercentage, scrollToPercentageWithConfig, jumpToPercentage, jumpToPercentageWithConfig


### X Axis Only

@docs scrollToPercentageX, scrollToPercentageXWithConfig, jumpToPercentageX, jumpToPercentageXWithConfig


### Y Axis Only

@docs scrollToPercentageY, scrollToPercentageYWithConfig, jumpToPercentageY, jumpToPercentageYWithConfig

_[↑ Percentage-Based Positioning](#percentage-based-positioning) | [↑ Advanced Positioning Functions](#advanced-positioning-functions) | [↑ Documentation Index](#documentation-index)_


## Relative Movement


### Pixel Offsets

Move relative to the current scroll position within the container by specific pixel amounts.

@docs ScrollDeltaX, ScrollDeltaY


#### Both Axes

@docs scrollBy, scrollByWithConfig, jumpBy, jumpByWithConfig


#### X Axis Only

@docs scrollByX, scrollByXWithConfig, jumpByX, jumpByXWithConfig


#### Y Axis Only

@docs scrollByY, scrollByYWithConfig, jumpByY, jumpByYWithConfig


### Viewport Multiples

Move relative to the current scroll position within the container by multiples of the viewport size.

@docs ViewportMultiplierX, ViewportMultiplierY


#### Both Axes

@docs scrollByViewportSize, scrollByViewportSizeWithConfig, jumpByViewportSize, jumpByViewportSizeWithConfig


#### X Axis Only

@docs scrollByViewportSizeX, scrollByViewportSizeXWithConfig, jumpByViewportSizeX, jumpByViewportSizeXWithConfig


#### Y Axis Only

@docs scrollByViewportSizeY, scrollByViewportSizeYWithConfig, jumpByViewportSizeY, jumpByViewportSizeYWithConfig

_[↑ Coordinate Targeting](#coordinate-targeting) | [↑ Advanced Positioning Functions](#advanced-positioning-functions) | [↑ Documentation Index](#documentation-index)_

-}

import Browser.Dom as Dom
import Internal.AnimationCore exposing (animationSteps, animationStepsWithFrames)
import Scroll exposing (Axis(..), Config, defaultConfig)
import Scroll.Internal exposing (Container(..), Direction(..), calculateScrollIntoView, getAxisDirection, getClampedPositions, getContainerInfo, getViewport, timingToSpeed)
import Task exposing (Task)



-- TYPE ALIASES


{-| Type alias for container element IDs that define scrollable areas.
-}
type alias ContainerId =
    String


{-| Type alias for target element IDs that we want to scroll to.
-}
type alias TargetId =
    String


{-| X-coordinate percentage (0.0 to 1.0)
-}
type alias PercX =
    Float


{-| Y-coordinate percentage (0.0 to 1.0)
-}
type alias PercY =
    Float


{-| Horizontal scroll delta in pixels
-}
type alias ScrollDeltaX =
    Float


{-| Vertical scroll delta in pixels
-}
type alias ScrollDeltaY =
    Float


{-| X-axis viewport size multiplier
-}
type alias ViewportMultiplierX =
    Float


{-| Y-axis viewport size multiplier
-}
type alias ViewportMultiplierY =
    Float


{-| X-coordinate in pixels from document origin
-}
type alias XCoordinate =
    Float


{-| Y-coordinate in pixels from document origin
-}
type alias YCoordinate =
    Float


{-| Smooth scroll to element within a container.
-}
scroll : ContainerId -> TargetId -> Task Dom.Error (List ())
scroll containerId elementId =
    scrollWithConfig containerId elementId defaultConfig


{-| Smooth scroll to element within a container with custom configuration.
-}
scrollWithConfig : ContainerId -> TargetId -> Config -> Task Dom.Error (List ())
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
                    case getAxisDirection config.axis of
                        XDirection ->
                            animationSteps (timingToSpeed config.timing (abs (clampedX - viewport.x))) config.easing viewport.x clampedX
                                |> List.map (\x -> Dom.setViewportOf containerId x viewport.y)
                                |> Task.sequence

                        YDirection ->
                            animationSteps (timingToSpeed config.timing (abs (clampedY - viewport.y))) config.easing viewport.y clampedY
                                |> List.map (\y -> Dom.setViewportOf containerId viewport.x y)
                                |> Task.sequence

                        BothDirection ->
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
jump : ContainerId -> TargetId -> Task Dom.Error ()
jump containerId elementId =
    jumpWithConfig containerId elementId defaultConfig


{-| Jump instantly to element within a container with custom configuration.
-}
jumpWithConfig : ContainerId -> TargetId -> Config -> Task Dom.Error ()
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
                    case getAxisDirection config.axis of
                        XDirection ->
                            Dom.setViewportOf containerId clampedX viewport.y

                        YDirection ->
                            Dom.setViewportOf containerId viewport.x clampedY

                        BothDirection ->
                            Dom.setViewportOf containerId clampedX clampedY
            in
            setViewportTask
    in
    Task.map3 performJumpTask getViewport_ (Dom.getElement elementId) getContainerInfo_
        |> Task.andThen identity


{-| Smooth scroll to top of container.
-}
scrollToTop : ContainerId -> Task Dom.Error (List ())
scrollToTop containerId =
    scrollToTopWithConfig containerId defaultConfig


{-| Smooth scroll to top of container with custom configuration.
-}
scrollToTopWithConfig : ContainerId -> Config -> Task Dom.Error (List ())
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
scrollToBottom : ContainerId -> Task Dom.Error (List ())
scrollToBottom containerId =
    scrollToBottomWithConfig containerId defaultConfig


{-| Smooth scroll to bottom of container with custom configuration.
-}
scrollToBottomWithConfig : ContainerId -> Config -> Task Dom.Error (List ())
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
scrollToLeftEdge : ContainerId -> Task Dom.Error (List ())
scrollToLeftEdge containerId =
    scrollToLeftEdgeWithConfig containerId defaultConfig


{-| Smooth scroll to left edge of container with custom configuration.
-}
scrollToLeftEdgeWithConfig : ContainerId -> Config -> Task Dom.Error (List ())
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
scrollToRightEdge : ContainerId -> Task Dom.Error (List ())
scrollToRightEdge containerId =
    scrollToRightEdgeWithConfig containerId defaultConfig


{-| Smooth scroll to right edge of container with custom configuration.
-}
scrollToRightEdgeWithConfig : ContainerId -> Config -> Task Dom.Error (List ())
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
jumpToTop : ContainerId -> Task Dom.Error ()
jumpToTop containerId =
    jumpToTopWithConfig containerId defaultConfig


{-| Jump instantly to top of container with custom configuration.
-}
jumpToTopWithConfig : ContainerId -> Config -> Task Dom.Error ()
jumpToTopWithConfig containerId _ =
    Dom.getViewportOf containerId
        |> Task.andThen (\{ viewport } -> Dom.setViewportOf containerId viewport.x 0)


{-| Jump instantly to bottom of container.
-}
jumpToBottom : ContainerId -> Task Dom.Error ()
jumpToBottom containerId =
    jumpToBottomWithConfig containerId defaultConfig


{-| Jump instantly to bottom of container with custom configuration.
-}
jumpToBottomWithConfig : ContainerId -> Config -> Task Dom.Error ()
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
jumpToLeftEdge : ContainerId -> Task Dom.Error ()
jumpToLeftEdge containerId =
    jumpToLeftEdgeWithConfig containerId defaultConfig


{-| Jump instantly to left edge of container with custom configuration.
-}
jumpToLeftEdgeWithConfig : ContainerId -> Config -> Task Dom.Error ()
jumpToLeftEdgeWithConfig containerId _ =
    Dom.getViewportOf containerId
        |> Task.andThen (\{ viewport } -> Dom.setViewportOf containerId 0 viewport.y)


{-| Jump instantly to right edge of container.
-}
jumpToRightEdge : ContainerId -> Task Dom.Error ()
jumpToRightEdge containerId =
    jumpToRightEdgeWithConfig containerId defaultConfig


{-| Jump instantly to right edge of container with custom configuration.
-}
jumpToRightEdgeWithConfig : ContainerId -> Config -> Task Dom.Error ()
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



-- SCROLL INTO VIEW FUNCTIONS


{-| Smoothly scroll to bring an element into view within a container using minimal movement.

Uses the same logic as document scrolling but operates within the specified container.
This scrolls the minimum amount necessary to make the target element fully visible.

    scrollIntoView "container-id" "target-element"

-}
scrollIntoView : ContainerId -> TargetId -> Task Dom.Error (List ())
scrollIntoView containerId elementId =
    scrollIntoViewWithConfig containerId elementId { defaultConfig | axis = BothWithOffset 0 0 }


{-| Smoothly scroll to bring an element into view within a container with custom configuration.

    scrollIntoViewWithConfig "container-id" "target-element" { defaultConfig | timing = 500 }

-}
scrollIntoViewWithConfig : ContainerId -> TargetId -> Config -> Task Dom.Error (List ())
scrollIntoViewWithConfig containerId elementId config =
    let
        getViewport_ =
            getViewport (Container containerId)

        getContainerInfo_ =
            getContainerInfo (Container containerId)

        performScrollTask { scene, viewport } { element } containerInfo =
            let
                ( targetX, targetY ) =
                    calculateScrollIntoView element viewport scene containerInfo config

                ( clampedX, clampedY ) =
                    ( targetX
                        |> min (scene.width - viewport.width)
                        |> max 0
                    , targetY
                        |> min (scene.height - viewport.height)
                        |> max 0
                    )

                setViewportTask =
                    case getAxisDirection config.axis of
                        XDirection ->
                            animationSteps (timingToSpeed config.timing (abs (clampedX - viewport.x))) config.easing viewport.x clampedX
                                |> List.map (\x -> Dom.setViewportOf containerId x viewport.y)
                                |> Task.sequence

                        YDirection ->
                            animationSteps (timingToSpeed config.timing (abs (clampedY - viewport.y))) config.easing viewport.y clampedY
                                |> List.map (\y -> Dom.setViewportOf containerId viewport.x y)
                                |> Task.sequence

                        BothDirection ->
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

                                combinedSteps =
                                    List.map2 Tuple.pair xSteps ySteps
                            in
                            combinedSteps
                                |> List.map (\( x, y ) -> Dom.setViewportOf containerId x y)
                                |> Task.sequence
            in
            setViewportTask
    in
    Task.map3 performScrollTask getViewport_ (Dom.getElement elementId) getContainerInfo_
        |> Task.andThen identity


{-| Jump instantly to bring an element into view within a container using minimal movement.

    jumpIntoView "container-id" "target-element"

-}
jumpIntoView : ContainerId -> TargetId -> Task Dom.Error ()
jumpIntoView containerId elementId =
    jumpIntoViewWithConfig containerId elementId { defaultConfig | axis = BothWithOffset 0 0 }


{-| Jump instantly to bring an element into view within a container with custom configuration.

    jumpIntoViewWithConfig "container-id" "target-element" { defaultConfig | offsetY = 50 }

-}
jumpIntoViewWithConfig : ContainerId -> TargetId -> Config -> Task Dom.Error ()
jumpIntoViewWithConfig containerId elementId config =
    let
        getViewport_ =
            getViewport (Container containerId)

        getContainerInfo_ =
            getContainerInfo (Container containerId)

        performJumpTask { scene, viewport } { element } containerInfo =
            let
                ( targetX, targetY ) =
                    calculateScrollIntoView element viewport scene containerInfo config

                ( clampedX, clampedY ) =
                    ( targetX
                        |> min (scene.width - viewport.width)
                        |> max 0
                    , targetY
                        |> min (scene.height - viewport.height)
                        |> max 0
                    )
            in
            Dom.setViewportOf containerId clampedX clampedY
    in
    Task.map3 performJumpTask getViewport_ (Dom.getElement elementId) getContainerInfo_
        |> Task.andThen identity



-- CORNER POSITIONING FUNCTIONS


{-| Smoothly scroll to the top-left corner of a container.
-}
scrollToTopLeft : ContainerId -> Task Dom.Error (List ())
scrollToTopLeft containerId =
    scrollToTopLeftWithConfig containerId defaultConfig


{-| Smoothly scroll to the top-left corner with custom configuration.
-}
scrollToTopLeftWithConfig : ContainerId -> Config -> Task Dom.Error (List ())
scrollToTopLeftWithConfig containerId config =
    scrollToCoordinatesWithConfig containerId 0 0 config


{-| Jump instantly to the top-left corner of a container.
-}
jumpToTopLeft : ContainerId -> Task Dom.Error ()
jumpToTopLeft containerId =
    jumpToTopLeftWithConfig containerId defaultConfig


{-| Jump instantly to the top-left corner with custom configuration.
-}
jumpToTopLeftWithConfig : ContainerId -> Config -> Task Dom.Error ()
jumpToTopLeftWithConfig containerId config =
    jumpToCoordinatesWithConfig containerId 0 0 config


{-| Smoothly scroll to the top-right corner of a container.
-}
scrollToTopRight : ContainerId -> Task Dom.Error (List ())
scrollToTopRight containerId =
    scrollToTopRightWithConfig containerId defaultConfig


{-| Smoothly scroll to the top-right corner with custom configuration.
-}
scrollToTopRightWithConfig : ContainerId -> Config -> Task Dom.Error (List ())
scrollToTopRightWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    rightX =
                        scene.width - viewport.width
                in
                scrollToCoordinatesWithConfig containerId rightX 0 config
            )


{-| Jump instantly to the top-right corner of a container.
-}
jumpToTopRight : ContainerId -> Task Dom.Error ()
jumpToTopRight containerId =
    jumpToTopRightWithConfig containerId defaultConfig


{-| Jump instantly to the top-right corner with custom configuration.
-}
jumpToTopRightWithConfig : ContainerId -> Config -> Task Dom.Error ()
jumpToTopRightWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    rightX =
                        scene.width - viewport.width
                in
                jumpToCoordinatesWithConfig containerId rightX 0 config
            )


{-| Smoothly scroll to the bottom-left corner of a container.
-}
scrollToBottomLeft : ContainerId -> Task Dom.Error (List ())
scrollToBottomLeft containerId =
    scrollToBottomLeftWithConfig containerId defaultConfig


{-| Smoothly scroll to the bottom-left corner with custom configuration.
-}
scrollToBottomLeftWithConfig : ContainerId -> Config -> Task Dom.Error (List ())
scrollToBottomLeftWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    bottomY =
                        scene.height - viewport.height
                in
                scrollToCoordinatesWithConfig containerId 0 bottomY config
            )


{-| Jump instantly to the bottom-left corner of a container.
-}
jumpToBottomLeft : ContainerId -> Task Dom.Error ()
jumpToBottomLeft containerId =
    jumpToBottomLeftWithConfig containerId defaultConfig


{-| Jump instantly to the bottom-left corner with custom configuration.
-}
jumpToBottomLeftWithConfig : ContainerId -> Config -> Task Dom.Error ()
jumpToBottomLeftWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    bottomY =
                        scene.height - viewport.height
                in
                jumpToCoordinatesWithConfig containerId 0 bottomY config
            )


{-| Smoothly scroll to the bottom-right corner of a container.
-}
scrollToBottomRight : ContainerId -> Task Dom.Error (List ())
scrollToBottomRight containerId =
    scrollToBottomRightWithConfig containerId defaultConfig


{-| Smoothly scroll to the bottom-right corner with custom configuration.
-}
scrollToBottomRightWithConfig : ContainerId -> Config -> Task Dom.Error (List ())
scrollToBottomRightWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    rightX =
                        scene.width - viewport.width

                    bottomY =
                        scene.height - viewport.height
                in
                scrollToCoordinatesWithConfig containerId rightX bottomY config
            )


{-| Jump instantly to the bottom-right corner of a container.
-}
jumpToBottomRight : ContainerId -> Task Dom.Error ()
jumpToBottomRight containerId =
    jumpToBottomRightWithConfig containerId defaultConfig


{-| Jump instantly to the bottom-right corner with custom configuration.
-}
jumpToBottomRightWithConfig : ContainerId -> Config -> Task Dom.Error ()
jumpToBottomRightWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    rightX =
                        scene.width - viewport.width

                    bottomY =
                        scene.height - viewport.height
                in
                jumpToCoordinatesWithConfig containerId rightX bottomY config
            )



-- CENTER POSITIONING FUNCTIONS


{-| Smoothly scroll to the center of a container (both X and Y axes).
-}
scrollToCenter : ContainerId -> Task Dom.Error (List ())
scrollToCenter containerId =
    scrollToCenterWithConfig containerId defaultConfig


{-| Smoothly scroll to the center with custom configuration.
-}
scrollToCenterWithConfig : ContainerId -> Config -> Task Dom.Error (List ())
scrollToCenterWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    centerX =
                        (scene.width - viewport.width) / 2

                    centerY =
                        (scene.height - viewport.height) / 2
                in
                scrollToCoordinatesWithConfig containerId centerX centerY config
            )


{-| Jump instantly to the center of a container (both X and Y axes).
-}
jumpToCenter : ContainerId -> Task Dom.Error ()
jumpToCenter containerId =
    jumpToCenterWithConfig containerId defaultConfig


{-| Jump instantly to the center with custom configuration.
-}
jumpToCenterWithConfig : ContainerId -> Config -> Task Dom.Error ()
jumpToCenterWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    centerX =
                        (scene.width - viewport.width) / 2

                    centerY =
                        (scene.height - viewport.height) / 2
                in
                jumpToCoordinatesWithConfig containerId centerX centerY config
            )


{-| Smoothly scroll to center horizontally (X axis only).
-}
scrollToCenterX : ContainerId -> Task Dom.Error (List ())
scrollToCenterX containerId =
    scrollToCenterXWithConfig containerId defaultConfig


{-| Smoothly scroll to center horizontally with custom configuration.
-}
scrollToCenterXWithConfig : ContainerId -> Config -> Task Dom.Error (List ())
scrollToCenterXWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    centerX =
                        (scene.width - viewport.width) / 2
                in
                scrollToCoordinatesWithConfig containerId centerX viewport.y { config | axis = X }
            )


{-| Jump instantly to center horizontally (X axis only).
-}
jumpToCenterX : ContainerId -> Task Dom.Error ()
jumpToCenterX containerId =
    jumpToCenterXWithConfig containerId defaultConfig


{-| Jump instantly to center horizontally with custom configuration.
-}
jumpToCenterXWithConfig : ContainerId -> Config -> Task Dom.Error ()
jumpToCenterXWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    centerX =
                        (scene.width - viewport.width) / 2
                in
                jumpToCoordinatesWithConfig containerId centerX viewport.y config
            )


{-| Smoothly scroll to center vertically (Y axis only).
-}
scrollToCenterY : ContainerId -> Task Dom.Error (List ())
scrollToCenterY containerId =
    scrollToCenterYWithConfig containerId defaultConfig


{-| Smoothly scroll to center vertically with custom configuration.
-}
scrollToCenterYWithConfig : ContainerId -> Config -> Task Dom.Error (List ())
scrollToCenterYWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    centerY =
                        (scene.height - viewport.height) / 2
                in
                scrollToCoordinatesWithConfig containerId viewport.x centerY { config | axis = Y }
            )


{-| Jump instantly to center vertically (Y axis only).
-}
jumpToCenterY : ContainerId -> Task Dom.Error ()
jumpToCenterY containerId =
    jumpToCenterYWithConfig containerId defaultConfig


{-| Jump instantly to center vertically with custom configuration.
-}
jumpToCenterYWithConfig : ContainerId -> Config -> Task Dom.Error ()
jumpToCenterYWithConfig containerId config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    centerY =
                        (scene.height - viewport.height) / 2
                in
                jumpToCoordinatesWithConfig containerId viewport.x centerY config
            )



-- PERCENTAGE-BASED POSITIONING FUNCTIONS


{-| Smoothly scroll to a position defined by percentages (both X and Y).
-}
scrollToPercentage : ContainerId -> PercX -> PercY -> Task Dom.Error (List ())
scrollToPercentage containerId percentX percentY =
    scrollToPercentageWithConfig containerId percentX percentY defaultConfig


{-| Smoothly scroll to percentage position with custom configuration.
-}
scrollToPercentageWithConfig : ContainerId -> PercX -> PercY -> Config -> Task Dom.Error (List ())
scrollToPercentageWithConfig containerId percentX percentY config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    clampedPercentX =
                        clamp 0 100 percentX

                    clampedPercentY =
                        clamp 0 100 percentY

                    targetX =
                        (scene.width - viewport.width) * (clampedPercentX / 100)

                    targetY =
                        (scene.height - viewport.height) * (clampedPercentY / 100)
                in
                scrollToCoordinatesWithConfig containerId targetX targetY config
            )


{-| Jump instantly to a position defined by percentages (both X and Y).
-}
jumpToPercentage : ContainerId -> PercX -> PercY -> Task Dom.Error ()
jumpToPercentage containerId percentX percentY =
    jumpToPercentageWithConfig containerId percentX percentY defaultConfig


{-| Jump instantly to percentage position with custom configuration.
-}
jumpToPercentageWithConfig : ContainerId -> PercX -> PercY -> Config -> Task Dom.Error ()
jumpToPercentageWithConfig containerId percentX percentY config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    clampedPercentX =
                        clamp 0 100 percentX

                    clampedPercentY =
                        clamp 0 100 percentY

                    targetX =
                        (scene.width - viewport.width) * (clampedPercentX / 100)

                    targetY =
                        (scene.height - viewport.height) * (clampedPercentY / 100)
                in
                jumpToCoordinatesWithConfig containerId targetX targetY config
            )


{-| Smoothly scroll to a horizontal percentage position (X axis only).
-}
scrollToPercentageX : ContainerId -> PercX -> Task Dom.Error (List ())
scrollToPercentageX containerId percentX =
    scrollToPercentageXWithConfig containerId percentX defaultConfig


{-| Smoothly scroll to horizontal percentage with custom configuration.
-}
scrollToPercentageXWithConfig : ContainerId -> PercX -> Config -> Task Dom.Error (List ())
scrollToPercentageXWithConfig containerId percentX config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    clampedPercentX =
                        clamp 0 100 percentX

                    targetX =
                        (scene.width - viewport.width) * (clampedPercentX / 100)
                in
                scrollToCoordinatesWithConfig containerId targetX viewport.y { config | axis = X }
            )


{-| Jump instantly to a horizontal percentage position (X axis only).
-}
jumpToPercentageX : ContainerId -> PercX -> Task Dom.Error ()
jumpToPercentageX containerId percentX =
    jumpToPercentageXWithConfig containerId percentX defaultConfig


{-| Jump instantly to horizontal percentage with custom configuration.
-}
jumpToPercentageXWithConfig : ContainerId -> PercX -> Config -> Task Dom.Error ()
jumpToPercentageXWithConfig containerId percentX config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    clampedPercentX =
                        clamp 0 100 percentX

                    targetX =
                        (scene.width - viewport.width) * (clampedPercentX / 100)
                in
                jumpToCoordinatesWithConfig containerId targetX viewport.y config
            )


{-| Smoothly scroll to a vertical percentage position (Y axis only).
-}
scrollToPercentageY : ContainerId -> PercY -> Task Dom.Error (List ())
scrollToPercentageY containerId percentY =
    scrollToPercentageYWithConfig containerId percentY defaultConfig


{-| Smoothly scroll to vertical percentage with custom configuration.
-}
scrollToPercentageYWithConfig : ContainerId -> PercY -> Config -> Task Dom.Error (List ())
scrollToPercentageYWithConfig containerId percentY config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    clampedPercentY =
                        clamp 0 100 percentY

                    targetY =
                        (scene.height - viewport.height) * (clampedPercentY / 100)
                in
                scrollToCoordinatesWithConfig containerId viewport.x targetY { config | axis = Y }
            )


{-| Jump instantly to a vertical percentage position (Y axis only).
-}
jumpToPercentageY : ContainerId -> PercY -> Task Dom.Error ()
jumpToPercentageY containerId percentY =
    jumpToPercentageYWithConfig containerId percentY defaultConfig


{-| Jump instantly to vertical percentage with custom configuration.
-}
jumpToPercentageYWithConfig : ContainerId -> PercY -> Config -> Task Dom.Error ()
jumpToPercentageYWithConfig containerId percentY config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    clampedPercentY =
                        clamp 0 100 percentY

                    targetY =
                        (scene.height - viewport.height) * (clampedPercentY / 100)
                in
                jumpToCoordinatesWithConfig containerId viewport.x targetY config
            )



-- RELATIVE MOVEMENT FUNCTIONS


{-| Smoothly scroll by specific pixel amounts from the current position.

    scrollBy "container-id" 100.0 -50.0

-}
scrollBy : ContainerId -> ScrollDeltaX -> ScrollDeltaY -> Task Dom.Error (List ())
scrollBy containerId deltaX deltaY =
    scrollByWithConfig containerId deltaX deltaY defaultConfig


{-| Smoothly scroll by pixel amounts with custom configuration.

    scrollByWithConfig "container-id" 100.0 -50.0 <|
        { defaultConfig | speed = 1000 }

-}
scrollByWithConfig : ContainerId -> ScrollDeltaX -> ScrollDeltaY -> Config -> Task Dom.Error (List ())
scrollByWithConfig containerId deltaX deltaY config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ viewport } ->
                let
                    targetX =
                        viewport.x + deltaX

                    targetY =
                        viewport.y + deltaY
                in
                scrollToCoordinatesWithConfig containerId targetX targetY config
            )


{-| Jump instantly by specific pixel amounts from the current position.

    jumpBy "container-id" 100.0 -50.0

-}
jumpBy : ContainerId -> ScrollDeltaX -> ScrollDeltaY -> Task Dom.Error ()
jumpBy containerId deltaX deltaY =
    jumpByWithConfig containerId deltaX deltaY defaultConfig


{-| Jump instantly by pixel amounts with custom configuration.

    jumpByWithConfig "container-id" 100.0 -50.0 defaultConfig

-}
jumpByWithConfig : ContainerId -> ScrollDeltaX -> ScrollDeltaY -> Config -> Task Dom.Error ()
jumpByWithConfig containerId deltaX deltaY config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ viewport } ->
                let
                    targetX =
                        viewport.x + deltaX

                    targetY =
                        viewport.y + deltaY
                in
                jumpToCoordinatesWithConfig containerId targetX targetY config
            )


{-| Smoothly scroll horizontally by a specific pixel amount from the current position.

    scrollByX "container-id" 100.0

-}
scrollByX : ContainerId -> ScrollDeltaX -> Task Dom.Error (List ())
scrollByX containerId deltaX =
    scrollByXWithConfig containerId deltaX defaultConfig


{-| Smoothly scroll horizontally by pixel amounts with custom configuration.

    scrollByXWithConfig "container-id" 100.0 <|
        { defaultConfig | speed = 1000 }

-}
scrollByXWithConfig : ContainerId -> ScrollDeltaX -> Config -> Task Dom.Error (List ())
scrollByXWithConfig containerId deltaX config =
    scrollByWithConfig containerId deltaX 0.0 config


{-| Jump instantly horizontally by a specific pixel amount from the current position.

    jumpByX "container-id" 100.0

-}
jumpByX : ContainerId -> ScrollDeltaX -> Task Dom.Error ()
jumpByX containerId deltaX =
    jumpByXWithConfig containerId deltaX defaultConfig


{-| Jump instantly horizontally by pixel amounts with custom configuration.

    jumpByXWithConfig "container-id" 100.0 defaultConfig

-}
jumpByXWithConfig : ContainerId -> ScrollDeltaX -> Config -> Task Dom.Error ()
jumpByXWithConfig containerId deltaX config =
    jumpByWithConfig containerId deltaX 0.0 config


{-| Smoothly scroll vertically by a specific pixel amount from the current position.

    scrollByY "container-id" -50.0

-}
scrollByY : ContainerId -> ScrollDeltaY -> Task Dom.Error (List ())
scrollByY containerId deltaY =
    scrollByYWithConfig containerId deltaY defaultConfig


{-| Smoothly scroll vertically by pixel amounts with custom configuration.

    scrollByYWithConfig "container-id" -50.0 <|
        { defaultConfig | speed = 1000 }

-}
scrollByYWithConfig : ContainerId -> ScrollDeltaY -> Config -> Task Dom.Error (List ())
scrollByYWithConfig containerId deltaY config =
    scrollByWithConfig containerId 0.0 deltaY config


{-| Jump instantly vertically by a specific pixel amount from the current position.

    jumpByY "container-id" -50.0

-}
jumpByY : ContainerId -> ScrollDeltaY -> Task Dom.Error ()
jumpByY containerId deltaY =
    jumpByYWithConfig containerId deltaY defaultConfig


{-| Jump instantly vertically by pixel amounts with custom configuration.

    jumpByYWithConfig "container-id" -50.0 defaultConfig

-}
jumpByYWithConfig : ContainerId -> ScrollDeltaY -> Config -> Task Dom.Error ()
jumpByYWithConfig containerId deltaY config =
    jumpByWithConfig containerId 0.0 deltaY config


{-| Smoothly scroll by viewport multiples from the current position.

    scrollByViewportSize "container-id" 1.0 0.5

-}
scrollByViewportSize : ContainerId -> ViewportMultiplierX -> ViewportMultiplierY -> Task Dom.Error (List ())
scrollByViewportSize containerId multiplierX multiplierY =
    scrollByViewportSizeWithConfig containerId multiplierX multiplierY defaultConfig


{-| Smoothly scroll by viewport multiples with custom configuration.

    scrollByViewportSizeWithConfig "container-id" 1.0 0.5 <|
        { defaultConfig | speed = 1000 }

-}
scrollByViewportSizeWithConfig : ContainerId -> ViewportMultiplierX -> ViewportMultiplierY -> Config -> Task Dom.Error (List ())
scrollByViewportSizeWithConfig containerId multiplierX multiplierY config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ viewport } ->
                let
                    deltaX =
                        viewport.width * multiplierX

                    deltaY =
                        viewport.height * multiplierY

                    targetX =
                        viewport.x + deltaX

                    targetY =
                        viewport.y + deltaY
                in
                scrollToCoordinatesWithConfig containerId targetX targetY config
            )


{-| Jump instantly by viewport multiples from the current position.

    jumpByViewportSize "container-id" 1.0 0.5

-}
jumpByViewportSize : ContainerId -> ViewportMultiplierX -> ViewportMultiplierY -> Task Dom.Error ()
jumpByViewportSize containerId multiplierX multiplierY =
    jumpByViewportSizeWithConfig containerId multiplierX multiplierY defaultConfig


{-| Jump instantly by viewport multiples with custom configuration.

    jumpByViewportSizeWithConfig "container-id" 1.0 0.5 defaultConfig

-}
jumpByViewportSizeWithConfig : ContainerId -> ViewportMultiplierX -> ViewportMultiplierY -> Config -> Task Dom.Error ()
jumpByViewportSizeWithConfig containerId multiplierX multiplierY config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ viewport } ->
                let
                    deltaX =
                        viewport.width * multiplierX

                    deltaY =
                        viewport.height * multiplierY

                    targetX =
                        viewport.x + deltaX

                    targetY =
                        viewport.y + deltaY
                in
                jumpToCoordinatesWithConfig containerId targetX targetY config
            )


{-| Smoothly scroll horizontally by viewport width multiples from the current position.

    scrollByViewportSizeX "container-id" 1.0

-}
scrollByViewportSizeX : ContainerId -> ViewportMultiplierX -> Task Dom.Error (List ())
scrollByViewportSizeX containerId multiplierX =
    scrollByViewportSizeXWithConfig containerId multiplierX defaultConfig


{-| Smoothly scroll horizontally by viewport width multiples with custom configuration.

    scrollByViewportSizeXWithConfig "container-id" 1.0 <|
        { defaultConfig | speed = 1000 }

-}
scrollByViewportSizeXWithConfig : ContainerId -> ViewportMultiplierX -> Config -> Task Dom.Error (List ())
scrollByViewportSizeXWithConfig containerId multiplierX config =
    scrollByViewportSizeWithConfig containerId multiplierX 0.0 config


{-| Jump instantly horizontally by viewport width multiples from the current position.

    jumpByViewportSizeX "container-id" 1.0

-}
jumpByViewportSizeX : ContainerId -> ViewportMultiplierX -> Task Dom.Error ()
jumpByViewportSizeX containerId multiplierX =
    jumpByViewportSizeXWithConfig containerId multiplierX defaultConfig


{-| Jump instantly horizontally by viewport width multiples with custom configuration.

    jumpByViewportSizeXWithConfig "container-id" 1.0 defaultConfig

-}
jumpByViewportSizeXWithConfig : ContainerId -> ViewportMultiplierX -> Config -> Task Dom.Error ()
jumpByViewportSizeXWithConfig containerId multiplierX config =
    jumpByViewportSizeWithConfig containerId multiplierX 0.0 config


{-| Smoothly scroll vertically by viewport height multiples from the current position.

    scrollByViewportSizeY "container-id" 1.0

-}
scrollByViewportSizeY : ContainerId -> ViewportMultiplierY -> Task Dom.Error (List ())
scrollByViewportSizeY containerId multiplierY =
    scrollByViewportSizeYWithConfig containerId multiplierY defaultConfig


{-| Smoothly scroll vertically by viewport height multiples with custom configuration.

    scrollByViewportSizeYWithConfig "container-id" 1.0 <|
        { defaultConfig | speed = 1000 }

-}
scrollByViewportSizeYWithConfig : ContainerId -> ViewportMultiplierY -> Config -> Task Dom.Error (List ())
scrollByViewportSizeYWithConfig containerId multiplierY config =
    scrollByViewportSizeWithConfig containerId 0.0 multiplierY config


{-| Jump instantly vertically by viewport height multiples from the current position.

    jumpByViewportSizeY "container-id" 1.0

-}
jumpByViewportSizeY : ContainerId -> ViewportMultiplierY -> Task Dom.Error ()
jumpByViewportSizeY containerId multiplierY =
    jumpByViewportSizeYWithConfig containerId multiplierY defaultConfig


{-| Jump instantly vertically by viewport height multiples with custom configuration.

    jumpByViewportSizeYWithConfig "container-id" 1.0 defaultConfig

-}
jumpByViewportSizeYWithConfig : ContainerId -> ViewportMultiplierY -> Config -> Task Dom.Error ()
jumpByViewportSizeYWithConfig containerId multiplierY config =
    jumpByViewportSizeWithConfig containerId 0.0 multiplierY config



-- COORDINATE TARGETING FUNCTIONS


{-| Smoothly scroll to specific pixel coordinates within a container.
-}
scrollToCoordinates : ContainerId -> XCoordinate -> YCoordinate -> Task Dom.Error (List ())
scrollToCoordinates containerId x y =
    scrollToCoordinatesWithConfig containerId x y defaultConfig


{-| Smoothly scroll to coordinates with custom configuration.
-}
scrollToCoordinatesWithConfig : ContainerId -> XCoordinate -> YCoordinate -> Config -> Task Dom.Error (List ())
scrollToCoordinatesWithConfig containerId targetX targetY config =
    let
        getViewport_ =
            getViewport (Container containerId)

        getContainerInfo_ =
            getContainerInfo (Container containerId)

        performScrollTask { scene, viewport } _ =
            let
                ( clampedX, clampedY ) =
                    ( targetX
                        |> min (scene.width - viewport.width)
                        |> max 0
                    , targetY
                        |> min (scene.height - viewport.height)
                        |> max 0
                    )

                setViewportTask =
                    case getAxisDirection config.axis of
                        XDirection ->
                            animationSteps (timingToSpeed config.timing (abs (clampedX - viewport.x))) config.easing viewport.x clampedX
                                |> List.map (\x -> Dom.setViewportOf containerId x viewport.y)
                                |> Task.sequence

                        YDirection ->
                            animationSteps (timingToSpeed config.timing (abs (clampedY - viewport.y))) config.easing viewport.y clampedY
                                |> List.map (\y -> Dom.setViewportOf containerId viewport.x y)
                                |> Task.sequence

                        BothDirection ->
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

                                combinedSteps =
                                    List.map2 Tuple.pair xSteps ySteps
                            in
                            combinedSteps
                                |> List.map (\( x, y ) -> Dom.setViewportOf containerId x y)
                                |> Task.sequence
            in
            setViewportTask
    in
    Task.map2 performScrollTask getViewport_ getContainerInfo_
        |> Task.andThen identity


{-| Jump instantly to specific pixel coordinates within a container.
-}
jumpToCoordinates : ContainerId -> XCoordinate -> YCoordinate -> Task Dom.Error ()
jumpToCoordinates containerId x y =
    jumpToCoordinatesWithConfig containerId x y defaultConfig


{-| Jump instantly to coordinates with custom configuration.
-}
jumpToCoordinatesWithConfig : ContainerId -> XCoordinate -> YCoordinate -> Config -> Task Dom.Error ()
jumpToCoordinatesWithConfig containerId targetX targetY _ =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    ( clampedX, clampedY ) =
                        ( targetX
                            |> min (scene.width - viewport.width)
                            |> max 0
                        , targetY
                            |> min (scene.height - viewport.height)
                            |> max 0
                        )
                in
                Dom.setViewportOf containerId clampedX clampedY
            )



-- X AXIS COORDINATE FUNCTIONS


{-| Smoothly scroll to specific X coordinate, keeping current Y position.

    scrollToCoordinateX "container-id" 500.0

-}
scrollToCoordinateX : ContainerId -> XCoordinate -> Task Dom.Error (List ())
scrollToCoordinateX containerId x =
    scrollToCoordinateXWithConfig containerId x defaultConfig


{-| Smoothly scroll to specific X coordinate with custom configuration.

    scrollToCoordinateXWithConfig "container-id" 500.0 <|
        { defaultConfig | speed = 1000 }

-}
scrollToCoordinateXWithConfig : ContainerId -> XCoordinate -> Config -> Task Dom.Error (List ())
scrollToCoordinateXWithConfig containerId x config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\viewport ->
                scrollToCoordinatesWithConfig containerId x viewport.viewport.y { config | axis = X }
            )


{-| Jump instantly to specific X coordinate, keeping current Y position.

    jumpToCoordinateX "container-id" 500.0

-}
jumpToCoordinateX : ContainerId -> XCoordinate -> Task Dom.Error ()
jumpToCoordinateX containerId x =
    jumpToCoordinateXWithConfig containerId x defaultConfig


{-| Jump instantly to specific X coordinate with custom configuration.

    jumpToCoordinateXWithConfig "container-id" 500.0 defaultConfig

-}
jumpToCoordinateXWithConfig : ContainerId -> XCoordinate -> Config -> Task Dom.Error ()
jumpToCoordinateXWithConfig containerId x config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\viewport ->
                jumpToCoordinatesWithConfig containerId x viewport.viewport.y config
            )



-- Y AXIS COORDINATE FUNCTIONS


{-| Smoothly scroll to specific Y coordinate, keeping current X position.

    scrollToCoordinateY "container-id" 1000.0

-}
scrollToCoordinateY : ContainerId -> YCoordinate -> Task Dom.Error (List ())
scrollToCoordinateY containerId y =
    scrollToCoordinateYWithConfig containerId y defaultConfig


{-| Smoothly scroll to specific Y coordinate with custom configuration.

    scrollToCoordinateYWithConfig "container-id" 1000.0 <|
        { defaultConfig | speed = 1000 }

-}
scrollToCoordinateYWithConfig : ContainerId -> YCoordinate -> Config -> Task Dom.Error (List ())
scrollToCoordinateYWithConfig containerId y config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\viewport ->
                scrollToCoordinatesWithConfig containerId viewport.viewport.x y { config | axis = Y }
            )


{-| Jump instantly to specific Y coordinate, keeping current X position.

    jumpToCoordinateY "container-id" 1000.0

-}
jumpToCoordinateY : ContainerId -> YCoordinate -> Task Dom.Error ()
jumpToCoordinateY containerId y =
    jumpToCoordinateYWithConfig containerId y defaultConfig


{-| Jump instantly to specific Y coordinate with custom configuration.

    jumpToCoordinateYWithConfig "container-id" 1000.0 defaultConfig

-}
jumpToCoordinateYWithConfig : ContainerId -> YCoordinate -> Config -> Task Dom.Error ()
jumpToCoordinateYWithConfig containerId y config =
    Dom.getViewportOf containerId
        |> Task.andThen
            (\viewport ->
                jumpToCoordinatesWithConfig containerId viewport.viewport.x y config
            )
