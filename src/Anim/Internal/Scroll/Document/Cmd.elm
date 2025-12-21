module Anim.Internal.Scroll.Document.Cmd exposing
    ( TargetId
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

{-| This module provides smooth scrolling operations for the main document body using commands.

**Use this module when you want:**

  - Simple 'fire-and-forget' scroll commands
  - Easy integration with standard Elm architecture
  - No need for error handling (errors are silently ignored)

**Use [Scroll.Document.Task](Scroll.Document.Task) instead when you need:**

  - Error handling for scroll operations
  - Task composition and chaining

**For container-based scrolling, see:**

  - [Scroll.Container.Cmd](Scroll.Container.Cmd)


# Documentation Index

  - **[Element-Targeting Functions](#element-targeting-functions)** - Scroll to elements by ID
  - **[Bring Into View Functions](#bring-into-view-functions)** - Minimal movement to show elements
  - **[Position-Targeting Functions](#position-targeting-functions)** - Scroll to specific positions
      - [Edges](#edges) - Top, bottom, left, and right edges
      - [Corners](#corners) - All four corner positions
      - [Center Positioning](#center-positioning) - Center elements in viewport
  - **[Advanced Positioning Functions](#advanced-positioning-functions)** - Sophisticated positioning
      - [Coordinate Targeting](#coordinate-targeting) - Direct coordinate positioning
      - [Percentage-Based Positioning](#percentage-based-positioning) - Position by percentage
      - [Relative Movement](#relative-movement) - Move by pixel amounts or viewport sizes


# Element-Targeting Functions

Perfect for navigating to specific sections, anchors, or dynamic content anywhere on the page.

@docs TargetId
@docs scroll, scrollWithConfig, jump, jumpWithConfig

_[↑ Element-Targeting Functions](#element-targeting-functions) | [↑ Documentation Index](#documentation-index)_


# Bring Into View Functions

Bring an element into view using minimal movement.

If the bottom of the target element is below the viewport, it will scroll up enough to make it fully visible, so
it's bottom edge will line up with the bottom edge of the viewport.

If the element is taller than the viewport, it's top edge will align with the top of the viewport.
The same logic applies for horizontal scrolling, with the left edge equating to the top.

So if an element is taller and wider than the viewport, the top-left corner of the element will be aligned with
the top-left corner of the viewport.

Perfect for ensuring form fields, error messages, or search results stay visible without jarring movements.

@docs scrollIntoView, scrollIntoViewWithConfig, jumpIntoView, jumpIntoViewWithConfig

_[↑ Bring Into View Functions](#bring-into-view-functions) | [↑ Documentation Index](#documentation-index)_


# Position-Targeting Functions


## Edges

Use these functions to scroll or jump to specific edges of the document.

These functions ignore the `axis` field in the [Config](Scroll#Config) because they will always scroll on the required axis
to reach the target edge.

Perfect for "back to top" buttons, "skip to bottom" links, or page navigation shortcuts.


## Top

@docs scrollToTop, scrollToTopWithConfig, jumpToTop, jumpToTopWithConfig


## Bottom

@docs scrollToBottom, scrollToBottomWithConfig, jumpToBottom, jumpToBottomWithConfig


## Left

@docs scrollToLeftEdge, scrollToLeftEdgeWithConfig, jumpToLeftEdge, jumpToLeftEdgeWithConfig


## Right

@docs scrollToRightEdge, scrollToRightEdgeWithConfig, jumpToRightEdge, jumpToRightEdgeWithConfig

_[↑ Edges](#edges) | [↑ Position-Targeting Functions](#position-targeting-functions) | [↑ Documentation Index](#documentation-index)_


## Corners

Use these functions to scroll or jump to specific corners of the document.

These functions ignore the `axis` field in the [Config](Scroll#Config) because they will always scroll on both axes to reach the target corner.

Perfect for full-page image viewers, document readers, or when you need precise positioning at page boundaries.


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

Perfect for focusing attention, creating cinematic effects, or centering important content like modals or hero sections.


### Both Axes

@docs scrollToCenter, scrollToCenterWithConfig, jumpToCenter, jumpToCenterWithConfig


### X Axis Only

@docs scrollToCenterX, scrollToCenterXWithConfig, jumpToCenterX, jumpToCenterXWithConfig


### Y Axis Only

@docs scrollToCenterY, scrollToCenterYWithConfig, jumpToCenterY, jumpToCenterYWithConfig

_[↑ Center Positioning](#center-positioning) | [↑ Position-Targeting Functions](#position-targeting-functions) | [↑ Documentation Index](#documentation-index)_


# Advanced Positioning Functions


## Coordinate Targeting

Scroll to specific pixel coordinates within the document.

Perfect for programmatic positioning, restoring saved scroll states, or implementing custom navigation systems.

@docs XCoordinate, YCoordinate


### Both Axes

@docs scrollToCoordinates, scrollToCoordinatesWithConfig, jumpToCoordinates, jumpToCoordinatesWithConfig


### X Axis Only

@docs scrollToCoordinateX, scrollToCoordinateXWithConfig, jumpToCoordinateX, jumpToCoordinateXWithConfig


### Y Axis Only

@docs scrollToCoordinateY, scrollToCoordinateYWithConfig, jumpToCoordinateY, jumpToCoordinateYWithConfig

_[↑ Coordinate Targeting](#coordinate-targeting) | [↑ Advanced Positioning Functions](#advanced-positioning-functions) | [↑ Documentation Index](#documentation-index)_


## Percentage-Based Positioning

Scroll to positions defined as percentages of the total scrollable area.

Perfect for progress-based navigation, reading position indicators, or responsive layouts that adapt to content length.

@docs PercX, PercY


### Both Axes

@docs scrollToPercentage, scrollToPercentageWithConfig, jumpToPercentage, jumpToPercentageWithConfig


### X Axis Only

@docs scrollToPercentageX, scrollToPercentageXWithConfig, jumpToPercentageX, jumpToPercentageXWithConfig


### Y Axis Only

@docs scrollToPercentageY, scrollToPercentageYWithConfig, jumpToPercentageY, jumpToPercentageYWithConfig

_[↑ Percentage-Based Positioning](#percentage-based-positioning) | [↑ Advanced Positioning Functions](#advanced-positioning-functions) | [↑ Documentation Index](#documentation-index)_


## Relative Movement

Perfect for keyboard navigation, incremental scrolling, or step-by-step content browsing like pagination.


### Pixel Offsets

Move relative to the current scroll position by specific pixel amounts.

@docs ScrollDeltaX, ScrollDeltaY


#### Both Axes

@docs scrollBy, scrollByWithConfig, jumpBy, jumpByWithConfig


#### X Axis Only

@docs scrollByX, scrollByXWithConfig, jumpByX, jumpByXWithConfig


#### Y Axis Only

@docs scrollByY, scrollByYWithConfig, jumpByY, jumpByYWithConfig


### Viewport Multiples

Move relative to the current scroll position by multiples of the viewport size.

@docs ViewportMultiplierX, ViewportMultiplierY


#### Both Axes

@docs scrollByViewportSize, scrollByViewportSizeWithConfig, jumpByViewportSize, jumpByViewportSizeWithConfig


#### X Axis Only

@docs scrollByViewportSizeX, scrollByViewportSizeXWithConfig, jumpByViewportSizeX, jumpByViewportSizeXWithConfig


#### Y Axis Only

@docs scrollByViewportSizeY, scrollByViewportSizeYWithConfig, jumpByViewportSizeY, jumpByViewportSizeYWithConfig

_[↑ Relative Movement](#relative-movement) | [↑ Advanced Positioning Functions](#advanced-positioning-functions) | [↑ Documentation Index](#documentation-index)_

-}

import Anim.Internal.Scroll.Common exposing (Config, defaultConfig)
import Anim.Internal.Scroll.Document.Task as ScrollTask
import Task



-- TYPE ALIASES


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



-- ELEMENT-TARGETING FUNCTIONS


{-| Smoothly scroll to a DOM element using default configuration.

    scroll "my-element" NoOp

This scrolls to the element with ID "my-element" in the document body.

-}
scroll : TargetId -> msg -> Cmd msg
scroll elementId msg =
    scrollWithConfig elementId msg defaultConfig


{-| Smoothly scroll to a DOM element with custom configuration.

    scrollWithConfig "my-element"
        NoOp
        { defaultConfig
            | axis = XWithOffset 20
        }

-}
scrollWithConfig : TargetId -> msg -> Config -> Cmd msg
scrollWithConfig elementId msg config =
    ScrollTask.scrollWithConfig elementId config
        |> Task.attempt (always msg)


{-| Instantly jump to a DOM element using default configuration.

    jump "my-element" NoOp

-}
jump : TargetId -> msg -> Cmd msg
jump elementId msg =
    jumpWithConfig elementId msg defaultConfig


{-| Instantly jump to a DOM element with custom configuration.

    jumpWithConfig "my-element"
        NoOp
        { defaultConfig | offsetY = 50 }

-}
jumpWithConfig : TargetId -> msg -> Config -> Cmd msg
jumpWithConfig elementId msg config =
    ScrollTask.jumpWithConfig elementId config
        |> Task.attempt (always msg)



-- BRING INTO VIEW FUNCTIONS


{-| Scroll element into view using minimal movement.

    scrollIntoView "target-element" NoOp

-}
scrollIntoView : TargetId -> msg -> Cmd msg
scrollIntoView elementId msg =
    scrollIntoViewWithConfig elementId msg defaultConfig


{-| Scroll element into view using minimal movement with custom configuration.

    scrollIntoViewWithConfig "target-element"
        NoOp
        { defaultConfig | offsetY = 20 }

-}
scrollIntoViewWithConfig : TargetId -> msg -> Config -> Cmd msg
scrollIntoViewWithConfig elementId msg config =
    ScrollTask.scrollIntoViewWithConfig elementId config
        |> Task.attempt (always msg)


{-| Jump element into view using minimal movement.

    jumpIntoView "target-element" NoOp

-}
jumpIntoView : TargetId -> msg -> Cmd msg
jumpIntoView elementId msg =
    jumpIntoViewWithConfig elementId msg defaultConfig


{-| Jump element into view using minimal movement with custom configuration.

    jumpIntoViewWithConfig "target-element"
        NoOp
        { defaultConfig |

-}
jumpIntoViewWithConfig : TargetId -> msg -> Config -> Cmd msg
jumpIntoViewWithConfig elementId msg config =
    ScrollTask.jumpIntoViewWithConfig elementId config
        |> Task.attempt (always msg)



-- POSITION-TARGETING FUNCTIONS


{-| Smoothly scroll to the top of the document using default configuration.

    scrollToTop NoOp

-}
scrollToTop : msg -> Cmd msg
scrollToTop msg =
    scrollToTopWithConfig msg defaultConfig


{-| Smoothly scroll to the top of the document with custom configuration.

    scrollToTopWithConfig NoOp <|
        { defaultConfig | timing = Duration 600 }

-}
scrollToTopWithConfig : msg -> Config -> Cmd msg
scrollToTopWithConfig msg config =
    ScrollTask.scrollToTopWithConfig config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the bottom of the document using default configuration.

    scrollToBottom NoOp

-}
scrollToBottom : msg -> Cmd msg
scrollToBottom msg =
    scrollToBottomWithConfig msg defaultConfig


{-| Smoothly scroll to the bottom of the document with custom configuration.

    scrollToBottomWithConfig NoOp
        { defaultConfig | timing = Speed 800 }

-}
scrollToBottomWithConfig : msg -> Config -> Cmd msg
scrollToBottomWithConfig msg config =
    ScrollTask.scrollToBottomWithConfig config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the left edge of the document using default configuration.

    scrollToLeftEdge NoOp

-}
scrollToLeftEdge : msg -> Cmd msg
scrollToLeftEdge msg =
    scrollToLeftEdgeWithConfig msg defaultConfig


{-| Smoothly scroll to the left edge of the document with custom configuration.

    scrollToLeftEdgeWithConfig NoOp <|
        { defaultConfig | timing = Duration 400 }

-}
scrollToLeftEdgeWithConfig : msg -> Config -> Cmd msg
scrollToLeftEdgeWithConfig msg config =
    ScrollTask.scrollToLeftEdgeWithConfig config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the right edge of the document using default configuration.

    scrollToRightEdge NoOp

-}
scrollToRightEdge : msg -> Cmd msg
scrollToRightEdge msg =
    scrollToRightEdgeWithConfig msg defaultConfig


{-| Smoothly scroll to the right edge of the document with custom configuration.

    scrollToRightEdgeWithConfig NoOp <|
        { defaultConfig | timing = Duration 500 }

-}
scrollToRightEdgeWithConfig : msg -> Config -> Cmd msg
scrollToRightEdgeWithConfig msg config =
    ScrollTask.scrollToRightEdgeWithConfig config
        |> Task.attempt (always msg)


{-| Instantly jump to the top of the document using default configuration.

    jumpToTop NoOp

-}
jumpToTop : msg -> Cmd msg
jumpToTop msg =
    jumpToTopWithConfig msg defaultConfig


{-| Instantly jump to the top of the document with custom configuration.

    jumpToTopWithConfig NoOp
        { defaultConfig | offsetY = 10 }

-}
jumpToTopWithConfig : msg -> Config -> Cmd msg
jumpToTopWithConfig msg config =
    ScrollTask.jumpToTopWithConfig config
        |> Task.attempt (always msg)


{-| Instantly jump to the bottom of the document using default configuration.

    jumpToBottom NoOp

-}
jumpToBottom : msg -> Cmd msg
jumpToBottom msg =
    jumpToBottomWithConfig msg defaultConfig


{-| Instantly jump to the bottom of the document with custom configuration.

    jumpToBottomWithConfig NoOp
        { defaultConfig | offsetY = 20 }

-}
jumpToBottomWithConfig : msg -> Config -> Cmd msg
jumpToBottomWithConfig msg config =
    ScrollTask.jumpToBottomWithConfig config
        |> Task.attempt (always msg)


{-| Instantly jump to the left edge of the document using default configuration.

    jumpToLeftEdge NoOp

-}
jumpToLeftEdge : msg -> Cmd msg
jumpToLeftEdge msg =
    jumpToLeftEdgeWithConfig msg defaultConfig


{-| Instantly jump to the left edge of the document with custom configuration.

    jumpToLeftEdgeWithConfig NoOp
        { defaultConfig |

-}
jumpToLeftEdgeWithConfig : msg -> Config -> Cmd msg
jumpToLeftEdgeWithConfig msg config =
    ScrollTask.jumpToLeftEdgeWithConfig config
        |> Task.attempt (always msg)


{-| Instantly jump to the right edge of the document using default configuration.

    jumpToRightEdge NoOp

-}
jumpToRightEdge : msg -> Cmd msg
jumpToRightEdge msg =
    jumpToRightEdgeWithConfig msg defaultConfig


{-| Instantly jump to the right edge of the document with custom configuration.

    jumpToRightEdgeWithConfig NoOp
        { defaultConfig |

-}
jumpToRightEdgeWithConfig : msg -> Config -> Cmd msg
jumpToRightEdgeWithConfig msg config =
    ScrollTask.jumpToRightEdgeWithConfig config
        |> Task.attempt (always msg)



-- CORNER FUNCTIONS


{-| Smoothly scroll to the top-left corner of the document using default configuration.

    scrollToTopLeft NoOp

-}
scrollToTopLeft : msg -> Cmd msg
scrollToTopLeft msg =
    scrollToTopLeftWithConfig msg defaultConfig


{-| Smoothly scroll to the top-left corner of the document with custom configuration.

    scrollToTopLeftWithConfig NoOp
        { defaultConfig | axis = BothWithOffset 10 20 }

-}
scrollToTopLeftWithConfig : msg -> Config -> Cmd msg
scrollToTopLeftWithConfig msg config =
    ScrollTask.scrollToTopLeftWithConfig config
        |> Task.attempt (always msg)


{-| Jump instantly to the top-left corner of the document using default configuration.

    jumpToTopLeft NoOp

-}
jumpToTopLeft : msg -> Cmd msg
jumpToTopLeft msg =
    jumpToTopLeftWithConfig msg defaultConfig


{-| Jump instantly to the top-left corner of the document with custom configuration.

    jumpToTopLeftWithConfig NoOp
        { defaultConfig | axis = BothWithOffset 10 20 }

-}
jumpToTopLeftWithConfig : msg -> Config -> Cmd msg
jumpToTopLeftWithConfig msg config =
    ScrollTask.jumpToTopLeftWithConfig config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the top-right corner of the document using default configuration.

    scrollToTopRight NoOp

-}
scrollToTopRight : msg -> Cmd msg
scrollToTopRight msg =
    scrollToTopRightWithConfig msg defaultConfig


{-| Smoothly scroll to the top-right corner of the document with custom configuration.

    scrollToTopRightWithConfig NoOp
        { defaultConfig | axis = BothWithOffset 10 20 }

-}
scrollToTopRightWithConfig : msg -> Config -> Cmd msg
scrollToTopRightWithConfig msg config =
    ScrollTask.scrollToTopRightWithConfig config
        |> Task.attempt (always msg)


{-| Jump instantly to the top-right corner of the document using default configuration.

    jumpToTopRight NoOp

-}
jumpToTopRight : msg -> Cmd msg
jumpToTopRight msg =
    jumpToTopRightWithConfig msg defaultConfig


{-| Jump instantly to the top-right corner of the document with custom configuration.

    jumpToTopRightWithConfig NoOp
        { defaultConfig | axis = BothWithOffset 10 20 }

-}
jumpToTopRightWithConfig : msg -> Config -> Cmd msg
jumpToTopRightWithConfig msg config =
    ScrollTask.jumpToTopRightWithConfig config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the bottom-left corner of the document using default configuration.

    scrollToBottomLeft NoOp

-}
scrollToBottomLeft : msg -> Cmd msg
scrollToBottomLeft msg =
    scrollToBottomLeftWithConfig msg defaultConfig


{-| Smoothly scroll to the bottom-left corner of the document with custom configuration.

    scrollToBottomLeftWithConfig NoOp
        { defaultConfig | axis = BothWithOffset 10 20 }

-}
scrollToBottomLeftWithConfig : msg -> Config -> Cmd msg
scrollToBottomLeftWithConfig msg config =
    ScrollTask.scrollToBottomLeftWithConfig config
        |> Task.attempt (always msg)


{-| Jump instantly to the bottom-left corner of the document using default configuration.

    jumpToBottomLeft NoOp

-}
jumpToBottomLeft : msg -> Cmd msg
jumpToBottomLeft msg =
    jumpToBottomLeftWithConfig msg defaultConfig


{-| Jump instantly to the bottom-left corner of the document with custom configuration.

    jumpToBottomLeftWithConfig NoOp
        { defaultConfig | axis = BothWithOffset 10 20 }

-}
jumpToBottomLeftWithConfig : msg -> Config -> Cmd msg
jumpToBottomLeftWithConfig msg config =
    ScrollTask.jumpToBottomLeftWithConfig config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the bottom-right corner of the document using default configuration.

    scrollToBottomRight NoOp

-}
scrollToBottomRight : msg -> Cmd msg
scrollToBottomRight msg =
    scrollToBottomRightWithConfig msg defaultConfig


{-| Smoothly scroll to the bottom-right corner of the document with custom configuration.

    scrollToBottomRightWithConfig NoOp
        { defaultConfig | axis = BothWithOffset 10 20 }

-}
scrollToBottomRightWithConfig : msg -> Config -> Cmd msg
scrollToBottomRightWithConfig msg config =
    ScrollTask.scrollToBottomRightWithConfig config
        |> Task.attempt (always msg)


{-| Jump instantly to the bottom-right corner of the document using default configuration.

    jumpToBottomRight NoOp

-}
jumpToBottomRight : msg -> Cmd msg
jumpToBottomRight msg =
    jumpToBottomRightWithConfig msg defaultConfig


{-| Jump instantly to the bottom-right corner of the document with custom configuration.

    jumpToBottomRightWithConfig NoOp
        { defaultConfig | axis = BothWithOffset 10 20 }

-}
jumpToBottomRightWithConfig : msg -> Config -> Cmd msg
jumpToBottomRightWithConfig msg config =
    ScrollTask.jumpToBottomRightWithConfig config
        |> Task.attempt (always msg)



-- CENTER POSITIONING FUNCTIONS


{-| Smoothly scroll to the center of the document using default configuration.

    scrollToCenter NoOp

-}
scrollToCenter : msg -> Cmd msg
scrollToCenter msg =
    scrollToCenterWithConfig msg defaultConfig


{-| Smoothly scroll to the center of the document with custom configuration.

    scrollToCenterWithConfig NoOp
        { defaultConfig | axis = BothWithOffset 10 20 }

-}
scrollToCenterWithConfig : msg -> Config -> Cmd msg
scrollToCenterWithConfig msg config =
    ScrollTask.scrollToCenterWithConfig config
        |> Task.attempt (always msg)


{-| Jump instantly to the center of the document using default configuration.

    jumpToCenter NoOp

-}
jumpToCenter : msg -> Cmd msg
jumpToCenter msg =
    jumpToCenterWithConfig msg defaultConfig


{-| Jump instantly to the center of the document with custom configuration.

    jumpToCenterWithConfig NoOp
        { defaultConfig | axis = BothWithOffset 10 20 }

-}
jumpToCenterWithConfig : msg -> Config -> Cmd msg
jumpToCenterWithConfig msg config =
    ScrollTask.jumpToCenterWithConfig config
        |> Task.attempt (always msg)


{-| Smoothly scroll to center horizontally using default configuration.

    scrollToCenterX NoOp

-}
scrollToCenterX : msg -> Cmd msg
scrollToCenterX msg =
    scrollToCenterXWithConfig msg defaultConfig


{-| Smoothly scroll to center horizontally with custom configuration.

    scrollToCenterXWithConfig NoOp
        { defaultConfig |

-}
scrollToCenterXWithConfig : msg -> Config -> Cmd msg
scrollToCenterXWithConfig msg config =
    ScrollTask.scrollToCenterXWithConfig config
        |> Task.attempt (always msg)


{-| Jump instantly to center horizontally using default configuration.

    jumpToCenterX NoOp

-}
jumpToCenterX : msg -> Cmd msg
jumpToCenterX msg =
    jumpToCenterXWithConfig msg defaultConfig


{-| Jump instantly to center horizontally with custom configuration.

    jumpToCenterXWithConfig NoOp
        { defaultConfig |

-}
jumpToCenterXWithConfig : msg -> Config -> Cmd msg
jumpToCenterXWithConfig msg config =
    ScrollTask.jumpToCenterXWithConfig config
        |> Task.attempt (always msg)


{-| Smoothly scroll to center vertically using default configuration.

    scrollToCenterY NoOp

-}
scrollToCenterY : msg -> Cmd msg
scrollToCenterY msg =
    scrollToCenterYWithConfig msg defaultConfig


{-| Smoothly scroll to center vertically with custom configuration.

    scrollToCenterYWithConfig NoOp
        { defaultConfig | offsetY = 20 }

-}
scrollToCenterYWithConfig : msg -> Config -> Cmd msg
scrollToCenterYWithConfig msg config =
    ScrollTask.scrollToCenterYWithConfig config
        |> Task.attempt (always msg)


{-| Jump instantly to center vertically using default configuration.

    jumpToCenterY NoOp

-}
jumpToCenterY : msg -> Cmd msg
jumpToCenterY msg =
    jumpToCenterYWithConfig msg defaultConfig


{-| Jump instantly to center vertically with custom configuration.

    jumpToCenterYWithConfig NoOp
        { defaultConfig | offsetY = 20 }

-}
jumpToCenterYWithConfig : msg -> Config -> Cmd msg
jumpToCenterYWithConfig msg config =
    ScrollTask.jumpToCenterYWithConfig config
        |> Task.attempt (always msg)



-- PERCENTAGE-BASED POSITIONING FUNCTIONS


{-| Smoothly scroll to percentage positions using default configuration.

    scrollToPercentage 0.5 0.8 NoOp -- 50% horizontally, 80% vertically

-}
scrollToPercentage : PercX -> PercY -> msg -> Cmd msg
scrollToPercentage percentageX percentageY msg =
    scrollToPercentageWithConfig percentageX percentageY msg defaultConfig


{-| Smoothly scroll to percentage positions with custom configuration.

    scrollToPercentageWithConfig 0.5 0.8 NoOp <|
        { defaultConfig | timing = Duration 800 }

-}
scrollToPercentageWithConfig : PercX -> PercY -> msg -> Config -> Cmd msg
scrollToPercentageWithConfig percentageX percentageY msg config =
    ScrollTask.scrollToPercentageWithConfig percentageX percentageY config
        |> Task.attempt (always msg)


{-| Jump instantly to percentage positions using default configuration.

    jumpToPercentage 0.5 0.8 NoOp

-}
jumpToPercentage : PercX -> PercY -> msg -> Cmd msg
jumpToPercentage percentageX percentageY msg =
    jumpToPercentageWithConfig percentageX percentageY msg defaultConfig


{-| Jump instantly to percentage positions with custom configuration.

    jumpToPercentageWithConfig 0.5
        0.8
        NoOp
        { defaultConfig | axis = BothWithOffset 10 20 }

-}
jumpToPercentageWithConfig : PercX -> PercY -> msg -> Config -> Cmd msg
jumpToPercentageWithConfig percentageX percentageY msg config =
    ScrollTask.jumpToPercentageWithConfig percentageX percentageY config
        |> Task.attempt (always msg)


{-| Smoothly scroll to percentage position horizontally using default configuration.

    scrollToPercentageX 0.5 NoOp -- 50% horizontally

-}
scrollToPercentageX : PercX -> msg -> Cmd msg
scrollToPercentageX percentage msg =
    scrollToPercentageXWithConfig percentage msg defaultConfig


{-| Smoothly scroll to percentage position horizontally with custom configuration.

    scrollToPercentageXWithConfig 0.5 NoOp <|
        { defaultConfig | timing = Duration 800 }

-}
scrollToPercentageXWithConfig : PercX -> msg -> Config -> Cmd msg
scrollToPercentageXWithConfig percentage msg config =
    ScrollTask.scrollToPercentageXWithConfig percentage config
        |> Task.attempt (always msg)


{-| Jump instantly to percentage position horizontally using default configuration.

    jumpToPercentageX 0.5 NoOp

-}
jumpToPercentageX : PercX -> msg -> Cmd msg
jumpToPercentageX percentage msg =
    jumpToPercentageXWithConfig percentage msg defaultConfig


{-| Jump instantly to percentage position horizontally with custom configuration.

    jumpToPercentageXWithConfig 0.5
        NoOp
        { defaultConfig |

-}
jumpToPercentageXWithConfig : PercX -> msg -> Config -> Cmd msg
jumpToPercentageXWithConfig percentage msg config =
    ScrollTask.jumpToPercentageXWithConfig percentage config
        |> Task.attempt (always msg)


{-| Smoothly scroll to percentage position vertically using default configuration.

    scrollToPercentageY 0.8 NoOp -- 80% vertically

-}
scrollToPercentageY : PercY -> msg -> Cmd msg
scrollToPercentageY percentage msg =
    scrollToPercentageYWithConfig percentage msg defaultConfig


{-| Smoothly scroll to percentage position vertically with custom configuration.

    scrollToPercentageYWithConfig 0.8 NoOp <|
        { defaultConfig | timing = Duration 800 }

-}
scrollToPercentageYWithConfig : PercY -> msg -> Config -> Cmd msg
scrollToPercentageYWithConfig percentage msg config =
    ScrollTask.scrollToPercentageYWithConfig percentage config
        |> Task.attempt (always msg)


{-| Jump instantly to percentage position vertically using default configuration.

    jumpToPercentageY 0.8 NoOp

-}
jumpToPercentageY : PercY -> msg -> Cmd msg
jumpToPercentageY percentage msg =
    jumpToPercentageYWithConfig percentage msg defaultConfig


{-| Jump instantly to percentage position vertically with custom configuration.

    jumpToPercentageYWithConfig 0.8
        NoOp
        { defaultConfig | offsetY = 20 }

-}
jumpToPercentageYWithConfig : PercY -> msg -> Config -> Cmd msg
jumpToPercentageYWithConfig percentage msg config =
    ScrollTask.jumpToPercentageYWithConfig percentage config
        |> Task.attempt (always msg)



-- RELATIVE MOVEMENT FUNCTIONS


{-| Smoothly scroll by pixel offsets from current position using default configuration.

    scrollBy 100 -50 NoOp -- 100px right, 50px up

-}
scrollBy : ScrollDeltaX -> ScrollDeltaY -> msg -> Cmd msg
scrollBy offsetX offsetY msg =
    scrollByWithConfig offsetX offsetY msg defaultConfig


{-| Smoothly scroll by pixel offsets from current position with custom configuration.

    scrollByWithConfig 100.0 -50.0 NoOp <|
        { defaultConfig | timing = Duration 800 }

-}
scrollByWithConfig : ScrollDeltaX -> ScrollDeltaY -> msg -> Config -> Cmd msg
scrollByWithConfig offsetX offsetY msg config =
    ScrollTask.scrollByWithConfig offsetX offsetY config
        |> Task.attempt (always msg)


{-| Jump instantly by pixel offsets from current position using default configuration.

    jumpBy 100 -50 NoOp

-}
jumpBy : ScrollDeltaX -> ScrollDeltaY -> msg -> Cmd msg
jumpBy offsetX offsetY msg =
    jumpByWithConfig offsetX offsetY msg defaultConfig


{-| Jump instantly by pixel offsets from current position with custom configuration.

    jumpByWithConfig 100
        -50
        NoOp
        { defaultConfig | axis = BothWithOffset 10 20 }

-}
jumpByWithConfig : ScrollDeltaX -> ScrollDeltaY -> msg -> Config -> Cmd msg
jumpByWithConfig offsetX offsetY msg config =
    ScrollTask.jumpByWithConfig offsetX offsetY config
        |> Task.attempt (always msg)


{-| Smoothly scroll horizontally by a pixel offset from current position using default configuration.

    scrollByX 100 NoOp -- scroll 100px to the right

-}
scrollByX : ScrollDeltaX -> msg -> Cmd msg
scrollByX offsetX msg =
    scrollByXWithConfig offsetX msg defaultConfig


{-| Smoothly scroll horizontally by pixel offset with custom configuration.

    scrollByXWithConfig 100.0 NoOp <|
        { defaultConfig | speed = 1000 }

-}
scrollByXWithConfig : ScrollDeltaX -> msg -> Config -> Cmd msg
scrollByXWithConfig offsetX msg config =
    ScrollTask.scrollByWithConfig offsetX 0.0 config
        |> Task.attempt (always msg)


{-| Jump instantly horizontally by a pixel offset from current position using default configuration.

    jumpByX 100 NoOp

-}
jumpByX : ScrollDeltaX -> msg -> Cmd msg
jumpByX offsetX msg =
    jumpByXWithConfig offsetX msg defaultConfig


{-| Jump instantly horizontally by pixel offset with custom configuration.

    jumpByXWithConfig 100 NoOp defaultConfig

-}
jumpByXWithConfig : ScrollDeltaX -> msg -> Config -> Cmd msg
jumpByXWithConfig offsetX msg config =
    ScrollTask.jumpByWithConfig offsetX 0.0 config
        |> Task.attempt (always msg)


{-| Smoothly scroll vertically by a pixel offset from current position using default configuration.

    scrollByY -50 NoOp -- scroll 50px up

-}
scrollByY : ScrollDeltaY -> msg -> Cmd msg
scrollByY offsetY msg =
    scrollByYWithConfig offsetY msg defaultConfig


{-| Smoothly scroll vertically by pixel offset with custom configuration.

    scrollByYWithConfig -50.0 NoOp <|
        { defaultConfig | speed = 1000 }

-}
scrollByYWithConfig : ScrollDeltaY -> msg -> Config -> Cmd msg
scrollByYWithConfig offsetY msg config =
    ScrollTask.scrollByWithConfig 0.0 offsetY config
        |> Task.attempt (always msg)


{-| Jump instantly vertically by a pixel offset from current position using default configuration.

    jumpByY -50 NoOp

-}
jumpByY : ScrollDeltaY -> msg -> Cmd msg
jumpByY offsetY msg =
    jumpByYWithConfig offsetY msg defaultConfig


{-| Jump instantly vertically by pixel offset with custom configuration.

    jumpByYWithConfig -50 NoOp defaultConfig

-}
jumpByYWithConfig : ScrollDeltaY -> msg -> Config -> Cmd msg
jumpByYWithConfig offsetY msg config =
    ScrollTask.jumpByWithConfig 0.0 offsetY config
        |> Task.attempt (always msg)


{-| Smoothly scroll by viewport size multiples from current position using default configuration.

    scrollByViewportSize 1 -0.5 NoOp -- 1 viewport right, half viewport up

-}
scrollByViewportSize : ViewportMultiplierX -> ViewportMultiplierY -> msg -> Cmd msg
scrollByViewportSize multiplierX multiplierY msg =
    scrollByViewportSizeWithConfig multiplierX multiplierY msg defaultConfig


{-| Smoothly scroll by viewport size multiples from current position with custom configuration.

    scrollByViewportSizeWithConfig 1.0 0.5 NoOp <|
        { defaultConfig | speed = 1000 }

-}
scrollByViewportSizeWithConfig : ViewportMultiplierX -> ViewportMultiplierY -> msg -> Config -> Cmd msg
scrollByViewportSizeWithConfig multiplierX multiplierY msg config =
    ScrollTask.scrollByViewportSizeWithConfig multiplierX multiplierY config
        |> Task.attempt (always msg)


{-| Jump instantly by viewport size multiples from current position using default configuration.

    jumpByViewportSize 1 -0.5 NoOp

-}
jumpByViewportSize : ViewportMultiplierX -> ViewportMultiplierY -> msg -> Cmd msg
jumpByViewportSize multiplierX multiplierY msg =
    jumpByViewportSizeWithConfig multiplierX multiplierY msg defaultConfig


{-| Jump instantly by viewport size multiples from current position with custom configuration.

    jumpByViewportSizeWithConfig 1
        -0.5
        NoOp
        { defaultConfig | axis = BothWithOffset 10 20 }

-}
jumpByViewportSizeWithConfig : ViewportMultiplierX -> ViewportMultiplierY -> msg -> Config -> Cmd msg
jumpByViewportSizeWithConfig multiplierX multiplierY msg config =
    ScrollTask.jumpByViewportSizeWithConfig multiplierX multiplierY config
        |> Task.attempt (always msg)


{-| Smoothly scroll horizontally by viewport width multiples from current position using default configuration.

    scrollByViewportSizeX 1.0 NoOp -- scroll one viewport width to the right

-}
scrollByViewportSizeX : ViewportMultiplierX -> msg -> Cmd msg
scrollByViewportSizeX multiplierX msg =
    scrollByViewportSizeXWithConfig multiplierX msg defaultConfig


{-| Smoothly scroll horizontally by viewport width multiples with custom configuration.

    scrollByViewportSizeXWithConfig 1.0 NoOp <|
        { defaultConfig | speed = 1000 }

-}
scrollByViewportSizeXWithConfig : ViewportMultiplierX -> msg -> Config -> Cmd msg
scrollByViewportSizeXWithConfig multiplierX msg config =
    ScrollTask.scrollByViewportSizeWithConfig multiplierX 0.0 config
        |> Task.attempt (always msg)


{-| Jump instantly horizontally by viewport width multiples from current position using default configuration.

    jumpByViewportSizeX 1.0 NoOp

-}
jumpByViewportSizeX : ViewportMultiplierX -> msg -> Cmd msg
jumpByViewportSizeX multiplierX msg =
    jumpByViewportSizeXWithConfig multiplierX msg defaultConfig


{-| Jump instantly horizontally by viewport width multiples with custom configuration.

    jumpByViewportSizeXWithConfig 1.0 NoOp defaultConfig

-}
jumpByViewportSizeXWithConfig : ViewportMultiplierX -> msg -> Config -> Cmd msg
jumpByViewportSizeXWithConfig multiplierX msg config =
    ScrollTask.jumpByViewportSizeWithConfig multiplierX 0.0 config
        |> Task.attempt (always msg)


{-| Smoothly scroll vertically by viewport height multiples from current position using default configuration.

    scrollByViewportSizeY 1.0 NoOp -- scroll one viewport height down

-}
scrollByViewportSizeY : ViewportMultiplierY -> msg -> Cmd msg
scrollByViewportSizeY multiplierY msg =
    scrollByViewportSizeYWithConfig multiplierY msg defaultConfig


{-| Smoothly scroll vertically by viewport height multiples with custom configuration.

    scrollByViewportSizeYWithConfig 1.0 NoOp <|
        { defaultConfig | speed = 1000 }

-}
scrollByViewportSizeYWithConfig : ViewportMultiplierY -> msg -> Config -> Cmd msg
scrollByViewportSizeYWithConfig multiplierY msg config =
    ScrollTask.scrollByViewportSizeWithConfig 0.0 multiplierY config
        |> Task.attempt (always msg)


{-| Jump instantly vertically by viewport height multiples from current position using default configuration.

    jumpByViewportSizeY 1.0 NoOp

-}
jumpByViewportSizeY : ViewportMultiplierY -> msg -> Cmd msg
jumpByViewportSizeY multiplierY msg =
    jumpByViewportSizeYWithConfig multiplierY msg defaultConfig


{-| Jump instantly vertically by viewport height multiples with custom configuration.

    jumpByViewportSizeYWithConfig 1.0 NoOp <|
        { defaultConfig | speed = 1000 }

-}
jumpByViewportSizeYWithConfig : ViewportMultiplierY -> msg -> Config -> Cmd msg
jumpByViewportSizeYWithConfig multiplierY msg config =
    ScrollTask.jumpByViewportSizeWithConfig 0.0 multiplierY config
        |> Task.attempt (always msg)



-- COORDINATE TARGETING FUNCTIONS


{-| Smoothly scroll to specific pixel coordinates using default configuration.

    scrollToCoordinates 100 200 NoOp -- scroll to (100, 200)

-}
scrollToCoordinates : XCoordinate -> YCoordinate -> msg -> Cmd msg
scrollToCoordinates x y msg =
    scrollToCoordinatesWithConfig x y msg defaultConfig


{-| Smoothly scroll to specific pixel coordinates with custom configuration.

    scrollToCoordinatesWithConfig 100.0 200.0 NoOp <|
        { defaultConfig | timing = Duration 800 }

-}
scrollToCoordinatesWithConfig : XCoordinate -> YCoordinate -> msg -> Config -> Cmd msg
scrollToCoordinatesWithConfig x y msg config =
    ScrollTask.scrollToCoordinatesWithConfig x y config
        |> Task.attempt (always msg)


{-| Jump instantly to specific pixel coordinates using default configuration.

    jumpToCoordinates 100 200 NoOp

-}
jumpToCoordinates : XCoordinate -> YCoordinate -> msg -> Cmd msg
jumpToCoordinates x y msg =
    jumpToCoordinatesWithConfig x y msg defaultConfig


{-| Jump instantly to specific pixel coordinates with custom configuration.

    jumpToCoordinatesWithConfig 100
        200
        NoOp
        { defaultConfig | axis = BothWithOffset 10 20 }

-}
jumpToCoordinatesWithConfig : XCoordinate -> YCoordinate -> msg -> Config -> Cmd msg
jumpToCoordinatesWithConfig x y msg config =
    ScrollTask.jumpToCoordinatesWithConfig x y config
        |> Task.attempt (always msg)



-- X AXIS COORDINATE FUNCTIONS


{-| Smoothly scroll to specific X coordinate, keeping current Y position.

    scrollToCoordinateX 500.0 NoOp

-}
scrollToCoordinateX : XCoordinate -> msg -> Cmd msg
scrollToCoordinateX x msg =
    scrollToCoordinateXWithConfig x msg defaultConfig


{-| Smoothly scroll to specific X coordinate with custom configuration.

    scrollToCoordinateXWithConfig 500.0 NoOp <|
        { defaultConfig | speed = 1000 }

-}
scrollToCoordinateXWithConfig : XCoordinate -> msg -> Config -> Cmd msg
scrollToCoordinateXWithConfig x msg config =
    ScrollTask.scrollToCoordinateXWithConfig x config
        |> Task.attempt (always msg)


{-| Jump instantly to specific X coordinate, keeping current Y position.

    jumpToCoordinateX 500.0 NoOp

-}
jumpToCoordinateX : XCoordinate -> msg -> Cmd msg
jumpToCoordinateX x msg =
    jumpToCoordinateXWithConfig x msg defaultConfig


{-| Jump instantly to specific X coordinate with custom configuration.

    jumpToCoordinateXWithConfig 500.0 NoOp <|
        { defaultConfig | speed = 1000 }

-}
jumpToCoordinateXWithConfig : XCoordinate -> msg -> Config -> Cmd msg
jumpToCoordinateXWithConfig x msg config =
    ScrollTask.jumpToCoordinateXWithConfig x config
        |> Task.attempt (always msg)



-- Y AXIS COORDINATE FUNCTIONS


{-| Smoothly scroll to specific Y coordinate, keeping current X position.

    scrollToCoordinateY 1000.0 NoOp

-}
scrollToCoordinateY : YCoordinate -> msg -> Cmd msg
scrollToCoordinateY y msg =
    scrollToCoordinateYWithConfig y msg defaultConfig


{-| Smoothly scroll to specific Y coordinate with custom configuration.

    scrollToCoordinateYWithConfig 1000.0 NoOp <|
        { defaultConfig | speed = 1000 }

-}
scrollToCoordinateYWithConfig : YCoordinate -> msg -> Config -> Cmd msg
scrollToCoordinateYWithConfig y msg config =
    ScrollTask.scrollToCoordinateYWithConfig y config
        |> Task.attempt (always msg)


{-| Jump instantly to specific Y coordinate, keeping current X position.

    jumpToCoordinateY 1000.0 NoOp

-}
jumpToCoordinateY : YCoordinate -> msg -> Cmd msg
jumpToCoordinateY y msg =
    jumpToCoordinateYWithConfig y msg defaultConfig


{-| Jump instantly to specific Y coordinate with custom configuration.

    jumpToCoordinateYWithConfig 1000.0 NoOp <|
        { defaultConfig | speed = 1000 }

-}
jumpToCoordinateYWithConfig : YCoordinate -> msg -> Config -> Cmd msg
jumpToCoordinateYWithConfig y msg config =
    ScrollTask.jumpToCoordinateYWithConfig y config
        |> Task.attempt (always msg)
