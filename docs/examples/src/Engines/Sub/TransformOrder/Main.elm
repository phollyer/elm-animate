module Engines.Sub.TransformOrder.Main exposing (main)

import Anim.Engine.Sub as Sub exposing (AnimBuilder, TransformOrder(..))
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Common.UI as UI
import Common.View.Controls as ViewControls
import Element exposing (Element, centerX, centerY, column, el, fill, height, html, htmlAttribute, inFront, padding, px, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html
import Html.Attributes exposing (style)



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = always init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : Sub.AnimState
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


permutationOrder : Permutation -> List TransformOrder
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


permutationColor : Permutation -> Element.Color
permutationColor perm =
    case perm of
        TRS ->
            Element.rgb255 59 130 246

        TSR ->
            Element.rgb255 16 185 129

        RTS ->
            Element.rgb255 245 158 11

        RST ->
            Element.rgb255 239 68 68

        STR ->
            Element.rgb255 139 92 246

        SRT ->
            Element.rgb255 236 72 153



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Sub.init <|
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
    Sub.transformOrder (permutationOrder perm)
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
        >> Scale.to 1.3
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
        >> Scale.for key
        >> Scale.to 1
        >> Scale.duration 2000
        >> Scale.easing EaseInOut
        >> Scale.build



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
            ( { model
                | animState =
                    Sub.animate model.animState (animatePermutation perm)
              }
            , Cmd.none
            )

        Reset perm ->
            ( { model
                | animState =
                    Sub.animate model.animState (resetPermutation perm)
              }
            , Cmd.none
            )

        AnimateAll ->
            ( { model
                | animState =
                    List.foldl
                        (\perm acc -> Sub.animate acc (animatePermutation perm))
                        model.animState
                        allPermutations
              }
            , Cmd.none
            )

        ResetAll ->
            ( { model
                | animState =
                    List.foldl
                        (\perm acc -> Sub.animate acc (resetPermutation perm))
                        model.animState
                        allPermutations
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Transform Order - Sub Engine"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ ViewControls.header
        [ "Transform Order" ]
    , UI.wrappedButtonRow
        (List.map
            (\perm -> ( UI.Primary, Animate perm, permutationLabel perm ))
            allPermutations
        )
    , row [ centerX, spacing 8 ]
        [ el [ centerX ] <|
            html <|
                UI.htmlButton ( UI.Success, AnimateAll, "▶️ All" )
        , el [ centerX ] <|
            html <|
                UI.htmlButton ( UI.Warning, ResetAll, "⏮️ Reset All" )
        ]
    , animationArea model.animState
    ]


animationArea : Sub.AnimState -> Element Msg
animationArea animState =
    let
        boxes =
            List.map (animatedBox animState) allPermutations
    in
    el
        ([ width (fill |> Element.maximum 500)
         , height (px 350)
         , Background.color (Element.rgb255 255 255 255)
         , Border.rounded 12
         , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.1
            }
         , centerX
         , htmlAttribute (style "position" "relative")
         , htmlAttribute (style "overflow" "hidden")
         ]
            ++ List.map inFront boxes
        )
        Element.none


animatedBox : Sub.AnimState -> Permutation -> Element Msg
animatedBox animState perm =
    el
        [ centerX
        , centerY
        , width (px 80)
        , height (px 80)
        ]
        (el
            (List.map htmlAttribute (Sub.attributes (permutationKey perm) animState)
                ++ [ width (px 80)
                   , height (px 80)
                   , Background.color (permutationColor perm |> withAlpha 0.25)
                   , Border.rounded 8
                   , Border.width 2
                   , Border.color (permutationColor perm)
                   , Font.size 11
                   , Font.bold
                   , Font.color (permutationColor perm)
                   , padding 4
                   ]
            )
            (text (permutationLabel perm))
        )


withAlpha : Float -> Element.Color -> Element.Color
withAlpha a color =
    let
        { red, green, blue } =
            Element.toRgb color
    in
    Element.rgba red green blue a
