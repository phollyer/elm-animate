module SmoothMoveScroll exposing
    ( Config
    , defaultConfig
    , Timing(..)
    , Axis(..)
    , Container
    , containerElement
    , setContainer
    , setDocumentBody
    , animateToCmd
    , animateToCmdWithConfig
    , jumpTo
    , jumpToWithConfig
    , animateToTask
    , animateToTaskWithConfig
    , scrollToTop
    , scrollToTopWithConfig
    )

{-| Smooth scrolling animations for precise DOM element targeting.

This module contains portions derived from SmoothScroll by Linus Schoemaker and Ruben Lie King (2019),
specifically the vertical scrolling functionality. Additional features and improvements by phollyer (2025).

This module provides both simple Cmd-based functions (recommended for most users)
and Task-based functions for more complex control flow and error handling.

Key features:

  - Smooth scrolling to specific DOM elements
  - Support for both document body and container element scrolling
  - Configurable animation parameters (speed, easing, axis)
  - Task-based API for composable operations
  - Error handling for missing DOM elements


# Configuration

@docs Config
@docs defaultConfig
@docs Timing
@docs Axis
@docs Container
@docs containerElement
@docs setContainer
@docs setDocumentBody


# Simple Commands (Recommended)

@docs animateToCmd
@docs animateToCmdWithConfig


# Instant Scrolling

@docs jumpTo
@docs jumpToWithConfig


# Task-based API (Advanced)

@docs animateToTask
@docs animateToTaskWithConfig


# Convenience Functions

@docs scrollToTop
@docs scrollToTopWithConfig

-}

import Browser.Dom as Dom
import Ease
import Internal.AnimationCore exposing (animationSteps, animationStepsWithFrames)
import Task exposing (Task)


{-| Animation timing configuration

Choose between speed-based or duration-based timing:

  - Speed: Animation speed in pixels per second (higher = faster)
  - Duration: Animation duration in milliseconds (higher = slower)

-}
type Timing
    = Speed Float
    | Duration Int


{-| Configuration for scrolling animations

This module provides both simple Cmd-based functions (recommended for most users)
and advanced Task-based functions (for composition and custom error handling).

  - timing: Animation timing (Speed in pixels per second or Duration in milliseconds)
  - offsetX: Horizontal offset in pixels from the target position
  - offsetY: Vertical offset in pixels from the target position
  - easing: Easing function from [elm-community/easing-functions](https://package.elm-lang.org/packages/elm-community/easing-functions/latest/)
  - axis: Movement axis (Y for scrolling, X for horizontal, Both for diagonal)
  - container: Which element to scroll within (document body or container)
  - scrollBar: Whether to show scrollbar during animation

-}
type alias Config =
    { timing : Timing
    , offsetX : Int
    , offsetY : Int
    , easing : Ease.Easing
    , axis : Axis
    , container : Container
    , scrollBar : Bool
    }


{-| Axis configuration for animation movement direction.

Use this to control whether your animation moves horizontally or vertically:

  - `Y` - Vertical scrolling (most common, default for page scrolling)
  - `X` - Horizontal scrolling (for sideways carousels or horizontal content)
  - `Both` - Both horizontal and vertical scrolling to reach the target element

Examples:

    -- Vertical scrolling to an element (default behavior)
    animateToCmdWithConfig
        { defaultConfig | axis = Y }
        "my-section"

    -- Horizontal scrolling within a carousel container
    animateToCmdWithConfig
        { defaultConfig
            | axis = X
            , container = containerElement "carousel-container"
        }
        "slide-3"

    -- Both horizontal and vertical scrolling
    animateToCmdWithConfig
        { defaultConfig | axis = Both }
        "target-element"

-}
type Axis
    = X
    | Y
    | Both


{-| An internal type for configuring which element to scroll within.
-}
type Container
    = DocumentBody
    | InnerNode String


{-| The default configuration which can be modified

    import Ease
    import SmoothMoveScroll exposing (defaultConfig)

    defaultConfig : Config
    defaultConfig =
        { speed = 200
        , offsetX = 0
        , offsetY = 12
        , easing = Ease.outQuint
        , container = DocumentBody
        , axis = Y
        , scrollBar = True
        }

-}
defaultConfig : Config
defaultConfig =
    { timing = Duration 400
    , offsetX = 0
    , offsetY = 12
    , easing = Ease.outQuint
    , container = DocumentBody
    , axis = Y
    , scrollBar = True
    }


{-| Convert timing configuration to speed divider for internal animation functions
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


{-| Set the container to scroll within to a specific DOM element by ID.

    import SmoothMoveScroll exposing (setContainer, animateToCmdWithConfig, defaultConfig)

    animateToCmdWithConfig NoOp (setContainer "article-list" defaultConfig) "article-42"

-}
setContainer : String -> Config -> Config
setContainer elementId config =
    { config | container = InnerNode elementId }


{-| Set the container to scroll within to the document body (default behavior).

    import SmoothMoveScroll exposing (setDocumentBody, animateToCmdWithConfig, defaultConfig)

    animateToCmdWithConfig NoOp (setDocumentBody defaultConfig) "article-42"

-}
setDocumentBody : Config -> Config
setDocumentBody config =
    { config | container = DocumentBody }


{-| Create a container reference for use with record update syntax.
Provides an alternative coding style for developers who prefer this approach.

    import SmoothMoveScroll exposing (containerElement, animateToCmdWithConfig, defaultConfig)

    animateToCmdWithConfig NoOp { defaultConfig | container = containerElement "article-list" } "article-42"

-}
containerElement : String -> Container
containerElement elementId =
    InnerNode elementId


{-| Cmd-based scrolling with custom completion message.

    ScrollTo elementId ->
        ( model, animateToCmd ScrollComplete elementId )

-}
animateToCmd : msg -> String -> Cmd msg
animateToCmd msg elementId =
    animateToCmdWithConfig msg defaultConfig elementId


{-| Cmd-based scrolling with configuration and custom completion message.

    ScrollTo elementId ->
        ( model, animateToCmdWithConfig ScrollComplete { defaultConfig | offset = 100 } elementId )

-}
animateToCmdWithConfig : msg -> Config -> String -> Cmd msg
animateToCmdWithConfig msg config elementId =
    animateToTaskWithConfig config elementId
        |> Task.attempt (always msg)


{-| Instantly jump to an element without animation.

Perfect for immediate navigation where you don't want smooth scrolling.

    JumpToSection sectionId ->
        ( model, jumpTo JumpComplete sectionId )

-}
jumpTo : msg -> String -> Cmd msg
jumpTo msg elementId =
    jumpToWithConfig msg defaultConfig elementId


{-| Jump to an element with configuration (respects offset and axis settings).

    JumpToSection sectionId ->
        ( model, jumpToWithConfig JumpComplete { defaultConfig | offset = 50 } sectionId )

-}
jumpToWithConfig : msg -> Config -> String -> Cmd msg
jumpToWithConfig msg config elementId =
    jumpToTask config elementId
        |> Task.attempt (always msg)


{-| Internal task for instant jumping - used by jumpTo functions
-}
jumpToTask : Config -> String -> Task Dom.Error ()
jumpToTask config id =
    let
        getViewport_ =
            getViewport config.container

        getContainerInfo_ =
            getContainerInfo config.container

        scrollTask { scene, viewport } { element } container =
            let
                ( clampedX, clampedY ) =
                    getClampedPositions element viewport scene container config

                setViewportTask =
                    case config.container of
                        DocumentBody ->
                            case config.axis of
                                X ->
                                    Dom.setViewport clampedX viewport.y

                                Y ->
                                    Dom.setViewport viewport.x clampedY

                                Both ->
                                    Dom.setViewport clampedX clampedY

                        InnerNode containerNodeId ->
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
    Task.map3 scrollTask getViewport_ (Dom.getElement id) getContainerInfo_
        |> Task.andThen identity


{-| Task-based scrolling for advanced users who need error handling or composition.

    ScrollTo elementId ->
        ( model, Task.attempt HandleScrollError (animateToTask elementId) )

-}
animateToTask : String -> Task Dom.Error (List ())
animateToTask elementId =
    animateToTaskWithConfig defaultConfig elementId


{-| Task-based scrolling with configuration for advanced users.

    ScrollTo elementId ->
        ( model, Task.attempt HandleScrollError (animateToTaskWithConfig config elementId) )

-}
animateToTaskWithConfig : Config -> String -> Task Dom.Error (List ())
animateToTaskWithConfig config id =
    let
        getViewport_ =
            getViewport config.container

        getContainerInfo_ =
            getContainerInfo config.container

        scrollTask { scene, viewport } { element } container =
            let
                ( clampedX, clampedY ) =
                    getClampedPositions element viewport scene container config

                setViewportTask =
                    case config.container of
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

                        InnerNode containerNodeId ->
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
    Task.map3 scrollTask getViewport_ (Dom.getElement id) getContainerInfo_
        |> Task.andThen identity


{-| Scroll to the top of a container with default configuration.

Perfect for "back to top" buttons or resetting scroll position.

    BackToTop ->
        ( model, scrollToTop "main-content" )

For document body scrolling, use an empty string:

    BackToTop ->
        ( model, scrollToTop "" )

-}
scrollToTop : msg -> String -> Cmd msg
scrollToTop msg containerId =
    scrollToTopWithConfig msg defaultConfig containerId


{-| Scroll to the top of a container with custom configuration.

    BackToTop ->
        ( model, scrollToTopWithConfig NoOp { defaultConfig | timing = Duration 500 } "main-content" )

-}
scrollToTopWithConfig : msg -> Config -> String -> Cmd msg
scrollToTopWithConfig msg config containerId =
    let
        scrollToTopTask =
            case containerId of
                "" ->
                    -- Document body scrolling
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
                                    |> Task.map (always ())
                            )

                _ ->
                    -- Container scrolling
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
                                    |> Task.map (always ())
                            )
    in
    Task.attempt (always msg) scrollToTopTask


getViewport : Container -> Task Dom.Error Dom.Viewport
getViewport container =
    case container of
        DocumentBody ->
            Dom.getViewport

        InnerNode containerNodeId ->
            Dom.getViewportOf containerNodeId


getContainerInfo : Container -> Task Dom.Error (Maybe Dom.Element)
getContainerInfo container =
    case container of
        DocumentBody ->
            Task.succeed Nothing

        InnerNode containerNodeId ->
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
