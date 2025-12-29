port module ElmUI.WAAPI.Choreography.Main exposing (main)

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

import Anim.Engine.WAAPI as WAAPI
import Anim.Properties.Position as Position
import Anim.Timing.Easing as Easing
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
    { animState : WAAPI.AnimState
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState = WAAPI.init }
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
                -- Animate each element to scattered positions
                ( state1, cmd1 ) =
                    let
                        builder =
                            WAAPI.builder model.animState
                                |> WAAPI.duration 1000
                                |> WAAPI.easing Easing.EaseInOut
                                |> Position.for "elementA"
                                |> Position.toXY 70 250
                                |> Position.build

                        ( newState, encodedValue ) =
                            WAAPI.animate model.animState builder
                    in
                    ( newState, animateElement encodedValue )

                ( state2, cmd2 ) =
                    let
                        builder =
                            WAAPI.builder state1
                                |> WAAPI.duration 1000
                                |> WAAPI.easing Easing.EaseInOut
                                |> Position.for "elementB"
                                |> Position.toXY 220 280
                                |> Position.build

                        ( newState, encodedValue ) =
                            WAAPI.animate state1 builder
                    in
                    ( newState, animateElement encodedValue )

                ( state3, cmd3 ) =
                    let
                        builder =
                            WAAPI.builder state2
                                |> WAAPI.duration 1000
                                |> WAAPI.easing Easing.EaseInOut
                                |> Position.for "elementC"
                                |> Position.toXY 370 260
                                |> Position.build

                        ( newState, encodedValue ) =
                            WAAPI.animate state2 builder
                    in
                    ( newState, animateElement encodedValue )

                ( state4, cmd4 ) =
                    let
                        builder =
                            WAAPI.builder state3
                                |> WAAPI.duration 1000
                                |> WAAPI.easing Easing.EaseInOut
                                |> Position.for "elementD"
                                |> Position.toXY 50 50
                                |> Position.build

                        ( newState, encodedValue ) =
                            WAAPI.animate state3 builder
                    in
                    ( newState, animateElement encodedValue )

                ( state5, cmd5 ) =
                    let
                        builder =
                            WAAPI.builder state4
                                |> WAAPI.duration 1000
                                |> WAAPI.easing Easing.EaseInOut
                                |> Position.for "elementE"
                                |> Position.toXY 200 80
                                |> Position.build

                        ( newState, encodedValue ) =
                            WAAPI.animate state4 builder
                    in
                    ( newState, animateElement encodedValue )

                ( finalState, cmd6 ) =
                    let
                        builder =
                            WAAPI.builder state5
                                |> WAAPI.duration 1000
                                |> WAAPI.easing Easing.EaseInOut
                                |> Position.for "elementF"
                                |> Position.toXY 350 60
                                |> Position.build

                        ( newState, encodedValue ) =
                            WAAPI.animate state5 builder
                    in
                    ( newState, animateElement encodedValue )
            in
            ( { model | animState = finalState }
            , Cmd.batch [ cmd1, cmd2, cmd3, cmd4, cmd5, cmd6 ]
            )

        CircleFormation ->
            let
                -- Circle formation: elements arranged in a circle
                centerX_ =
                    200

                centerY_ =
                    175

                radius =
                    120

                angleStep =
                    2 * pi / 6

                createCircleAnimation index elementId state =
                    let
                        angle =
                            toFloat index * angleStep

                        x =
                            centerX_ + radius * cos angle

                        y =
                            centerY_ + radius * sin angle

                        builder =
                            WAAPI.builder state
                                |> WAAPI.duration 1000
                                |> WAAPI.easing Easing.EaseInOut
                                |> Position.for elementId
                                |> Position.toXY x y
                                |> Position.build

                        ( newState, encodedValue ) =
                            WAAPI.animate state builder
                    in
                    ( newState, animateElement encodedValue )

                ( state1, cmd1 ) =
                    createCircleAnimation 0 "elementA" model.animState

                ( state2, cmd2 ) =
                    createCircleAnimation 1 "elementB" state1

                ( state3, cmd3 ) =
                    createCircleAnimation 2 "elementC" state2

                ( state4, cmd4 ) =
                    createCircleAnimation 3 "elementD" state3

                ( state5, cmd5 ) =
                    createCircleAnimation 4 "elementE" state4

                ( finalState, cmd6 ) =
                    createCircleAnimation 5 "elementF" state5
            in
            ( { model | animState = finalState }
            , Cmd.batch [ cmd1, cmd2, cmd3, cmd4, cmd5, cmd6 ]
            )

        ResetPositions ->
            let
                -- Grid formation: elements in 2x3 grid
                createGridAnimation row col elementId state =
                    let
                        x =
                            toFloat (50 + col * 150)

                        y =
                            toFloat (50 + row * 150)

                        builder =
                            WAAPI.builder state
                                |> WAAPI.duration 1000
                                |> WAAPI.easing Easing.EaseInOut
                                |> Position.for elementId
                                |> Position.toXY x y
                                |> Position.build

                        ( newState, encodedValue ) =
                            WAAPI.animate state builder
                    in
                    ( newState, animateElement encodedValue )

                ( state1, cmd1 ) =
                    createGridAnimation 0 0 "elementA" model.animState

                ( state2, cmd2 ) =
                    createGridAnimation 0 1 "elementB" state1

                ( state3, cmd3 ) =
                    createGridAnimation 0 2 "elementC" state2

                ( state4, cmd4 ) =
                    createGridAnimation 1 0 "elementD" state3

                ( state5, cmd5 ) =
                    createGridAnimation 1 1 "elementE" state4

                ( finalState, cmd6 ) =
                    createGridAnimation 1 2 "elementF" state5
            in
            ( { model | animState = finalState }
            , Cmd.batch [ cmd1, cmd2, cmd3, cmd4, cmd5, cmd6 ]
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.WAAPI Choreography ElmUI Example"
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


{-| Helper function to create an animated box element using the new Anim.Engine.WAAPI API
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
