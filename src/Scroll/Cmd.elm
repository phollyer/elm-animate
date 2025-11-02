module Scroll.Cmd exposing
    ( scroll
    , scrollWithConfig
    , jump
    , jumpWithConfig
    , scrollToTop
    , scrollToTopWithConfig
    , scrollToBottom
    , scrollToBottomWithConfig
    , scrollToLeftEdge
    , scrollToLeftEdgeWithConfig
    , scrollToRightEdge
    , scrollToRightEdgeWithConfig
    , jumpToTop
    , jumpToTopWithConfig
    , jumpToBottom
    , jumpToBottomWithConfig
    , jumpToLeftEdge
    , jumpToLeftEdgeWithConfig
    , jumpToRightEdge
    , jumpToRightEdgeWithConfig
    )

{-| Command-based smooth scrolling animations.

This module provides a simple command-based API for smooth scrolling operations.
All functions return `Cmd msg` for easy integration into Elm applications.

This module is targeted at use-cases where you either know that the scroll
target exists, or don't need to handle errors if it doesn't. If error-handling is
important to your application, use the [Scroll.Task](Scroll.Task) module instead.


# Element-Targeting Functions

Functions that scroll to specific DOM elements.

@docs scroll
@docs scrollWithConfig
@docs jump
@docs jumpWithConfig


# Position-Targeting Functions

Functions that scroll to specific positions within containers.


## Scroll to Edges

@docs scrollToTop
@docs scrollToTopWithConfig
@docs scrollToBottom
@docs scrollToBottomWithConfig
@docs scrollToLeftEdge
@docs scrollToLeftEdgeWithConfig
@docs scrollToRightEdge
@docs scrollToRightEdgeWithConfig


## Jump to Edges (Instant)

@docs jumpToTop
@docs jumpToTopWithConfig
@docs jumpToBottom
@docs jumpToBottomWithConfig
@docs jumpToLeftEdge
@docs jumpToLeftEdgeWithConfig
@docs jumpToRightEdge
@docs jumpToRightEdgeWithConfig

-}

import Scroll exposing (..)
import Scroll.Internal exposing (..)
import Scroll.Task as Task
import Task


{-| Smooth scroll to a specific DOM element.

    ScrollTo elementId ->
        ( model
        , scroll elementId DocumentBody ScrollComplete
        )

-}
scroll : ElementId -> Container -> msg -> Cmd msg
scroll elementId container msg =
    scrollWithConfig elementId container msg defaultConfig


{-| Smooth scroll to an element with custom configuration.

    ScrollTo elementId ->
        ( model
        , scrollWithConfig elementId DocumentBody ScrollComplete <|
            { defaultConfig | offsetY = 100 }
        )

-}
scrollWithConfig : ElementId -> Container -> msg -> Config -> Cmd msg
scrollWithConfig elementId container msg config =
    Task.scrollWithConfig elementId container config
        |> Task.attempt (always msg)


{-| Instantly jump to an element without animation.

Perfect for immediate navigation where you don't want smooth scrolling.

    JumpToSection sectionId ->
        ( model
        , jump sectionId DocumentBody JumpComplete
        )

-}
jump : ElementId -> Container -> msg -> Cmd msg
jump elementId container msg =
    jumpWithConfig elementId container msg defaultConfig


{-| Jump to an element with configuration (respects offset and axis settings).

    JumpToSection sectionId ->
        ( model
        , jumpWithConfig sectionId DocumentBody JumpComplete <|
            { defaultConfig | offsetY = 50 }
        )

-}
jumpWithConfig : ElementId -> Container -> msg -> Config -> Cmd msg
jumpWithConfig elementId container msg config =
    Task.jumpWithConfig elementId container config
        |> Task.attempt (always msg)


{-| Smooth scroll to the top of the document body or a container element.

Perfect for "back to top" buttons or resetting scroll position.

    BackToTop ->
        ( model
        , scrollToTop (Container "main-content") ScrollComplete
        )

For document body scrolling:

    BackToTop ->
        ( model, scrollToTop DocumentBody ScrollComplete )

-}
scrollToTop : Container -> msg -> Cmd msg
scrollToTop container msg =
    scrollToTopWithConfig container msg defaultConfig


{-| Scroll to the top of a container with custom configuration.

    BackToTop ->
        ( model
        , scrollToTopWithConfig (Container "main-content") ScrollComplete <|
            { defaultConfig | timing = Duration 500 }
        )

-}
scrollToTopWithConfig : Container -> msg -> Config -> Cmd msg
scrollToTopWithConfig container msg config =
    Task.scrollToTopWithConfig container config
        |> Task.attempt (always msg)


{-| Smooth scroll to the bottom of the document body or a container element.

Perfect for "scroll to bottom" functionality in chat applications or content sections.

    ScrollToBottom ->
        ( model
        , scrollToBottom (Container "chat-window") ScrollComplete
        )

For document body scrolling:

    ScrollToBottom ->
        ( model, scrollToBottom DocumentBody ScrollComplete )

-}
scrollToBottom : Container -> msg -> Cmd msg
scrollToBottom container msg =
    scrollToBottomWithConfig container msg defaultConfig


{-| Scroll to the bottom of a container with custom configuration.

    ScrollToBottom ->
        ( model
        , scrollToBottomWithConfig (Container "main-content") ScrollComplete <|
            { defaultConfig | timing = Duration 500 }
        )

-}
scrollToBottomWithConfig : Container -> msg -> Config -> Cmd msg
scrollToBottomWithConfig container msg config =
    Task.scrollToBottomWithConfig container config
        |> Task.attempt (always msg)


{-| Smooth scroll to the left edge of the document body or a container element.

Perfect for resetting horizontal scroll position or navigation.

    ScrollToLeft ->
        ( model, scrollToLeftEdge (Container "horizontal-scroller") ScrollComplete )

For document body scrolling:

    ScrollToLeft ->
        ( model, scrollToLeftEdge DocumentBody ScrollComplete )

-}
scrollToLeftEdge : Container -> msg -> Cmd msg
scrollToLeftEdge container msg =
    scrollToLeftEdgeWithConfig container msg defaultConfig


{-| Scroll to the left edge of a container with custom configuration.

    ScrollToLeft ->
        ( model, scrollToLeftEdgeWithConfig (Container "carousel") ScrollComplete { defaultConfig | timing = Duration 300 } )

-}
scrollToLeftEdgeWithConfig : Container -> msg -> Config -> Cmd msg
scrollToLeftEdgeWithConfig container msg config =
    Task.scrollToLeftEdgeWithConfig container config
        |> Task.attempt (always msg)


{-| Smooth scroll to the right edge of the document body or a container element.

Perfect for horizontal navigation to the end of content.

    ScrollToRight ->
        ( model, scrollToRightEdge (Container "horizontal-scroller") ScrollComplete )

For document body scrolling:

    ScrollToRight ->
        ( model, scrollToRightEdge DocumentBody ScrollComplete )

-}
scrollToRightEdge : Container -> msg -> Cmd msg
scrollToRightEdge container msg =
    scrollToRightEdgeWithConfig container msg defaultConfig


{-| Scroll to the right edge of a container with custom configuration.

    ScrollToRight ->
        ( model, scrollToRightEdgeWithConfig (Container "carousel") ScrollComplete { defaultConfig | timing = Duration 300 } )

-}
scrollToRightEdgeWithConfig : Container -> msg -> Config -> Cmd msg
scrollToRightEdgeWithConfig container msg config =
    Task.scrollToRightEdgeWithConfig container config
        |> Task.attempt (always msg)


{-| Instantly jump to the top of the document body or a container element.

Perfect for instant "back to top" functionality without animation.

    JumpToTop ->
        ( model, jumpToTop (Container "main-content") JumpComplete )

For document body jumping:

    JumpToTop ->
        ( model, jumpToTop DocumentBody JumpComplete )

-}
jumpToTop : Container -> msg -> Cmd msg
jumpToTop container msg =
    jumpToTopWithConfig container msg defaultConfig


{-| Jump to the top of a container with configuration (respects offset settings).

    JumpToTop ->
        ( model, jumpToTopWithConfig (Container "main-content") JumpComplete { defaultConfig | offsetY = 10 } )

-}
jumpToTopWithConfig : Container -> msg -> Config -> Cmd msg
jumpToTopWithConfig container msg config =
    Task.jumpToTopWithConfig container config
        |> Task.attempt (always msg)


{-| Instantly jump to the bottom of the document body or a container element.

Perfect for instant "jump to bottom" functionality without animation.

    JumpToBottom ->
        ( model, jumpToBottom (Container "chat-window") JumpComplete )

For document body jumping:

    JumpToBottom ->
        ( model, jumpToBottom DocumentBody JumpComplete )

-}
jumpToBottom : Container -> msg -> Cmd msg
jumpToBottom container msg =
    jumpToBottomWithConfig container msg defaultConfig


{-| Jump to the bottom of a container with configuration (respects offset settings).

    JumpToBottom ->
        ( model, jumpToBottomWithConfig (Container "chat-window") JumpComplete { defaultConfig | offsetY = -10 } )

-}
jumpToBottomWithConfig : Container -> msg -> Config -> Cmd msg
jumpToBottomWithConfig container msg config =
    Task.jumpToBottomWithConfig container config
        |> Task.attempt (always msg)


{-| Instantly jump to the left edge of the document body or a container element.

Perfect for resetting horizontal position without animation.

    JumpToLeft ->
        ( model, jumpToLeftEdge (Container "horizontal-scroller") JumpComplete )

For document body jumping:

    JumpToLeft ->
        ( model, jumpToLeftEdge DocumentBody JumpComplete )

-}
jumpToLeftEdge : Container -> msg -> Cmd msg
jumpToLeftEdge container msg =
    jumpToLeftEdgeWithConfig container msg defaultConfig


{-| Jump to the left edge of a container with configuration (respects offset settings).

    JumpToLeft ->
        ( model, jumpToLeftEdgeWithConfig (Container "carousel") JumpComplete { defaultConfig | offsetX = 5 } )

-}
jumpToLeftEdgeWithConfig : Container -> msg -> Config -> Cmd msg
jumpToLeftEdgeWithConfig container msg config =
    Task.jumpToLeftEdgeWithConfig container config
        |> Task.attempt (always msg)


{-| Instantly jump to the right edge of the document body or a container element.

Perfect for jumping to end of horizontal content without animation.

    JumpToRight ->
        ( model, jumpToRightEdge (Container "horizontal-scroller") JumpComplete )

For document body jumping:

    JumpToRight ->
        ( model, jumpToRightEdge DocumentBody JumpComplete )

-}
jumpToRightEdge : Container -> msg -> Cmd msg
jumpToRightEdge container msg =
    jumpToRightEdgeWithConfig container msg defaultConfig


{-| Jump to the right edge of a container with configuration (respects offset settings).

    JumpToRight ->
        ( model, jumpToRightEdgeWithConfig (Container "carousel") JumpComplete { defaultConfig | offsetX = -5 } )

-}
jumpToRightEdgeWithConfig : Container -> msg -> Config -> Cmd msg
jumpToRightEdgeWithConfig container msg config =
    Task.jumpToRightEdgeWithConfig container config
        |> Task.attempt (always msg)
