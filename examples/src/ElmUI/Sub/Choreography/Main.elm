module ElmUI.Sub.Choreography.Main exposing (main)

{-| Anim.Engine.Sub Choreography Example using ElmUI - Coordinated multi-element animations

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

-- Common UI imports

import Anim.Easing as Easing exposing (Easing(..))
import Anim.Engine.Sub as Sub
import Anim.Property.Position as Position
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
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animations : Sub.AnimState
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Sub.init
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ScatterElements
    | ResetPositions
    | CircleFormation
    | AnimationMsg Sub.AnimationMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScatterElements ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Position.for "elementA"
                        |> Position.toXY 80 60
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementB"
                        |> Position.toXY 320 80
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementC"
                        |> Position.toXY 40 300
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementD"
                        |> Position.toXY 380 260
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementE"
                        |> Position.toXY 60 120
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementF"
                        |> Position.toXY 350 320
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        ResetPositions ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Position.for "elementA"
                        |> Position.toXY 0 0
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementB"
                        |> Position.toXY 0 0
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementC"
                        |> Position.toXY 0 0
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementD"
                        |> Position.toXY 0 0
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementE"
                        |> Position.toXY 0 0
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementF"
                        |> Position.toXY 0 0
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Sub.animate
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
                        |> Sub.builder
                        |> Position.for "elementA"
                        |> Position.toXY (centerX + radius) (toFloat centerY)
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementB"
                        |> Position.toXY (centerX + radius * 0.5) (toFloat centerY + radius * 0.866)
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementC"
                        |> Position.toXY (centerX - radius * 0.5) (toFloat centerY + radius * 0.866)
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementD"
                        |> Position.toXY (centerX - radius) (toFloat centerY)
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementE"
                        |> Position.toXY (centerX - radius * 0.5) (toFloat centerY - radius * 0.866)
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Position.for "elementF"
                        |> Position.toXY (centerX + radius * 0.5) (toFloat centerY - radius * 0.866)
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        AnimationMsg subMsg ->
            let
                updatedAnimations =
                    Sub.update subMsg model.animations
            in
            ( { model | animations = updatedAnimations }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map AnimationMsg <|
        Sub.subscriptions model.animations



-- No subscriptions needed for Subscription-Based transitions!
-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.Sub Choreography ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        positionA =
            Sub.getCurrentPosition "elementA" model.animations

        positionB =
            Sub.getCurrentPosition "elementB" model.animations

        positionC =
            Sub.getCurrentPosition "elementC" model.animations

        positionD =
            Sub.getCurrentPosition "elementD" model.animations

        positionE =
            Sub.getCurrentPosition "elementE" model.animations

        positionF =
            Sub.getCurrentPosition "elementF" model.animations
    in
    [ UI.backButton
    , UI.pageHeader "ElmUI & Subscription Choreography Example"
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
        (column []
            [ -- Element A (Blue)
              animatedBox "elementA" "A" (rgb255 59 130 246) (rgb255 37 99 235) model
            , -- Element B (Green)
              animatedBox "elementB" "B" (rgb255 16 185 129) (rgb255 5 150 105) model
            , -- Element C (Purple)
              animatedBox "elementC" "C" (rgb255 168 85 247) (rgb255 147 51 234) model
            , -- Element D (Orange)
              animatedBox "elementD" "D" (rgb255 249 115 22) (rgb255 234 88 12) model
            , -- Element E (Red)
              animatedBox "elementE" "E" (rgb255 239 68 68) (rgb255 220 38 38) model
            , -- Element F (Pink)
              animatedBox "elementF" "F" (rgb255 236 72 153) (rgb255 219 39 119) model
            ]
        )
    ]


{-| Helper function to create an animated box element using the new Anim.Engine.Sub API
-}
animatedBox : String -> String -> Element.Color -> Element.Color -> Model -> Element Msg
animatedBox elementId label color1 color2 model =
    el
        ([ width (px 50)
         , height (px 50)
         , Background.gradient
            { angle = 2.356 -- 135 degrees in radians
            , steps = [ color1, color2 ]
            }
         , Border.rounded 12
         , Font.color (rgb255 255 255 255)
         , Font.semiBold
         , Font.size 16
         , htmlAttribute (Html.Attributes.id elementId)
         , htmlAttribute (Html.Attributes.style "position" "absolute")
         ]
            ++ List.map htmlAttribute (Sub.htmlAttributes elementId model.animations)
        )
        (el [ centerX, centerY ] (text label))
