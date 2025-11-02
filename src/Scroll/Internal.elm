module Scroll.Internal exposing
    ( calculateScrollIntoView
    , getClampedPositions
    , getContainerInfo
    , getTargetPositions
    , getViewport
    , timingToSpeed
    )

{-| Internal types and helper functions shared between Cmd and Task modules.
-}

import Browser.Dom as Dom
import Scroll exposing (..)
import Task exposing (Task)


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


{-| Calculate target scroll positions based on element position and container.
-}
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


{-| Calculate scroll positions to bring an element fully into view with minimal movement.
If element is larger than viewport, positions it at top-left.
-}
calculateScrollIntoView : { a | x : Float, y : Float, height : Float, width : Float } -> { a | x : Float, y : Float, height : Float, width : Float } -> { a | width : Float, height : Float } -> Maybe Dom.Element -> Config -> ( Float, Float )
calculateScrollIntoView element viewport scene containerInfo config =
    let
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
                let
                    leftEdge =
                        adjustedElementX

                    rightEdge =
                        adjustedElementX + elementWidth

                    viewportLeft =
                        currentScrollX

                    viewportRight =
                        currentScrollX + viewportWidth
                in
                if leftEdge >= viewportLeft && rightEdge <= viewportRight then
                    -- Already fully visible horizontally
                    currentScrollX

                else if leftEdge < viewportLeft then
                    -- Element cut off on left - scroll left to show left edge
                    leftEdge

                else
                    -- Element cut off on right - scroll right to show right edge
                    rightEdge - viewportWidth

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
    in
    ( newScrollX, newScrollY )
