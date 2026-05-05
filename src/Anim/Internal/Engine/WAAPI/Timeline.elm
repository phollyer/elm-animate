module Anim.Internal.Engine.WAAPI.Timeline exposing
    ( ForDocument
    , setScrollAxis
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)


{-| Phantom mode for standard document-driven animations (the default).
-}
type alias ForDocument =
    {}


{-| Set the scroll/view axis ("block" or "inline"). Works in any mode.
-}
setScrollAxis : String -> AnimBuilder mode -> AnimBuilder mode
setScrollAxis =
    Builder.setScrollAxis
