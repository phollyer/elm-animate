module Scroll.Container.Cmd exposing
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

{-| This module provides smooth scrolling operations for DOM containers using Commands.

**Use this module when you need:**

  - Simple 'fire-and-forget' scroll commands
  - Integration with standard Elm architecture
  - No need for error handling of scroll operations

**Use [Scroll.Container.Task](Scroll.Container.Task) instead when you want:**

  - Error handling for container scroll operations
  - Task composition and chaining
  - Fine-grained control over scroll completion

**For document-based scrolling, see:**

  - [Scroll.Document.Cmd](Scroll.Document.Cmd)
  - [Scroll.Document.Task](Scroll.Document.Task)


# Documentation Index

  - **[Element-Targeting Functions](#element-targeting-functions)** - Scroll to elements by ID within containers
  - **[Bring Into View Functions](#bring-into-view-functions)** - Minimal movement to show elements within containers
  - **[Position-Targeting Functions](#position-targeting-functions)** - Scroll to specific positions within containers
      - [Edges](#edges) - Top, bottom, left, and right edges of containers
      - [Corners](#corners) - All four corner positions within containers
      - [Center Positioning](#center-positioning) - Center elements within container viewport
  - **[Advanced Positioning Functions](#advanced-positioning-functions)** - Sophisticated container positioning
      - [Percentage-Based Positioning](#percentage-based-positioning) - Position by percentage within containers
      - [Relative Movement](#relative-movement) - Move by pixel amounts or viewport sizes within containers
      - [Coordinate Targeting](#coordinate-targeting) - Direct coordinate positioning within containers


# Element-Targeting Functions

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


## Percentage-Based Positioning

Position within the container using percentages (0-100). Values outside this range are automatically clamped.

The `axis` field in [Config](Scroll#Config) controls which axes are used for percentage positioning.

@docs PercX, PercY


### Both Axes

@docs scrollToPercentage, scrollToPercentageWithConfig, jumpToPercentage, jumpToPercentageWithConfig


### X Axis Only

@docs scrollToPercentageX, scrollToPercentageXWithConfig, jumpToPercentageX, jumpToPercentageXWithConfig


### Y Axis Only

@docs scrollToPercentageY, scrollToPercentageYWithConfig, jumpToPercentageY, jumpToPercentageYWithConfig

_[↑ Percentage-Based Positioning](#percentage-based-positioning) | [↑ Advanced Positioning Functions](#advanced-positioning-functions) | [↑ Documentation Index](#documentation-index)_


## Relative Movement

Move relative to the current scroll position within the container.

The `axis` field in [Config](Scroll#Config) controls which axes are affected by the relative movement.

@docs ScrollDeltaX, ScrollDeltaY, ViewportMultiplierX, ViewportMultiplierY


### Pixel-Based Movement

@docs scrollBy, scrollByWithConfig, jumpBy, jumpByWithConfig


### Viewport-Based Movement

@docs scrollByViewportSize, scrollByViewportSizeWithConfig, jumpByViewportSize, jumpByViewportSizeWithConfig

_[↑ Relative Movement](#relative-movement) | [↑ Advanced Positioning Functions](#advanced-positioning-functions) | [↑ Documentation Index](#documentation-index)_


## Coordinate Targeting

Scroll or jump to specific pixel coordinates within the container. Coordinates are automatically clamped to valid ranges.

The `axis` field in [Config](Scroll#Config) controls which axes are used for coordinate targeting.

@docs XCoordinate, YCoordinate

@docs scrollToCoordinates, scrollToCoordinatesWithConfig, jumpToCoordinates, jumpToCoordinatesWithConfig

_[↑ Coordinate Targeting](#coordinate-targeting) | [↑ Advanced Positioning Functions](#advanced-positioning-functions) | [↑ Documentation Index](#documentation-index)_

-}

import Scroll exposing (Config, Container(..), ContainerId, TargetId, defaultConfig)
import Scroll.Container.Task as ScrollTask
import Task


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



-- ELEMENT-TARGETING FUNCTIONS


{-| Smoothly scroll to a DOM element within a specific container using default configuration.

    scroll "container-id" "my-element" NoOp

This scrolls to the element with ID "my-element" within the container with ID "container-id".

-}
scroll : ContainerId -> TargetId -> msg -> Cmd msg
scroll containerId elementId msg =
    scrollWithConfig containerId elementId msg defaultConfig


{-| Smoothly scroll to a DOM element within a container with custom configuration.

    scrollWithConfig "container-id"
        "my-element"
        NoOp
        { defaultConfig
            | axis = XWithOffset 20
        }

-}
scrollWithConfig : ContainerId -> TargetId -> msg -> Config -> Cmd msg
scrollWithConfig containerId elementId msg config =
    ScrollTask.scrollWithConfig containerId elementId config
        |> Task.attempt (always msg)


{-| Instantly jump to a DOM element within a container using default configuration.

    jump "container-id" "my-element" NoOp

-}
jump : ContainerId -> TargetId -> msg -> Cmd msg
jump containerId elementId msg =
    jumpWithConfig containerId elementId msg defaultConfig


{-| Instantly jump to a DOM element within a container with custom configuration.

    jumpWithConfig "container-id"
        "my-element"
        NoOp
        { defaultConfig | offsetY = 50 }

-}
jumpWithConfig : ContainerId -> TargetId -> msg -> Config -> Cmd msg
jumpWithConfig containerId elementId msg config =
    ScrollTask.jumpWithConfig containerId elementId config
        |> Task.attempt (always msg)



-- POSITION-TARGETING FUNCTIONS


{-| Smoothly scroll to the top of a container using default configuration.

    scrollToTop "container-id" NoOp

-}
scrollToTop : ContainerId -> msg -> Cmd msg
scrollToTop containerId msg =
    scrollToTopWithConfig containerId msg defaultConfig


{-| Smoothly scroll to the top of a container with custom configuration.

    scrollToTopWithConfig "container-id"
        NoOp
        { defaultConfig | timing = Duration 600 }

-}
scrollToTopWithConfig : ContainerId -> msg -> Config -> Cmd msg
scrollToTopWithConfig containerId msg config =
    ScrollTask.scrollToTopWithConfig containerId config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the bottom of a container using default configuration.

    scrollToBottom "container-id" NoOp

-}
scrollToBottom : ContainerId -> msg -> Cmd msg
scrollToBottom containerId msg =
    scrollToBottomWithConfig containerId msg defaultConfig


{-| Smoothly scroll to the bottom of a container with custom configuration.

    scrollToBottomWithConfig "container-id"
        NoOp
        { defaultConfig | timing = Speed 800 }

-}
scrollToBottomWithConfig : ContainerId -> msg -> Config -> Cmd msg
scrollToBottomWithConfig containerId msg config =
    ScrollTask.scrollToBottomWithConfig containerId config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the left edge of a container using default configuration.

    scrollToLeftEdge "container-id" NoOp

-}
scrollToLeftEdge : ContainerId -> msg -> Cmd msg
scrollToLeftEdge containerId msg =
    scrollToLeftEdgeWithConfig containerId msg defaultConfig


{-| Smoothly scroll to the left edge of a container with custom configuration.

    scrollToLeftEdgeWithConfig "container-id"
        NoOp
        { defaultConfig | timing = Duration 400 }

-}
scrollToLeftEdgeWithConfig : ContainerId -> msg -> Config -> Cmd msg
scrollToLeftEdgeWithConfig containerId msg config =
    ScrollTask.scrollToLeftEdgeWithConfig containerId config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the right edge of a container using default configuration.

    scrollToRightEdge "container-id" NoOp

-}
scrollToRightEdge : ContainerId -> msg -> Cmd msg
scrollToRightEdge containerId msg =
    scrollToRightEdgeWithConfig containerId msg defaultConfig


{-| Smoothly scroll to the right edge of a container with custom configuration.

    scrollToRightEdgeWithConfig "container-id"
        NoOp
        { defaultConfig | timing = Duration 500 }

-}
scrollToRightEdgeWithConfig : ContainerId -> msg -> Config -> Cmd msg
scrollToRightEdgeWithConfig containerId msg config =
    ScrollTask.scrollToRightEdgeWithConfig containerId config
        |> Task.attempt (always msg)


{-| Instantly jump to the top of a container using default configuration.

    jumpToTop "container-id" NoOp

-}
jumpToTop : ContainerId -> msg -> Cmd msg
jumpToTop containerId msg =
    jumpToTopWithConfig containerId msg defaultConfig


{-| Instantly jump to the top of a container with custom configuration.

    jumpToTopWithConfig "container-id"
        NoOp
        { defaultConfig | offsetY = 10 }

-}
jumpToTopWithConfig : ContainerId -> msg -> Config -> Cmd msg
jumpToTopWithConfig containerId msg config =
    ScrollTask.jumpToTopWithConfig containerId config
        |> Task.attempt (always msg)


{-| Instantly jump to the bottom of a container using default configuration.

    jumpToBottom "container-id" NoOp

-}
jumpToBottom : ContainerId -> msg -> Cmd msg
jumpToBottom containerId msg =
    jumpToBottomWithConfig containerId msg defaultConfig


{-| Instantly jump to the bottom of a container with custom configuration.

    jumpToBottomWithConfig "container-id"
        NoOp
        { defaultConfig | offsetY = 20 }

-}
jumpToBottomWithConfig : ContainerId -> msg -> Config -> Cmd msg
jumpToBottomWithConfig containerId msg config =
    ScrollTask.jumpToBottomWithConfig containerId config
        |> Task.attempt (always msg)


{-| Instantly jump to the left edge of a container using default configuration.

    jumpToLeftEdge "container-id" NoOp

-}
jumpToLeftEdge : ContainerId -> msg -> Cmd msg
jumpToLeftEdge containerId msg =
    jumpToLeftEdgeWithConfig containerId msg defaultConfig


{-| Instantly jump to the left edge of a container with custom configuration.

    jumpToLeftEdgeWithConfig "container-id"
        NoOp
        { defaultConfig |

-}
jumpToLeftEdgeWithConfig : ContainerId -> msg -> Config -> Cmd msg
jumpToLeftEdgeWithConfig containerId msg config =
    ScrollTask.jumpToLeftEdgeWithConfig containerId config
        |> Task.attempt (always msg)


{-| Instantly jump to the right edge of a container using default configuration.

    jumpToRightEdge "container-id" NoOp

-}
jumpToRightEdge : ContainerId -> msg -> Cmd msg
jumpToRightEdge containerId msg =
    jumpToRightEdgeWithConfig containerId msg defaultConfig


{-| Instantly jump to the right edge of a container with custom configuration.

    jumpToRightEdgeWithConfig "container-id"
        NoOp
        { defaultConfig |

-}
jumpToRightEdgeWithConfig : ContainerId -> msg -> Config -> Cmd msg
jumpToRightEdgeWithConfig containerId msg config =
    ScrollTask.jumpToRightEdgeWithConfig containerId config
        |> Task.attempt (always msg)



-- BRING INTO VIEW FUNCTIONS


{-| Smoothly scroll to bring an element into view within a container using minimal movement.

    scrollIntoView "container-id" "target-element" NoOp

-}
scrollIntoView : ContainerId -> TargetId -> msg -> Cmd msg
scrollIntoView containerId elementId msg =
    scrollIntoViewWithConfig containerId elementId msg defaultConfig


{-| Smoothly scroll to bring an element into view within a container with custom configuration.

    scrollIntoViewWithConfig "container-id" "target-element" NoOp { defaultConfig | offsetY = 50 }

-}
scrollIntoViewWithConfig : ContainerId -> TargetId -> msg -> Config -> Cmd msg
scrollIntoViewWithConfig containerId elementId msg config =
    ScrollTask.scrollIntoViewWithConfig containerId elementId config
        |> Task.attempt (always msg)


{-| Jump instantly to bring an element into view within a container using minimal movement.

    jumpIntoView "container-id" "target-element" NoOp

-}
jumpIntoView : ContainerId -> TargetId -> msg -> Cmd msg
jumpIntoView containerId elementId msg =
    jumpIntoViewWithConfig containerId elementId msg defaultConfig


{-| Jump instantly to bring an element into view within a container with custom configuration.

    jumpIntoViewWithConfig "container-id" "target-element" NoOp { defaultConfig | offsetY = 50 }

-}
jumpIntoViewWithConfig : ContainerId -> TargetId -> msg -> Config -> Cmd msg
jumpIntoViewWithConfig containerId elementId msg config =
    ScrollTask.jumpIntoViewWithConfig containerId elementId config
        |> Task.attempt (always msg)



-- CORNER POSITIONING FUNCTIONS


{-| Smoothly scroll to the top-left corner of a container.

    scrollToTopLeft "container-id" NoOp

-}
scrollToTopLeft : ContainerId -> msg -> Cmd msg
scrollToTopLeft containerId msg =
    scrollToTopLeftWithConfig containerId msg defaultConfig


{-| Smoothly scroll to the top-left corner with custom configuration.

    scrollToTopLeftWithConfig "container-id" NoOp { defaultConfig | speed = 1000 }

-}
scrollToTopLeftWithConfig : ContainerId -> msg -> Config -> Cmd msg
scrollToTopLeftWithConfig containerId msg config =
    ScrollTask.scrollToTopLeftWithConfig containerId config
        |> Task.attempt (always msg)


{-| Jump instantly to the top-left corner of a container.

    jumpToTopLeft "container-id" NoOp

-}
jumpToTopLeft : ContainerId -> msg -> Cmd msg
jumpToTopLeft containerId msg =
    jumpToTopLeftWithConfig containerId msg defaultConfig


{-| Jump instantly to the top-left corner with custom configuration.

    jumpToTopLeftWithConfig "container-id" NoOp defaultConfig

-}
jumpToTopLeftWithConfig : ContainerId -> msg -> Config -> Cmd msg
jumpToTopLeftWithConfig containerId msg config =
    ScrollTask.jumpToTopLeftWithConfig containerId config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the top-right corner of a container.

    scrollToTopRight "container-id" NoOp

-}
scrollToTopRight : ContainerId -> msg -> Cmd msg
scrollToTopRight containerId msg =
    scrollToTopRightWithConfig containerId msg defaultConfig


{-| Smoothly scroll to the top-right corner with custom configuration.

    scrollToTopRightWithConfig "container-id" NoOp { defaultConfig | speed = 1000 }

-}
scrollToTopRightWithConfig : ContainerId -> msg -> Config -> Cmd msg
scrollToTopRightWithConfig containerId msg config =
    ScrollTask.scrollToTopRightWithConfig containerId config
        |> Task.attempt (always msg)


{-| Jump instantly to the top-right corner of a container.

    jumpToTopRight "container-id" NoOp

-}
jumpToTopRight : ContainerId -> msg -> Cmd msg
jumpToTopRight containerId msg =
    jumpToTopRightWithConfig containerId msg defaultConfig


{-| Jump instantly to the top-right corner with custom configuration.

    jumpToTopRightWithConfig "container-id" NoOp defaultConfig

-}
jumpToTopRightWithConfig : ContainerId -> msg -> Config -> Cmd msg
jumpToTopRightWithConfig containerId msg config =
    ScrollTask.jumpToTopRightWithConfig containerId config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the bottom-left corner of a container.

    scrollToBottomLeft "container-id" NoOp

-}
scrollToBottomLeft : ContainerId -> msg -> Cmd msg
scrollToBottomLeft containerId msg =
    scrollToBottomLeftWithConfig containerId msg defaultConfig


{-| Smoothly scroll to the bottom-left corner with custom configuration.

    scrollToBottomLeftWithConfig "container-id" NoOp { defaultConfig | speed = 1000 }

-}
scrollToBottomLeftWithConfig : ContainerId -> msg -> Config -> Cmd msg
scrollToBottomLeftWithConfig containerId msg config =
    ScrollTask.scrollToBottomLeftWithConfig containerId config
        |> Task.attempt (always msg)


{-| Jump instantly to the bottom-left corner of a container.

    jumpToBottomLeft "container-id" NoOp

-}
jumpToBottomLeft : ContainerId -> msg -> Cmd msg
jumpToBottomLeft containerId msg =
    jumpToBottomLeftWithConfig containerId msg defaultConfig


{-| Jump instantly to the bottom-left corner with custom configuration.

    jumpToBottomLeftWithConfig "container-id" NoOp defaultConfig

-}
jumpToBottomLeftWithConfig : ContainerId -> msg -> Config -> Cmd msg
jumpToBottomLeftWithConfig containerId msg config =
    ScrollTask.jumpToBottomLeftWithConfig containerId config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the bottom-right corner of a container.

    scrollToBottomRight "container-id" NoOp

-}
scrollToBottomRight : ContainerId -> msg -> Cmd msg
scrollToBottomRight containerId msg =
    scrollToBottomRightWithConfig containerId msg defaultConfig


{-| Smoothly scroll to the bottom-right corner with custom configuration.

    scrollToBottomRightWithConfig "container-id" NoOp { defaultConfig | speed = 1000 }

-}
scrollToBottomRightWithConfig : ContainerId -> msg -> Config -> Cmd msg
scrollToBottomRightWithConfig containerId msg config =
    ScrollTask.scrollToBottomRightWithConfig containerId config
        |> Task.attempt (always msg)


{-| Jump instantly to the bottom-right corner of a container.

    jumpToBottomRight "container-id" NoOp

-}
jumpToBottomRight : ContainerId -> msg -> Cmd msg
jumpToBottomRight containerId msg =
    jumpToBottomRightWithConfig containerId msg defaultConfig


{-| Jump instantly to the bottom-right corner with custom configuration.

    jumpToBottomRightWithConfig "container-id" NoOp defaultConfig

-}
jumpToBottomRightWithConfig : ContainerId -> msg -> Config -> Cmd msg
jumpToBottomRightWithConfig containerId msg config =
    ScrollTask.jumpToBottomRightWithConfig containerId config
        |> Task.attempt (always msg)



-- CENTER POSITIONING FUNCTIONS


{-| Smoothly scroll to the center of a container (both X and Y axes).

    scrollToCenter "container-id" NoOp

-}
scrollToCenter : ContainerId -> msg -> Cmd msg
scrollToCenter containerId msg =
    scrollToCenterWithConfig containerId msg defaultConfig


{-| Smoothly scroll to the center with custom configuration.

    scrollToCenterWithConfig "container-id" NoOp { defaultConfig | speed = 1000 }

-}
scrollToCenterWithConfig : ContainerId -> msg -> Config -> Cmd msg
scrollToCenterWithConfig containerId msg config =
    ScrollTask.scrollToCenterWithConfig containerId config
        |> Task.attempt (always msg)


{-| Jump instantly to the center of a container (both X and Y axes).

    jumpToCenter "container-id" NoOp

-}
jumpToCenter : ContainerId -> msg -> Cmd msg
jumpToCenter containerId msg =
    jumpToCenterWithConfig containerId msg defaultConfig


{-| Jump instantly to the center with custom configuration.

    jumpToCenterWithConfig "container-id" NoOp defaultConfig

-}
jumpToCenterWithConfig : ContainerId -> msg -> Config -> Cmd msg
jumpToCenterWithConfig containerId msg config =
    ScrollTask.jumpToCenterWithConfig containerId config
        |> Task.attempt (always msg)


{-| Smoothly scroll to center horizontally (X axis only).

    scrollToCenterX "container-id" NoOp

-}
scrollToCenterX : ContainerId -> msg -> Cmd msg
scrollToCenterX containerId msg =
    scrollToCenterXWithConfig containerId msg defaultConfig


{-| Smoothly scroll to center horizontally with custom configuration.

    scrollToCenterXWithConfig "container-id" NoOp { defaultConfig | speed = 1000 }

-}
scrollToCenterXWithConfig : ContainerId -> msg -> Config -> Cmd msg
scrollToCenterXWithConfig containerId msg config =
    ScrollTask.scrollToCenterXWithConfig containerId config
        |> Task.attempt (always msg)


{-| Jump instantly to center horizontally (X axis only).

    jumpToCenterX "container-id" NoOp

-}
jumpToCenterX : ContainerId -> msg -> Cmd msg
jumpToCenterX containerId msg =
    jumpToCenterXWithConfig containerId msg defaultConfig


{-| Jump instantly to center horizontally with custom configuration.

    jumpToCenterXWithConfig "container-id" NoOp defaultConfig

-}
jumpToCenterXWithConfig : ContainerId -> msg -> Config -> Cmd msg
jumpToCenterXWithConfig containerId msg config =
    ScrollTask.jumpToCenterXWithConfig containerId config
        |> Task.attempt (always msg)


{-| Smoothly scroll to center vertically (Y axis only).

    scrollToCenterY "container-id" NoOp

-}
scrollToCenterY : ContainerId -> msg -> Cmd msg
scrollToCenterY containerId msg =
    scrollToCenterYWithConfig containerId msg defaultConfig


{-| Smoothly scroll to center vertically with custom configuration.

    scrollToCenterYWithConfig "container-id" NoOp { defaultConfig | speed = 1000 }

-}
scrollToCenterYWithConfig : ContainerId -> msg -> Config -> Cmd msg
scrollToCenterYWithConfig containerId msg config =
    ScrollTask.scrollToCenterYWithConfig containerId config
        |> Task.attempt (always msg)


{-| Jump instantly to center vertically (Y axis only).

    jumpToCenterY "container-id" NoOp

-}
jumpToCenterY : ContainerId -> msg -> Cmd msg
jumpToCenterY containerId msg =
    jumpToCenterYWithConfig containerId msg defaultConfig


{-| Jump instantly to center vertically with custom configuration.

    jumpToCenterYWithConfig "container-id" NoOp defaultConfig

-}
jumpToCenterYWithConfig : ContainerId -> msg -> Config -> Cmd msg
jumpToCenterYWithConfig containerId msg config =
    ScrollTask.jumpToCenterYWithConfig containerId config
        |> Task.attempt (always msg)



-- PERCENTAGE-BASED POSITIONING FUNCTIONS


{-| Smoothly scroll to a position defined by percentages (both X and Y).

    scrollToPercentage "container-id" 50.0 75.0 NoOp

-}
scrollToPercentage : ContainerId -> PercX -> PercY -> msg -> Cmd msg
scrollToPercentage containerId percentX percentY msg =
    scrollToPercentageWithConfig containerId percentX percentY msg defaultConfig


{-| Smoothly scroll to percentage position with custom configuration.

    scrollToPercentageWithConfig "container-id" 50.0 75.0 NoOp { defaultConfig | speed = 1000 }

-}
scrollToPercentageWithConfig : ContainerId -> PercX -> PercY -> msg -> Config -> Cmd msg
scrollToPercentageWithConfig containerId percentX percentY msg config =
    ScrollTask.scrollToPercentageWithConfig containerId percentX percentY config
        |> Task.attempt (always msg)


{-| Jump instantly to a position defined by percentages (both X and Y).

    jumpToPercentage "container-id" 50.0 75.0 NoOp

-}
jumpToPercentage : ContainerId -> PercX -> PercY -> msg -> Cmd msg
jumpToPercentage containerId percentX percentY msg =
    jumpToPercentageWithConfig containerId percentX percentY msg defaultConfig


{-| Jump instantly to percentage position with custom configuration.

    jumpToPercentageWithConfig "container-id" 50.0 75.0 NoOp defaultConfig

-}
jumpToPercentageWithConfig : ContainerId -> PercX -> PercY -> msg -> Config -> Cmd msg
jumpToPercentageWithConfig containerId percentX percentY msg config =
    ScrollTask.jumpToPercentageWithConfig containerId percentX percentY config
        |> Task.attempt (always msg)


{-| Smoothly scroll to a horizontal percentage position (X axis only).

    scrollToPercentageX "container-id" 25.0 NoOp

-}
scrollToPercentageX : ContainerId -> PercX -> msg -> Cmd msg
scrollToPercentageX containerId percentX msg =
    scrollToPercentageXWithConfig containerId percentX msg defaultConfig


{-| Smoothly scroll to horizontal percentage with custom configuration.

    scrollToPercentageXWithConfig "container-id" 25.0 NoOp { defaultConfig | speed = 1000 }

-}
scrollToPercentageXWithConfig : ContainerId -> PercX -> msg -> Config -> Cmd msg
scrollToPercentageXWithConfig containerId percentX msg config =
    ScrollTask.scrollToPercentageXWithConfig containerId percentX config
        |> Task.attempt (always msg)


{-| Jump instantly to a horizontal percentage position (X axis only).

    jumpToPercentageX "container-id" 25.0 NoOp

-}
jumpToPercentageX : ContainerId -> PercX -> msg -> Cmd msg
jumpToPercentageX containerId percentX msg =
    jumpToPercentageXWithConfig containerId percentX msg defaultConfig


{-| Jump instantly to horizontal percentage with custom configuration.

    jumpToPercentageXWithConfig "container-id" 25.0 NoOp defaultConfig

-}
jumpToPercentageXWithConfig : ContainerId -> PercX -> msg -> Config -> Cmd msg
jumpToPercentageXWithConfig containerId percentX msg config =
    ScrollTask.jumpToPercentageXWithConfig containerId percentX config
        |> Task.attempt (always msg)


{-| Smoothly scroll to a vertical percentage position (Y axis only).

    scrollToPercentageY "container-id" 80.0 NoOp

-}
scrollToPercentageY : ContainerId -> PercY -> msg -> Cmd msg
scrollToPercentageY containerId percentY msg =
    scrollToPercentageYWithConfig containerId percentY msg defaultConfig


{-| Smoothly scroll to vertical percentage with custom configuration.

    scrollToPercentageYWithConfig "container-id" 80.0 NoOp { defaultConfig | speed = 1000 }

-}
scrollToPercentageYWithConfig : ContainerId -> PercY -> msg -> Config -> Cmd msg
scrollToPercentageYWithConfig containerId percentY msg config =
    ScrollTask.scrollToPercentageYWithConfig containerId percentY config
        |> Task.attempt (always msg)


{-| Jump instantly to a vertical percentage position (Y axis only).

    jumpToPercentageY "container-id" 80.0 NoOp

-}
jumpToPercentageY : ContainerId -> PercY -> msg -> Cmd msg
jumpToPercentageY containerId percentY msg =
    jumpToPercentageYWithConfig containerId percentY msg defaultConfig


{-| Jump instantly to vertical percentage with custom configuration.

    jumpToPercentageYWithConfig "container-id" 80.0 NoOp defaultConfig

-}
jumpToPercentageYWithConfig : ContainerId -> PercY -> msg -> Config -> Cmd msg
jumpToPercentageYWithConfig containerId percentY msg config =
    ScrollTask.jumpToPercentageYWithConfig containerId percentY config
        |> Task.attempt (always msg)



-- RELATIVE MOVEMENT FUNCTIONS


{-| Smoothly scroll by specific pixel amounts from the current position.

    scrollBy "container-id" 100.0 -50.0 NoOp

-}
scrollBy : ContainerId -> ScrollDeltaX -> ScrollDeltaY -> msg -> Cmd msg
scrollBy containerId deltaX deltaY msg =
    scrollByWithConfig containerId deltaX deltaY msg defaultConfig


{-| Smoothly scroll by pixel amounts with custom configuration.

    scrollByWithConfig "container-id" 100.0 -50.0 NoOp { defaultConfig | speed = 1000 }

-}
scrollByWithConfig : ContainerId -> ScrollDeltaX -> ScrollDeltaY -> msg -> Config -> Cmd msg
scrollByWithConfig containerId deltaX deltaY msg config =
    ScrollTask.scrollByWithConfig containerId deltaX deltaY config
        |> Task.attempt (always msg)


{-| Jump instantly by specific pixel amounts from the current position.

    jumpBy "container-id" 100.0 -50.0 NoOp

-}
jumpBy : ContainerId -> ScrollDeltaX -> ScrollDeltaY -> msg -> Cmd msg
jumpBy containerId deltaX deltaY msg =
    jumpByWithConfig containerId deltaX deltaY msg defaultConfig


{-| Jump instantly by pixel amounts with custom configuration.

    jumpByWithConfig "container-id" 100.0 -50.0 NoOp defaultConfig

-}
jumpByWithConfig : ContainerId -> ScrollDeltaX -> ScrollDeltaY -> msg -> Config -> Cmd msg
jumpByWithConfig containerId deltaX deltaY msg config =
    ScrollTask.jumpByWithConfig containerId deltaX deltaY config
        |> Task.attempt (always msg)


{-| Smoothly scroll by viewport multiples from the current position.

    scrollByViewportSize "container-id" 1.0 0.5 NoOp

-}
scrollByViewportSize : ContainerId -> ViewportMultiplierX -> ViewportMultiplierY -> msg -> Cmd msg
scrollByViewportSize containerId multiplierX multiplierY msg =
    scrollByViewportSizeWithConfig containerId multiplierX multiplierY msg defaultConfig


{-| Smoothly scroll by viewport multiples with custom configuration.

    scrollByViewportSizeWithConfig "container-id" 1.0 0.5 NoOp { defaultConfig | speed = 1000 }

-}
scrollByViewportSizeWithConfig : ContainerId -> ViewportMultiplierX -> ViewportMultiplierY -> msg -> Config -> Cmd msg
scrollByViewportSizeWithConfig containerId multiplierX multiplierY msg config =
    ScrollTask.scrollByViewportSizeWithConfig containerId multiplierX multiplierY config
        |> Task.attempt (always msg)


{-| Jump instantly by viewport multiples from the current position.

    jumpByViewportSize "container-id" 1.0 0.5 NoOp

-}
jumpByViewportSize : ContainerId -> ViewportMultiplierX -> ViewportMultiplierY -> msg -> Cmd msg
jumpByViewportSize containerId multiplierX multiplierY msg =
    jumpByViewportSizeWithConfig containerId multiplierX multiplierY msg defaultConfig


{-| Jump instantly by viewport multiples with custom configuration.

    jumpByViewportSizeWithConfig "container-id" 1.0 0.5 NoOp defaultConfig

-}
jumpByViewportSizeWithConfig : ContainerId -> ViewportMultiplierX -> ViewportMultiplierY -> msg -> Config -> Cmd msg
jumpByViewportSizeWithConfig containerId multiplierX multiplierY msg config =
    ScrollTask.jumpByViewportSizeWithConfig containerId multiplierX multiplierY config
        |> Task.attempt (always msg)



-- COORDINATE TARGETING FUNCTIONS


{-| Smoothly scroll to specific pixel coordinates within a container.

    scrollToCoordinates "container-id" 500.0 300.0 NoOp

-}
scrollToCoordinates : ContainerId -> XCoordinate -> YCoordinate -> msg -> Cmd msg
scrollToCoordinates containerId x y msg =
    scrollToCoordinatesWithConfig containerId x y msg defaultConfig


{-| Smoothly scroll to coordinates with custom configuration.

    scrollToCoordinatesWithConfig "container-id" 500.0 300.0 NoOp { defaultConfig | speed = 1000 }

-}
scrollToCoordinatesWithConfig : ContainerId -> XCoordinate -> YCoordinate -> msg -> Config -> Cmd msg
scrollToCoordinatesWithConfig containerId x y msg config =
    ScrollTask.scrollToCoordinatesWithConfig containerId x y config
        |> Task.attempt (always msg)


{-| Jump instantly to specific pixel coordinates within a container.

    jumpToCoordinates "container-id" 500.0 300.0 NoOp

-}
jumpToCoordinates : ContainerId -> XCoordinate -> YCoordinate -> msg -> Cmd msg
jumpToCoordinates containerId x y msg =
    jumpToCoordinatesWithConfig containerId x y msg defaultConfig


{-| Jump instantly to coordinates with custom configuration.

    jumpToCoordinatesWithConfig "container-id" 500.0 300.0 NoOp defaultConfig

-}
jumpToCoordinatesWithConfig : ContainerId -> XCoordinate -> YCoordinate -> msg -> Config -> Cmd msg
jumpToCoordinatesWithConfig containerId x y msg config =
    ScrollTask.jumpToCoordinatesWithConfig containerId x y config
        |> Task.attempt (always msg)
