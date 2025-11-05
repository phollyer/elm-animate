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
import Anim.Ports exposing (Model, animateTo, animateToX, animateToY, encodeAnimationCommand, getPosition, handlePropertyUpdateFromJson, init, styleProperties)
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
                ( model1, maybeCmd1 ) =
                    animateTo "elementA" (Position 80 60) model.animations

                ( model2, maybeCmd2 ) =
                    animateTo "elementB" (Position 320 80) model1

                ( model3, maybeCmd3 ) =
                    animateTo "elementC" (Position 40 300) model2

                ( model4, maybeCmd4 ) =
                    animateTo "elementD" (Position 380 260) model3

                ( model5, maybeCmd5 ) =
                    animateTo "elementE" (Position 60 120) model4

                ( model6, maybeCmd6 ) =
                    animateTo "elementF" (Position 350 320) model5

                commands =
                    [ maybeCmd1, maybeCmd2, maybeCmd3, maybeCmd4, maybeCmd5, maybeCmd6 ]
                        |> List.filterMap identity
                        |> List.map (animateElement << encodeAnimationCommand)
            in
            ( { model | animations = model6, isAnimating = True }
            , Cmd.batch commands
            )

        ResetPositions ->
            let
                ( model1, maybeCmd1 ) =
                    animateTo "elementA" (Position 150 100) model.animations

                ( model2, maybeCmd2 ) =
                    animateTo "elementB" (Position 200 150) model1

                ( model3, maybeCmd3 ) =
                    animateTo "elementC" (Position 100 200) model2

                ( model4, maybeCmd4 ) =
                    animateTo "elementD" (Position 250 200) model3

                ( model5, maybeCmd5 ) =
                    animateTo "elementE" (Position 300 100) model4

                ( model6, maybeCmd6 ) =
                    animateTo "elementF" (Position 180 50) model5

                commands =
                    [ maybeCmd1, maybeCmd2, maybeCmd3, maybeCmd4, maybeCmd5, maybeCmd6 ]
                        |> List.filterMap identity
                        |> List.map (animateElement << encodeAnimationCommand)
            in
            ( { model | animations = model6, isAnimating = True }
            , Cmd.batch commands
            )

        CircleFormation ->
            let
                centerX =
                    225

                centerY =
                    180

                radius =
                    90

                ( model1, maybeCmd1 ) =
                    animateTo "elementA" (Position (centerX + radius) centerY) model.animations

                -- 0°
                ( model2, maybeCmd2 ) =
                    animateTo "elementB" (Position (centerX + radius * 0.5) (centerY + radius * 0.866)) model1

                -- 60°
                ( model3, maybeCmd3 ) =
                    animateTo "elementC" (Position (centerX - radius * 0.5) (centerY + radius * 0.866)) model2

                -- 120°
                ( model4, maybeCmd4 ) =
                    animateTo "elementD" (Position (centerX - radius) centerY) model3

                -- 180°
                ( model5, maybeCmd5 ) =
                    animateTo "elementE" (Position (centerX - radius * 0.5) (centerY - radius * 0.866)) model4

                -- 240°
                ( model6, maybeCmd6 ) =
                    animateTo "elementF" (Position (centerX + radius * 0.5) (centerY - radius * 0.866)) model5

                -- 300°
                commands =
                    [ maybeCmd1, maybeCmd2, maybeCmd3, maybeCmd4, maybeCmd5, maybeCmd6 ]
                        |> List.filterMap identity
                        |> List.map (animateElement << encodeAnimationCommand)
            in
            ( { model | animations = model6, isAnimating = True }
            , Cmd.batch commands
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
      UI.htmlActionButtons
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
