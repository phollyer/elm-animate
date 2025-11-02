module Scroll.Internal exposing
    ( getClampedPositions
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
