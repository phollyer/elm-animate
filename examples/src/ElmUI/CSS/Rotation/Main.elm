module ElmUI.CSS.Rotation.Main exposing (main)

{-| Anim.CSS Rotation Example using ElmUI - Rotation transformation animations

This example demonstrates smooth rotation animations using browser-native CSS transforms.
Perfect for loading spinners, interactive elements, and dynamic orientation changes.

FEATURES:

  - ✅ Smooth rotation animations in degrees
  - ✅ Hardware-accelerated transform rotations
  - ✅ Multiple rotation directions and speeds
  - ✅ Continuous spinning and specific angle targeting
  - ✅ Battery efficient browser-native transforms

-}

import Anim
import Anim.CSS as CSS
import Anim.Properties.Rotation as Rotation
import Anim.Timing.Delay as Delay exposing (Delay(..))
import Anim.Timing.Easing as Easing exposing (Easing(..))
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
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
    { animations : CSS.AnimationState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = CSS.init }
    , Cmd.none
    )



-- UPDATE


anim : CSS.AnimationState -> Rotation.Builder
anim animations =
    animations
        |> CSS.builder
        |> Anim.duration 700
        |> Anim.easing Linear
        |> Rotation.for "box"


type Msg
    = Rotate45
    | Rotate90
    | Rotate180
    | RotateLeft
    | RotateRight
    | ResetRotation
    | AnimationComplete


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Rotate45 ->
            ( { model
                | animations =
                    model.animations
                        |> anim
                        |> Rotation.to 45
                        |> Rotation.easing Easing.QuadInOut
                        |> Rotation.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        Rotate90 ->
            ( { model
                | animations =
                    model.animations
                        |> anim
                        |> Rotation.to 90
                        |> Rotation.easing Easing.SineInOut
                        |> Rotation.speed 100
                        |> Rotation.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        Rotate180 ->
            ( { model
                | animations =
                    model.animations
                        |> anim
                        |> Rotation.to 180
                        |> Rotation.easing Easing.backInOut
                        |> Rotation.duration 900
                        |> Rotation.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        RotateLeft ->
            ( { model
                | animations =
                    model.animations
                        |> anim
                        |> Rotation.to -90
                        |> Rotation.easing Easing.bounceInOut
                        |> Rotation.delay (Delay 500)
                        |> Rotation.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        RotateRight ->
            ( { model
                | animations =
                    model.animations
                        |> anim
                        |> Rotation.to 90
                        |> Rotation.easing Easing.elasticInOut
                        |> Rotation.duration 600
                        |> Rotation.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        ResetRotation ->
            ( { model
                | animations =
                    model.animations
                        |> anim
                        |> Rotation.to 0
                        |> Rotation.easing Easing.EaseInOut
                        |> Rotation.build
                        |> CSS.animate
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
        "Anim.CSS Rotation ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "CSS Rotation Animations"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth rotation transformations using hardware-accelerated CSS transforms")
    , -- Rotation controls
      UI.wrappedButtonRow
        [ ( UI.Success, Rotate45, "45°" )
        , ( UI.Warning, Rotate90, "90°" )
        , ( UI.Primary, Rotate180, "180°" )
        , ( UI.Success, RotateLeft, "← 90°" )
        , ( UI.Purple, ResetRotation, "Reset" )
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
            (rotatingElement "box" "→" "Rotation Demo" Colors.primary model)
        )
    ]


rotatingElement : String -> String -> String -> Element.Color -> Model -> Element Msg
rotatingElement elementId symbol label color model =
    el
        ([ width (px 150)
         , height (px 150)
         , Background.color color
         , Border.rounded 12
         , centerX
         , htmlAttribute (Html.Attributes.id elementId)
         , htmlAttribute (Html.Attributes.style "transform-origin" "center")
         , htmlAttribute (Html.Attributes.style "display" "flex")
         , htmlAttribute (Html.Attributes.style "align-items" "center")
         , htmlAttribute (Html.Attributes.style "justify-content" "center")
         ]
            ++ List.map htmlAttribute (CSS.htmlAttributes elementId model.animations)
        )
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
