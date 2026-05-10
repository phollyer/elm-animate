module Anim.Property.SpringSpec exposing (suite)

{-| Verifies that every property module that exposes `spring`
correctly threads the spring through the builder pipeline and into
its `ProcessedAnimationConfig`.

The Sub engine already consumes `config.spring` for any property
type, so this is the surface-level proof that the per-property
setters added in commit 4 are wired up.

-}

import Anim.Extra.Color as Color
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Property.Custom as Custom exposing (Property(..))
import Anim.Property.CustomColor as CustomColor exposing (ColorProperty(..))
import Anim.Property.Opacity as Opacity
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Easing exposing (Easing(..))
import Expect
import Motion.Spring as Spring
import Test exposing (Test, describe, test)



-- ============================================================
-- HELPERS
-- ============================================================


initBuilder : Builder.AnimBuilder mode
initBuilder =
    Builder.init []


{-| Pull every per-property `spring` field out of the processed
builder, in source order. A flat list of `Maybe Spring` is enough
for the assertions below \u2014 we don't care which constructor each
came from.
-}
collectSprings : Builder.AnimBuilder mode -> List (Maybe Spring.Spring)
collectSprings builder =
    let
        groupSprings group =
            group.properties
                |> List.map propertySpring
    in
    Builder.process builder
        |> .groups
        |> AnimGroups.toList
        |> List.concatMap (Tuple.second >> groupSprings)


propertySpring : Builder.ProcessedPropertyConfig -> Maybe Spring.Spring
propertySpring p =
    case p of
        Builder.ProcessedOpacityConfig cfg ->
            cfg.spring

        Builder.ProcessedTranslateConfig cfg ->
            cfg.spring

        Builder.ProcessedScaleConfig cfg ->
            cfg.spring

        Builder.ProcessedRotateConfig cfg ->
            cfg.spring

        Builder.ProcessedSkewConfig cfg ->
            cfg.spring

        Builder.ProcessedSizeConfig cfg ->
            cfg.spring

        Builder.ProcessedPerspectiveOriginConfig cfg ->
            cfg.spring

        Builder.ProcessedCustomPropertyConfig _ _ cfg ->
            cfg.spring

        Builder.ProcessedCustomColorPropertyConfig _ cfg ->
            cfg.spring


propertyEasing : Builder.ProcessedPropertyConfig -> Maybe Easing
propertyEasing p =
    case p of
        Builder.ProcessedOpacityConfig cfg ->
            Just cfg.easing

        Builder.ProcessedTranslateConfig cfg ->
            Just cfg.easing

        Builder.ProcessedScaleConfig cfg ->
            Just cfg.easing

        Builder.ProcessedRotateConfig cfg ->
            Just cfg.easing

        Builder.ProcessedSkewConfig cfg ->
            Just cfg.easing

        Builder.ProcessedSizeConfig cfg ->
            Just cfg.easing

        Builder.ProcessedPerspectiveOriginConfig cfg ->
            Just cfg.easing

        Builder.ProcessedCustomPropertyConfig _ _ cfg ->
            Just cfg.easing

        Builder.ProcessedCustomColorPropertyConfig _ cfg ->
            Just cfg.easing


collectEasings : Builder.AnimBuilder mode -> List (Maybe Easing)
collectEasings builder =
    Builder.process builder
        |> .groups
        |> AnimGroups.toList
        |> List.concatMap (Tuple.second >> .properties)
        |> List.map propertyEasing



-- ============================================================
-- SUITE
-- ============================================================


suite : Test
suite =
    describe "Anim.Property.* spring setters"
        [ propagationTests
        , mutualExclusionTests
        ]



-- ============================================================
-- PROPAGATION
-- ============================================================


{-| For every property module, verify that calling its `spring`
setter populates the `ProcessedAnimationConfig.spring` field.
-}
propagationTests : Test
propagationTests =
    describe "spring is threaded into the ProcessedAnimationConfig"
        [ test "Translate.spring" <|
            \_ ->
                initBuilder
                    |> (Translate.for "el"
                            >> Translate.toX 100
                            >> Translate.spring Spring.wobbly
                            >> Translate.build
                       )
                    |> collectSprings
                    |> Expect.equal [ Just Spring.wobbly ]
        , test "Scale.spring" <|
            \_ ->
                initBuilder
                    |> (Scale.for "el"
                            >> Scale.to 2
                            >> Scale.spring Spring.gentle
                            >> Scale.build
                       )
                    |> collectSprings
                    |> Expect.equal [ Just Spring.gentle ]
        , test "Rotate.spring" <|
            \_ ->
                initBuilder
                    |> (Rotate.for "el"
                            >> Rotate.toZ 180
                            >> Rotate.spring Spring.stiff
                            >> Rotate.build
                       )
                    |> collectSprings
                    |> Expect.equal [ Just Spring.stiff ]
        , test "Skew.spring" <|
            \_ ->
                initBuilder
                    |> (Skew.for "el"
                            >> Skew.toXY 12 0
                            >> Skew.spring Spring.slow
                            >> Skew.build
                       )
                    |> collectSprings
                    |> Expect.equal [ Just Spring.slow ]
        , test "Size.spring" <|
            \_ ->
                initBuilder
                    |> (Size.for "el"
                            >> Size.toHW 200 100
                            >> Size.spring Spring.noWobble
                            >> Size.build
                       )
                    |> collectSprings
                    |> Expect.equal [ Just Spring.noWobble ]
        , test "PerspectiveOrigin.spring" <|
            \_ ->
                initBuilder
                    |> (PerspectiveOrigin.for "el"
                            >> PerspectiveOrigin.to 200
                            >> PerspectiveOrigin.spring Spring.wobbly
                            >> PerspectiveOrigin.build
                       )
                    |> collectSprings
                    |> Expect.equal [ Just Spring.wobbly ]
        , test "Custom.spring" <|
            \_ ->
                initBuilder
                    |> (Custom.for "el" (BorderRadius "px")
                            >> Custom.to 16
                            >> Custom.spring Spring.gentle
                            >> Custom.build
                       )
                    |> collectSprings
                    |> Expect.equal [ Just Spring.gentle ]
        , test "CustomColor.spring" <|
            \_ ->
                initBuilder
                    |> (CustomColor.for "el" BackgroundColor
                            >> CustomColor.to (Color.rgb 255 0 0)
                            >> CustomColor.spring Spring.stiff
                            >> CustomColor.build
                       )
                    |> collectSprings
                    |> Expect.equal [ Just Spring.stiff ]
        ]



-- ============================================================
-- MUTUAL EXCLUSION
-- ============================================================


{-| Spot-check that the per-property mutual-exclusion behaviour
inherited from `PropertyBuilder.spring` actually fires for the new
setters. Opacity is exhaustively covered in
`Anim.Engine.Sub.SpringSpec`; here we just sanity-check one of each
"shape" of internal builder.
-}
mutualExclusionTests : Test
mutualExclusionTests =
    describe "per-property mutual exclusion"
        [ test "Translate.spring after Translate.easing wins" <|
            \_ ->
                initBuilder
                    |> (Translate.for "el"
                            >> Translate.toX 100
                            >> Translate.easing EaseInOut
                            >> Translate.spring Spring.wobbly
                            >> Translate.build
                       )
                    |> collectSprings
                    |> Expect.equal [ Just Spring.wobbly ]
        , test "Translate.easing after Translate.spring wins" <|
            \_ ->
                let
                    builder =
                        initBuilder
                            |> (Translate.for "el"
                                    >> Translate.toX 100
                                    >> Translate.spring Spring.wobbly
                                    >> Translate.easing EaseInOut
                                    >> Translate.build
                               )
                in
                ( collectSprings builder, collectEasings builder )
                    |> Expect.equal ( [ Nothing ], [ Just EaseInOut ] )
        , test "PerspectiveOrigin.spring after PerspectiveOrigin.easing wins" <|
            \_ ->
                initBuilder
                    |> (PerspectiveOrigin.for "el"
                            >> PerspectiveOrigin.to 200
                            >> PerspectiveOrigin.easing EaseInOut
                            >> PerspectiveOrigin.spring Spring.wobbly
                            >> PerspectiveOrigin.build
                       )
                    |> collectSprings
                    |> Expect.equal [ Just Spring.wobbly ]
        , test "Custom.spring after Custom.easing wins" <|
            \_ ->
                initBuilder
                    |> (Custom.for "el" (BorderRadius "px")
                            >> Custom.to 16
                            >> Custom.easing EaseInOut
                            >> Custom.spring Spring.wobbly
                            >> Custom.build
                       )
                    |> collectSprings
                    |> Expect.equal [ Just Spring.wobbly ]
        , test "CustomColor.spring after CustomColor.easing wins" <|
            \_ ->
                initBuilder
                    |> (CustomColor.for "el" BackgroundColor
                            >> CustomColor.to (Color.rgb 255 0 0)
                            >> CustomColor.easing EaseInOut
                            >> CustomColor.spring Spring.wobbly
                            >> CustomColor.build
                       )
                    |> collectSprings
                    |> Expect.equal [ Just Spring.wobbly ]
        ]
