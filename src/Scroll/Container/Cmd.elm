module Scroll.Container.Cmd exposing
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

{-| Container-based smooth scrolling animations using commands.

This module provides smooth scrolling operations within specific container elements.
All functions return `Cmd msg` for easy integration into Elm applications.

For document-based scrolling, use the [Scroll.Document.Cmd](Scroll.Document.Cmd) module instead.


# Element-Targeting Functions

Functions that scroll to specific DOM elements within a container.

@docs scroll
@docs scrollWithConfig
@docs jump
@docs jumpWithConfig


# Position-Targeting Functions

Functions that scroll to specific positions within a container.


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
import Scroll.Container.Task as ScrollTask
import Task



-- ELEMENT-TARGETING FUNCTIONS


{-| Smoothly scroll to a DOM element within a specific container using default configuration.

    scroll "container-id" "my-element" NoOp

This scrolls to the element with ID "my-element" within the container with ID "container-id".

-}
scroll : ElementId -> ElementId -> msg -> Cmd msg
scroll containerId elementId msg =
    scrollWithConfig containerId elementId msg defaultConfig


{-| Smoothly scroll to a DOM element within a container with custom configuration.

    scrollWithConfig "container-id"
        "my-element"
        NoOp
        { defaultConfig
            | axis = X
            , offsetX = 20
        }

-}
scrollWithConfig : ElementId -> ElementId -> msg -> Config -> Cmd msg
scrollWithConfig containerId elementId msg config =
    ScrollTask.scrollWithConfig containerId elementId config
        |> Task.attempt (always msg)


{-| Instantly jump to a DOM element within a container using default configuration.

    jump "container-id" "my-element" NoOp

-}
jump : ElementId -> ElementId -> msg -> Cmd msg
jump containerId elementId msg =
    jumpWithConfig containerId elementId msg defaultConfig


{-| Instantly jump to a DOM element within a container with custom configuration.

    jumpWithConfig "container-id"
        "my-element"
        NoOp
        { defaultConfig | offsetY = 50 }

-}
jumpWithConfig : ElementId -> ElementId -> msg -> Config -> Cmd msg
jumpWithConfig containerId elementId msg config =
    ScrollTask.jumpWithConfig containerId elementId config
        |> Task.attempt (always msg)



-- POSITION-TARGETING FUNCTIONS


{-| Smoothly scroll to the top of a container using default configuration.

    scrollToTop "container-id" NoOp

-}
scrollToTop : ElementId -> msg -> Cmd msg
scrollToTop containerId msg =
    scrollToTopWithConfig containerId msg defaultConfig


{-| Smoothly scroll to the top of a container with custom configuration.

    scrollToTopWithConfig "container-id"
        NoOp
        { defaultConfig | timing = Duration 600 }

-}
scrollToTopWithConfig : ElementId -> msg -> Config -> Cmd msg
scrollToTopWithConfig containerId msg config =
    ScrollTask.scrollToTopWithConfig containerId config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the bottom of a container using default configuration.

    scrollToBottom "container-id" NoOp

-}
scrollToBottom : ElementId -> msg -> Cmd msg
scrollToBottom containerId msg =
    scrollToBottomWithConfig containerId msg defaultConfig


{-| Smoothly scroll to the bottom of a container with custom configuration.

    scrollToBottomWithConfig "container-id"
        NoOp
        { defaultConfig | timing = Speed 800 }

-}
scrollToBottomWithConfig : ElementId -> msg -> Config -> Cmd msg
scrollToBottomWithConfig containerId msg config =
    ScrollTask.scrollToBottomWithConfig containerId config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the left edge of a container using default configuration.

    scrollToLeftEdge "container-id" NoOp

-}
scrollToLeftEdge : ElementId -> msg -> Cmd msg
scrollToLeftEdge containerId msg =
    scrollToLeftEdgeWithConfig containerId msg defaultConfig


{-| Smoothly scroll to the left edge of a container with custom configuration.

    scrollToLeftEdgeWithConfig "container-id"
        NoOp
        { defaultConfig | timing = Duration 400 }

-}
scrollToLeftEdgeWithConfig : ElementId -> msg -> Config -> Cmd msg
scrollToLeftEdgeWithConfig containerId msg config =
    ScrollTask.scrollToLeftEdgeWithConfig containerId config
        |> Task.attempt (always msg)


{-| Smoothly scroll to the right edge of a container using default configuration.

    scrollToRightEdge "container-id" NoOp

-}
scrollToRightEdge : ElementId -> msg -> Cmd msg
scrollToRightEdge containerId msg =
    scrollToRightEdgeWithConfig containerId msg defaultConfig


{-| Smoothly scroll to the right edge of a container with custom configuration.

    scrollToRightEdgeWithConfig "container-id"
        NoOp
        { defaultConfig | timing = Duration 500 }

-}
scrollToRightEdgeWithConfig : ElementId -> msg -> Config -> Cmd msg
scrollToRightEdgeWithConfig containerId msg config =
    ScrollTask.scrollToRightEdgeWithConfig containerId config
        |> Task.attempt (always msg)


{-| Instantly jump to the top of a container using default configuration.

    jumpToTop "container-id" NoOp

-}
jumpToTop : ElementId -> msg -> Cmd msg
jumpToTop containerId msg =
    jumpToTopWithConfig containerId msg defaultConfig


{-| Instantly jump to the top of a container with custom configuration.

    jumpToTopWithConfig "container-id"
        NoOp
        { defaultConfig | offsetY = 10 }

-}
jumpToTopWithConfig : ElementId -> msg -> Config -> Cmd msg
jumpToTopWithConfig containerId msg config =
    ScrollTask.jumpToTopWithConfig containerId config
        |> Task.attempt (always msg)


{-| Instantly jump to the bottom of a container using default configuration.

    jumpToBottom "container-id" NoOp

-}
jumpToBottom : ElementId -> msg -> Cmd msg
jumpToBottom containerId msg =
    jumpToBottomWithConfig containerId msg defaultConfig


{-| Instantly jump to the bottom of a container with custom configuration.

    jumpToBottomWithConfig "container-id"
        NoOp
        { defaultConfig | offsetY = 20 }

-}
jumpToBottomWithConfig : ElementId -> msg -> Config -> Cmd msg
jumpToBottomWithConfig containerId msg config =
    ScrollTask.jumpToBottomWithConfig containerId config
        |> Task.attempt (always msg)


{-| Instantly jump to the left edge of a container using default configuration.

    jumpToLeftEdge "container-id" NoOp

-}
jumpToLeftEdge : ElementId -> msg -> Cmd msg
jumpToLeftEdge containerId msg =
    jumpToLeftEdgeWithConfig containerId msg defaultConfig


{-| Instantly jump to the left edge of a container with custom configuration.

    jumpToLeftEdgeWithConfig "container-id"
        NoOp
        { defaultConfig | offsetX = 5 }

-}
jumpToLeftEdgeWithConfig : ElementId -> msg -> Config -> Cmd msg
jumpToLeftEdgeWithConfig containerId msg config =
    ScrollTask.jumpToLeftEdgeWithConfig containerId config
        |> Task.attempt (always msg)


{-| Instantly jump to the right edge of a container using default configuration.

    jumpToRightEdge "container-id" NoOp

-}
jumpToRightEdge : ElementId -> msg -> Cmd msg
jumpToRightEdge containerId msg =
    jumpToRightEdgeWithConfig containerId msg defaultConfig


{-| Instantly jump to the right edge of a container with custom configuration.

    jumpToRightEdgeWithConfig "container-id"
        NoOp
        { defaultConfig | offsetX = 15 }

-}
jumpToRightEdgeWithConfig : ElementId -> msg -> Config -> Cmd msg
jumpToRightEdgeWithConfig containerId msg config =
    ScrollTask.jumpToRightEdgeWithConfig containerId config
        |> Task.attempt (always msg)
