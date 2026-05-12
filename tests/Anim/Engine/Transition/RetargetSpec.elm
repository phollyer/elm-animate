module Anim.Engine.Transition.RetargetSpec exposing (suite)

{-| End-to-end tests for `Transition.retarget`.

The Transition engine has no JavaScript-side runtime snapshot of the
currently rendered values, so `retarget` cannot smoothly continue an
in-flight transition. Instead it snaps to the freshly computed end values
with `transition: none` and marks the group complete - safe to call
repeatedly during a drag or resize without accumulating partial
transitions.
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
        [ propertyKeysTests
        , snapTests
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
-- propertyKeys (low-level state tracking)
-- ============================================================


propertyKeysTests : Test
propertyKeysTests =
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
-- SNAP SEMANTICS
-- ============================================================


snapTests : Test
snapTests =
    describe "retarget snaps to the new end values with transition: none"
        [ test "retarget on a running group emits transition: none" <|
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
                    |> Expect.equal (Just "none")
        , test "retarget sets the new value styles on the group" <|
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
                                    >> Translate.build
                                )
                       )
                    |> stylesFor "el"
                    |> Maybe.andThen (Styles.get "translate")
                    |> Maybe.map (String.contains "300px")
                    |> Expect.equal (Just True)
        , test "retarget on an idle group also snaps (transition: none)" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.retarget s <|
                                (Translate.for "el"
                                    >> Translate.toX 250
                                    >> Translate.build
                                )
                       )
                    |> transitionCss "el"
                    |> Expect.equal (Just "none")
        , test "transition-behavior is cleared so the snap is unambiguous" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Opacity.for "el"
                                    >> Opacity.to 1
                                    >> Opacity.duration 500
                                    >> Opacity.build
                                )
                       )
                    |> (\s ->
                            Transition.retarget s <|
                                (Opacity.for "el"
                                    >> Opacity.to 0
                                    >> Opacity.build
                                )
                       )
                    |> stylesFor "el"
                    |> Maybe.andThen (Styles.get "transition-behavior")
                    |> Expect.equal Nothing
        ]



-- ============================================================
-- SCOPING
-- ============================================================


scopingTests : Test
scopingTests =
    describe "retarget scoping"
        [ test "retarget on group B does not snap group A's in-flight transition" <|
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
                                (Translate.for "b"
                                    >> Translate.toX 300
                                    >> Translate.build
                                )
                       )
                    |> transitionCss "a"
                    |> Maybe.map (String.contains "500ms")
                    |> Expect.equal (Just True)
        , test "retarget snaps the touched group only" <|
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
                                (Translate.for "b"
                                    >> Translate.toX 300
                                    >> Translate.build
                                )
                       )
                    |> transitionCss "b"
                    |> Expect.equal (Just "none")
        ]
