module Anim.Internal.Engine.Transition.AnimGroup exposing
    ( AnimGroup
    , getDiscreteEntry
    , getDiscreteExit
    , getPropertyKeys
    , getStartingStyles
    , getStyles
    , init
    , isActive
    , isCancelled
    , isComplete
    , isRunning
    , mergeStyles
    , setDiscreteEntry
    , setDiscreteExit
    , setPlayState
    , setPropertyKeys
    , setStartingStyles
    , setStyles
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Engine.Shared.PlayState as PlayState exposing (PlayState)
import Dict exposing (Dict)
import Set exposing (Set)



-- ============================================================
-- TYPES
-- ============================================================


type AnimGroup
    = AnimGroup
        { styles : Styles
        , playState : PlayState
        , discreteEntry : Dict String String
        , discreteExit : Dict String Builder.DiscreteExitProperty
        , startingStyles : List String
        , propertyKeys : Set String
        }



-- ============================================================
-- INITIALIZE
-- ============================================================


init : AnimGroup
init =
    AnimGroup
        { styles = Styles.empty
        , playState = PlayState.NotStarted
        , discreteEntry = Dict.empty
        , discreteExit = Dict.empty
        , startingStyles = []
        , propertyKeys = Set.empty
        }



-- ============================================================
-- GETTERS
-- ============================================================


getStyles : AnimGroup -> Styles
getStyles (AnimGroup animGroup) =
    Dict.foldl Styles.insert animGroup.styles animGroup.discreteEntry


getDiscreteEntry : AnimGroup -> Dict String String
getDiscreteEntry (AnimGroup animGroup) =
    animGroup.discreteEntry


getDiscreteExit : AnimGroup -> Dict String Builder.DiscreteExitProperty
getDiscreteExit (AnimGroup animGroup) =
    animGroup.discreteExit


{-| Get the set of Builder property keys (e.g. "translate", "opacity",
"custom:left") currently animated by this group. Used by `retarget` to
report which properties are mid-flight.
-}
getPropertyKeys : AnimGroup -> Set String
getPropertyKeys (AnimGroup animGroup) =
    animGroup.propertyKeys



-- ============================================================
-- SETTERS
-- ============================================================


setDiscreteEntry : Dict String String -> AnimGroup -> AnimGroup
setDiscreteEntry entry (AnimGroup animGroup) =
    AnimGroup { animGroup | discreteEntry = entry }


setDiscreteExit : Dict String Builder.DiscreteExitProperty -> AnimGroup -> AnimGroup
setDiscreteExit exit (AnimGroup animGroup) =
    AnimGroup { animGroup | discreteExit = exit }


getStartingStyles : AnimGroup -> List String
getStartingStyles (AnimGroup animGroup) =
    animGroup.startingStyles


setStartingStyles : List String -> AnimGroup -> AnimGroup
setStartingStyles styles (AnimGroup animGroup) =
    AnimGroup { animGroup | startingStyles = styles }


setStyles : Styles -> AnimGroup -> AnimGroup
setStyles styles (AnimGroup animGroup) =
    AnimGroup { animGroup | styles = styles }


{-| Replace the set of Builder property keys associated with this group.
-}
setPropertyKeys : Set String -> AnimGroup -> AnimGroup
setPropertyKeys keys (AnimGroup animGroup) =
    AnimGroup { animGroup | propertyKeys = keys }



-- ============================================================
-- MERGE
-- ============================================================


mergeStyles :
    AnimGroup
    -> AnimGroup
    -> List String
    -> AnimGroup
mergeStyles (AnimGroup newGroup) (AnimGroup existingGroup) newCssProps =
    let
        isMetaStyle key =
            key == "transition" || key == "transition-behavior"

        existingStyles =
            existingGroup.styles
                |> Styles.remove "transition"
                |> Styles.remove "transition-behavior"

        newPropertyStyles =
            Styles.filter (\key _ -> not (isMetaStyle key)) newGroup.styles

        splitTransitionParts value =
            if value == "none" || String.isEmpty value then
                []

            else
                splitRespectingParens value

        transitionPartCssProp part =
            String.split " " (String.trim part)
                |> List.head
                |> Maybe.withDefault ""

        oldTransitionValue =
            Styles.get "transition" existingGroup.styles
                |> Maybe.withDefault "none"

        newTransitionValue =
            Styles.get "transition" newGroup.styles
                |> Maybe.withDefault "none"

        preservedOldTransitions =
            splitTransitionParts oldTransitionValue
                |> List.filter
                    (\part -> not (List.member (transitionPartCssProp part) newCssProps))

        mergedTransition =
            case preservedOldTransitions ++ splitTransitionParts newTransitionValue of
                [] ->
                    "none"

                parts ->
                    String.join ", " parts

        hasTransitionBehavior =
            Styles.member "transition-behavior" existingGroup.styles
                || Styles.member "transition-behavior" newGroup.styles

        styles =
            Styles.merge newPropertyStyles existingStyles
                |> Styles.insert "transition" mergedTransition
                |> (\s ->
                        if hasTransitionBehavior then
                            Styles.insert "transition-behavior" "allow-discrete" s

                        else
                            s
                   )

        mergedDiscreteEntry =
            Dict.union newGroup.discreteEntry existingGroup.discreteEntry

        mergedDiscreteExit =
            Dict.union newGroup.discreteExit existingGroup.discreteExit
    in
    AnimGroup
        { styles = styles
        , playState = newGroup.playState
        , discreteEntry = mergedDiscreteEntry
        , discreteExit = mergedDiscreteExit
        , startingStyles = newGroup.startingStyles
        , propertyKeys = Set.union newGroup.propertyKeys existingGroup.propertyKeys
        }



-- ============================================================
-- HELPERS
-- ============================================================


{-| Split a CSS transition value string by commas, but only at the top level
(not inside parentheses like `cubic-bezier(0.175, 0.885, 0.32, 1.275)`).
-}
splitRespectingParens : String -> List String
splitRespectingParens value =
    let
        chars =
            String.toList value

        helper remaining depth current acc =
            case remaining of
                [] ->
                    let
                        part =
                            String.fromList (List.reverse current)
                    in
                    if String.isEmpty (String.trim part) then
                        List.reverse acc

                    else
                        List.reverse (part :: acc)

                '(' :: rest ->
                    helper rest (depth + 1) ('(' :: current) acc

                ')' :: rest ->
                    helper rest (max 0 (depth - 1)) (')' :: current) acc

                ',' :: rest ->
                    if depth == 0 then
                        let
                            part =
                                String.fromList (List.reverse current)

                            trimmedRest =
                                case rest of
                                    ' ' :: afterSpace ->
                                        afterSpace

                                    _ ->
                                        rest
                        in
                        helper trimmedRest 0 [] (part :: acc)

                    else
                        helper rest depth (',' :: current) acc

                c :: rest ->
                    helper rest depth (c :: current) acc
    in
    helper chars 0 [] []



-- ============================================================
-- PLAY STATE
-- ============================================================


setPlayState : PlayState -> AnimGroup -> AnimGroup
setPlayState state (AnimGroup animGroup) =
    AnimGroup { animGroup | playState = state }


isActive : AnimGroup -> Bool
isActive (AnimGroup animGroup) =
    PlayState.isActive animGroup.playState


isCancelled : AnimGroup -> Bool
isCancelled (AnimGroup animGroup) =
    PlayState.isCancelled animGroup.playState


isComplete : AnimGroup -> Bool
isComplete (AnimGroup animGroup) =
    PlayState.isComplete animGroup.playState


isRunning : AnimGroup -> Bool
isRunning (AnimGroup animGroup) =
    PlayState.isRunning animGroup.playState
