module Scroll.Internal exposing
    ( Container(..)
    , Direction(..)
    , animationSteps
    , animationStepsWithFrames
    , calculateScrollIntoView
    , getAxisDirection
    , getClampedPositions
    , getContainerInfo
    , getOffsetX
    , getOffsetY
    , getTargetPositions
    , getViewport
    , timingToSpeed
    )

{-| Internal types and helper functions shared between Cmd and Task modules.

This module contains code derived from SmoothScroll by Linus Schoemaker and Ruben Lie King (2019).
The animationSteps functions implement frame-based interpolation logic from the original work.

-}

import Browser.Dom as Dom
import Ease
import Scroll exposing (Axis(..), Config, Timing(..), XOffsetFloat, YOffsetFloat)
import Scroll.Types exposing (CoordinatePair, Distance, Frames)
import Task exposing (Task)


{-| Extract horizontal offset from axis configuration.
-}
getOffsetX : Axis -> XOffsetFloat
getOffsetX axis =
    case axis of
        X ->
            0.0

        Y ->
            0.0

        Both ->
            0.0

        XWithOffset offset ->
            offset

        YWithOffset _ ->
            0.0

        BothWithOffset offsetX _ ->
            offsetX


{-| Extract vertical offset from axis configuration.
-}
getOffsetY : Axis -> YOffsetFloat
getOffsetY axis =
    case axis of
        X ->
            0.0

        Y ->
            0.0

        Both ->
            0.0

        XWithOffset _ ->
            0.0

        YWithOffset offset ->
            offset

        BothWithOffset _ offsetY ->
            offsetY



-- TYPE ALIASES


{-| Type alias for container element IDs that define scrollable areas.
-}
type alias ContainerId =
    String


{-| Type for configuring which element to scroll within.

Use `DocumentBody` for scrolling the main document, or `Container containerId`
for scrolling within a specific container element.

-}
type Container
    = DocumentBody
    | Container ContainerId


{-| Extract horizontal offset from axis configuration.
-}
type Direction
    = XDirection
    | YDirection
    | BothDirection


{-| Extract the basic axis direction from axis configuration, ignoring offsets.
-}
getAxisDirection : Axis -> Direction
getAxisDirection axis =
    case axis of
        X ->
            XDirection

        Y ->
            YDirection

        Both ->
            BothDirection

        XWithOffset _ ->
            XDirection

        YWithOffset _ ->
            YDirection

        BothWithOffset _ _ ->
            BothDirection


{-| Convert timing configuration to speed divider for internal animation functions.
-}
timingToSpeed : Timing -> Distance -> Frames
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


{-| Get viewport information for a container.
-}
getViewport : Container -> Task Dom.Error Dom.Viewport
getViewport container =
    case container of
        DocumentBody ->
            Dom.getViewport

        Container containerNodeId ->
            Dom.getViewportOf containerNodeId


{-| Get container element information if it's a specific container.
-}
getContainerInfo : Container -> Task Dom.Error (Maybe Dom.Element)
getContainerInfo container =
    case container of
        DocumentBody ->
            Task.succeed Nothing

        Container containerNodeId ->
            Task.map Just (Dom.getElement containerNodeId)


{-| Calculate clamped scroll positions to ensure they stay within bounds.
-}
getClampedPositions : { a | x : Float, y : Float, height : Float, width : Float } -> { a | x : Float, y : Float, height : Float, width : Float } -> { a | width : Float, height : Float } -> Maybe Dom.Element -> Config -> CoordinatePair
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


{-| Calculate target scroll positions based on element position and container.
-}
getTargetPositions : { a | x : Float, y : Float } -> { a | x : Float, y : Float } -> Maybe Dom.Element -> Config -> CoordinatePair
getTargetPositions element viewport container config =
    let
        offsetX =
            getOffsetX config.axis

        offsetY =
            getOffsetY config.axis
    in
    case container of
        Nothing ->
            ( element.x - offsetX
            , element.y - offsetY
            )

        Just containerInfo ->
            ( viewport.x + element.x - offsetX - containerInfo.element.x
            , viewport.y + element.y - offsetY - containerInfo.element.y
            )


{-| Calculate scroll positions to bring an element fully into view with minimal movement.
If element is larger than viewport, positions it at top-left.
-}
calculateScrollIntoView : { a | x : Float, y : Float, height : Float, width : Float } -> { a | x : Float, y : Float, height : Float, width : Float } -> { a | width : Float, height : Float } -> Maybe Dom.Element -> Config -> CoordinatePair
calculateScrollIntoView element viewport scene containerInfo config =
    let
        offsetX =
            getOffsetX config.axis

        offsetY =
            getOffsetY config.axis

        -- Get element dimensions
        elementX =
            element.x

        elementY =
            element.y

        elementWidth =
            element.width

        elementHeight =
            element.height

        -- Get viewport dimensions and current scroll
        viewportX =
            viewport.x

        viewportY =
            viewport.y

        viewportWidth =
            viewport.width

        viewportHeight =
            viewport.height

        -- Adjust for container if present
        ( adjustedElementX, adjustedElementY ) =
            case containerInfo of
                Nothing ->
                    -- Document scrolling
                    ( elementX, elementY )

                Just containerEl ->
                    -- Container scrolling - element position relative to container
                    ( elementX - containerEl.element.x
                    , elementY - containerEl.element.y
                    )

        ( currentScrollX, currentScrollY ) =
            ( viewportX, viewportY )

        -- Calculate horizontal scroll position
        newScrollX =
            if elementWidth >= viewportWidth then
                -- Element wider than viewport - align to left edge
                adjustedElementX

            else
                -- Element fits in viewport - calculate minimal movement
                let
                    -- For document scrolling: element positions are absolute
                    -- For container scrolling: element positions are relative to container
                    elementLeft =
                        adjustedElementX

                    elementRight =
                        adjustedElementX + elementWidth

                    -- Current viewport bounds in document coordinates
                    viewportLeft =
                        currentScrollX

                    viewportRight =
                        currentScrollX + viewportWidth
                in
                if elementLeft >= viewportLeft && elementRight <= viewportRight then
                    -- Already fully visible horizontally - no change needed
                    currentScrollX

                else if elementLeft < viewportLeft then
                    -- Element extends beyond left edge - scroll left to show element at left edge
                    elementLeft

                else
                    -- Element extends beyond right edge - scroll right to show element at right edge
                    elementRight - viewportWidth

        -- Calculate vertical scroll position
        newScrollY =
            if elementHeight >= viewportHeight then
                -- Element taller than viewport - align to top edge
                adjustedElementY

            else
                let
                    topEdge =
                        adjustedElementY

                    bottomEdge =
                        adjustedElementY + elementHeight

                    viewportTop =
                        currentScrollY

                    viewportBottom =
                        currentScrollY + viewportHeight
                in
                if topEdge >= viewportTop && bottomEdge <= viewportBottom then
                    -- Already fully visible vertically
                    currentScrollY

                else if topEdge < viewportTop then
                    -- Element cut off on top - scroll up to show top edge
                    topEdge

                else
                    -- Element cut off on bottom - scroll down to show bottom edge
                    bottomEdge - viewportHeight

        -- Apply offsets and clamp to valid scroll ranges
        finalScrollX =
            (newScrollX - offsetX)
                |> max 0
                |> min (scene.width - viewport.width)

        finalScrollY =
            (newScrollY - offsetY)
                |> max 0
                |> min (scene.height - viewport.height)
    in
    ( finalScrollX, finalScrollY )


animationSteps : Int -> Ease.Easing -> Float -> Float -> List Float
animationSteps speed easing start stop =
    let
        diff =
            abs <| start - stop

        frames =
            max 1 <| round diff // speed

        framesFloat =
            toFloat frames

        weights =
            List.map (\i -> easing (toFloat i / framesFloat)) (List.range 0 frames)

        operator =
            if start > stop then
                (-)

            else
                (+)
    in
    if speed <= 0 || start == stop then
        []

    else
        List.map (\weight -> operator start (weight * diff)) weights


{-| Generate animation steps with a specific frame count for synchronized animations.
This ensures both X and Y animations have the same number of steps for smooth diagonal movement.
-}
animationStepsWithFrames : Int -> Ease.Easing -> Float -> Float -> List Float
animationStepsWithFrames frames easing start stop =
    let
        diff =
            abs <| start - stop

        framesFloat =
            toFloat frames

        weights =
            List.map (\i -> easing (toFloat i / framesFloat)) (List.range 0 frames)

        operator =
            if start > stop then
                (-)

            else
                (+)
    in
    if frames <= 0 || start == stop then
        []

    else
        List.map (\weight -> operator start (weight * diff)) weights
