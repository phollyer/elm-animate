module ElmUI.CSS.Keyframes.Rotate.Main exposing (main)

{-| Anim.Engine.CSS Rotation Example using ElmUI - Element rotation animations with CSS keyframes

This example demonstrates smooth rotation animations using browser-native CSS keyframes.
Perfect for creating spin effects and angular transformations with precise timing control.

FEATURES:

  - ✅ Smooth rotation animations using CSS keyframes
  - ✅ Hardware-accelerated CSS transforms with fine-grained control
  - ✅ Multiple rotation angles and directions
  - ✅ Keyframes provide precise control over animation timing and composition

-}

import Anim.Extra.Easing as Easing exposing (Easing(..))
import Anim.Engine.CSS as CSS
import Anim.Property.Rotate as Rotate
import Browser exposing (Document)
import Common.Animations.Rotate as Animations
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html
import Html.Attributes



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { animations : CSS.AnimState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = CSS.init }
    , Cmd.none
    )



-- UPDATE


elementId : String
elementId =
    "box"


type Msg
    = Rotate45
    | Rotate90
    | Rotate180
    | RotateLeft
    | RotateRight
    | ResetRotate
    | AnimationComplete


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Rotate45 ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.rotate45 elementId)
              }
            , Cmd.none
            )

        Rotate90 ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.rotate90 elementId)
              }
            , Cmd.none
            )

        Rotate180 ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.rotate180 elementId)
              }
            , Cmd.none
            )

        RotateLeft ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.rotateLeft elementId)
              }
            , Cmd.none
            )

        RotateRight ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.rotateRight elementId)
              }
            , Cmd.none
            )

        ResetRotate ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.resetRotate elementId)
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( model
            , Cmd.none
            )



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.CSS Rotate Keyframes ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ Element.html (CSS.keyframesStyleNodeFor elementId model.animations)
    , UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "ElmUI & CSS Keyframes Rotate Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth rotate transformations using hardware-accelerated CSS transforms")
    , -- Rotate controls
      UI.wrappedButtonRow
        [ ( UI.Success, Rotate45, "45°" )
        , ( UI.Warning, Rotate90, "90°" )
        , ( UI.Primary, Rotate180, "180°" )
        , ( UI.Success, RotateLeft, "← 90°" )
        , ( UI.Purple, ResetRotate, "Reset" )
        ]
    , -- Animation area with boxes
      el
        [ width (fill |> maximum 600)
        , height (px 400)
        , Background.color Colors.backgroundWhite
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.1
            }
        , centerX
        , htmlAttribute (Html.Attributes.style "position" "relative")
        , htmlAttribute (Html.Attributes.style "overflow" "visible")
        , htmlAttribute (Html.Attributes.style "display" "flex")
        , htmlAttribute (Html.Attributes.style "flex-direction" "column")
        , htmlAttribute (Html.Attributes.style "align-items" "center")
        , htmlAttribute (Html.Attributes.style "justify-content" "space-around")
        , htmlAttribute (Html.Attributes.style "padding" "40px")
        ]
        (el
            [ centerX
            , Element.centerY
            , width (px 200)
            , height (px 200)
            ]
            (rotatingElement "→" "Rotate Demo" Colors.primary model)
        )
    ]


rotatingElement : String -> String -> Element.Color -> Model -> Element Msg
rotatingElement symbol label color model =
    el
        [ width (px 150)
        , height (px 150)
        , Background.color color
        , Border.rounded 12
        , centerX
        , htmlAttribute (Html.Attributes.id elementId)
        , htmlAttribute (Html.Attributes.style "transform-origin" "center")
        , htmlAttribute (Html.Attributes.style "display" "flex")
        , htmlAttribute (Html.Attributes.style "align-items" "center")
        , htmlAttribute (Html.Attributes.style "justify-content" "center")
        , htmlAttribute (CSS.animationStyleAttribute elementId model.animations)
        ]
        (column
            [ centerX
            , Element.centerY
            , spacing 8
            ]
            [ el
                [ centerX
                , Font.color Colors.backgroundWhite
                , Font.bold
                , Font.size 32
                ]
                (text symbol)
            , el
                [ centerX
                , Font.color Colors.backgroundWhite
                , Font.size 14
                ]
                (text label)
            ]
        )
