module Concepts.Animate3D.Main exposing (main)

import Anim.Engine.CSS.Keyframes as Keyframes
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Extra.View3D as View3D
import Anim.Property.Rotate as Rotate
import Anim.Property.Translate as Translate
import Browser
import Html exposing (Html, div, h1, h2, h3, li, p, strong, text, ul)
import Html.Attributes exposing (style)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { animState : Keyframes.AnimState
    }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        initialAnimState =
            Keyframes.init
                [ -- Level 1: starts at rotateY(0)
                  Rotate.initY "level-1" 0

                -- Level 2: starts at rotateX(0)
                , Rotate.initX "level-2" 0

                -- Level 3: starts at translateZ(0)
                , Translate.initZ "level-3" 0
                ]
    in
    ( { animState =
            Keyframes.animate initialAnimState
                (Keyframes.loopForever >> Keyframes.alternate >> animateToEnd)
      }
    , Cmd.none
    )



-- ANIMATIONS


animateToEnd : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
animateToEnd =
    rotateLevel1To 45
        >> rotateLevel2To 45
        >> translateLevel3To 60


rotateLevel1To : Float -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
rotateLevel1To angle =
    Rotate.for "level-1"
        >> Rotate.to angle
        >> Rotate.easing SineInOut
        >> Rotate.duration 2000
        >> Rotate.build


rotateLevel2To : Float -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
rotateLevel2To angle =
    Rotate.for "level-2"
        >> Rotate.toX angle
        >> Rotate.easing SineInOut
        >> Rotate.duration 1500
        >> Rotate.build


translateLevel3To : Float -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
translateLevel3To z =
    Translate.for "level-3"
        >> Translate.toZ z
        >> Translate.easing SineInOut
        >> Translate.duration 1000
        >> Translate.build



-- UPDATE


type Msg
    = GotKeyframeMsg Keyframes.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotKeyframeMsg animMsg ->
            let
                ( animState, _ ) =
                    Keyframes.update animMsg model.animState
            in
            ( { model | animState = animState }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "font-family" "system-ui, sans-serif"
        , style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        , style "padding" "40px"
        , style "background" "#f0f0f0"
        , style "min-height" "100vh"
        ]
        [ Keyframes.styleNode model.animState
        , h1 [ style "margin-bottom" "20px" ] [ text "Nested 3D Animation Test (Elm)" ]
        , viewScene model
        , viewInfo
        ]


viewScene : Model -> Html Msg
viewScene model =
    div
        [ style "width" "400px"
        , style "height" "400px"
        , style "background" "white"
        , style "border-radius" "12px"
        , style "box-shadow" "0 4px 12px rgba(0,0,0,0.1)"
        , style "display" "flex"
        , style "justify-content" "center"
        , style "align-items" "center"
        , View3D.perspective 800
        ]
        [ viewLevel1 model ]


viewLevel1 : Model -> Html Msg
viewLevel1 model =
    div
        ([ style "width" "200px"
         , style "height" "200px"
         , style "background" "rgba(52, 152, 219, 0.3)"
         , style "border" "3px solid rgb(52, 152, 219)"
         , style "display" "flex"
         , style "justify-content" "center"
         , style "align-items" "center"
         , View3D.transformStyle View3D.Preserve3D
         ]
            ++ Keyframes.attributes "level-1" model.animState
            ++ Keyframes.events "level-1" GotKeyframeMsg
        )
        [ viewLevel2 model ]


viewLevel2 : Model -> Html Msg
viewLevel2 model =
    div
        ([ style "width" "140px"
         , style "height" "140px"
         , style "background" "rgba(231, 76, 60, 0.3)"
         , style "border" "3px solid rgb(231, 76, 60)"
         , style "display" "flex"
         , style "justify-content" "center"
         , style "align-items" "center"
         , View3D.transformStyle View3D.Preserve3D
         ]
            ++ Keyframes.attributes "level-2" model.animState
        )
        [ viewLevel3 model ]


viewLevel3 : Model -> Html Msg
viewLevel3 model =
    div
        ([ style "width" "80px"
         , style "height" "80px"
         , style "background" "rgba(46, 204, 113, 0.8)"
         , style "border" "3px solid rgb(39, 174, 96)"
         , style "display" "flex"
         , style "justify-content" "center"
         , style "align-items" "center"
         , style "font-weight" "bold"
         , style "color" "white"
         ]
            ++ Keyframes.attributes "level-3" model.animState
        )
        [ text "INNER" ]


viewInfo : Html Msg
viewInfo =
    div
        [ style "margin-top" "30px"
        , style "max-width" "500px"
        , style "padding" "20px"
        , style "background" "#fff"
        , style "border-radius" "8px"
        , style "font-size" "14px"
        , style "line-height" "1.6"
        ]
        [ h2 [ style "margin-bottom" "10px", style "font-size" "16px" ]
            [ text "What this tests:" ]
        , ul [ style "margin-left" "20px" ]
            [ li [] [ strong [] [ text "Level 1 (Blue): " ], text "Rotates Y-axis to 45°" ]
            , li [] [ strong [] [ text "Level 2 (Red): " ], text "Rotates X-axis to 45°" ]
            , li [] [ strong [] [ text "Level 3 (Green): " ], text "Translates Z-axis to 60px" ]
            ]
        , div
            [ style "margin-top" "15px"
            , style "padding" "15px"
            , style "background" "#e8f5e9"
            , style "border-radius" "6px"
            ]
            [ h3 [ style "font-size" "14px", style "margin-bottom" "8px", style "color" "#2e7d32" ]
                [ text "Expected behavior if 3D context works:" ]
            , p []
                [ text "All three animations should be visible and combine in 3D space. "
                , text "The green inner box should appear to move toward you while "
                , text "the red middle rotates on X, and the blue outer rotates on Y."
                ]
            ]
        ]
