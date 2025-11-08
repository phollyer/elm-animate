module ElmUI.CSS.Choreography.Main exposing (main)

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

import Anim
import Anim.CSS as CSS exposing (AnimationResult)
import Anim.Easing as Easing
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
    { animations : Maybe AnimationResult
    , isAnimating : Bool
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Nothing
      , isAnimating = False
      }
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
        ScatterElements ->
            let
                -- Create a multi-element animation using the new API
                animationResult =
                    Anim.init "elementA"
                        |> Position.to { x = 80, y = 60 }
                        |> Anim.duration 800
                        |> Anim.easing Easing.easeInOutQuad
                        |> Anim.for "elementB"
                        |> Position.to { x = 320, y = 80 }
                        |> Anim.for "elementC"
                        |> Position.to { x = 40, y = 300 }
                        |> Anim.for "elementD"
                        |> Position.to { x = 380, y = 260 }
                        |> Anim.for "elementE"
                        |> Position.to { x = 60, y = 120 }
                        |> Anim.for "elementF"
                        |> Position.to { x = 350, y = 320 }
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
              }
            , Cmd.none
            )

        ResetPositions ->
            let
                animationResult =
                    Anim.init "elementA"
                        |> Position.to { x = 150, y = 100 }
                        |> Anim.duration 600
                        |> Anim.easing Easing.easeInOutQuad
                        |> Anim.for "elementB"
                        |> Position.to { x = 200, y = 150 }
                        |> Anim.for "elementC"
                        |> Position.to { x = 100, y = 200 }
                        |> Anim.for "elementD"
                        |> Position.to { x = 250, y = 200 }
                        |> Anim.for "elementE"
                        |> Position.to { x = 300, y = 100 }
                        |> Anim.for "elementF"
                        |> Position.to { x = 180, y = 50 }
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
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

                animationResult =
                    Anim.init "elementA"
                        |> Position.to { x = centerX + radius, y = centerY }
                        -- 0°
                        |> Anim.duration 1000
                        |> Anim.easing Easing.easeInOutBack
                        |> Anim.for "elementB"
                        |> Position.to { x = centerX + radius * 0.5, y = centerY + radius * 0.866 }
                        -- 60°
                        |> Anim.for "elementC"
                        |> Position.to { x = centerX - radius * 0.5, y = centerY + radius * 0.866 }
                        -- 120°
                        |> Anim.for "elementD"
                        |> Position.to { x = centerX - radius, y = centerY }
                        -- 180°
                        |> Anim.for "elementE"
                        |> Position.to { x = centerX - radius * 0.5, y = centerY - radius * 0.866 }
                        -- 240°
                        |> Anim.for "elementF"
                        |> Position.to { x = centerX + radius * 0.5, y = centerY - radius * 0.866 }
                        -- 300°
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( { model | isAnimating = False, animations = Nothing }
            , Cmd.none
            )



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.CSS Choreography ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "CSS Choreography Animations"
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
            ++ List.map htmlAttribute (CSS.htmlAttributes elementId model.animations AnimationComplete)
        )
        (el [ centerX, centerY ] (text label))
