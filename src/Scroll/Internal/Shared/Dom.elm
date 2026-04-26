module Scroll.Internal.Shared.Dom exposing
    ( Element
    , Viewport
    , getContainerInfo
    , getElement
    , getViewport
    , setViewport
    )

import Browser.Dom as Dom
import Scroll.Internal.Shared.Container exposing (Container(..))
import Task exposing (Task)


type alias Element =
    Dom.Element


type alias Viewport =
    Dom.Viewport


getElement : String -> Task Dom.Error Element
getElement =
    Dom.getElement


getViewport : Container -> Task Dom.Error Dom.Viewport
getViewport container =
    case container of
        Document ->
            Dom.getViewport

        Container containerNodeId ->
            Dom.getViewportOf containerNodeId


setViewport : Container -> Float -> Float -> Task Dom.Error ()
setViewport container x y =
    case container of
        Document ->
            Dom.setViewport x y

        Container containerNodeId ->
            Dom.setViewportOf containerNodeId x y


getContainerInfo : Container -> Task Dom.Error (Maybe Dom.Element)
getContainerInfo container =
    case container of
        Document ->
            Task.succeed Nothing

        Container containerNodeId ->
            Task.map Just (Dom.getElement containerNodeId)
