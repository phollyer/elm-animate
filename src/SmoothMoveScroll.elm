module SmoothMoveScroll exposing
    ( Config
    , defaultConfig
    , Axis(..)
    , Timing(..)
    , ElementId
    , Container(..)
    , scrollCmd
    , scrollCmdWithConfig
    , scrollTask
    , scrollTaskWithConfig
    , jumpCmd
    , jumpCmdWithConfig
    , jumpTask
    , jumpTaskWithConfig
    , scrollToTop
    , scrollToTopWithConfig
    , scrollToTopTask
    , scrollToTopTaskWithConfig
    , scrollToBottom
    , scrollToBottomWithConfig
    , scrollToBottomTask
    , scrollToBottomTaskWithConfig
    , scrollToLeftEdge
    , scrollToLeftEdgeWithConfig
    , scrollToLeftEdgeTask
    , scrollToLeftEdgeTaskWithConfig
    , scrollToRightEdge
    , scrollToRightEdgeWithConfig
    , scrollToRightEdgeTask
    , scrollToRightEdgeTaskWithConfig
    , jumpToTop
    , jumpToTopWithConfig
    , jumpToTopTask
    , jumpToTopTaskWithConfig
    , jumpToBottom
    , jumpToBottomWithConfig
    , jumpToBottomTask
    , jumpToBottomTaskWithConfig
    , jumpToLeftEdge
    , jumpToLeftEdgeWithConfig
    , jumpToLeftEdgeTask
    , jumpToLeftEdgeTaskWithConfig
    , jumpToRightEdge
    , jumpToRightEdgeWithConfig
    , jumpToRightEdgeTask
    , jumpToRightEdgeTaskWithConfig
    -- Element-targeting functions (ElementId -> Container -> ...)
    -- Position-targeting functions (Container -> ...)
    )

{-| Comprehensive smooth scrolling animations for DOM elements and container edges.

This module contains portions derived from [SmoothScroll](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/) by Linus Schoemaker and Ruben Lie King (2019),
with significant enhancements and a complete API redesign by phollyer (2025).


## Key Features

  - **Element-targeting**: Smooth scroll to specific DOM elements with precise positioning
  - **Position-targeting**: Scroll to container edges (top, bottom, left, right)
  - **Dual API**: Both Cmd and Task versions of every function for different use cases
  - **Instant alternatives**: Jump functions for immediate positioning without animation
  - **Container support**: Works with document body or any scrollable container element
  - **Rich configuration**: Timing, easing, offsets, and axis control


## API Structure

**Element-targeting functions** (require ElementId + Container):

  - `scroll*` - Smooth animations to specific elements
  - `jump*` - Instant positioning to specific elements

**Position-targeting functions** (require only Container):

  - `scrollTo*` - Smooth animations to container edges
  - `jumpTo*` - Instant positioning to container edges

**Consistent patterns**:

  - `*Cmd` - Simple command-based API
  - `*CmdWithConfig` - Commands with custom configuration
  - `*Task` - Task-based API for error handling and composition
  - `*TaskWithConfig` - Tasks with custom configuration


## Parameter Order

All functions follow consistent parameter ordering:

  - Element-targeting: `ElementId -> Container -> msg -> Config`
  - Position-targeting: `Container -> msg -> Config`


# Configuration

@docs Config
@docs defaultConfig
@docs Axis
@docs Timing
@docs ElementId
@docs Container


# Element-Targeting Functions

Functions that scroll to specific DOM elements. These require both an ElementId (target element)
and a Container (scrollable container).

Parameter order: `ElementId -> Container -> msg -> Config`


## Smooth Scrolling to Elements

@docs scrollCmd
@docs scrollCmdWithConfig
@docs scrollTask
@docs scrollTaskWithConfig


## Instant Jumping to Elements

@docs jumpCmd
@docs jumpCmdWithConfig
@docs jumpTask
@docs jumpTaskWithConfig


# Position-Targeting Functions

Functions that scroll to specific positions (edges) within containers. These only need a Container parameter.

Parameter order: `Container -> msg -> Config`


## Scroll to Top/Bottom

@docs scrollToTop
@docs scrollToTopWithConfig
@docs scrollToTopTask
@docs scrollToTopTaskWithConfig
@docs scrollToBottom
@docs scrollToBottomWithConfig
@docs scrollToBottomTask
@docs scrollToBottomTaskWithConfig


## Scroll to Left/Right Edges

@docs scrollToLeftEdge
@docs scrollToLeftEdgeWithConfig
@docs scrollToLeftEdgeTask
@docs scrollToLeftEdgeTaskWithConfig
@docs scrollToRightEdge
@docs scrollToRightEdgeWithConfig
@docs scrollToRightEdgeTask
@docs scrollToRightEdgeTaskWithConfig


## Jump to Top/Bottom (Instant)

@docs jumpToTop
@docs jumpToTopWithConfig
@docs jumpToTopTask
@docs jumpToTopTaskWithConfig
@docs jumpToBottom
@docs jumpToBottomWithConfig
@docs jumpToBottomTask
@docs jumpToBottomTaskWithConfig


## Jump to Left/Right Edges (Instant)

@docs jumpToLeftEdge
@docs jumpToLeftEdgeWithConfig
@docs jumpToLeftEdgeTask
@docs jumpToLeftEdgeTaskWithConfig
@docs jumpToRightEdge
@docs jumpToRightEdgeWithConfig
@docs jumpToRightEdgeTask
@docs jumpToRightEdgeTaskWithConfig

-}

import Browser.Dom as Dom
import Ease
import Internal.AnimationCore exposing (animationSteps, animationStepsWithFrames)
import Task exposing (Task)


{-| Type alias for DOM element IDs.
-}
type alias ElementId =
    String


{-| Animation timing configuration.

Choose between speed-based or duration-based timing:

  - Speed: Animation speed in pixels per second (higher = faster)
  - Duration: Animation duration in milliseconds (higher = slower)

-}
type Timing
    = Speed Float
    | Duration Int


{-| Configuration for scrolling.

  - **timing**: Animation timing (Speed in pixels per second or Duration in milliseconds). Default is `Duration 400`.
  - **offsetX**: Horizontal offset in pixels from the target position. Default is 0.
  - **offsetY**: Vertical offset in pixels from the target position. Default is 12.
  - **easing**: Easing function from [elm-community/easing-functions](https://package.elm-lang.org/packages/elm-community/easing-functions/latest/). Default is [Ease.outQuint](https://package.elm-lang.org/packages/elm-community/easing-functions/latest/Ease#outQuint).
  - **axis**: Movement axis (Y for vertical, X for horizontal, Both for diagonal). Default is Y.

-}
type alias Config =
    { timing : Timing
    , offsetX : Int
    , offsetY : Int
    , easing : Ease.Easing
    , axis : Axis
    }


{-| Axis configuration for animation movement direction.

Use this to control whether your animation moves horizontally or vertically:

  - `Y` - Vertical scrolling (most common, default for page scrolling)
  - `X` - Horizontal scrolling (for sideways carousels or horizontal content)
  - `Both` - Both horizontal and vertical scrolling to reach the target element

Examples:

    -- Vertical document scrolling to an element (default behavior)
    scrollCmdWithConfig "my-section" DocumentBody NoOp defaultConfig

    -- Horizontal scrolling within a carousel container
    scrollCmdWithConfig "slide-3"
        (Container "carousel-container")
        NoOp
        { defaultConfig | axis = X }

    -- Both horizontal and vertical scrolling
    scrollCmdWithConfig "target-element"
        DocumentBody
        NoOp
        { defaultConfig | axis = Both }

-}
type Axis
    = X
    | Y
    | Both


{-| Type for configuring which element to scroll within.

Use `DocumentBody` for scrolling the main document, or `Container elementId`
for scrolling within a specific container element.

-}
type Container
    = DocumentBody
    | Container ElementId


{-| The default configuration which you can customize as needed.

    import Ease
    import SmoothMoveScroll exposing (Axis(..), Timing(..), defaultConfig)

    customConfig =
        { defaultConfig
            | timing = Duration 500
            , offsetY = 20
            , easing = Ease.inOutCubic
            , axis = Both
        }

-}
defaultConfig : Config
defaultConfig =
    { timing = Duration 400
    , offsetX = 0
    , offsetY = 12
    , easing = Ease.outQuint
    , axis = Y
    }


{-| Convert timing configuration to speed divider for internal animation functions.
-}
timingToSpeed : Timing -> Float -> Int
timingToSpeed timing distance =
    case timing of
        Speed pixelsPerSecond ->
            -- Convert pixels per second to frame divider
            -- Assuming 60fps, we want: frames = distance / (pixelsPerSecond / 60)
            max 1 (round (distance * 60 / pixelsPerSecond))

        Duration milliseconds ->
            -- Convert duration in milliseconds to frame divider
            -- Assuming 60fps: frames = (milliseconds / 1000) * 60 = milliseconds * 0.06
            -- speed divider = distance / frames = distance / (milliseconds * 0.06)
            max 1 (round (distance / (toFloat milliseconds * 0.06)))


{-| Cmd-based scrolling with custom completion message.

    ScrollTo elementId ->
        ( model
        , scrollCmd elementId DocumentBody ScrollComplete
        )

-}
scrollCmd : ElementId -> Container -> msg -> Cmd msg
scrollCmd elementId container msg =
    scrollCmdWithConfig elementId container msg defaultConfig


{-| Cmd-based scrolling with configuration and custom completion message.

    ScrollTo elementId ->
        ( model
        , scrollCmdWithConfig elementId DocumentBody ScrollComplete <|
            { defaultConfig | offsetY = 100 } )
        }

-}
scrollCmdWithConfig : ElementId -> Container -> msg -> Config -> Cmd msg
scrollCmdWithConfig elementId container msg config =
    scrollTaskWithConfig elementId container config
        |> Task.attempt (always msg)


{-| Instantly jump to an element without animation.

Perfect for immediate navigation where you don't want smooth scrolling.

    JumpToSection sectionId ->
        ( model
        , jumpCmd sectionId DocumentBody JumpComplete
        )

-}
jumpCmd : ElementId -> Container -> msg -> Cmd msg
jumpCmd elementId container msg =
    jumpCmdWithConfig elementId container msg defaultConfig


{-| Jump to an element with configuration (respects offset and axis settings).

    JumpToSection sectionId ->
        ( model
        , jumpCmdWithConfig sectionId DocumentBody JumpComplete <|
            { defaultConfig | offsetY = 50 }
        )

-}
jumpCmdWithConfig : ElementId -> Container -> msg -> Config -> Cmd msg
jumpCmdWithConfig elementId container msg config =
    jumpTaskWithConfig elementId container config
        |> Task.attempt (always msg)


{-| Task-based instant jumping for advanced users who need error handling.

    JumpToSection sectionId ->
        ( model
        , Task.attempt HandleJumpError <|
            jumpTask sectionId DocumentBody
        )

-}
jumpTask : ElementId -> Container -> Task Dom.Error ()
jumpTask elementId container =
    jumpTaskWithConfig elementId container defaultConfig


{-| Task-based instant jumping with configuration for advanced users who need error handling.

    JumpToSection sectionId ->
        ( model
        , Task.attempt HandleJumpError <|
            jumpTaskWithConfig sectionId DocumentBody <|
                { defaultConfig | offsetY = 50 }
        )

-}
jumpTaskWithConfig : ElementId -> Container -> Config -> Task Dom.Error ()
jumpTaskWithConfig id container config =
    let
        getViewport_ =
            getViewport container

        getContainerInfo_ =
            getContainerInfo container

        performJumpTask { scene, viewport } { element } containerInfo =
            let
                ( clampedX, clampedY ) =
                    getClampedPositions element viewport scene containerInfo config

                setViewportTask =
                    case container of
                        DocumentBody ->
                            case config.axis of
                                X ->
                                    Dom.setViewport clampedX viewport.y

                                Y ->
                                    Dom.setViewport viewport.x clampedY

                                Both ->
                                    Dom.setViewport clampedX clampedY

                        Container containerNodeId ->
                            case config.axis of
                                X ->
                                    Dom.setViewportOf containerNodeId clampedX viewport.y

                                Y ->
                                    Dom.setViewportOf containerNodeId viewport.x clampedY

                                Both ->
                                    Dom.setViewportOf containerNodeId clampedX clampedY
            in
            setViewportTask
    in
    Task.map3 performJumpTask getViewport_ (Dom.getElement id) getContainerInfo_
        |> Task.andThen identity


{-|

    ScrollTo elementId ->
        ( model
        , Task.attempt HandleScrollError <|
            scrollTask elementId
        )

-}
scrollTask : ElementId -> Container -> Task Dom.Error (List ())
scrollTask elementId container =
    scrollTaskWithConfig elementId container defaultConfig


{-|

    ScrollTo elementId ->
        ( model
        , Task.attempt HandleScrollError <|
            scrollTaskWithConfig elementId container config
        )

-}
scrollTaskWithConfig : ElementId -> Container -> Config -> Task Dom.Error (List ())
scrollTaskWithConfig id container config =
    let
        getViewport_ =
            getViewport container

        getContainerInfo_ =
            getContainerInfo container

        performScrollTask { scene, viewport } { element } containerInfo =
            let
                ( clampedX, clampedY ) =
                    getClampedPositions element viewport scene containerInfo config

                setViewportTask =
                    case container of
                        DocumentBody ->
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

                        Container containerNodeId ->
                            case config.axis of
                                X ->
                                    animationSteps (timingToSpeed config.timing (abs (clampedX - viewport.x))) config.easing viewport.x clampedX
                                        |> List.map (\x -> Dom.setViewportOf containerNodeId x viewport.y)
                                        |> Task.sequence

                                Y ->
                                    animationSteps (timingToSpeed config.timing (abs (clampedY - viewport.y))) config.easing viewport.y clampedY
                                        |> List.map (\y -> Dom.setViewportOf containerNodeId viewport.x y)
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
                                                |> List.map (\y -> Dom.setViewportOf containerNodeId viewport.x y)
                                                |> Task.sequence

                                        ( _, [] ) ->
                                            -- No vertical movement needed, only animate X
                                            xSteps
                                                |> List.map (\x -> Dom.setViewportOf containerNodeId x viewport.y)
                                                |> Task.sequence

                                        _ ->
                                            List.map2 (Dom.setViewportOf containerNodeId) xSteps ySteps
                                                |> Task.sequence
            in
            setViewportTask
    in
    Task.map3 performScrollTask getViewport_ (Dom.getElement id) getContainerInfo_
        |> Task.andThen identity


{-| Smooth scroll to the top of the document body or a container element.

Perfect for "back to top" buttons or resetting scroll position.

    BackToTop ->
        ( model
        , scrollToTop (Container "main-content")
        )

For document body scrolling:

    BackToTop ->
        ( model, scrollToTop DocumentBody )

-}
scrollToTop : Container -> msg -> Cmd msg
scrollToTop container msg =
    scrollToTopWithConfig container msg defaultConfig


{-| Scroll to the top of a container with custom configuration.

    BackToTop ->
        ( model
        , scrollToTopWithConfig (Container "main-content") NoOp <|
            { defaultConfig | timing = Duration 500 }
        )

-}
scrollToTopWithConfig : Container -> msg -> Config -> Cmd msg
scrollToTopWithConfig container msg config =
    scrollToTopTaskWithConfig container config
        |> Task.attempt (always msg)


{-| Task-based scrolling to top for advanced users who need error handling.

    BackToTop ->
        ( model
        , Task.attempt HandleScrollError <|
            scrollToTopTask DocumentBody
        )

-}
scrollToTopTask : Container -> Task Dom.Error (List ())
scrollToTopTask container =
    scrollToTopTaskWithConfig container defaultConfig


{-| Task-based scrolling to top with custom configuration.

    BackToTop ->
        ( model
        , Task.attempt HandleScrollError <|
            scrollToTopTaskWithConfig (Container "main-content") <|
                { defaultConfig | timing = Duration 500 }
        )

-}
scrollToTopTaskWithConfig : Container -> Config -> Task Dom.Error (List ())
scrollToTopTaskWithConfig container config =
    case container of
        DocumentBody ->
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

        Container containerId ->
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


{-| Smooth scroll to the bottom of the document body or a container element.

Perfect for "scroll to bottom" functionality in chat applications or content sections.

    ScrollToBottom ->
        ( model
        , scrollToBottom <|
            Container "chat-window"
        )

For document body scrolling:

    ScrollToBottom ->
        ( model, scrollToBottom DocumentBody )

-}
scrollToBottom : Container -> msg -> Cmd msg
scrollToBottom container msg =
    scrollToBottomWithConfig container msg defaultConfig


{-| Scroll to the bottom of a container with custom configuration.

    ScrollToBottom ->
        ( model
        , scrollToBottomWithConfig (Container "main-content") NoOp <|
            { defaultConfig | timing = Duration 500 }
        )

-}
scrollToBottomWithConfig : Container -> msg -> Config -> Cmd msg
scrollToBottomWithConfig container msg config =
    scrollToBottomTaskWithConfig container config
        |> Task.attempt (always msg)


{-| Task-based scrolling to bottom for advanced users who need error handling.

    ScrollToBottom ->
        ( model
        , Task.attempt HandleScrollError <|
            scrollToBottomTask DocumentBody
        )

-}
scrollToBottomTask : Container -> Task Dom.Error (List ())
scrollToBottomTask container =
    scrollToBottomTaskWithConfig container defaultConfig


{-| Task-based scrolling to bottom with custom configuration.

    ScrollToBottom ->
        ( model
        , Task.attempt HandleScrollError (scrollToBottomTaskWithConfig (Container "main-content") <|
            { defaultConfig | timing = Duration 500 }
        )

-}
scrollToBottomTaskWithConfig : Container -> Config -> Task Dom.Error (List ())
scrollToBottomTaskWithConfig container config =
    case container of
        DocumentBody ->
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

        Container containerId ->
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


{-| Smooth scroll to the left edge of the document body or a container element.

Perfect for resetting horizontal scroll position or navigation.

    ScrollToLeft ->
        ( model
        , scrollToLeftEdge <|
            Container "horizontal-scroller"
        )

For document body scrolling:

    ScrollToLeft ->
        ( model, scrollToLeftEdge DocumentBody )

-}
scrollToLeftEdge : Container -> msg -> Cmd msg
scrollToLeftEdge container msg =
    scrollToLeftEdgeWithConfig container msg defaultConfig


{-| Scroll to the left edge of a container with custom configuration.

    ScrollToLeft ->
        ( model
        , scrollToLeftEdgeWithConfig (Container "carousel") NoOp <|
            { defaultConfig | timing = Duration 300 }
        )

-}
scrollToLeftEdgeWithConfig : Container -> msg -> Config -> Cmd msg
scrollToLeftEdgeWithConfig container msg config =
    scrollToLeftEdgeTaskWithConfig container config
        |> Task.attempt (always msg)


{-| Task-based scrolling to left edge for advanced users who need error handling.

    ScrollToLeft ->
        ( model
        , Task.attempt HandleScrollError <|
            scrollToLeftEdgeTask DocumentBody
        )

-}
scrollToLeftEdgeTask : Container -> Task Dom.Error (List ())
scrollToLeftEdgeTask container =
    scrollToLeftEdgeTaskWithConfig container defaultConfig


{-| Task-based scrolling to left edge with custom configuration.

    ScrollToLeft ->
        ( model
        , Task.attempt HandleScrollError <|
            scrollToLeftEdgeTaskWithConfig (Container "carousel") <|
                { defaultConfig | timing = Duration 300 }
        )

-}
scrollToLeftEdgeTaskWithConfig : Container -> Config -> Task Dom.Error (List ())
scrollToLeftEdgeTaskWithConfig container config =
    case container of
        DocumentBody ->
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

        Container containerId ->
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


{-| Smooth scroll to the right edge of the document body or a container element.

Perfect for horizontal navigation to the end of content.

    ScrollToRight ->
        ( model, scrollToRightEdge (Container "horizontal-scroller") )

For document body scrolling:

    ScrollToRight ->
        ( model, scrollToRightEdge DocumentBody )

-}
scrollToRightEdge : Container -> msg -> Cmd msg
scrollToRightEdge container msg =
    scrollToRightEdgeWithConfig container msg defaultConfig


{-| Scroll to the right edge of a container with custom configuration.

    ScrollToRight ->
        ( model, scrollToRightEdgeWithConfig (Container "carousel") NoOp { defaultConfig | timing = Duration 300 } )

-}
scrollToRightEdgeWithConfig : Container -> msg -> Config -> Cmd msg
scrollToRightEdgeWithConfig container msg config =
    scrollToRightEdgeTaskWithConfig container config
        |> Task.attempt (always msg)


{-| Task-based scrolling to right edge for advanced users who need error handling.

    ScrollToRight ->
        ( model, Task.attempt HandleScrollError (scrollToRightEdgeTask DocumentBody) )

-}
scrollToRightEdgeTask : Container -> Task Dom.Error (List ())
scrollToRightEdgeTask container =
    scrollToRightEdgeTaskWithConfig container defaultConfig


{-| Task-based scrolling to right edge with custom configuration.

    ScrollToRight ->
        ( model, Task.attempt HandleScrollError (scrollToRightEdgeTaskWithConfig (Container "carousel") { defaultConfig | timing = Duration 300 }) )

-}
scrollToRightEdgeTaskWithConfig : Container -> Config -> Task Dom.Error (List ())
scrollToRightEdgeTaskWithConfig container config =
    case container of
        DocumentBody ->
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

        Container containerId ->
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


{-| Instantly jump to the top of the document body or a container element.

Perfect for instant "back to top" functionality without animation.

    JumpToTop ->
        ( model, jumpToTop (Container "main-content") )

For document body jumping:

    JumpToTop ->
        ( model, jumpToTop DocumentBody )

-}
jumpToTop : Container -> msg -> Cmd msg
jumpToTop container msg =
    jumpToTopWithConfig container msg defaultConfig


{-| Jump to the top of a container with configuration (respects offset settings).

    JumpToTop ->
        ( model, jumpToTopWithConfig (Container "main-content") NoOp { defaultConfig | offsetY = 10 } )

-}
jumpToTopWithConfig : Container -> msg -> Config -> Cmd msg
jumpToTopWithConfig container msg config =
    jumpToTopTaskWithConfig container config
        |> Task.attempt (always msg)


{-| Task-based instant jumping to top for advanced users who need error handling.

    JumpToTop ->
        ( model, Task.attempt HandleJumpError (jumpToTopTask DocumentBody) )

-}
jumpToTopTask : Container -> Task Dom.Error ()
jumpToTopTask container =
    jumpToTopTaskWithConfig container defaultConfig


{-| Task-based jumping to top with custom configuration.

    JumpToTop ->
        ( model, Task.attempt HandleJumpError (jumpToTopTaskWithConfig (Container "main-content") { defaultConfig | offsetY = 10 }) )

-}
jumpToTopTaskWithConfig : Container -> Config -> Task Dom.Error ()
jumpToTopTaskWithConfig container config =
    case container of
        DocumentBody ->
            Dom.getViewport
                |> Task.andThen (\{ viewport } -> Dom.setViewport viewport.x (0 + toFloat config.offsetY))

        Container containerId ->
            Dom.getViewportOf containerId
                |> Task.andThen (\{ viewport } -> Dom.setViewportOf containerId viewport.x (0 + toFloat config.offsetY))


{-| Instantly jump to the bottom of the document body or a container element.

Perfect for instant "jump to bottom" functionality without animation.

    JumpToBottom ->
        ( model, jumpToBottom (Container "chat-window") )

For document body jumping:

    JumpToBottom ->
        ( model, jumpToBottom DocumentBody )

-}
jumpToBottom : Container -> msg -> Cmd msg
jumpToBottom container msg =
    jumpToBottomWithConfig container msg defaultConfig


{-| Jump to the bottom of a container with configuration (respects offset settings).

    JumpToBottom ->
        ( model, jumpToBottomWithConfig (Container "chat-window") NoOp { defaultConfig | offsetY = -10 } )

-}
jumpToBottomWithConfig : Container -> msg -> Config -> Cmd msg
jumpToBottomWithConfig container msg config =
    jumpToBottomTaskWithConfig container config
        |> Task.attempt (always msg)


{-| Task-based instant jumping to bottom for advanced users who need error handling.

    JumpToBottom ->
        ( model, Task.attempt HandleJumpError (jumpToBottomTask DocumentBody) )

-}
jumpToBottomTask : Container -> Task Dom.Error ()
jumpToBottomTask container =
    jumpToBottomTaskWithConfig container defaultConfig


{-| Task-based jumping to bottom with custom configuration.

    JumpToBottom ->
        ( model, Task.attempt HandleJumpError (jumpToBottomTaskWithConfig (Container "chat-window") { defaultConfig | offsetY = -10 }) )

-}
jumpToBottomTaskWithConfig : Container -> Config -> Task Dom.Error ()
jumpToBottomTaskWithConfig container config =
    case container of
        DocumentBody ->
            Dom.getViewport
                |> Task.andThen
                    (\{ scene, viewport } ->
                        let
                            maxY =
                                scene.height - viewport.height
                        in
                        Dom.setViewport viewport.x (maxY + toFloat config.offsetY)
                    )

        Container containerId ->
            Dom.getViewportOf containerId
                |> Task.andThen
                    (\{ scene, viewport } ->
                        let
                            maxY =
                                scene.height - viewport.height
                        in
                        Dom.setViewportOf containerId viewport.x (maxY + toFloat config.offsetY)
                    )


{-| Instantly jump to the left edge of the document body or a container element.

Perfect for resetting horizontal position without animation.

    JumpToLeft ->
        ( model, jumpToLeftEdge (Container "horizontal-scroller") )

For document body jumping:

    JumpToLeft ->
        ( model, jumpToLeftEdge DocumentBody )

-}
jumpToLeftEdge : Container -> msg -> Cmd msg
jumpToLeftEdge container msg =
    jumpToLeftEdgeWithConfig container msg defaultConfig


{-| Jump to the left edge of a container with configuration (respects offset settings).

    JumpToLeft ->
        ( model, jumpToLeftEdgeWithConfig (Container "carousel") NoOp { defaultConfig | offsetX = 5 } )

-}
jumpToLeftEdgeWithConfig : Container -> msg -> Config -> Cmd msg
jumpToLeftEdgeWithConfig container msg config =
    jumpToLeftEdgeTaskWithConfig container config
        |> Task.attempt (always msg)


{-| Task-based instant jumping to left edge for advanced users who need error handling.

    JumpToLeft ->
        ( model, Task.attempt HandleJumpError (jumpToLeftEdgeTask DocumentBody) )

-}
jumpToLeftEdgeTask : Container -> Task Dom.Error ()
jumpToLeftEdgeTask container =
    jumpToLeftEdgeTaskWithConfig container defaultConfig


{-| Task-based jumping to left edge with custom configuration.

    JumpToLeft ->
        ( model, Task.attempt HandleJumpError (jumpToLeftEdgeTaskWithConfig (Container "carousel") { defaultConfig | offsetX = 5 }) )

-}
jumpToLeftEdgeTaskWithConfig : Container -> Config -> Task Dom.Error ()
jumpToLeftEdgeTaskWithConfig container config =
    case container of
        DocumentBody ->
            Dom.getViewport
                |> Task.andThen (\{ viewport } -> Dom.setViewport (0 + toFloat config.offsetX) viewport.y)

        Container containerId ->
            Dom.getViewportOf containerId
                |> Task.andThen (\{ viewport } -> Dom.setViewportOf containerId (0 + toFloat config.offsetX) viewport.y)


{-| Instantly jump to the right edge of the document body or a container element.

Perfect for jumping to end of horizontal content without animation.

    JumpToRight ->
        ( model, jumpToRightEdge (Container "horizontal-scroller") )

For document body jumping:

    JumpToRight ->
        ( model, jumpToRightEdge DocumentBody )

-}
jumpToRightEdge : Container -> msg -> Cmd msg
jumpToRightEdge container msg =
    jumpToRightEdgeWithConfig container msg defaultConfig


{-| Jump to the right edge of a container with configuration (respects offset settings).

    JumpToRight ->
        ( model, jumpToRightEdgeWithConfig (Container "carousel") NoOp { defaultConfig | offsetX = -5 } )

-}
jumpToRightEdgeWithConfig : Container -> msg -> Config -> Cmd msg
jumpToRightEdgeWithConfig container msg config =
    jumpToRightEdgeTaskWithConfig container config
        |> Task.attempt (always msg)


{-| Task-based instant jumping to right edge for advanced users who need error handling.

    JumpToRight ->
        ( model, Task.attempt HandleJumpError (jumpToRightEdgeTask DocumentBody) )

-}
jumpToRightEdgeTask : Container -> Task Dom.Error ()
jumpToRightEdgeTask container =
    jumpToRightEdgeTaskWithConfig container defaultConfig


{-| Task-based jumping to right edge with custom configuration.

    JumpToRight ->
        ( model, Task.attempt HandleJumpError (jumpToRightEdgeTaskWithConfig (Container "carousel") { defaultConfig | offsetX = -5 }) )

-}
jumpToRightEdgeTaskWithConfig : Container -> Config -> Task Dom.Error ()
jumpToRightEdgeTaskWithConfig container config =
    case container of
        DocumentBody ->
            Dom.getViewport
                |> Task.andThen
                    (\{ scene, viewport } ->
                        let
                            maxX =
                                scene.width - viewport.width
                        in
                        Dom.setViewport (maxX + toFloat config.offsetX) viewport.y
                    )

        Container containerId ->
            Dom.getViewportOf containerId
                |> Task.andThen
                    (\{ scene, viewport } ->
                        let
                            maxX =
                                scene.width - viewport.width
                        in
                        Dom.setViewportOf containerId (maxX + toFloat config.offsetX) viewport.y
                    )


getViewport : Container -> Task Dom.Error Dom.Viewport
getViewport container =
    case container of
        DocumentBody ->
            Dom.getViewport

        Container containerNodeId ->
            Dom.getViewportOf containerNodeId


getContainerInfo : Container -> Task Dom.Error (Maybe Dom.Element)
getContainerInfo container =
    case container of
        DocumentBody ->
            Task.succeed Nothing

        Container containerNodeId ->
            Task.map Just (Dom.getElement containerNodeId)


getClampedPositions : { a | x : Float, y : Float, height : Float, width : Float } -> { a | x : Float, y : Float, height : Float, width : Float } -> { a | width : Float, height : Float } -> Maybe Dom.Element -> Config -> ( Float, Float )
getClampedPositions element viewport scene container config =
    let
        ( targetX, targetY ) =
            getTargetPositions element viewport container config
    in
    ( targetX
        |> min (scene.width - viewport.width)
        |> max 0
    , targetY
        |> min (scene.height - viewport.height)
        |> max 0
    )


getTargetPositions : { a | x : Float, y : Float } -> { a | x : Float, y : Float } -> Maybe Dom.Element -> Config -> ( Float, Float )
getTargetPositions element viewport container config =
    case container of
        Nothing ->
            ( element.x - toFloat config.offsetX
            , element.y - toFloat config.offsetY
            )

        Just containerInfo ->
            ( viewport.x + element.x - toFloat config.offsetX - containerInfo.element.x
            , viewport.y + element.y - toFloat config.offsetY - containerInfo.element.y
            )
