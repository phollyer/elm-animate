port module ElmUI.Ports.Choreography.Main exposing (main)

{-| Anim.CSS Choreography Example using ElmUI - Coordinated multi-element animations

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

import Anim exposing (Position, defaultConfig)
import Anim.Ports exposing (Model, animateTo, animateToMultiple, animateToX, animateToY, encodeAnimationCommand, getPosition, handlePropertyUpdateFromJson, init, styleProperties)
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


port stopElement : Encode.Value -> Cmd msg


port positionUpdates : (Decode.Value -> msg) -> Sub msg


port animationComplete : (String -> msg) -> Sub msg



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
    { animations : Anim.Ports.Model
    , isAnimating : Bool
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.Ports.init
      , isAnimating = False
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ScatterElements
    | ResetPositions
    | CircleFormation
    | AnimationComplete String
    | PositionUpdateReceived (Result Decode.Error Anim.Ports.PropertyUpdate)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScatterElements ->
            let
                scatterPositions =
                    [ ( "elementA", Position 80 60 )
                    , ( "elementB", Position 320 80 )
                    , ( "elementC", Position 40 300 )
                    , ( "elementD", Position 380 260 )
                    , ( "elementE", Position 60 120 )
                    , ( "elementF", Position 350 320 )
                    ]

                ( updatedAnimations, animationCommands ) =
                    animateToMultiple scatterPositions model.animations

                batchedCommand =
                    animationCommands
                        |> List.map (animateElement << encodeAnimationCommand)
                        |> Cmd.batch
            in
            ( { model | animations = updatedAnimations, isAnimating = True }
            , batchedCommand
            )

        ResetPositions ->
            let
                resetPositions =
                    [ ( "elementA", Position 150 100 )
                    , ( "elementB", Position 200 150 )
                    , ( "elementC", Position 100 200 )
                    , ( "elementD", Position 250 200 )
                    , ( "elementE", Position 300 100 )
                    , ( "elementF", Position 180 50 )
                    ]

                ( updatedAnimations, animationCommands ) =
                    animateToMultiple resetPositions model.animations

                batchedCommand =
                    animationCommands
                        |> List.map (animateElement << encodeAnimationCommand)
                        |> Cmd.batch
            in
            ( { model | animations = updatedAnimations, isAnimating = True }
            , batchedCommand
            )

        CircleFormation ->
            let
                centerX =
                    225

                centerY =
                    175

                radius =
                    90

                circlePositions =
                    [ ( "elementA", Position (centerX + radius) centerY ) -- 0°
                    , ( "elementB", Position (centerX + radius * 0.5) (centerY + radius * 0.866) ) -- 60°
                    , ( "elementC", Position (centerX - radius * 0.5) (centerY + radius * 0.866) ) -- 120°
                    , ( "elementD", Position (centerX - radius) centerY ) -- 180°
                    , ( "elementE", Position (centerX - radius * 0.5) (centerY - radius * 0.866) ) -- 240°
                    , ( "elementF", Position (centerX + radius * 0.5) (centerY - radius * 0.866) ) -- 300°
                    ]

                ( updatedAnimations, animationCommands ) =
                    animateToMultiple circlePositions model.animations

                batchedCommand =
                    animationCommands
                        |> List.map (animateElement << encodeAnimationCommand)
                        |> Cmd.batch
            in
            ( { model | animations = updatedAnimations, isAnimating = True }
            , batchedCommand
            )

        AnimationComplete _ ->
            ( { model | isAnimating = False }
            , Cmd.none
            )

        PositionUpdateReceived result ->
            case result of
                Ok propertyUpdate ->
                    ( { model | animations = Anim.Ports.handlePropertyUpdate propertyUpdate model.animations }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ positionUpdates (PositionUpdateReceived << handlePropertyUpdateFromJson)
        , animationComplete AnimationComplete
        ]



-- No subscriptions needed for CSS transitions!
-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Ports Choreography ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        positionA =
            getPosition "elementA" model.animations

        positionB =
            getPosition "elementB" model.animations

        positionC =
            getPosition "elementC" model.animations

        positionD =
            getPosition "elementD" model.animations

        positionE =
            getPosition "elementE" model.animations

        positionF =
            getPosition "elementF" model.animations
    in
    [ UI.backButton
    , UI.pageHeader "Ports Choreography Animations"
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


{-| Helper function to create an animated box element using the new Anim.CSS API
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
            ++ (styleProperties elementId model.animations
                    |> List.map (\( prop, value ) -> htmlAttribute (Html.Attributes.style prop value))
               )
        )
        (el [ centerX, centerY ] (text label))
