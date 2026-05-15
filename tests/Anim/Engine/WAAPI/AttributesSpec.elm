module Anim.Engine.WAAPI.AttributesSpec exposing (suite)

{-| Tests for `WAAPI.attributes` per-property style ownership.

`Generator.init` writes only to the per-group property snapshot, leaving
`propertyStates` empty for that property. `WAAPI.animate` _also_ writes
an entry into `propertyStates`, marking the property as JS-owned for
the lifetime of the group.

`WAAPI.attributes` consults `propertyStates` to decide which inline
styles to emit:

  - Independent slots (`opacity`, `perspective-origin`, `width`/`height`,
    custom, custom-color) are emitted only when the corresponding
    property has no entry in `propertyStates`.
  - The CSS `transform` slot is always rendered from the snapshot when
    the snapshot has any transform values. The snapshot tracks the
    latest value for every sub-property (init values, the start value
    merged in by `Generator.generateAnimation`, and per-frame
    `propertyUpdate` values from JS). Emitting unconditionally closes
    the one-frame gap that previously existed when ownership of any
    sub-property flipped to JS - the running CSS animation effect
    supersedes inline values during playback, and `commitAnimatedStyles`
    writes the final WAAPI value back to inline before `cancel()`.
  - The `data-anim-target` attribute is always emitted.

-}

import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Opacity as Opacity
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Expect
import Html
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "WAAPI.attributes ownership"
        [ initOnlyTests
        , animatedTests
        , mixedKindTests
        , transformSlotTests
        , dataAttrTests
        ]



-- ============================================================
-- HELPERS
-- ============================================================


type Msg
    = NoOp


fakeCommandPort : Encode.Value -> Cmd Msg
fakeCommandPort _ =
    Cmd.none


fakeSubscriptionPort : (Decode.Value -> Msg) -> Sub Msg
fakeSubscriptionPort _ =
    Sub.none


initWith : List (WAAPI.EngineBuilder -> WAAPI.EngineBuilder) -> WAAPI.AnimState Msg
initWith =
    WAAPI.init fakeCommandPort fakeSubscriptionPort


animate : (WAAPI.EngineBuilder -> WAAPI.EngineBuilder) -> WAAPI.AnimState Msg -> WAAPI.AnimState Msg
animate config state =
    WAAPI.animate state config |> Tuple.first


query : WAAPI.AnimState Msg -> Query.Single Msg
query state =
    Html.div (WAAPI.attributes "el" state) []
        |> Query.fromHtml



-- ============================================================
-- INIT-ONLY PROPERTIES (Elm-owned)
-- ============================================================


initOnlyTests : Test
initOnlyTests =
    describe "init-only properties are rendered as inline styles"
        [ test "Translate.initX emits transform: translate3d(...)" <|
            \_ ->
                initWith [ Translate.initX "el" 100 ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(100px, 0px, 0px)" ]
        , test "Opacity.init emits opacity" <|
            \_ ->
                initWith [ Opacity.init "el" 0.5 ]
                    |> query
                    |> Query.has [ Selector.style "opacity" "0.5" ]
        , test "Size.init emits width and height" <|
            \_ ->
                initWith [ Size.init "el" 120 ]
                    |> query
                    |> Expect.all
                        [ Query.has [ Selector.style "width" "120px" ]
                        , Query.has [ Selector.style "height" "120px" ]
                        ]
        , test "PerspectiveOrigin.initPercent emits perspective-origin" <|
            \_ ->
                initWith [ PerspectiveOrigin.initPercent "el" 50 75 ]
                    |> query
                    |> Query.has [ Selector.style "perspective-origin" "50% 75%" ]
        ]



-- ============================================================
-- ANIMATED PROPERTIES (JS-owned, Elm omits)
-- ============================================================


animatedTests : Test
animatedTests =
    describe "animated properties"
        [ test "animate Opacity → opacity inline suppressed" <|
            \_ ->
                initWith []
                    |> animate
                        (Opacity.for "el"
                            >> Opacity.to 0.5
                            >> Opacity.build
                        )
                    |> query
                    |> Query.hasNot [ Selector.style "opacity" "0.5" ]
        , test "animate Translate → transform inline rendered from snapshot start value" <|
            \_ ->
                -- The snapshot is seeded with the animation's start value
                -- (`Generator.generateAnimation` merges `animationBounds.start`
                -- into the snapshot). Elm renders that value so the inline
                -- `transform` is never empty when the bridge takes over.
                initWith []
                    |> animate
                        (Translate.for "el"
                            >> Translate.toX 100
                            >> Translate.build
                        )
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(0px, 0px, 0px)" ]
        , test "animate Rotate → transform inline rendered from snapshot start value" <|
            \_ ->
                initWith []
                    |> animate
                        (Rotate.for "el"
                            >> Rotate.toZ 360
                            >> Rotate.build
                        )
                    |> query
                    |> Query.has [ Selector.style "transform" "rotateZ(0deg)" ]
        , test "data-anim-target is still emitted for animated groups" <|
            \_ ->
                initWith []
                    |> animate
                        (Opacity.for "el"
                            >> Opacity.to 0.5
                            >> Opacity.build
                        )
                    |> query
                    |> Query.has [ Selector.attribute (Html.Attributes.attribute "data-anim-target" "el") ]
        ]



-- ============================================================
-- MIXED KINDS (one Elm-owned, one JS-owned)
-- ============================================================


mixedKindTests : Test
mixedKindTests =
    describe "mixed kinds: each property's ownership is independent"
        [ test "init-only Translate + animated Opacity → transform inline, no opacity inline" <|
            \_ ->
                initWith [ Translate.initX "el" 100 ]
                    |> animate
                        (Opacity.for "el"
                            >> Opacity.to 0.5
                            >> Opacity.build
                        )
                    |> query
                    |> Expect.all
                        [ Query.has [ Selector.style "transform" "translate3d(100px, 0px, 0px)" ]
                        , Query.hasNot [ Selector.style "opacity" "0.5" ]
                        ]
        , test "init-only Opacity + animated Translate → opacity inline, transform inline rendered from snapshot start value" <|
            \_ ->
                initWith [ Opacity.init "el" 0.5 ]
                    |> animate
                        (Translate.for "el"
                            >> Translate.toX 100
                            >> Translate.build
                        )
                    |> query
                    |> Expect.all
                        [ Query.has [ Selector.style "opacity" "0.5" ]
                        , Query.has [ Selector.style "transform" "translate3d(0px, 0px, 0px)" ]
                        ]
        ]



-- ============================================================
-- TRANSFORM SLOT (monolithic)
-- ============================================================


transformSlotTests : Test
transformSlotTests =
    describe "transform slot is rendered from the snapshot regardless of ownership"
        [ test "init-only Translate + animated Rotate → combined transform inline (translate from init, rotate from animation start)" <|
            \_ ->
                -- The snapshot retains the init translate (x=100) and is
                -- merged with the rotate animation's start value (0deg).
                -- Emitting the combined transform closes the one-frame gap
                -- that previously caused the element to collapse to identity
                -- between Elm's render and the JS bridge's inline write.
                initWith [ Translate.initX "el" 100 ]
                    |> animate
                        (Rotate.for "el"
                            >> Rotate.toZ 360
                            >> Rotate.build
                        )
                    |> query
                    |> Query.has
                        [ Selector.style "transform"
                            "translate3d(100px, 0px, 0px) rotateZ(0deg)"
                        ]
        , test "init-only Opacity + init-only Translate (no transform animated) → transform inline" <|
            \_ ->
                initWith
                    [ Opacity.init "el" 0.5
                    , Translate.initX "el" 100
                    ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(100px, 0px, 0px)" ]
        , test "no transform configured at all → no transform inline" <|
            \_ ->
                initWith [ Opacity.init "el" 0.5 ]
                    |> query
                    |> Query.hasNot [ Selector.style "transform" "" ]
        , test "regression: animating Rotate after Translate.initZ keeps z translate in inline transform (no flicker)" <|
            -- Regression for the Animate3D flicker bug. Previously, when an
            -- animation gave JS ownership of any transform sub-property (here,
            -- rotate), Elm dropped the entire `transform` attribute on that
            -- render and the browser could paint the element with no transform
            -- (collapsing perspective-translated elements to identity / z=0)
            -- before the JS bridge wrote inline styles back. Re-emitting from
            -- the snapshot must preserve the init translate values so the
            -- element never visually snaps.
            \_ ->
                initWith [ Translate.initZ "el" 200 ]
                    |> animate
                        (Rotate.for "el"
                            >> Rotate.toX 360
                            >> Rotate.build
                        )
                    |> query
                    |> Query.has
                        [ Selector.style "transform"
                            "translate3d(0px, 0px, 200px) rotateZ(0deg)"
                        ]
        ]



-- ============================================================
-- data-anim-target
-- ============================================================


dataAttrTests : Test
dataAttrTests =
    describe "data-anim-target"
        [ test "is emitted for unknown groups (no init, no animate)" <|
            \_ ->
                initWith []
                    |> query
                    |> Query.has [ Selector.attribute (Html.Attributes.attribute "data-anim-target" "el") ]
        , test "is emitted for init-only groups" <|
            \_ ->
                initWith [ Opacity.init "el" 0.5 ]
                    |> query
                    |> Query.has [ Selector.attribute (Html.Attributes.attribute "data-anim-target" "el") ]
        ]
