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
  - The CSS `transform` slot is monolithic. The combined `transform`
    string is emitted only when **none** of `translate`, `rotate`,
    `scale`, `skew` appear in `propertyStates`. If any one is JS-owned,
    the whole slot is suppressed.
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
    describe "animated properties have inline styles suppressed"
        [ test "animate Opacity → no opacity inline" <|
            \_ ->
                initWith []
                    |> animate
                        (Opacity.for "el"
                            >> Opacity.to 0.5
                            >> Opacity.build
                        )
                    |> query
                    |> Query.hasNot [ Selector.style "opacity" "0.5" ]
        , test "animate Translate → no transform inline" <|
            \_ ->
                initWith []
                    |> animate
                        (Translate.for "el"
                            >> Translate.toX 100
                            >> Translate.build
                        )
                    |> query
                    |> Query.hasNot [ Selector.style "transform" "translate3d(100px, 0px, 0px)" ]
        , test "animate Rotate → no transform inline" <|
            \_ ->
                initWith []
                    |> animate
                        (Rotate.for "el"
                            >> Rotate.toZ 360
                            >> Rotate.build
                        )
                    |> query
                    |> Query.hasNot [ Selector.style "transform" "rotateX(0deg) rotateY(0deg) rotateZ(360deg)" ]
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
        , test "init-only Opacity + animated Translate → opacity inline, no transform inline" <|
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
                        , Query.hasNot [ Selector.style "transform" "translate3d(100px, 0px, 0px)" ]
                        ]
        ]



-- ============================================================
-- TRANSFORM SLOT (monolithic)
-- ============================================================


transformSlotTests : Test
transformSlotTests =
    describe "transform slot is monolithic: any animated transform sub-property suppresses the whole slot"
        [ test "init-only Translate + animated Rotate → transform omitted entirely" <|
            \_ ->
                initWith [ Translate.initX "el" 100 ]
                    |> animate
                        (Rotate.for "el"
                            >> Rotate.toZ 360
                            >> Rotate.build
                        )
                    |> query
                    |> Expect.all
                        -- Even though translate is Elm-owned, rotate's entry
                        -- in propertyStates means JS owns the transform slot.
                        -- Elm must not write `transform` at all, otherwise
                        -- it would clobber the JS-managed rotate value.
                        [ Query.hasNot [ Selector.style "transform" "translate3d(100px, 0px, 0px)" ]
                        , Query.hasNot
                            [ Selector.style "transform"
                                "translate3d(100px, 0px, 0px) rotateX(0deg) rotateY(0deg) rotateZ(360deg)"
                            ]
                        ]
        , test "init-only Opacity + init-only Translate (no transform animated) → transform inline" <|
            \_ ->
                initWith
                    [ Opacity.init "el" 0.5
                    , Translate.initX "el" 100
                    ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(100px, 0px, 0px)" ]
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
