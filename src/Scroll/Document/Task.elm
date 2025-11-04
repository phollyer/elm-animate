module Scroll.Document.Task exposing
    ( scroll, scrollWithConfig, jump, jumpWithConfig
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
    , PercX, PercY
    , scrollToPercentage, scrollToPercentageWithConfig, jumpToPercentage, jumpToPercentageWithConfig
    , scrollToPercentageX, scrollToPercentageXWithConfig, jumpToPercentageX, jumpToPercentageXWithConfig
    , scrollToPercentageY, scrollToPercentageYWithConfig, jumpToPercentageY, jumpToPercentageYWithConfig
    , ScrollDeltaX, ScrollDeltaY, ViewportMultiplierX, ViewportMultiplierY
    , scrollBy, scrollByWithConfig, jumpBy, jumpByWithConfig
    , scrollByViewportSize, scrollByViewportSizeWithConfig, jumpByViewportSize, jumpByViewportSizeWithConfig
    , XCoordinate, YCoordinate
    , scrollToCoordinates, scrollToCoordinatesWithConfig, jumpToCoordinates, jumpToCoordinatesWithConfig
    )

{-| This module provides smooth scrolling operations for the main document body using Tasks.

**Use this module when you need:**

  - Error handling for scroll operations
  - Task composition and chaining
  - Fine-grained control over scroll completion

**Use [Scroll.Document.Cmd](Scroll.Document.Cmd) instead when you want:**

  - Simple 'fire-and-forget' scroll commands
  - Integration with standard Elm architecture

**For container-based scrolling, see:**

  - [Scroll.Container.Task](Scroll.Container.Task)
  - [Scroll.Container.Cmd](Scroll.Container.Cmd)


# Documentation Index

  - **[Element-Targeting Functions](#element-targeting-functions)** - Scroll to elements by ID
  - **[Bring Into View Functions](#bring-into-view-functions)** - Minimal movement to show elements
  - **[Position-Targeting Functions](#position-targeting-functions)** - Scroll to specific positions
      - [Edges](#edges) - Top, bottom, left, and right edges
      - [Corners](#corners) - All four corner positions
      - [Center Positioning](#center-positioning) - Center elements in viewport
  - **[Advanced Positioning Functions](#advanced-positioning-functions)** - Sophisticated positioning
      - [Percentage-Based Positioning](#percentage-based-positioning) - Position by percentage
      - [Relative Movement](#relative-movement) - Move by pixel amounts or viewport sizes
      - [Coordinate Targeting](#coordinate-targeting) - Direct coordinate positioning


# Element-Targeting Functions

@docs scroll, scrollWithConfig, jump, jumpWithConfig


# Bring Into View Functions

Bring an element into view using minimal movement.

If the bottom of the target element is below the viewport, it will scroll up enough to make it fully visible, so
it's bottom edge will line up with the bottom edge of the viewport.

If the element is taller than the viewport, it's top edge will align with the top of the viewport.
The same logic applies for horizontal scrolling, with the left edge equating to the top.

So if an element is taller and wider than the viewport, the top-left corner of the element will be aligned with
the top-left corner of the viewport.

@docs scrollIntoView, scrollIntoViewWithConfig, jumpIntoView, jumpIntoViewWithConfig

_[↑ Bring Into View Functions](#bring-into-view-functions) | [↑ Documentation Index](#documentation-index)_


# Position-Targeting Functions


## Edges

Use these functions to scroll or jump to specific edges of the document.

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

Use these functions to scroll or jump to specific corners of the document.

These functions ignore the `axis` field in the [Config](Scroll#Config) because they will always scroll on both axes to reach the target corner.


## Top-Left Corner

@docs scrollToTopLeft, scrollToTopLeftWithConfig, jumpToTopLeft, jumpToTopLeftWithConfig


## Top-Right Corner

@docs scrollToTopRight, scrollToTopRightWithConfig, jumpToTopRight, jumpToTopRightWithConfig


## Bottom-Left Corner

@docs scrollToBottomLeft, scrollToBottomLeftWithConfig, jumpToBottomLeft, jumpToBottomLeftWithConfig


## Bottom-Right Corner

@docs scrollToBottomRight, scrollToBottomRightWithConfig, jumpToBottomRight, jumpToBottomRightWithConfig

_[↑ Corners](#corners) | [↑ Position-Targeting Functions](#position-targeting-functions) | [↑ Documentation Index](#documentation-index)_


## Center Positioning

Use these functions to scroll or jump to the center of the document or center on a specific axis.

These functions ignore the `axis` field in the [Config](Scroll#Config) and scroll on the required axes.

@docs scrollToCenter, scrollToCenterWithConfig, jumpToCenter, jumpToCenterWithConfig
@docs scrollToCenterX, scrollToCenterXWithConfig, jumpToCenterX, jumpToCenterXWithConfig
@docs scrollToCenterY, scrollToCenterYWithConfig, jumpToCenterY, jumpToCenterYWithConfig

_[↑ Center Positioning](#center-positioning) | [↑ Position-Targeting Functions](#position-targeting-functions) | [↑ Documentation Index](#documentation-index)_


# Advanced Positioning Functions


## Percentage-Based Positioning

Scroll to positions defined as percentages of the total scrollable area.

@docs PercX, PercY

@docs scrollToPercentage, scrollToPercentageWithConfig, jumpToPercentage, jumpToPercentageWithConfig
@docs scrollToPercentageX, scrollToPercentageXWithConfig, jumpToPercentageX, jumpToPercentageXWithConfig
@docs scrollToPercentageY, scrollToPercentageYWithConfig, jumpToPercentageY, jumpToPercentageYWithConfig

_[↑ Percentage-Based Positioning](#percentage-based-positioning) | [↑ Advanced Positioning Functions](#advanced-positioning-functions) | [↑ Documentation Index](#documentation-index)_


## Relative Movement

Scroll relative to the current position by pixel offsets or viewport multiples.

@docs ScrollDeltaX, ScrollDeltaY, ViewportMultiplierX, ViewportMultiplierY

@docs scrollBy, scrollByWithConfig, jumpBy, jumpByWithConfig
@docs scrollByViewportSize, scrollByViewportSizeWithConfig, jumpByViewportSize, jumpByViewportSizeWithConfig

_[↑ Relative Movement](#relative-movement) | [↑ Advanced Positioning Functions](#advanced-positioning-functions) | [↑ Documentation Index](#documentation-index)_


## Coordinate Targeting

Scroll to specific pixel coordinates within the document.

@docs XCoordinate, YCoordinate

@docs scrollToCoordinates, scrollToCoordinatesWithConfig, jumpToCoordinates, jumpToCoordinatesWithConfig

_[↑ Relative Movement](#relative-movement) | [↑ Advanced Positioning Functions](#advanced-positioning-functions) | [↑ Documentation Index](#documentation-index)_

-}

import Browser.Dom as Dom
import Internal.AnimationCore exposing (animationSteps, animationStepsWithFrames)
import Scroll exposing (Axis(..), Config, Container(..), TargetId, defaultConfig)
import Scroll.Internal exposing (Direction(..), calculateScrollIntoView, getAxisDirection, getClampedPositions, getContainerInfo, getOffsetX, getOffsetY, getViewport, timingToSpeed)
import Task exposing (Task)



-- TYPE ALIASES


{-| Type alias for horizontal percentage values (0.0 to 1.0).
-}
type alias PercX =
    Float


{-| Type alias for vertical percentage values (0.0 to 1.0).
-}
type alias PercY =
    Float


{-| Type alias for horizontal scroll offset delta values in pixels.
-}
type alias ScrollDeltaX =
    Float


{-| Type alias for vertical scroll offset delta values in pixels.
-}
type alias ScrollDeltaY =
    Float


{-| Type alias for horizontal viewport size multiplier values.
-}
type alias ViewportMultiplierX =
    Float


{-| Type alias for vertical viewport size multiplier values.
-}
type alias ViewportMultiplierY =
    Float


{-| Type alias for horizontal coordinate positions in pixels.
-}
type alias XCoordinate =
    Float


{-| Type alias for vertical coordinate positions in pixels.
-}
type alias YCoordinate =
    Float



-- FUNCTIONS


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
                    case getAxisDirection config.axis of
                        XDirection ->
                            animationSteps (timingToSpeed config.timing (abs (clampedX - viewport.x))) config.easing viewport.x clampedX
                                |> List.map (\x -> Dom.setViewport x viewport.y)
                                |> Task.sequence

                        YDirection ->
                            animationSteps (timingToSpeed config.timing (abs (clampedY - viewport.y))) config.easing viewport.y clampedY
                                |> List.map (\y -> Dom.setViewport viewport.x y)
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
                    case getAxisDirection config.axis of
                        XDirection ->
                            Dom.setViewport clampedX viewport.y

                        YDirection ->
                            Dom.setViewport viewport.x clampedY

                        BothDirection ->
                            Dom.setViewport clampedX clampedY
            in
            setViewportTask
    in
    Task.map3 performJumpTask getViewport_ (Dom.getElement id) getContainerInfo_
        |> Task.andThen identity


{-| Scroll element into view using minimal movement. Automatically scrolls on both X and Y axes as needed.
-}
scrollIntoView : TargetId -> Task Dom.Error (List ())
scrollIntoView elementId =
    scrollIntoViewWithConfig elementId { defaultConfig | axis = Both }


{-| Scroll element into view using minimal movement. Automatically scrolls on both X and Y axes as needed.

Use the [Config](Scroll#Config) to customize the scrolling behavior (e.g. axis, timing, offsets).

-}
scrollIntoViewWithConfig : TargetId -> Config -> Task Dom.Error (List ())
scrollIntoViewWithConfig elementId config =
    let
        getViewport_ =
            getViewport DocumentBody

        getContainerInfo_ =
            getContainerInfo DocumentBody

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
                                |> List.map (\x -> Dom.setViewport x viewport.y)
                                |> Task.sequence

                        YDirection ->
                            animationSteps (timingToSpeed config.timing (abs (clampedY - viewport.y))) config.easing viewport.y clampedY
                                |> List.map (\y -> Dom.setViewport viewport.x y)
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


{-| Jump element into view using minimal movement. Automatically jumps on both X and Y axes as needed.
-}
jumpIntoView : TargetId -> Task Dom.Error ()
jumpIntoView elementId =
    jumpIntoViewWithConfig elementId { defaultConfig | axis = Both }


{-| Jump element into view using minimal movement.

Use the [Config](Scroll#Config) to customize the jump behavior (e.g. axis, offsets).

-}
jumpIntoViewWithConfig : TargetId -> Config -> Task Dom.Error ()
jumpIntoViewWithConfig elementId config =
    let
        getViewport_ =
            getViewport DocumentBody

        getContainerInfo_ =
            getContainerInfo DocumentBody

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

                setViewportTask =
                    case getAxisDirection config.axis of
                        XDirection ->
                            Dom.setViewport clampedX viewport.y

                        YDirection ->
                            Dom.setViewport viewport.x clampedY

                        BothDirection ->
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
                    targetY =
                        getOffsetY config.axis

                    steps =
                        animationSteps (timingToSpeed config.timing (abs (viewport.y - targetY))) config.easing viewport.y targetY
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

                    targetY =
                        maxY - getOffsetY config.axis

                    steps =
                        animationSteps (timingToSpeed config.timing (abs (targetY - viewport.y))) config.easing viewport.y targetY
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
                    targetX =
                        getOffsetX config.axis

                    steps =
                        animationSteps (timingToSpeed config.timing (abs (viewport.x - targetX))) config.easing viewport.x targetX
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

                    targetX =
                        maxX - getOffsetX config.axis

                    steps =
                        animationSteps (timingToSpeed config.timing (abs (targetX - viewport.x))) config.easing viewport.x targetX
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
jumpToTopWithConfig config =
    Dom.getViewport
        |> Task.andThen (\{ viewport } -> Dom.setViewport viewport.x (getOffsetY config.axis))


{-| Jump instantly to bottom of document.
-}
jumpToBottom : Task Dom.Error ()
jumpToBottom =
    jumpToBottomWithConfig defaultConfig


{-| Jump instantly to bottom of document with custom configuration.
-}
jumpToBottomWithConfig : Config -> Task Dom.Error ()
jumpToBottomWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxY =
                        scene.height - viewport.height - getOffsetY config.axis
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
jumpToLeftEdgeWithConfig config =
    Dom.getViewport
        |> Task.andThen (\{ viewport } -> Dom.setViewport (getOffsetX config.axis) viewport.y)


{-| Jump instantly to right edge of document.
-}
jumpToRightEdge : Task Dom.Error ()
jumpToRightEdge =
    jumpToRightEdgeWithConfig defaultConfig


{-| Jump instantly to right edge of document with custom configuration.
-}
jumpToRightEdgeWithConfig : Config -> Task Dom.Error ()
jumpToRightEdgeWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width - getOffsetX config.axis
                in
                Dom.setViewport maxX viewport.y
            )


{-| Smooth scroll to top-left corner of document.
-}
scrollToTopLeft : Task Dom.Error (List ())
scrollToTopLeft =
    scrollToTopLeftWithConfig defaultConfig


{-| Smooth scroll to top-left corner of document with custom configuration.
-}
scrollToTopLeftWithConfig : Config -> Task Dom.Error (List ())
scrollToTopLeftWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ viewport } ->
                let
                    targetX =
                        getOffsetX config.axis

                    targetY =
                        getOffsetY config.axis

                    -- Calculate the maximum distance to determine frame count
                    xDistance =
                        abs (viewport.x - targetX)

                    yDistance =
                        abs (viewport.y - targetY)

                    maxDistance =
                        max xDistance yDistance

                    -- Use the same frame count for both axes to ensure synchronization
                    frames =
                        Basics.max 1 (timingToSpeed config.timing maxDistance)

                    -- Generate synchronized steps
                    xSteps =
                        animationStepsWithFrames frames config.easing viewport.x targetX

                    ySteps =
                        animationStepsWithFrames frames config.easing viewport.y targetY
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
            )


{-| Jump instantly to top-left corner of document.
-}
jumpToTopLeft : Task Dom.Error ()
jumpToTopLeft =
    jumpToTopLeftWithConfig defaultConfig


{-| Jump instantly to top-left corner of document with custom configuration.
-}
jumpToTopLeftWithConfig : Config -> Task Dom.Error ()
jumpToTopLeftWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\_ ->
                Dom.setViewport (getOffsetX config.axis) (getOffsetY config.axis)
            )


{-| Smooth scroll to top-right corner of document.
-}
scrollToTopRight : Task Dom.Error (List ())
scrollToTopRight =
    scrollToTopRightWithConfig defaultConfig


{-| Smooth scroll to top-right corner of document with custom configuration.
-}
scrollToTopRightWithConfig : Config -> Task Dom.Error (List ())
scrollToTopRightWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width

                    targetX =
                        maxX - getOffsetX config.axis

                    targetY =
                        getOffsetY config.axis

                    -- Calculate the maximum distance to determine frame count
                    xDistance =
                        abs (viewport.x - targetX)

                    yDistance =
                        abs (viewport.y - targetY)

                    maxDistance =
                        max xDistance yDistance

                    -- Use the same frame count for both axes to ensure synchronization
                    frames =
                        Basics.max 1 (timingToSpeed config.timing maxDistance)

                    -- Generate synchronized steps
                    xSteps =
                        animationStepsWithFrames frames config.easing viewport.x targetX

                    ySteps =
                        animationStepsWithFrames frames config.easing viewport.y targetY
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
            )


{-| Jump instantly to top-right corner of document.
-}
jumpToTopRight : Task Dom.Error ()
jumpToTopRight =
    jumpToTopRightWithConfig defaultConfig


{-| Jump instantly to top-right corner of document with custom configuration.
-}
jumpToTopRightWithConfig : Config -> Task Dom.Error ()
jumpToTopRightWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width - getOffsetX config.axis
                in
                Dom.setViewport maxX (getOffsetY config.axis)
            )


{-| Smooth scroll to bottom-left corner of document.
-}
scrollToBottomLeft : Task Dom.Error (List ())
scrollToBottomLeft =
    scrollToBottomLeftWithConfig defaultConfig


{-| Smooth scroll to bottom-left corner of document with custom configuration.
-}
scrollToBottomLeftWithConfig : Config -> Task Dom.Error (List ())
scrollToBottomLeftWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxY =
                        scene.height - viewport.height

                    targetX =
                        getOffsetX config.axis

                    targetY =
                        maxY - getOffsetY config.axis

                    -- Calculate the maximum distance to determine frame count
                    xDistance =
                        abs (viewport.x - targetX)

                    yDistance =
                        abs (viewport.y - targetY)

                    maxDistance =
                        max xDistance yDistance

                    -- Use the same frame count for both axes to ensure synchronization
                    frames =
                        Basics.max 1 (timingToSpeed config.timing maxDistance)

                    -- Generate synchronized steps
                    xSteps =
                        animationStepsWithFrames frames config.easing viewport.x targetX

                    ySteps =
                        animationStepsWithFrames frames config.easing viewport.y targetY
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
            )


{-| Jump instantly to bottom-left corner of document.
-}
jumpToBottomLeft : Task Dom.Error ()
jumpToBottomLeft =
    jumpToBottomLeftWithConfig defaultConfig


{-| Jump instantly to bottom-left corner of document with custom configuration.
-}
jumpToBottomLeftWithConfig : Config -> Task Dom.Error ()
jumpToBottomLeftWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxY =
                        scene.height - viewport.height - getOffsetY config.axis
                in
                Dom.setViewport (getOffsetX config.axis) maxY
            )


{-| Smooth scroll to bottom-right corner of document.
-}
scrollToBottomRight : Task Dom.Error (List ())
scrollToBottomRight =
    scrollToBottomRightWithConfig defaultConfig


{-| Smooth scroll to bottom-right corner of document with custom configuration.
-}
scrollToBottomRightWithConfig : Config -> Task Dom.Error (List ())
scrollToBottomRightWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width

                    maxY =
                        scene.height - viewport.height

                    targetX =
                        maxX - getOffsetX config.axis

                    targetY =
                        maxY - getOffsetY config.axis

                    -- Calculate the maximum distance to determine frame count
                    xDistance =
                        abs (viewport.x - targetX)

                    yDistance =
                        abs (viewport.y - targetY)

                    maxDistance =
                        max xDistance yDistance

                    -- Use the same frame count for both axes to ensure synchronization
                    frames =
                        Basics.max 1 (timingToSpeed config.timing maxDistance)

                    -- Generate synchronized steps
                    xSteps =
                        animationStepsWithFrames frames config.easing viewport.x targetX

                    ySteps =
                        animationStepsWithFrames frames config.easing viewport.y targetY
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
            )


{-| Jump instantly to bottom-right corner of document.
-}
jumpToBottomRight : Task Dom.Error ()
jumpToBottomRight =
    jumpToBottomRightWithConfig defaultConfig


{-| Jump instantly to bottom-right corner of document with custom configuration.
-}
jumpToBottomRightWithConfig : Config -> Task Dom.Error ()
jumpToBottomRightWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width - getOffsetX config.axis

                    maxY =
                        scene.height - viewport.height - getOffsetY config.axis
                in
                Dom.setViewport maxX maxY
            )


{-| Smooth scroll to center of document.
-}
scrollToCenter : Task Dom.Error (List ())
scrollToCenter =
    scrollToCenterWithConfig defaultConfig


{-| Smooth scroll to center of document with custom configuration.
-}
scrollToCenterWithConfig : Config -> Task Dom.Error (List ())
scrollToCenterWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    centerX =
                        (scene.width - viewport.width) / 2 + getOffsetX config.axis

                    centerY =
                        (scene.height - viewport.height) / 2 + getOffsetY config.axis

                    -- Calculate the maximum distance to determine frame count
                    xDistance =
                        abs (viewport.x - centerX)

                    yDistance =
                        abs (viewport.y - centerY)

                    maxDistance =
                        max xDistance yDistance

                    -- Use the same frame count for both axes to ensure synchronization
                    frames =
                        Basics.max 1 (timingToSpeed config.timing maxDistance)

                    -- Generate synchronized steps
                    xSteps =
                        animationStepsWithFrames frames config.easing viewport.x centerX

                    ySteps =
                        animationStepsWithFrames frames config.easing viewport.y centerY
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
            )


{-| Jump instantly to center of document.
-}
jumpToCenter : Task Dom.Error ()
jumpToCenter =
    jumpToCenterWithConfig defaultConfig


{-| Jump instantly to center of document with custom configuration.
-}
jumpToCenterWithConfig : Config -> Task Dom.Error ()
jumpToCenterWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    centerX =
                        (scene.width - viewport.width) / 2 + getOffsetX config.axis

                    centerY =
                        (scene.height - viewport.height) / 2 + getOffsetY config.axis
                in
                Dom.setViewport centerX centerY
            )


{-| Smooth scroll to center horizontally.
-}
scrollToCenterX : Task Dom.Error (List ())
scrollToCenterX =
    scrollToCenterXWithConfig defaultConfig


{-| Smooth scroll to center horizontally with custom configuration.
-}
scrollToCenterXWithConfig : Config -> Task Dom.Error (List ())
scrollToCenterXWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    centerX =
                        (scene.width - viewport.width) / 2 + getOffsetX config.axis

                    steps =
                        animationSteps (timingToSpeed config.timing (abs (viewport.x - centerX))) config.easing viewport.x centerX
                in
                steps
                    |> List.map (\x -> Dom.setViewport x viewport.y)
                    |> Task.sequence
            )


{-| Jump instantly to center horizontally.
-}
jumpToCenterX : Task Dom.Error ()
jumpToCenterX =
    jumpToCenterXWithConfig defaultConfig


{-| Jump instantly to center horizontally with custom configuration.
-}
jumpToCenterXWithConfig : Config -> Task Dom.Error ()
jumpToCenterXWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    centerX =
                        (scene.width - viewport.width) / 2 + getOffsetX config.axis
                in
                Dom.setViewport centerX viewport.y
            )


{-| Smooth scroll to center vertically.
-}
scrollToCenterY : Task Dom.Error (List ())
scrollToCenterY =
    scrollToCenterYWithConfig defaultConfig


{-| Smooth scroll to center vertically with custom configuration.
-}
scrollToCenterYWithConfig : Config -> Task Dom.Error (List ())
scrollToCenterYWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    centerY =
                        (scene.height - viewport.height) / 2 + getOffsetY config.axis

                    steps =
                        animationSteps (timingToSpeed config.timing (abs (viewport.y - centerY))) config.easing viewport.y centerY
                in
                steps
                    |> List.map (\y -> Dom.setViewport viewport.x y)
                    |> Task.sequence
            )


{-| Jump instantly to center vertically.
-}
jumpToCenterY : Task Dom.Error ()
jumpToCenterY =
    jumpToCenterYWithConfig defaultConfig


{-| Jump instantly to center vertically with custom configuration.
-}
jumpToCenterYWithConfig : Config -> Task Dom.Error ()
jumpToCenterYWithConfig config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    centerY =
                        (scene.height - viewport.height) / 2 + getOffsetY config.axis
                in
                Dom.setViewport viewport.x centerY
            )


{-| Smooth scroll to percentage positions. Takes percentageX and percentageY as values between 0.0 and 1.0.
-}
scrollToPercentage : PercX -> PercY -> Task Dom.Error (List ())
scrollToPercentage percentageX percentageY =
    scrollToPercentageWithConfig percentageX percentageY defaultConfig


{-| Smooth scroll to percentage positions with custom configuration.
-}
scrollToPercentageWithConfig : PercX -> PercY -> Config -> Task Dom.Error (List ())
scrollToPercentageWithConfig percentageX percentageY config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width

                    maxY =
                        scene.height - viewport.height

                    targetX =
                        (maxX * percentageX) + getOffsetX config.axis

                    targetY =
                        (maxY * percentageY) + getOffsetY config.axis

                    -- Calculate the maximum distance to determine frame count
                    xDistance =
                        abs (viewport.x - targetX)

                    yDistance =
                        abs (viewport.y - targetY)

                    maxDistance =
                        max xDistance yDistance

                    -- Use the same frame count for both axes to ensure synchronization
                    frames =
                        Basics.max 1 (timingToSpeed config.timing maxDistance)

                    -- Generate synchronized steps
                    xSteps =
                        animationStepsWithFrames frames config.easing viewport.x targetX

                    ySteps =
                        animationStepsWithFrames frames config.easing viewport.y targetY
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
            )


{-| Jump instantly to percentage positions.
-}
jumpToPercentage : PercX -> PercY -> Task Dom.Error ()
jumpToPercentage percentageX percentageY =
    jumpToPercentageWithConfig percentageX percentageY defaultConfig


{-| Jump instantly to percentage positions with custom configuration.
-}
jumpToPercentageWithConfig : PercX -> PercY -> Config -> Task Dom.Error ()
jumpToPercentageWithConfig percentageX percentageY config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width

                    maxY =
                        scene.height - viewport.height

                    targetX =
                        (maxX * percentageX) + getOffsetX config.axis

                    targetY =
                        (maxY * percentageY) + getOffsetY config.axis
                in
                Dom.setViewport targetX targetY
            )


{-| Smooth scroll to percentage position horizontally.
-}
scrollToPercentageX : PercX -> Task Dom.Error (List ())
scrollToPercentageX percentage =
    scrollToPercentageXWithConfig percentage defaultConfig


{-| Smooth scroll to percentage position horizontally with custom configuration.
-}
scrollToPercentageXWithConfig : PercX -> Config -> Task Dom.Error (List ())
scrollToPercentageXWithConfig percentage config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width

                    targetX =
                        (maxX * percentage) + getOffsetX config.axis

                    steps =
                        animationSteps (timingToSpeed config.timing (abs (viewport.x - targetX))) config.easing viewport.x targetX
                in
                steps
                    |> List.map (\x -> Dom.setViewport x viewport.y)
                    |> Task.sequence
            )


{-| Jump instantly to percentage position horizontally.
-}
jumpToPercentageX : PercX -> Task Dom.Error ()
jumpToPercentageX percentage =
    jumpToPercentageXWithConfig percentage defaultConfig


{-| Jump instantly to percentage position horizontally with custom configuration.
-}
jumpToPercentageXWithConfig : PercX -> Config -> Task Dom.Error ()
jumpToPercentageXWithConfig percentage config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width

                    targetX =
                        (maxX * percentage) + getOffsetX config.axis
                in
                Dom.setViewport targetX viewport.y
            )


{-| Smooth scroll to percentage position vertically.
-}
scrollToPercentageY : PercY -> Task Dom.Error (List ())
scrollToPercentageY percentage =
    scrollToPercentageYWithConfig percentage defaultConfig


{-| Smooth scroll to percentage position vertically with custom configuration.
-}
scrollToPercentageYWithConfig : PercY -> Config -> Task Dom.Error (List ())
scrollToPercentageYWithConfig percentage config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxY =
                        scene.height - viewport.height

                    targetY =
                        (maxY * percentage) + getOffsetY config.axis

                    steps =
                        animationSteps (timingToSpeed config.timing (abs (viewport.y - targetY))) config.easing viewport.y targetY
                in
                steps
                    |> List.map (\y -> Dom.setViewport viewport.x y)
                    |> Task.sequence
            )


{-| Jump instantly to percentage position vertically.
-}
jumpToPercentageY : PercY -> Task Dom.Error ()
jumpToPercentageY percentage =
    jumpToPercentageYWithConfig percentage defaultConfig


{-| Jump instantly to percentage position vertically with custom configuration.
-}
jumpToPercentageYWithConfig : PercY -> Config -> Task Dom.Error ()
jumpToPercentageYWithConfig percentage config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxY =
                        scene.height - viewport.height

                    targetY =
                        (maxY * percentage) + getOffsetY config.axis
                in
                Dom.setViewport viewport.x targetY
            )


{-| Smooth scroll by pixel offsets from current position.
-}
scrollBy : ScrollDeltaX -> ScrollDeltaY -> Task Dom.Error (List ())
scrollBy offsetX offsetY =
    scrollByWithConfig offsetX offsetY defaultConfig


{-| Smooth scroll by pixel offsets from current position with custom configuration.
-}
scrollByWithConfig : ScrollDeltaX -> ScrollDeltaY -> Config -> Task Dom.Error (List ())
scrollByWithConfig offsetX offsetY config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width

                    maxY =
                        scene.height - viewport.height

                    targetX =
                        (viewport.x + offsetX + getOffsetX config.axis)
                            |> max 0
                            |> min maxX

                    targetY =
                        (viewport.y + offsetY + getOffsetY config.axis)
                            |> max 0
                            |> min maxY

                    -- Calculate the maximum distance to determine frame count
                    xDistance =
                        abs (viewport.x - targetX)

                    yDistance =
                        abs (viewport.y - targetY)

                    maxDistance =
                        max xDistance yDistance

                    -- Use the same frame count for both axes to ensure synchronization
                    frames =
                        Basics.max 1 (timingToSpeed config.timing maxDistance)

                    -- Generate synchronized steps
                    xSteps =
                        animationStepsWithFrames frames config.easing viewport.x targetX

                    ySteps =
                        animationStepsWithFrames frames config.easing viewport.y targetY
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
            )


{-| Jump instantly by pixel offsets from current position.
-}
jumpBy : ScrollDeltaX -> ScrollDeltaY -> Task Dom.Error ()
jumpBy offsetX offsetY =
    jumpByWithConfig offsetX offsetY defaultConfig


{-| Jump instantly by pixel offsets from current position with custom configuration.
-}
jumpByWithConfig : ScrollDeltaX -> ScrollDeltaY -> Config -> Task Dom.Error ()
jumpByWithConfig offsetX offsetY config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width

                    maxY =
                        scene.height - viewport.height

                    targetX =
                        (viewport.x + offsetX + getOffsetX config.axis)
                            |> max 0
                            |> min maxX

                    targetY =
                        (viewport.y + offsetY + getOffsetY config.axis)
                            |> max 0
                            |> min maxY
                in
                Dom.setViewport targetX targetY
            )


{-| Smooth scroll by viewport size multiples from current position.
-}
scrollByViewportSize : ViewportMultiplierX -> ViewportMultiplierY -> Task Dom.Error (List ())
scrollByViewportSize multiplierX multiplierY =
    scrollByViewportSizeWithConfig multiplierX multiplierY defaultConfig


{-| Smooth scroll by viewport size multiples from current position with custom configuration.
-}
scrollByViewportSizeWithConfig : ViewportMultiplierX -> ViewportMultiplierY -> Config -> Task Dom.Error (List ())
scrollByViewportSizeWithConfig multiplierX multiplierY config =
    Dom.getViewport
        |> Task.andThen
            (\{ viewport } ->
                let
                    offsetX =
                        viewport.width * multiplierX

                    offsetY =
                        viewport.height * multiplierY
                in
                scrollByWithConfig offsetX offsetY config
            )


{-| Jump instantly by viewport size multiples from current position.
-}
jumpByViewportSize : ViewportMultiplierX -> ViewportMultiplierY -> Task Dom.Error ()
jumpByViewportSize multiplierX multiplierY =
    jumpByViewportSizeWithConfig multiplierX multiplierY defaultConfig


{-| Jump instantly by viewport size multiples from current position with custom configuration.
-}
jumpByViewportSizeWithConfig : ViewportMultiplierX -> ViewportMultiplierY -> Config -> Task Dom.Error ()
jumpByViewportSizeWithConfig multiplierX multiplierY config =
    Dom.getViewport
        |> Task.andThen
            (\{ viewport } ->
                let
                    offsetX =
                        viewport.width * multiplierX

                    offsetY =
                        viewport.height * multiplierY
                in
                jumpByWithConfig offsetX offsetY config
            )


{-| Smooth scroll to specific pixel coordinates.
-}
scrollToCoordinates : XCoordinate -> YCoordinate -> Task Dom.Error (List ())
scrollToCoordinates x y =
    scrollToCoordinatesWithConfig x y defaultConfig


{-| Smooth scroll to specific pixel coordinates with custom configuration.
-}
scrollToCoordinatesWithConfig : XCoordinate -> YCoordinate -> Config -> Task Dom.Error (List ())
scrollToCoordinatesWithConfig x y config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width

                    maxY =
                        scene.height - viewport.height

                    targetX =
                        (x + getOffsetX config.axis)
                            |> max 0
                            |> min maxX

                    targetY =
                        (y + getOffsetY config.axis)
                            |> max 0
                            |> min maxY

                    -- Calculate the maximum distance to determine frame count
                    xDistance =
                        abs (viewport.x - targetX)

                    yDistance =
                        abs (viewport.y - targetY)

                    maxDistance =
                        max xDistance yDistance

                    -- Use the same frame count for both axes to ensure synchronization
                    frames =
                        Basics.max 1 (timingToSpeed config.timing maxDistance)

                    -- Generate synchronized steps
                    xSteps =
                        animationStepsWithFrames frames config.easing viewport.x targetX

                    ySteps =
                        animationStepsWithFrames frames config.easing viewport.y targetY
                in
                case ( xSteps, ySteps ) of
                    ( [], _ ) ->
                        -- No horizontal movement needed, only animate Y
                        ySteps
                            |> List.map (\y_ -> Dom.setViewport viewport.x y_)
                            |> Task.sequence

                    ( _, [] ) ->
                        -- No vertical movement needed, only animate X
                        xSteps
                            |> List.map (\x_ -> Dom.setViewport x_ viewport.y)
                            |> Task.sequence

                    _ ->
                        List.map2 Dom.setViewport xSteps ySteps
                            |> Task.sequence
            )


{-| Jump instantly to specific pixel coordinates.
-}
jumpToCoordinates : XCoordinate -> YCoordinate -> Task Dom.Error ()
jumpToCoordinates x y =
    jumpToCoordinatesWithConfig x y defaultConfig


{-| Jump instantly to specific pixel coordinates with custom configuration.
-}
jumpToCoordinatesWithConfig : XCoordinate -> YCoordinate -> Config -> Task Dom.Error ()
jumpToCoordinatesWithConfig x y config =
    Dom.getViewport
        |> Task.andThen
            (\{ scene, viewport } ->
                let
                    maxX =
                        scene.width - viewport.width

                    maxY =
                        scene.height - viewport.height

                    targetX =
                        (x + getOffsetX config.axis)
                            |> max 0
                            |> min maxX

                    targetY =
                        (y + getOffsetY config.axis)
                            |> max 0
                            |> min maxY
                in
                Dom.setViewport targetX targetY
            )
