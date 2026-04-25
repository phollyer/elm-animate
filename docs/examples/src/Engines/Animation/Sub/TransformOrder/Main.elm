module Engines.Animation.Sub.TransformOrder.Main exposing (main)

import Anim.Engine.Sub as Sub exposing (AnimBuilder)
import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty(..))
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Browser
import Easing exposing (Easing(..))
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : Sub.AnimState
    , debugLog : List String
    }


type Permutation
    = TRSkS
    | TSkRS
    | RTSkS
    | SkTRS
    | STRSk
    | RSkTS


allPermutations : List Permutation
allPermutations =
    [ TRSkS, TSkRS, RTSkS, SkTRS, STRSk, RSkTS ]


permutationKey : Permutation -> String
permutationKey perm =
    case perm of
        TRSkS ->
            "t-r-sk-s"

        TSkRS ->
            "t-sk-r-s"

        RTSkS ->
            "r-t-sk-s"

        SkTRS ->
            "sk-t-r-s"

        STRSk ->
            "s-t-r-sk"

        RSkTS ->
            "r-sk-t-s"


permutationLabel : Permutation -> String
permutationLabel perm =
    case perm of
        TRSkS ->
            "T → R → Sk → S"

        TSkRS ->
            "T → Sk → R → S"

        RTSkS ->
            "R → T → Sk → S"

        SkTRS ->
            "Sk → T → R → S"

        STRSk ->
            "S → T → R → Sk"

        RSkTS ->
            "R → Sk → T → S"


permutationOrder : Permutation -> List TransformProperty
permutationOrder perm =
    case perm of
        TRSkS ->
            [ Translate, Rotate, Skew, Scale ]

        TSkRS ->
            [ Translate, Skew, Rotate, Scale ]

        RTSkS ->
            [ Rotate, Translate, Skew, Scale ]

        SkTRS ->
            [ Skew, Translate, Rotate, Scale ]

        STRSk ->
            [ Scale, Translate, Rotate, Skew ]

        RSkTS ->
            [ Rotate, Skew, Translate, Scale ]


permutationColor : Permutation -> String
permutationColor perm =
    case perm of
        TRSkS ->
            "59, 130, 246"

        TSkRS ->
            "16, 185, 129"

        RTSkS ->
            "245, 158, 11"

        SkTRS ->
            "239, 68, 68"

        STRSk ->
            "139, 92, 246"

        RSkTS ->
            "236, 72, 153"



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Sub.init <|
                List.concatMap
                    (\perm ->
                        [ Translate.initXY (permutationKey perm) 0 0
                        , Skew.initXY (permutationKey perm) 0 0
                        ]
                    )
                    allPermutations
            , debugLog =
                [ "ready" ]
      }
    , Cmd.none
    )



-- ANIMATION


animatePermutation : Permutation -> AnimBuilder -> AnimBuilder
animatePermutation perm =
    let
        key =
            permutationKey perm
    in
    Sub.transformOrder (permutationOrder perm)
        >> Translate.for key
        >> Translate.toXY 120 56
        >> Translate.duration 2000
        >> Translate.easing EaseInOut
        >> Translate.build
        >> Rotate.for key
        >> Rotate.toZ 45
        >> Rotate.duration 2000
        >> Rotate.easing EaseInOut
        >> Rotate.build
        >> Skew.for key
        >> Skew.toXY 15 9
        >> Skew.duration 2000
        >> Skew.easing EaseInOut
        >> Skew.build
        >> Scale.for key
        >> Scale.toXY 1.5 0.8
        >> Scale.duration 2000
        >> Scale.easing EaseInOut
        >> Scale.build


resetPermutation : Permutation -> AnimBuilder -> AnimBuilder
resetPermutation perm =
    let
        key =
            permutationKey perm
    in
    Sub.transformOrder (permutationOrder perm)
        >> Translate.for key
        >> Translate.toXY 0 0
        >> Translate.duration 2000
        >> Translate.easing EaseInOut
        >> Translate.build
        >> Rotate.for key
        >> Rotate.toZ 0
        >> Rotate.duration 2000
        >> Rotate.easing EaseInOut
        >> Rotate.build
        >> Skew.for key
        >> Skew.toXY 0 0
        >> Skew.duration 2000
        >> Skew.easing EaseInOut
        >> Skew.build
        >> Scale.for key
        >> Scale.toXY 1 1
        >> Scale.duration 2000
        >> Scale.easing EaseInOut
        >> Scale.build


orderString : Permutation -> String
orderString perm =
    permutationOrder perm
        |> List.map TransformProperty.toString
        |> String.join " -> "


debugMessageFor : String -> Permutation -> String
debugMessageFor action perm =
    action ++ " | key=" ++ permutationKey perm ++ " | order=" ++ orderString perm



-- UPDATE


type Msg
    = Animate Permutation
    | Reset Permutation
    | AnimateAll
    | ResetAll
    | GotSubMsg Sub.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSubMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    Sub.update subMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        Animate perm ->
            let
                message =
                    debugMessageFor "animate" perm |> Debug.log "TransformOrder"
            in
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        animatePermutation perm
                , debugLog =
                    (message :: model.debugLog)
                        |> List.take 12
              }
            , Cmd.none
            )

        Reset perm ->
            let
                message =
                    debugMessageFor "reset" perm |> Debug.log "TransformOrder"
            in
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        resetPermutation perm
                , debugLog =
                    (message :: model.debugLog)
                        |> List.take 12
              }
            , Cmd.none
            )

        AnimateAll ->
            let
                message =
                    "animate-all | perms=" ++ String.fromInt (List.length allPermutations) |> Debug.log "TransformOrder"
            in
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        List.foldl
                            (\perm acc ->
                                animatePermutation perm >> acc
                            )
                            identity
                            allPermutations
                , debugLog =
                    (message :: model.debugLog)
                        |> List.take 12
              }
            , Cmd.none
            )

        ResetAll ->
            let
                message =
                    "reset-all | perms=" ++ String.fromInt (List.length allPermutations) |> Debug.log "TransformOrder"
            in
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        List.foldl
                            (\perm acc ->
                                resetPermutation perm >> acc
                            )
                            identity
                            allPermutations
                , debugLog =
                    (message :: model.debugLog)
                        |> List.take 12
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        , style "gap" "16px"
        , style "padding" "16px"
        , style "font-family" "sans-serif"
        ]
        [ div
            [ style "display" "flex"
            , style "flex-wrap" "wrap"
            , style "justify-content" "center"
            , style "gap" "8px"
            ]
            (List.map permButton allPermutations)
        , div
            [ style "display" "flex"
            , style "gap" "8px"
            , style "justify-content" "center"
            ]
            [ actionButton "▶️ All" AnimateAll "#16a34a"
            , actionButton "⏮️ Reset All" ResetAll "#d97706"
            ]
        , debugPanel model
        , animationArea model.animState
        ]


permButton : Permutation -> Html Msg
permButton perm =
    button
        [ onClick (Animate perm)
        , style "padding" "6px 14px"
        , style "border" "none"
        , style "border-radius" "6px"
        , style "background-color" ("rgb(" ++ permutationColor perm ++ ")")
        , style "color" "white"
        , style "font-size" "13px"
        , style "font-weight" "600"
        , style "cursor" "pointer"
        ]
        [ text (permutationLabel perm) ]


actionButton : String -> Msg -> String -> Html Msg
actionButton label msg color =
    button
        [ onClick msg
        , style "padding" "6px 14px"
        , style "border" "none"
        , style "border-radius" "6px"
        , style "background-color" color
        , style "color" "white"
        , style "font-size" "13px"
        , style "font-weight" "600"
        , style "cursor" "pointer"
        ]
        [ text label ]


debugPanel : Model -> Html Msg
debugPanel model =
    div
        [ style "width" "100%"
        , style "max-width" "760px"
        , style "background" "#f8fafc"
        , style "border" "1px solid #cbd5e1"
        , style "border-radius" "8px"
        , style "padding" "10px"
        , style "font-family" "monospace"
        , style "font-size" "12px"
        , style "color" "#0f172a"
        ]
        ([ div [ style "font-weight" "700", style "margin-bottom" "6px" ] [ text "Debug: permutation keys and orders" ]
         , div [ style "display" "flex", style "flex-direction" "column", style "gap" "2px", style "margin-bottom" "8px" ]
            (List.map
                (\perm ->
                    div []
                        [ text
                            (permutationLabel perm
                                ++ " | key="
                                ++ permutationKey perm
                                ++ " | order="
                                ++ orderString perm
                            )
                        ]
                )
                allPermutations
            )
         , div [ style "font-weight" "700", style "margin" "8px 0 4px" ] [ text "Debug log (most recent first)" ]
         ]
            ++ List.map (\line -> div [] [ text line ]) model.debugLog
        )


animationArea : Sub.AnimState -> Html Msg
animationArea animState =
    div
        [ style "position" "relative"
        , style "width" "100%"
        , style "max-width" "500px"
        , style "height" "350px"
        , style "background-color" "#ffffff"
        , style "border-radius" "12px"
        , style "box-shadow" "0 4px 8px rgba(0, 0, 0, 0.1)"
        , style "overflow" "hidden"
        ]
        (List.map (animatedBox animState) allPermutations)


animatedBox : Sub.AnimState -> Permutation -> Html Msg
animatedBox animState perm =
    let
        rgb =
            permutationColor perm
    in
    div
        [ style "position" "absolute"
        , style "top" "50%"
        , style "left" "50%"
        , style "margin-top" "-40px"
        , style "margin-left" "-40px"
        ]
        [ div
            (Sub.attributes (permutationKey perm) animState
                ++ [ style "width" "80px"
                   , style "height" "80px"
                   , style "background-color" ("rgba(" ++ rgb ++ ", 0.25)")
                   , style "border-radius" "8px"
                   , style "border" ("2px solid rgb(" ++ rgb ++ ")")
                   , style "font-size" "11px"
                   , style "font-weight" "bold"
                   , style "color" ("rgb(" ++ rgb ++ ")")
                   , style "padding" "4px"
                   , style "box-sizing" "border-box"
                   ]
            )
            [ text (permutationLabel perm) ]
        ]
