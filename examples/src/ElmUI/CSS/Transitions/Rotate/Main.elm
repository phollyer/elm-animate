module ElmUI.CSS.Transitions.Rotate.Main exposing (main)

{-| Anim.Engine.CSS Rotate Example using ElmUI - Rotate transformation animations

This example demonstrates smooth rotate animations using browser-native CSS transforms.
Perfect for loading spinners, interactive elements, and dynamic orientation changes.

FEATURES:

  - ✅ Smooth rotate animations in degrees
  - ✅ Hardware-accelerated transform rotates
  - ✅ Multiple rotate directions and speeds
  - ✅ Continuous spinning and specific angle targeting
  - ✅ Battery efficient browser-native transforms

-}

import Anim.Easing as Easing exposing (Easing(..))
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
                    model.animations
                        |> CSS.builder
                        |> Animations.rotate45 "box"
                        |> CSS.animate
              }
            , Cmd.none
            )

        Rotate90 ->
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        |> Animations.rotate90 "box"
                        |> CSS.animate
              }
            , Cmd.none
            )

        Rotate180 ->
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        |> Animations.rotate180 "box"
                        |> CSS.animate
              }
            , Cmd.none
            )

        RotateLeft ->
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        |> Animations.rotateLeft "box"
                        |> CSS.animate
              }
            , Cmd.none
            )

        RotateRight ->
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        |> Animations.rotateRight "box"
                        |> CSS.animate
              }
            , Cmd.none
            )

        ResetRotate ->
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        |> Animations.resetRotate "box"
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
        "Anim.Engine.CSS Rotate ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "ElmUI & CSS Transitions Rotate Example"
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
            (rotatingElement "box" "→" "Rotate Demo" Colors.primary model)
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
