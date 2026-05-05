module Anim.Internal.Engine.WAAPI.ViewTimeline exposing
    ( AnimMsg(..)
    , ForView
    , asView
    , rangeEnd
    , rangeStart
    , view
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Json.Decode as Decode
import Json.Encode as Encode


type AnimMsg
    = JavascriptUpdate Decode.Value


{-| Phantom mode for view-driven animations.
-}
type alias ForView =
    { isViewBased : () }


{-| Fire-and-forget view-driven animation using a `ViewTimeline`.
-}
view : (Encode.Value -> Cmd msg) -> (AnimBuilder ForView -> AnimBuilder ForView) -> Cmd msg
view sendToPort buildAnimation =
    Builder.init [ buildAnimation ]
        |> Encoder.encodeView
        |> sendToPort


{-| Transition the builder to ForView mode.
-}
asView : AnimBuilder mode -> AnimBuilder { isViewBased : () }
asView =
    Builder.transitionMode


{-| Set the ViewTimeline rangeStart value. Only valid in ForView mode.
-}
rangeStart : String -> AnimBuilder { r | isViewBased : () } -> AnimBuilder { r | isViewBased : () }
rangeStart =
    Builder.setViewRangeStart


{-| Set the ViewTimeline rangeEnd value. Only valid in ForView mode.
-}
rangeEnd : String -> AnimBuilder { r | isViewBased : () } -> AnimBuilder { r | isViewBased : () }
rangeEnd =
    Builder.setViewRangeEnd
