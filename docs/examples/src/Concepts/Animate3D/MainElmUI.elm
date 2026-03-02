module Concepts.Animate3D.MainElmUI exposing (main)

import Anim.Engine.CSS.Keyframes as Keyframes
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Extra.View3D as View3D
import Anim.Property.Rotate as Rotate
import Anim.Property.Translate as Translate
import Browser
import Element exposing (Element, centerX, centerY, column, el, fill, height, html, htmlAttribute, padding, paddingEach, paragraph, px, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html exposing (Html)
import Html.Attributes



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
    Element.layout
        [ Background.color (Element.rgb255 240 240 240)
        , Font.family [ Font.typeface "system-ui", Font.sansSerif ]
        , padding 40
        , width fill
        , height fill
        ]
        (column
            [ centerX
            , spacing 20
            ]
            [ html (Keyframes.styleNode model.animState)
            , el
                [ centerX
                , Font.size 24
                , Font.bold
                ]
                (text "Nested 3D Animation Test (Elm + elm-ui)")
            , viewScene model
            , viewInfo
            ]
        )


viewScene : Model -> Element Msg
viewScene model =
    el
        [ width (px 400)
        , height (px 400)
        , Background.color (Element.rgb 1 1 1)
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 12
            , color = Element.rgba 0 0 0 0.1
            }
        , View3D.perspective 800 |> htmlAttribute
        , View3D.perspectiveOrigin View3D.LeftMiddle
            |> htmlAttribute
        , View3D.opacityHack
            -- Kind of fixes Chrome on macOS compositor tile corruption when
            -- animating 3D transforms by creating a new stacking
            -- context for the animation area
            -- it's not perfect, some flickering can still occur
            -- pull requests to improve this are welcome!
            |> htmlAttribute

        -- Use raw CSS for centering to avoid elm-ui wrapper elements
        , Html.Attributes.style "display" "flex" |> htmlAttribute
        , Html.Attributes.style "justify-content" "center" |> htmlAttribute
        , Html.Attributes.style "align-items" "center" |> htmlAttribute
        ]
        (viewLevel1 model)


viewLevel1 : Model -> Element Msg
viewLevel1 model =
    let
        animAttributes =
            Keyframes.attributes "level-1" model.animState
                |> List.map htmlAttribute

        eventAttributes =
            Keyframes.events "level-1" GotKeyframeMsg
                |> List.map htmlAttribute
    in
    el
        ([ width (px 200)
         , height (px 200)
         , Background.color (Element.rgba255 52 152 219 0.3)
         , Border.width 3
         , Border.color (Element.rgb255 52 152 219)
         , View3D.transformStyle View3D.Preserve3D |> htmlAttribute

         -- Use raw CSS for centering to avoid elm-ui wrapper elements
         , Html.Attributes.style "display" "flex" |> htmlAttribute
         , Html.Attributes.style "justify-content" "center" |> htmlAttribute
         , Html.Attributes.style "align-items" "center" |> htmlAttribute
         ]
            ++ animAttributes
            ++ eventAttributes
        )
        (viewLevel2 model)


viewLevel2 : Model -> Element Msg
viewLevel2 model =
    let
        animAttributes =
            Keyframes.attributes "level-2" model.animState
                |> List.map htmlAttribute
    in
    el
        ([ width (px 140)
         , height (px 140)
         , Background.color (Element.rgba255 231 76 60 0.3)
         , Border.width 3
         , Border.color (Element.rgb255 231 76 60)
         , View3D.transformStyle View3D.Preserve3D |> htmlAttribute

         -- Use raw CSS for centering to avoid elm-ui wrapper elements
         , Html.Attributes.style "display" "flex" |> htmlAttribute
         , Html.Attributes.style "justify-content" "center" |> htmlAttribute
         , Html.Attributes.style "align-items" "center" |> htmlAttribute
         ]
            ++ animAttributes
        )
        (viewLevel3 model)


viewLevel3 : Model -> Element Msg
viewLevel3 model =
    let
        animAttributes =
            Keyframes.attributes "level-3" model.animState
                |> List.map htmlAttribute
    in
    el
        ([ width (px 80)
         , height (px 80)
         , Background.color (Element.rgba255 46 204 113 0.8)
         , Border.width 3
         , Border.color (Element.rgb255 39 174 96)
         , Font.bold
         , Font.color (Element.rgb 1 1 1)

         -- Use raw CSS for centering to avoid elm-ui wrapper elements
         , Html.Attributes.style "display" "flex" |> htmlAttribute
         , Html.Attributes.style "justify-content" "center" |> htmlAttribute
         , Html.Attributes.style "align-items" "center" |> htmlAttribute
         ]
            ++ animAttributes
        )
        (text "INNER")


viewInfo : Element Msg
viewInfo =
    column
        [ width (Element.fillPortion 1 |> Element.maximum 500)
        , padding 20
        , spacing 10
        , Background.color (Element.rgb 1 1 1)
        , Border.rounded 8
        , Font.size 14
        , centerX
        ]
        [ el [ Font.bold, Font.size 16, paddingEach { top = 0, right = 0, bottom = 10, left = 0 } ]
            (text "What this tests:")
        , paragraph []
            [ el [ Font.bold ] (text "Level 1 (Blue): ")
            , text "Rotates Y-axis to 45°"
            ]
        , paragraph []
            [ el [ Font.bold ] (text "Level 2 (Red): ")
            , text "Rotates X-axis to 45°"
            ]
        , paragraph []
            [ el [ Font.bold ] (text "Level 3 (Green): ")
            , text "Translates Z-axis to 60px"
            ]
        , el
            [ padding 15
            , Background.color (Element.rgb255 232 245 233)
            , Border.rounded 6
            , width fill
            ]
            (column [ spacing 8 ]
                [ el [ Font.bold, Font.size 14, Font.color (Element.rgb255 46 125 50) ]
                    (text "Expected behavior if 3D context works:")
                , paragraph []
                    [ text "All three animations should be visible and combine in 3D space. "
                    , text "The green inner box should appear to move toward you while "
                    , text "the red middle rotates on X, and the blue outer rotates on Y."
                    ]
                ]
            )
        ]
