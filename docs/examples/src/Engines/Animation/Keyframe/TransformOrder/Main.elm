module Engines.Animation.Keyframe.TransformOrder.Main exposing (main)

import Anim.Engine.CSS.Keyframe as Keyframe exposing (AnimBuilder)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty(..))
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Translate as Translate
import Browser
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
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { animState : Keyframe.AnimState
    }


type Permutation
    = TRS
    | TSR
    | RTS
    | RST
    | STR
    | SRT


allPermutations : List Permutation
allPermutations =
    [ TRS, TSR, RTS, RST, STR, SRT ]


permutationKey : Permutation -> String
permutationKey perm =
    case perm of
        TRS ->
            "trs"

        TSR ->
            "tsr"

        RTS ->
            "rts"

        RST ->
            "rst"

        STR ->
            "str"

        SRT ->
            "srt"


permutationLabel : Permutation -> String
permutationLabel perm =
    case perm of
        TRS ->
            "T → R → S"

        TSR ->
            "T → S → R"

        RTS ->
            "R → T → S"

        RST ->
            "R → S → T"

        STR ->
            "S → T → R"

        SRT ->
            "S → R → T"


permutationOrder : Permutation -> List TransformProperty
permutationOrder perm =
    case perm of
        TRS ->
            [ Translate, Rotate, Scale ]

        TSR ->
            [ Translate, Scale, Rotate ]

        RTS ->
            [ Rotate, Translate, Scale ]

        RST ->
            [ Rotate, Scale, Translate ]

        STR ->
            [ Scale, Translate, Rotate ]

        SRT ->
            [ Scale, Rotate, Translate ]


permutationColor : Permutation -> String
permutationColor perm =
    case perm of
        TRS ->
            "59, 130, 246"

        TSR ->
            "16, 185, 129"

        RTS ->
            "245, 158, 11"

        RST ->
            "239, 68, 68"

        STR ->
            "139, 92, 246"

        SRT ->
            "236, 72, 153"



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Keyframe.init <|
                List.map
                    (\perm -> Translate.initXY (permutationKey perm) 0 0)
                    allPermutations
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
    Keyframe.transformOrder (permutationOrder perm)
        >> Translate.for key
        >> Translate.toXY 120 0
        >> Translate.duration 2000
        >> Translate.easing EaseInOut
        >> Translate.build
        >> Rotate.for key
        >> Rotate.toZ 45
        >> Rotate.duration 2000
        >> Rotate.easing EaseInOut
        >> Rotate.build
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
    Keyframe.transformOrder (permutationOrder perm)
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
        >> Scale.for key
        >> Scale.toXY 1 1
        >> Scale.duration 2000
        >> Scale.easing EaseInOut
        >> Scale.build



-- UPDATE


type Msg
    = Animate Permutation
    | Reset Permutation
    | AnimateAll
    | ResetAll


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate perm ->
            ( { model
                | animState =
                    Keyframe.animate model.animState (animatePermutation perm)
              }
            , Cmd.none
            )

        Reset perm ->
            ( { model
                | animState =
                    Keyframe.animate model.animState (resetPermutation perm)
              }
            , Cmd.none
            )

        AnimateAll ->
            ( { model
                | animState =
                    List.foldl
                        (\perm acc -> Keyframe.animate acc (animatePermutation perm))
                        model.animState
                        allPermutations
              }
            , Cmd.none
            )

        ResetAll ->
            ( { model
                | animState =
                    List.foldl
                        (\perm acc -> Keyframe.animate acc (resetPermutation perm))
                        model.animState
                        allPermutations
              }
            , Cmd.none
            )



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
        [ Keyframe.styleNode model.animState
        , div
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


animationArea : Keyframe.AnimState -> Html Msg
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


animatedBox : Keyframe.AnimState -> Permutation -> Html Msg
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
            (Keyframe.attributes (permutationKey perm) animState
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
