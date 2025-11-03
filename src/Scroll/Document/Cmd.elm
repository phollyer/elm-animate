module Scroll.Document.Cmd exposing
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
    , scrollToPercentage, scrollToPercentageWithConfig, jumpToPercentage, jumpToPercentageWithConfig
    , scrollToPercentageX, scrollToPercentageXWithConfig, jumpToPercentageX, jumpToPercentageXWithConfig
    , scrollToPercentageY, scrollToPercentageYWithConfig, jumpToPercentageY, jumpToPercentageYWithConfig
    , scrollBy, scrollByWithConfig, jumpBy, jumpByWithConfig
    , scrollByViewportSize, scrollByViewportSizeWithConfig, jumpByViewportSize, jumpByViewportSizeWithConfig
    , scrollToCoordinates, scrollToCoordinatesWithConfig, jumpToCoordinates, jumpToCoordinatesWithConfig
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


## Center Positioning

Use these functions to scroll or jump to the center of the document or center on a specific axis.

These functions ignore the `axis` field in the [Config](Scroll#Config) and scroll on the required axes.

@docs scrollToCenter, scrollToCenterWithConfig, jumpToCenter, jumpToCenterWithConfig
@docs scrollToCenterX, scrollToCenterXWithConfig, jumpToCenterX, jumpToCenterXWithConfig
@docs scrollToCenterY, scrollToCenterYWithConfig, jumpToCenterY, jumpToCenterYWithConfig


# Advanced Positioning Functions


## Percentage-Based Positioning

Scroll to positions defined as percentages of the total scrollable area.

@docs scrollToPercentage, scrollToPercentageWithConfig, jumpToPercentage, jumpToPercentageWithConfig
@docs scrollToPercentageX, scrollToPercentageXWithConfig, jumpToPercentageX, jumpToPercentageXWithConfig
@docs scrollToPercentageY, scrollToPercentageYWithConfig, jumpToPercentageY, jumpToPercentageYWithConfig


## Relative Movement

Scroll relative to the current position by pixel offsets or viewport multiples.

@docs scrollBy, scrollByWithConfig, jumpBy, jumpByWithConfig
@docs scrollByViewportSize, scrollByViewportSizeWithConfig, jumpByViewportSize, jumpByViewportSizeWithConfig


## Coordinate Targeting

Scroll to specific pixel coordinates within the document.

@docs scrollToCoordinates, scrollToCoordinatesWithConfig, jumpToCoordinates, jumpToCoordinatesWithConfig

-}

import Scroll exposing (Config, Container(..), TargetId, defaultConfig)
import Scroll.Document.Task as ScrollTask
import Task



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
            | axis = X
            , offsetX = 20
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
        { defaultConfig | offsetX = 15 }

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

    scrollToTopWithConfig NoOp
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

    scrollToLeftEdgeWithConfig NoOp
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

    scrollToRightEdgeWithConfig NoOp
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
        { defaultConfig | offsetX = 5 }

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
        { defaultConfig | offsetX = 15 }

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
        { defaultConfig | offsetX = 10, offsetY = 20 }

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
        { defaultConfig | offsetX = 10, offsetY = 20 }

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
        { defaultConfig | offsetX = 10, offsetY = 20 }

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
        { defaultConfig | offsetX = 10, offsetY = 20 }

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
        { defaultConfig | offsetX = 10, offsetY = 20 }

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
        { defaultConfig | offsetX = 10, offsetY = 20 }

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
        { defaultConfig | offsetX = 10, offsetY = 20 }

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
        { defaultConfig | offsetX = 10, offsetY = 20 }

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
        { defaultConfig | offsetX = 10, offsetY = 20 }

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
        { defaultConfig | offsetX = 10, offsetY = 20 }

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
        { defaultConfig | offsetX = 10 }

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
        { defaultConfig | offsetX = 10 }

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
scrollToPercentage : Float -> Float -> msg -> Cmd msg
scrollToPercentage percentageX percentageY msg =
    scrollToPercentageWithConfig percentageX percentageY msg defaultConfig


{-| Smoothly scroll to percentage positions with custom configuration.

    scrollToPercentageWithConfig 0.5
        0.8
        NoOp
        { defaultConfig | timing = Duration 800 }

-}
scrollToPercentageWithConfig : Float -> Float -> msg -> Config -> Cmd msg
scrollToPercentageWithConfig percentageX percentageY msg config =
    ScrollTask.scrollToPercentageWithConfig percentageX percentageY config
        |> Task.attempt (always msg)


{-| Jump instantly to percentage positions using default configuration.

    jumpToPercentage 0.5 0.8 NoOp

-}
jumpToPercentage : Float -> Float -> msg -> Cmd msg
jumpToPercentage percentageX percentageY msg =
    jumpToPercentageWithConfig percentageX percentageY msg defaultConfig


{-| Jump instantly to percentage positions with custom configuration.

    jumpToPercentageWithConfig 0.5
        0.8
        NoOp
        { defaultConfig | offsetX = 10, offsetY = 20 }

-}
jumpToPercentageWithConfig : Float -> Float -> msg -> Config -> Cmd msg
jumpToPercentageWithConfig percentageX percentageY msg config =
    ScrollTask.jumpToPercentageWithConfig percentageX percentageY config
        |> Task.attempt (always msg)


{-| Smoothly scroll to percentage position horizontally using default configuration.

    scrollToPercentageX 0.5 NoOp -- 50% horizontally

-}
scrollToPercentageX : Float -> msg -> Cmd msg
scrollToPercentageX percentage msg =
    scrollToPercentageXWithConfig percentage msg defaultConfig


{-| Smoothly scroll to percentage position horizontally with custom configuration.

    scrollToPercentageXWithConfig 0.5
        NoOp
        { defaultConfig | timing = Duration 800 }

-}
scrollToPercentageXWithConfig : Float -> msg -> Config -> Cmd msg
scrollToPercentageXWithConfig percentage msg config =
    ScrollTask.scrollToPercentageXWithConfig percentage config
        |> Task.attempt (always msg)


{-| Jump instantly to percentage position horizontally using default configuration.

    jumpToPercentageX 0.5 NoOp

-}
jumpToPercentageX : Float -> msg -> Cmd msg
jumpToPercentageX percentage msg =
    jumpToPercentageXWithConfig percentage msg defaultConfig


{-| Jump instantly to percentage position horizontally with custom configuration.

    jumpToPercentageXWithConfig 0.5
        NoOp
        { defaultConfig | offsetX = 10 }

-}
jumpToPercentageXWithConfig : Float -> msg -> Config -> Cmd msg
jumpToPercentageXWithConfig percentage msg config =
    ScrollTask.jumpToPercentageXWithConfig percentage config
        |> Task.attempt (always msg)


{-| Smoothly scroll to percentage position vertically using default configuration.

    scrollToPercentageY 0.8 NoOp -- 80% vertically

-}
scrollToPercentageY : Float -> msg -> Cmd msg
scrollToPercentageY percentage msg =
    scrollToPercentageYWithConfig percentage msg defaultConfig


{-| Smoothly scroll to percentage position vertically with custom configuration.

    scrollToPercentageYWithConfig 0.8
        NoOp
        { defaultConfig | timing = Duration 800 }

-}
scrollToPercentageYWithConfig : Float -> msg -> Config -> Cmd msg
scrollToPercentageYWithConfig percentage msg config =
    ScrollTask.scrollToPercentageYWithConfig percentage config
        |> Task.attempt (always msg)


{-| Jump instantly to percentage position vertically using default configuration.

    jumpToPercentageY 0.8 NoOp

-}
jumpToPercentageY : Float -> msg -> Cmd msg
jumpToPercentageY percentage msg =
    jumpToPercentageYWithConfig percentage msg defaultConfig


{-| Jump instantly to percentage position vertically with custom configuration.

    jumpToPercentageYWithConfig 0.8
        NoOp
        { defaultConfig | offsetY = 20 }

-}
jumpToPercentageYWithConfig : Float -> msg -> Config -> Cmd msg
jumpToPercentageYWithConfig percentage msg config =
    ScrollTask.jumpToPercentageYWithConfig percentage config
        |> Task.attempt (always msg)



-- RELATIVE MOVEMENT FUNCTIONS


{-| Smoothly scroll by pixel offsets from current position using default configuration.

    scrollBy 100 -50 NoOp -- 100px right, 50px up

-}
scrollBy : Float -> Float -> msg -> Cmd msg
scrollBy offsetX offsetY msg =
    scrollByWithConfig offsetX offsetY msg defaultConfig


{-| Smoothly scroll by pixel offsets from current position with custom configuration.

    scrollByWithConfig 100
        -50
        NoOp
        { defaultConfig | timing = Duration 800 }

-}
scrollByWithConfig : Float -> Float -> msg -> Config -> Cmd msg
scrollByWithConfig offsetX offsetY msg config =
    ScrollTask.scrollByWithConfig offsetX offsetY config
        |> Task.attempt (always msg)


{-| Jump instantly by pixel offsets from current position using default configuration.

    jumpBy 100 -50 NoOp

-}
jumpBy : Float -> Float -> msg -> Cmd msg
jumpBy offsetX offsetY msg =
    jumpByWithConfig offsetX offsetY msg defaultConfig


{-| Jump instantly by pixel offsets from current position with custom configuration.

    jumpByWithConfig 100
        -50
        NoOp
        { defaultConfig | offsetX = 10, offsetY = 20 }

-}
jumpByWithConfig : Float -> Float -> msg -> Config -> Cmd msg
jumpByWithConfig offsetX offsetY msg config =
    ScrollTask.jumpByWithConfig offsetX offsetY config
        |> Task.attempt (always msg)


{-| Smoothly scroll by viewport size multiples from current position using default configuration.

    scrollByViewportSize 1 -0.5 NoOp -- 1 viewport right, half viewport up

-}
scrollByViewportSize : Float -> Float -> msg -> Cmd msg
scrollByViewportSize multiplierX multiplierY msg =
    scrollByViewportSizeWithConfig multiplierX multiplierY msg defaultConfig


{-| Smoothly scroll by viewport size multiples from current position with custom configuration.

    scrollByViewportSizeWithConfig 1
        -0.5
        NoOp
        { defaultConfig | timing = Duration 800 }

-}
scrollByViewportSizeWithConfig : Float -> Float -> msg -> Config -> Cmd msg
scrollByViewportSizeWithConfig multiplierX multiplierY msg config =
    ScrollTask.scrollByViewportSizeWithConfig multiplierX multiplierY config
        |> Task.attempt (always msg)


{-| Jump instantly by viewport size multiples from current position using default configuration.

    jumpByViewportSize 1 -0.5 NoOp

-}
jumpByViewportSize : Float -> Float -> msg -> Cmd msg
jumpByViewportSize multiplierX multiplierY msg =
    jumpByViewportSizeWithConfig multiplierX multiplierY msg defaultConfig


{-| Jump instantly by viewport size multiples from current position with custom configuration.

    jumpByViewportSizeWithConfig 1
        -0.5
        NoOp
        { defaultConfig | offsetX = 10, offsetY = 20 }

-}
jumpByViewportSizeWithConfig : Float -> Float -> msg -> Config -> Cmd msg
jumpByViewportSizeWithConfig multiplierX multiplierY msg config =
    ScrollTask.jumpByViewportSizeWithConfig multiplierX multiplierY config
        |> Task.attempt (always msg)



-- COORDINATE TARGETING FUNCTIONS


{-| Smoothly scroll to specific pixel coordinates using default configuration.

    scrollToCoordinates 100 200 NoOp -- scroll to (100, 200)

-}
scrollToCoordinates : Float -> Float -> msg -> Cmd msg
scrollToCoordinates x y msg =
    scrollToCoordinatesWithConfig x y msg defaultConfig


{-| Smoothly scroll to specific pixel coordinates with custom configuration.

    scrollToCoordinatesWithConfig 100
        200
        NoOp
        { defaultConfig | timing = Duration 800 }

-}
scrollToCoordinatesWithConfig : Float -> Float -> msg -> Config -> Cmd msg
scrollToCoordinatesWithConfig x y msg config =
    ScrollTask.scrollToCoordinatesWithConfig x y config
        |> Task.attempt (always msg)


{-| Jump instantly to specific pixel coordinates using default configuration.

    jumpToCoordinates 100 200 NoOp

-}
jumpToCoordinates : Float -> Float -> msg -> Cmd msg
jumpToCoordinates x y msg =
    jumpToCoordinatesWithConfig x y msg defaultConfig


{-| Jump instantly to specific pixel coordinates with custom configuration.

    jumpToCoordinatesWithConfig 100
        200
        NoOp
        { defaultConfig | offsetX = 10, offsetY = 20 }

-}
jumpToCoordinatesWithConfig : Float -> Float -> msg -> Config -> Cmd msg
jumpToCoordinatesWithConfig x y msg config =
    ScrollTask.jumpToCoordinatesWithConfig x y config
        |> Task.attempt (always msg)
