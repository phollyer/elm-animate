module Anim.Engine.Transition.RetargetSpec exposing (suite)

{-| End-to-end tests for `Transition.retarget` and the
`continueFor`-driven timing inheritance it enables.
-}

import Anim.Engine.Transition as Transition
import Anim.Internal.Engine.CSS.CSS as CSS
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.Transition.AnimGroup as TAnimGroup
import Anim.Property.Opacity as Opacity
import Anim.Property.Translate as Translate
import Expect
import Motion.Easing exposing (Easing(..))
import Set
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Anim.Engine.Transition retarget"
        [ extractRunningTests
        , inheritanceTests
        , scopingTests
        ]



-- ============================================================
-- HELPERS
-- ============================================================


initState : Transition.AnimState
initState =
    Transition.init []


stylesFor : String -> Transition.AnimState -> Maybe Styles
stylesFor groupName (CSS.AnimState _ animGroups) =
    AnimGroups.get groupName animGroups
        |> Maybe.map TAnimGroup.getStyles


transitionCss : String -> Transition.AnimState -> Maybe String
transitionCss groupName state =
    stylesFor groupName state
        |> Maybe.andThen (Styles.get "transition")


propertyKeysFor : String -> Transition.AnimState -> Maybe (List String)
propertyKeysFor groupName (CSS.AnimState _ animGroups) =
    AnimGroups.get groupName animGroups
        |> Maybe.map (TAnimGroup.getPropertyKeys >> setToSortedList)


setToSortedList : Set.Set String -> List String
setToSortedList =
    Set.toList >> List.sort



-- ============================================================
-- extractRunningProperties (group-level)
-- ============================================================


extractRunningTests : Test
extractRunningTests =
    describe "property keys reported by AnimGroup"
        [ test "animate populates propertyKeys with every Builder key in the group" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Translate.for "el"
                                    >> Translate.toX 100
                                    >> Translate.duration 500
                                    >> Translate.build
                                    >> Opacity.for "el"
                                    >> Opacity.to 0.5
                                    >> Opacity.duration 500
                                    >> Opacity.build
                                )
                       )
                    |> propertyKeysFor "el"
                    |> Expect.equal (Just [ "opacity", "translate" ])
        , test "second animate on the same group merges existing + new keys" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Translate.for "el"
                                    >> Translate.toX 100
                                    >> Translate.duration 500
                                    >> Translate.build
                                )
                       )
                    |> (\s ->
                            Transition.animate s <|
                                (Opacity.for "el"
                                    >> Opacity.to 0.5
                                    >> Opacity.duration 500
                                    >> Opacity.build
                                )
                       )
                    |> propertyKeysFor "el"
                    |> Expect.equal (Just [ "opacity", "translate" ])
        ]



-- ============================================================
-- INHERITANCE
-- ============================================================


inheritanceTests : Test
inheritanceTests =
    describe "retarget + continueFor inherits in-flight timing"
        [ test "continueFor inherits duration when the property is mid-flight" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Translate.for "el"
                                    >> Translate.toX 100
                                    >> Translate.duration 500
                                    >> Translate.easing BounceOut
                                    >> Translate.build
                                )
                       )
                    |> (\s ->
                            Transition.retarget s <|
                                (Translate.continueFor "el"
                                    >> Translate.toX 300
                                    >> Translate.build
                                )
                       )
                    |> transitionCss "el"
                    |> Maybe.map (String.contains "500ms")
                    |> Expect.equal (Just True)
        , test "continueFor with retarget inherits easing" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Translate.for "el"
                                    >> Translate.toX 100
                                    >> Translate.duration 500
                                    >> Translate.easing BounceOut
                                    >> Translate.build
                                )
                       )
                    |> (\s ->
                            Transition.retarget s <|
                                (Translate.continueFor "el"
                                    >> Translate.toX 300
                                    >> Translate.build
                                )
                       )
                    |> transitionCss "el"
                    |> Maybe.map (String.contains "cubic-bezier")
                    |> Expect.equal (Just True)
        , test "explicit timing on continueFor wins over inherited timing" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Translate.for "el"
                                    >> Translate.toX 100
                                    >> Translate.duration 500
                                    >> Translate.build
                                )
                       )
                    |> (\s ->
                            Transition.retarget s <|
                                (Translate.continueFor "el"
                                    >> Translate.toX 300
                                    >> Translate.duration 1200
                                    >> Translate.build
                                )
                       )
                    |> transitionCss "el"
                    |> Maybe.map (String.contains "1200ms")
                    |> Expect.equal (Just True)
        , test "for (without continueFor) does NOT inherit even via retarget" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Translate.for "el"
                                    >> Translate.toX 100
                                    >> Translate.duration 500
                                    >> Translate.build
                                )
                       )
                    |> (\s ->
                            Transition.retarget s <|
                                (Translate.for "el"
                                    >> Translate.toX 300
                                    >> Translate.build
                                )
                       )
                    |> transitionCss "el"
                    |> Maybe.map (String.contains "500ms")
                    |> Expect.equal (Just False)
        , test "no-op retarget (continueFor with same target) preserves the in-flight transition" <|
            -- Regression: when a resize handler re-runs continueFor with the
            -- same target as the in-flight animation, the inherited speed
            -- yields a zero-distance => zero-duration transition. Without the
            -- no-op guard the engine emits `transition: none` which cancels
            -- the running CSS transition and snaps the element to the end
            -- value. The guard preserves the existing animation untouched.
            \_ ->
                let
                    afterAnimate =
                        Transition.animate initState <|
                            (Translate.for "el"
                                >> Translate.toX 200
                                >> Translate.speed 100
                                >> Translate.build
                            )

                    afterRetarget =
                        Transition.retarget afterAnimate <|
                            (Translate.continueFor "el"
                                >> Translate.toX 200
                                >> Translate.build
                            )
                in
                Expect.all
                    [ \_ ->
                        transitionCss "el" afterAnimate
                            |> Expect.equal (transitionCss "el" afterRetarget)
                    , \_ ->
                        stylesFor "el" afterAnimate
                            |> Maybe.andThen (Styles.get "translate")
                            |> Expect.equal
                                (stylesFor "el" afterRetarget
                                    |> Maybe.andThen (Styles.get "translate")
                                )
                    , \_ ->
                        transitionCss "el" afterRetarget
                            |> Maybe.map (String.contains "translate")
                            |> Expect.equal (Just True)
                    ]
                    ()
        ]



-- ============================================================
-- SCOPING
-- ============================================================


scopingTests : Test
scopingTests =
    describe "retarget scoping"
        [ test "running properties on group A do not leak to group B" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Translate.for "a"
                                    >> Translate.toX 100
                                    >> Translate.duration 500
                                    >> Translate.build
                                )
                       )
                    |> (\s ->
                            Transition.retarget s <|
                                (Translate.continueFor "b"
                                    >> Translate.toX 300
                                    >> Translate.build
                                )
                       )
                    |> transitionCss "b"
                    |> Maybe.map (String.contains "500ms")
                    |> Expect.equal (Just False)
        ]
