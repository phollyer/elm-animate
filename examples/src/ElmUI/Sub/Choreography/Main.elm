module ElmUI.Sub.Choreography.Main exposing (main)

{-| Anim.Sub Choreography Example using ElmUI - Coordinated multi-element animations

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
import Anim.Sub exposing (Model, animateTo, animateToX, animateToY, getPosition, init, step, styleProperties, subscriptions)
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
    { animations : Anim.Sub.Model
    , isAnimating : Bool
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.Sub.init
      , isAnimating = False
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ScatterElements
    | ResetPositions
    | CircleFormation
    | AnimationFrame Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScatterElements ->
            let
                updatedAnimations =
                    model.animations
                        |> animateTo "elementA" (Position 80 60)
                        |> animateTo "elementB" (Position 320 80)
                        |> animateTo "elementC" (Position 40 300)
                        |> animateTo "elementD" (Position 380 260)
                        |> animateTo "elementE" (Position 60 120)
                        |> animateTo "elementF" (Position 350 320)
            in
            ( { model
                | animations = updatedAnimations
                , isAnimating = True
              }
            , Cmd.none
            )

        ResetPositions ->
            let
                updatedAnimations =
                    model.animations
                        |> animateTo "elementA" (Position 150 100)
                        |> animateTo "elementB" (Position 200 150)
                        |> animateTo "elementC" (Position 100 200)
                        |> animateTo "elementD" (Position 250 200)
                        |> animateTo "elementE" (Position 300 100)
                        |> animateTo "elementF" (Position 180 50)
            in
            ( { model
                | animations = updatedAnimations
                , isAnimating = True
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

                updatedAnimations =
                    model.animations
                        |> animateTo "elementA" (Position (centerX + radius) centerY)
                        -- 0°
                        |> animateTo "elementB" (Position (centerX + radius * 0.5) (centerY + radius * 0.866))
                        -- 60°
                        |> animateTo "elementC" (Position (centerX - radius * 0.5) (centerY + radius * 0.866))
                        -- 120°
                        |> animateTo "elementD" (Position (centerX - radius) centerY)
                        -- 180°
                        |> animateTo "elementE" (Position (centerX - radius * 0.5) (centerY - radius * 0.866))
                        -- 240°
                        |> animateTo "elementF" (Position (centerX + radius * 0.5) (centerY - radius * 0.866))

                -- 300°
            in
            ( { model
                | animations = updatedAnimations
                , isAnimating = True
              }
            , Cmd.none
            )

        AnimationFrame deltaTime ->
            ( model
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Anim.Sub.subscriptions AnimationFrame model.animations



-- No subscriptions needed for Subscription-Based transitions!
-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Sub Choreography ElmUI Example"
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
    , UI.pageHeader "Subscription-Based Choreography Animations"
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


{-| Helper function to create an animated box element using the new Anim.Sub API
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
