module Anim.Internal.Engine.WAAPI.ScrollTimeline exposing
    ( AnimMsg(..)
    , ForScroll
    , scroll
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Json.Decode as Decode
import Json.Encode as Encode


type AnimMsg
    = JavascriptUpdate Decode.Value


{-| Phantom mode for scroll-driven animations.
-}
type alias ForScroll =
    { isScrollBased : () }


{-| Fire-and-forget scroll-driven animation using a `ScrollTimeline`.
-}
scroll : (Encode.Value -> Cmd msg) -> String -> (AnimBuilder ForScroll -> AnimBuilder ForScroll) -> Cmd msg
scroll sendToPort containerId buildAnimation =
    Builder.init [ buildAnimation ]
        |> Builder.setScrollSource containerId
        |> Encoder.encodeScroll
        |> sendToPort
