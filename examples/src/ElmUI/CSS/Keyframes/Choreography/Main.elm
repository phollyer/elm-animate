module ElmUI.CSS.Keyframes.Choreography.Main exposing (main)

{-| Anim.Engine.CSS Choreography Example using ElmUI - Coordinated multi-element animations

This demonstrates choreographed animations with multiple elements moving together in formations.
Shows how to create complex patterns like scatter, circle formations, and synchronized group movements.

FEATURES:

  - ✅ Coordinated multi-element animations
  - ✅ Formation patterns (scatter, circle, custom arrangements)
  - ✅ Synchronized group movements
  - ✅ Hardware-accelerated choreography
  - ✅ Complex animation orchestration
  - ✅ Real-time formation transitions

USAGE EXAMPLES:

  - Dashboard widgets arranging into grid layouts
  - Game pieces moving in coordinated formations
  - Data visualization elements reorganizing
  - UI components transitioning between layouts
  - Interactive storytelling with character movement

-}

import Anim.Engine.CSS as CSS
import Anim.Properties.Position as Position
import Anim.Timing.Easing as Easing exposing (Easing(..))
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, alignLeft, centerX, centerY, column, el, fill, height, htmlAttribute, layout, maximum, padding, paddingXY, paragraph, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
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


type Msg
    = ScatterElements
    | ResetPositions
    | CircleFormation
    | AnimationComplete


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AnimationComplete ->
            ( model, Cmd.none )

        ScatterElements ->
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        |> CSS.duration 800
                        |> CSS.easing Easing.QuadInOut
                        |> Position.for "elementA"
                        |> Position.toXY 80 60
                        |> Position.build
                        |> Position.for "elementB"
                        |> Position.toXY 320 80
                        |> Position.build
                        |> Position.for "elementC"
                        |> Position.toXY 40 300
                        |> Position.build
                        |> Position.for "elementD"
                        |> Position.toXY 380 260
                        |> Position.build
                        |> Position.for "elementE"
                        |> Position.toXY 60 120
                        |> Position.build
                        |> Position.for "elementF"
                        |> Position.toXY 350 320
                        |> Position.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        ResetPositions ->
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        |> CSS.duration 600
                        |> CSS.easing Easing.QuadInOut
                        |> Position.for "elementA"
                        |> Position.toXY 0 0
                        |> Position.build
                        |> Position.for "elementB"
                        |> Position.toXY 0 0
                        |> Position.build
                        |> Position.for "elementC"
                        |> Position.toXY 0 0
                        |> Position.build
                        |> Position.for "elementD"
                        |> Position.toXY 0 0
                        |> Position.build
                        |> Position.for "elementE"
                        |> Position.toXY 0 0
                        |> Position.build
                        |> Position.for "elementF"
                        |> Position.toXY 0 0
                        |> Position.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        CircleFormation ->
            let
                centerX =
                    225

                centerY =
                    180

                radius =
                    90
            in
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        |> CSS.duration 1000
                        |> CSS.easing Easing.backInOut
                        |> Position.for "elementA"
                        |> Position.toXY (toFloat (centerX + round radius)) (toFloat centerY)
                        |> Position.build
                        |> Position.for "elementB"
                        |> Position.toXY (toFloat (centerX + round (radius * 0.5))) (toFloat (centerY + round (radius * 0.866)))
                        |> Position.build
                        |> Position.for "elementC"
                        |> Position.toXY (toFloat (centerX - round (radius * 0.5))) (toFloat (centerY + round (radius * 0.866)))
                        |> Position.build
                        |> Position.for "elementD"
                        |> Position.toXY (toFloat (centerX - round radius)) (toFloat centerY)
                        |> Position.build
                        |> Position.for "elementE"
                        |> Position.toXY (toFloat (centerX - round (radius * 0.5))) (toFloat (centerY - round (radius * 0.866)))
                        |> Position.build
                        |> Position.for "elementF"
                        |> Position.toXY (toFloat (centerX + round (radius * 0.5))) (toFloat (centerY - round (radius * 0.866)))
                        |> Position.build
                        |> CSS.animate
              }
            , Cmd.none
            )



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.CSS Choreography Keyframes ElmUI Example"
        UI.Basic
        (viewContent model)


type alias ElementData =
    { id : String
    , label : String
    , color : Element.Color
    }


elements : List ElementData
elements =
    [ { id = "elementA", label = "A", color = rgb255 59 130 246 }
    , { id = "elementB", label = "B", color = rgb255 16 185 129 }
    , { id = "elementC", label = "C", color = rgb255 168 85 247 }
    , { id = "elementD", label = "D", color = rgb255 249 115 22 }
    , { id = "elementE", label = "E", color = rgb255 239 68 68 }
    , { id = "elementF", label = "F", color = rgb255 236 72 153 }
    ]


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        keyframeStyleNodes =
            elements
                |> List.map
                    (\{ id } ->
                        Element.html <|
                            CSS.keyframesStyleNodeFor id model.animations
                    )
    in
    keyframeStyleNodes
        ++ [ UI.backButtonWithPath "../../../index.html"
           , UI.pageHeader "ElmUI & CSS Keyframes Choreography Example"
           , -- Element status display
             el
                [ Font.size 14
                , Font.color Colors.textMedium
                , centerX
                ]
                (text "Coordinated choreography with 6 elements in formation patterns")
           , -- Control buttons
             UI.wrappedButtonRow
                [ ( UI.Primary, ScatterElements, "Scatter Formation" )
                , ( UI.Success, CircleFormation, "Circle Formation" )
                , ( UI.Purple, ResetPositions, "Reset Formation" )
                ]
           , -- Animation area with 6 moving boxes using proper ElmUI + new API
             el
                [ width (fill |> maximum 500)
                , height (px 400)
                , centerX
                , Background.color Colors.backgroundWhite
                , Border.rounded 12
                , Border.shadow
                    { offset = ( 0, 4 )
                    , size = 0
                    , blur = 8
                    , color = Element.rgba 0 0 0 0.1
                    }
                , htmlAttribute (Html.Attributes.style "position" "relative")
                , htmlAttribute (Html.Attributes.style "overflow" "hidden")
                ]
                (column [] <|
                    List.map
                        (\{ id, label, color } ->
                            animatedBox id label color model
                        )
                        elements
                )
           ]


animatedBox : String -> String -> Element.Color -> Model -> Element Msg
animatedBox elementId label color1 model =
    el
        [ width (px 50)
        , height (px 50)
        , Background.color color1
        , Border.rounded 12
        , Font.color (rgb255 255 255 255)
        , Font.semiBold
        , Font.size 16
        , htmlAttribute (Html.Attributes.id elementId)
        , htmlAttribute (Html.Attributes.style "position" "absolute")
        , htmlAttribute (CSS.animationStyleAttribute elementId model.animations)
        ]
        (el [ centerX, centerY ] (text label))
