module SmoothMoveScroll exposing
    ( Config
    , defaultConfig
    , Axis(..)
    , Timing(..)
    , ElementId
    , Container(..)
    , scrollCmd
    , scrollCmdWithConfig
    , jumpTo
    , jumpToWithConfig
    , scrollTask
    , scrollTaskWithConfig
    , scrollToTop
    , scrollToTopWithConfig
    )

{-| Smooth scrolling animations for precise DOM element targeting.

This module contains portions derived from [SmoothScroll](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/) by Linus Schoemaker and Ruben Lie King (2019),
specifically the vertical scrolling functionality. Additional features and improvements by phollyer (2025).

This module provides both simple Cmd-based functions and Task-based
functions for more complex control flow and error handling.

Key features:

  - Smooth scrolling (both vertical and horizontal) to specific DOM elements
  - Support for both document body and container element scrolling
  - Configurable animation parameters (speed, easing, axis)
  - Task-based API for composable operations and error handling


# Configuration

@docs Config
@docs defaultConfig
@docs Axis
@docs Timing
@docs ElementId
@docs Container


# Simple Commands

These commands do not provide error handling and are best suited for straightforward use cases
such as:

1.  You know the target elements exist, or
2.  You want a quick and easy way to trigger scrolling without handling errors

@docs scrollCmd
@docs scrollCmdWithConfig


# Instant Scrolling

@docs jumpTo
@docs jumpToWithConfig


# Task API

Task-based scrolling for advanced users who need error handling or composition.

@docs scrollTask
@docs scrollTaskWithConfig


# Convenience Functions

@docs scrollToTop
@docs scrollToTopWithConfig

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
  - **container**: Which element to scroll within. Use `DocumentBody` for document scrolling or `Container "element-id"` for container scrolling. Default is `DocumentBody`.

-}
type alias Config =
    { timing : Timing
    , offsetX : Int
    , offsetY : Int
    , easing : Ease.Easing
    , axis : Axis
    , container : Container
    }


{-| Axis configuration for animation movement direction.

Use this to control whether your animation moves horizontally or vertically:

  - `Y` - Vertical scrolling (most common, default for page scrolling)
  - `X` - Horizontal scrolling (for sideways carousels or horizontal content)
  - `Both` - Both horizontal and vertical scrolling to reach the target element

Examples:

    -- Vertical document scrolling to an element (default behavior)
    scrollCmdWithConfig NoOp "my-section" defaultConfig

    -- Horizontal scrolling within a carousel container
    scrollCmdWithConfig "slide-3"
        NoOp
        { defaultConfig
            | axis = X
            , container = Container "carousel-container"
        }

    -- Both horizontal and vertical scrolling
    scrollCmdWithConfig "target-element"
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
    | Container String


{-| The default configuration which you can customize as needed.

    import Ease
    import SmoothMoveScroll exposing (Axis(..), Container(..), Timing(..), defaultConfig)

    newConfig =
        { defaultConfig
            | timing = Duration 500
            , offsetY = 20
            , easing = Ease.inOutCubic
            , axis = Both
            , container = Container "my-scroll-container"
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
        ( model, scrollCmd elementId ScrollComplete )

-}
scrollCmd : ElementId -> msg -> Cmd msg
scrollCmd elementId msg =
    scrollCmdWithConfig elementId msg defaultConfig


{-| Cmd-based scrolling with configuration and custom completion message.

    ScrollTo elementId ->
        ( model, scrollCmdWithConfig elementId ScrollComplete { defaultConfig | offsetY = 100 } )

-}
scrollCmdWithConfig : ElementId -> msg -> Config -> Cmd msg
scrollCmdWithConfig elementId msg config =
    scrollTaskWithConfig elementId config
        |> Task.attempt (always msg)


{-| Instantly jump to an element without animation.

Perfect for immediate navigation where you don't want smooth scrolling.

    JumpToSection sectionId ->
        ( model, jumpTo sectionId JumpComplete )

-}
jumpTo : ElementId -> msg -> Cmd msg
jumpTo elementId msg =
    jumpToWithConfig elementId msg defaultConfig


{-| Jump to an element with configuration (respects offset and axis settings).

    JumpToSection sectionId ->
        ( model, jumpToWithConfig sectionId JumpComplete { defaultConfig | offsetY = 50 } )

-}
jumpToWithConfig : ElementId -> msg -> Config -> Cmd msg
jumpToWithConfig elementId msg config =
    jumpToTask elementId config
        |> Task.attempt (always msg)


{-| Internal task for instant jumping - used by jumpTo functions.
-}
jumpToTask : ElementId -> Config -> Task Dom.Error ()
jumpToTask id config =
    let
        getViewport_ =
            getViewport config.container

        getContainerInfo_ =
            getContainerInfo config.container

        performJumpTask { scene, viewport } { element } container =
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
        ( model, Task.attempt HandleScrollError (scrollTask elementId) )

-}
scrollTask : ElementId -> Task Dom.Error (List ())
scrollTask elementId =
    scrollTaskWithConfig elementId defaultConfig


{-|

    ScrollTo elementId ->
        ( model, Task.attempt HandleScrollError (scrollTaskWithConfig elementId config) )

-}
scrollTaskWithConfig : ElementId -> Config -> Task Dom.Error (List ())
scrollTaskWithConfig id config =
    let
        getViewport_ =
            getViewport config.container

        getContainerInfo_ =
            getContainerInfo config.container

        performScrollTask { scene, viewport } { element } container =
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
        ( model, scrollToTop (Container "main-content") )

For document body scrolling:

    BackToTop ->
        ( model, scrollToTop DocumentBody )

-}
scrollToTop : Container -> msg -> Cmd msg
scrollToTop container msg =
    scrollToTopWithConfig container msg defaultConfig


{-| Scroll to the top of a container with custom configuration.

    BackToTop ->
        ( model, scrollToTopWithConfig (Container "main-content") NoOp { defaultConfig | timing = Duration 500 } )

-}
scrollToTopWithConfig : Container -> msg -> Config -> Cmd msg
scrollToTopWithConfig container msg config =
    let
        scrollToTopTask =
            case container of
                DocumentBody ->
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

                Container containerId ->
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
