port module ElmUI.Ports.Choreography.Main exposing (main)

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

-- Common UI imports


import Anim.Timing.Easing as Easing
import Anim.Engine.Ports as Ports
import Anim.Properties.Position as Position
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
import Json.Decode as Decode
import Json.Encode as Encode



-- PORTS


port animateElement : Encode.Value -> Cmd msg



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
    {}



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( {}
    , Cmd.none
    )



-- UPDATE


type Msg
    = ScatterElements
    | ResetPositions
    | CircleFormation


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScatterElements ->
            let
                animationCmd1 =
                    Anim.init "elementA"
                        |> Position.to { x = 70, y = 250 }
                        |> Position.duration 1000
                        |> Position.easing Easing.easeInOut
                        |> Ports.animate animateElement

                animationCmd2 =
                    Anim.init "elementB"
                        |> Position.to { x = 220, y = 280 }
                        |> Position.duration 1000
                        |> Position.easing Easing.easeInOut
                        |> Ports.animate animateElement

                animationCmd3 =
                    Anim.init "elementC"
                        |> Position.to { x = 370, y = 260 }
                        |> Position.duration 1000
                        |> Position.easing Easing.easeInOut
                        |> Ports.animate animateElement

                animationCmd4 =
                    Anim.init "elementD"
                        |> Position.to { x = 50, y = 50 }
                        |> Position.duration 1000
                        |> Position.easing Easing.easeInOut
                        |> Anim.for "elementE"
                        |> Position.to { x = 200, y = 80 }
                        |> Position.duration 1000
                        |> Position.easing Easing.easeInOut
                        |> Anim.for "elementF"
                        |> Position.to { x = 350, y = 60 }
                        |> Position.duration 1000
                        |> Position.easing Easing.easeInOut
                        |> Ports.animate animateElement
            in
            ( model
            , Cmd.batch
                [ animationCmd1
                , animationCmd2
                , animationCmd3
                , animationCmd4
                ]
            )

        CircleFormation ->
            let
                -- Circle formation: elements arranged in a circle
                centerX =
                    200

                centerY =
                    175

                radius =
                    120

                angleStep =
                    2 * pi / 6

                createCircleAnimation index elementId =
                    let
                        angle =
                            toFloat index * angleStep

                        x =
                            centerX + radius * cos angle

                        y =
                            centerY + radius * sin angle
                    in
                    Anim.init elementId
                        |> Position.to { x = x, y = y }
                        |> Position.duration 1000
                        |> Position.easing Easing.easeInOut
            in
            ( model
            , Ports.animateBatch animateElement <|
                [ createCircleAnimation 0 "elementA"
                , createCircleAnimation 1 "elementB"
                , createCircleAnimation 2 "elementC"
                , createCircleAnimation 3 "elementD"
                , createCircleAnimation 4 "elementE"
                , createCircleAnimation 5 "elementF"
                ]
            )

        ResetPositions ->
            let
                -- Grid formation: elements in 2x3 grid
                createGridAnimation row col elementId =
                    Anim.init elementId
                        |> Position.to { x = toFloat (50 + col * 150), y = toFloat (50 + row * 150) }
                        |> Position.duration 1000
                        |> Position.easing Easing.easeInOut
            in
            ( model
            , Ports.animateBatch animateElement <|
                [ createGridAnimation 0 0 "elementA"
                , createGridAnimation 0 1 "elementB"
                , createGridAnimation 0 2 "elementC"
                , createGridAnimation 1 0 "elementD"
                , createGridAnimation 1 1 "elementE"
                , createGridAnimation 1 2 "elementF"
                ]
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.Ports Choreography ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Ports Choreography Example"
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
              animatedBox "elementA" "A" (rgb255 59 130 246) (rgb255 37 99 235)
            , -- Element B (Green)
              animatedBox "elementB" "B" (rgb255 16 185 129) (rgb255 5 150 105)
            , -- Element C (Purple)
              animatedBox "elementC" "C" (rgb255 168 85 247) (rgb255 147 51 234)
            , -- Element D (Orange)
              animatedBox "elementD" "D" (rgb255 249 115 22) (rgb255 234 88 12)
            , -- Element E (Red)
              animatedBox "elementE" "E" (rgb255 239 68 68) (rgb255 220 38 38)
            , -- Element F (Pink)
              animatedBox "elementF" "F" (rgb255 236 72 153) (rgb255 219 39 119)
            ]
        )
    ]


{-| Helper function to create an animated box element using the new Anim.Engine.Ports API
-}
animatedBox : String -> String -> Element.Color -> Element.Color -> Element Msg
animatedBox elementId label color1 color2 =
    el
        [ width (px 50)
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
        (el [ centerX, centerY ] (text label))
