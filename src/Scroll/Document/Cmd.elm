module Scroll.Document.Cmd exposing
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

{-| Document-based smooth scrolling animations using commands.

This module provides smooth scrolling operations for the main document body.
All functions return `Cmd msg` for easy integration into Elm applications.

For container-based scrolling, use the [Scroll.Container.Cmd](Scroll.Container.Cmd) module instead.


# Element-Targeting Functions

Functions that scroll to specific DOM elements within the document.

@docs scroll
@docs scrollWithConfig
@docs jump
@docs jumpWithConfig


# Position-Targeting Functions

Functions that scroll to specific positions within the document.


## Scroll to Edges

@docs scrollToTop
@docs scrollToTopWithConfig
@docs scrollToBottom
@docs scrollToBottomWithConfig
@docs scrollToLeftEdge
@docs scrollToLeftEdgeWithConfig
@docs scrollToRightEdge
@docs scrollToRightEdgeWithConfig


## Jump to Edges

@docs jumpToTop
@docs jumpToTopWithConfig
@docs jumpToBottom
@docs jumpToBottomWithConfig
@docs jumpToLeftEdge
@docs jumpToLeftEdgeWithConfig
@docs jumpToRightEdge
@docs jumpToRightEdgeWithConfig

-}

import Scroll exposing (Config, Container(..), ElementId, defaultConfig)
import Scroll.Document.Task as ScrollTask
import Task



-- ELEMENT-TARGETING FUNCTIONS


{-| Smoothly scroll to a DOM element using default configuration.

    scroll "my-element" NoOp

This scrolls to the element with ID "my-element" in the document body.

-}
scroll : ElementId -> msg -> Cmd msg
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
scrollWithConfig : ElementId -> msg -> Config -> Cmd msg
scrollWithConfig elementId msg config =
    ScrollTask.scrollWithConfig elementId config
        |> Task.attempt (always msg)


{-| Instantly jump to a DOM element using default configuration.

    jump "my-element" NoOp

-}
jump : ElementId -> msg -> Cmd msg
jump elementId msg =
    jumpWithConfig elementId msg defaultConfig


{-| Instantly jump to a DOM element with custom configuration.

    jumpWithConfig "my-element"
        NoOp
        { defaultConfig | offsetY = 50 }

-}
jumpWithConfig : ElementId -> msg -> Config -> Cmd msg
jumpWithConfig elementId msg config =
    ScrollTask.jumpWithConfig elementId config
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
