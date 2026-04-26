module Scroll.Internal.Shared.Container exposing
    ( Container(..)
    , toContainer
    )


type Container
    = Document
    | Container ElementId


type alias ElementId =
    String


toContainer : String -> Container
toContainer id =
    if id == "document" then
        Document

    else
        Container id
