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
