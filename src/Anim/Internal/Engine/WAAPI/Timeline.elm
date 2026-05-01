module Anim.Internal.Engine.WAAPI.Timeline exposing (..)

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Engine.AnimGroups as AnimGroups
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
scroll : (Encode.Value -> Cmd msg) -> (AnimBuilder ForScroll -> AnimBuilder ForScroll) -> Cmd msg
scroll sendToPort buildAnimation =
    Builder.init [ buildAnimation ]
        |> encodeScroll
        |> sendToPort


{-| Fire-and-forget view-driven animation using a `ViewTimeline`.

Requires `asView` to have been called in the pipeline (enforced at compile time
via the `ForView` phantom type).

-}
view : (Encode.Value -> Cmd msg) -> (AnimBuilder ForView -> AnimBuilder ForView) -> Cmd msg
view sendToPort buildAnimation =
    Builder.init [ buildAnimation ]
        |> encodeView
        |> sendToPort


{-| The scroll/view axis.

  - `Block` - the block axis (vertical scrolling in most writing modes)
  - `Inline` - the inline axis (horizontal scrolling in most writing modes)

-}
type Axis
    = Block
    | Inline


{-| Set the scroll or view axis.

Only has an effect in a [`scroll`](#scroll) or [`view`](#view) pipeline — ignored for
standard document-driven animations.

Defaults to `Block` if not called.

-}
axis : Axis -> AnimBuilder mode -> AnimBuilder mode
axis axisValue =
    setScrollAxis
        (case axisValue of
            Block ->
                "block"

            Inline ->
                "inline"
        )


{-| Set the scroll source element ID and transition to ForScroll mode.
Passing `"document"` targets the viewport's root scrolling element.
-}
scrollSource : String -> AnimBuilder mode -> AnimBuilder { isScrollBased : () }
scrollSource =
    Builder.setScrollSource


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


{-| Set the target id used to resolve the DOM element for the current animation group.
-}
setTarget : String -> AnimBuilder mode -> AnimBuilder mode
setTarget =
    Builder.setAnimTarget


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


{-| Encode a scroll-driven animation using a `ScrollTimeline`.
Duration and delay are omitted — the timeline drives progress.
Iterations, direction, and easing are supported.
-}
encodeScroll : AnimBuilder ForScroll -> Encode.Value
encodeScroll builder =
    let
        processed =
            Builder.process builder

        source =
            Builder.getScrollSource builder
                |> Maybe.withDefault "document"

        axis_ =
            Builder.getScrollAxis builder
                |> Maybe.withDefault "block"

        elements =
            processed.groups
                |> AnimGroups.toList
                |> List.map
                    (\( animGroupName, config ) ->
                        ( animGroupName
                        , Encoder.encodeProcessedAnimGroupConfig
                            animGroupName
                            (Builder.getAnimTarget animGroupName builder |> Maybe.withDefault animGroupName)
                            Nothing
                            Nothing
                            config.properties
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "scrollDriven" )
        , ( "timeline"
          , Encode.object
                [ ( "type", Encode.string "scroll" )
                , ( "source", Encode.string source )
                , ( "axis", Encode.string axis_ )
                ]
          )
        , ( "elements", Encode.object elements )
        , ( "iterations", Encoder.encodeIterations processed.iterations )
        , ( "direction", Encoder.encodeAnimationDirection processed.animationDirection )
        ]


{-| Encode a view-driven animation using a `ViewTimeline`.
Duration and delay are omitted — the timeline drives progress.
Iterations, direction, and easing are supported.
-}
encodeView : AnimBuilder mode -> Encode.Value
encodeView builder =
    let
        processed =
            Builder.process builder

        axis_ =
            Builder.getScrollAxis builder
                |> Maybe.withDefault "block"

        timelineBase =
            [ ( "type", Encode.string "view" )
            , ( "axis", Encode.string axis_ )
            ]

        rangeFields =
            [ Builder.getViewRangeStart builder
                |> Maybe.map (\r -> ( "rangeStart", Encode.string r ))
            , Builder.getViewRangeEnd builder
                |> Maybe.map (\r -> ( "rangeEnd", Encode.string r ))
            ]
                |> List.filterMap identity

        elements =
            processed.groups
                |> AnimGroups.toList
                |> List.map
                    (\( animGroupName, config ) ->
                        ( animGroupName
                        , Encoder.encodeProcessedAnimGroupConfig
                            animGroupName
                            (Builder.getAnimTarget animGroupName builder |> Maybe.withDefault animGroupName)
                            Nothing
                            Nothing
                            config.properties
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "viewDriven" )
        , ( "timeline", Encode.object (timelineBase ++ rangeFields) )
        , ( "elements", Encode.object elements )
        , ( "iterations", Encoder.encodeIterations processed.iterations )
        , ( "direction", Encoder.encodeAnimationDirection processed.animationDirection )
        ]
