module Anim.Internal.Engine.Animation.CSS.Transition.AnimGroup exposing
    ( AnimGroup
    , getStyles
    , init
    , mergeStyles
    , setStyles
    )

import Anim.Internal.Engine.Animation.CSS.Styles as Styles exposing (Styles)


type AnimGroup
    = AnimGroup
        { styles : Styles
        }


init : AnimGroup
init =
    AnimGroup
        { styles = Styles.empty }


getStyles : AnimGroup -> Styles
getStyles (AnimGroup animGroup) =
    animGroup.styles


setStyles : Styles -> AnimGroup -> AnimGroup
setStyles styles (AnimGroup animGroup) =
    AnimGroup { animGroup | styles = styles }


mergeStyles :
    List String
    -> AnimGroup
    -> AnimGroup
    -> AnimGroup
mergeStyles newCssProps (AnimGroup newGroup) (AnimGroup existingGroup) =
    let
        isMetaStyle key =
            key == "transition" || key == "transition-behavior"

        existingStyles =
            existingGroup.styles
                |> Styles.remove "transition"
                |> Styles.remove "transition-behavior"

        {-
           Styles.filter
               (\key _ -> not (isMetaStyle key) && not (List.member key newCssProps))
               existingGroup.styles
        -}
        newPropertyStyles =
            Styles.filter (\key _ -> not (isMetaStyle key)) newGroup.styles

        -- Parse transition string into individual parts, respecting parentheses
        -- e.g. "translate 3175ms cubic-bezier(0.175, 0.885, 0.32, 1.275) 0ms, transform 1600ms ease-in-out 0ms"
        -- must NOT split inside cubic-bezier(...)
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
    in
    AnimGroup { styles = styles }


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
