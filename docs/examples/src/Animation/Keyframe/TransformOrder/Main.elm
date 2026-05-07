module Animation.Keyframe.TransformOrder.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
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
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { animState : Keyframe.AnimState }


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
            Keyframe.init <|
                List.concatMap
                    (\perm ->
                        [ Translate.initXY (permutationKey perm) 0 0
                        , Skew.initXY (permutationKey perm) 0 0
                        ]
                    )
                    allPermutations
      }
    , Cmd.none
    )



-- ANIMATION


animatePermutation : Permutation -> AnimBuilder mode -> AnimBuilder mode
animatePermutation perm =
    let
        key =
            permutationKey perm
    in
    Translate.for key
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


resetPermutation : Permutation -> AnimBuilder mode -> AnimBuilder mode
resetPermutation perm =
    let
        key =
            permutationKey perm
    in
    Translate.for key
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
                    Keyframe.animate model.animState <|
                        Keyframe.transformOrder (permutationOrder perm)
                            >> animatePermutation perm
              }
            , Cmd.none
            )

        Reset perm ->
            ( { model
                | animState =
                    Keyframe.animate model.animState <|
                        Keyframe.transformOrder (permutationOrder perm)
                            >> resetPermutation perm
              }
            , Cmd.none
            )

        AnimateAll ->
            ( { model
                | animState =
                    Keyframe.animate model.animState <|
                        List.foldl
                            (\perm acc ->
                                Keyframe.transformOrder (permutationOrder perm)
                                    >> animatePermutation perm
                                    >> acc
                            )
                            identity
                            allPermutations
              }
            , Cmd.none
            )

        ResetAll ->
            ( { model
                | animState =
                    Keyframe.animate model.animState <|
                        List.foldl
                            (\perm acc ->
                                Keyframe.transformOrder (permutationOrder perm)
                                    >> resetPermutation perm
                                    >> acc
                            )
                            identity
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
