module Anim.Internal.Engine.WAAPI.Timeline exposing
    ( ForDocument
    , ForScroll
    , ForView
    , asView
    , rangeEnd
    , rangeStart
    , scroll
    , setScrollAxis
    , view
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Json.Encode as Encode


{-| Phantom mode for standard document-driven animations (the default).
-}
type alias ForDocument =
    {}


{-| Phantom mode for scroll-driven animations. Requires calling `scrollSource`.
-}
type alias ForScroll =
    { isScrollBased : () }


{-| Phantom mode for view-driven animations. Requires calling `asView`.
-}
type alias ForView =
    { isViewBased : () }


{-| Fire-and-forget scroll-driven animation using a `ScrollTimeline`.

Requires `scrollSource` to have been called in the pipeline (enforced at compile
time via the `ForScroll` phantom type).

-}
scroll : (Encode.Value -> Cmd msg) -> String -> (AnimBuilder ForScroll -> AnimBuilder ForScroll) -> Cmd msg
scroll sendToPort containerId buildAnimation =
    Builder.init [ buildAnimation ]
        |> Builder.setScrollSource containerId
        |> Encoder.encodeScroll
        |> sendToPort


{-| Fire-and-forget view-driven animation using a `ViewTimeline`.

Requires `asView` to have been called in the pipeline (enforced at compile time
via the `ForView` phantom type).

-}
view : (Encode.Value -> Cmd msg) -> (AnimBuilder ForView -> AnimBuilder ForView) -> Cmd msg
view sendToPort buildAnimation =
    Builder.init [ buildAnimation ]
        |> Encoder.encodeView
        |> sendToPort


{-| Transition the builder to ForView mode.
The animated element itself is used as the ViewTimeline subject by the JS companion.
-}
asView : AnimBuilder mode -> AnimBuilder { isViewBased : () }
asView =
    Builder.transitionMode


{-| Set the scroll/view axis ("block" or "inline"). Works in any mode.
-}
setScrollAxis : String -> AnimBuilder mode -> AnimBuilder mode
setScrollAxis =
    Builder.setScrollAxis


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
