module ElmUI.CSS.Multiple.Main exposing (main)

{-| Anim.CSS Multiple Example using ElmUI - Multiple elements with native CSS transitions

This demonstrates hardware-accelerated animations for multiple elements simultaneously
using browser-native CSS transitions for optimal performance and battery efficiency.

FEATURES:

  - ✅ Multiple hardware-accelerated animations
  - ✅ Native browser optimization for each element
  - ✅ Battery efficient simultaneous transitions
  - ✅ Formation patterns with CSS-native easing
  - ✅ Zero JavaScript animation overhead
  - ✅ Auto-scaling based on device performance

-}

-- Common UI imports

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
import Anim exposing (Position, defaultConfig)
import Anim.CSS exposing (Model, init, animatePosition, animateToX, animateToY, getCurrentPosition, styleProperties, transitionStyles, onTransitionEnd)



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
    { animations : Anim.CSS.Model
    , isAnimating : Bool
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.CSS.init
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
                updatedAnimations =
                    model.animations
                        |> animatePosition "elementA" (Position 80 60)
                        |> animatePosition "elementB" (Position 320 80)
                        |> animatePosition "elementC" (Position 40 300)
                        |> animatePosition "elementD" (Position 380 260)
                        |> animatePosition "elementE" (Position 60 120)
                        |> animatePosition "elementF" (Position 350 320)
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
                        |> animatePosition "elementA" (Position 150 100)
                        |> animatePosition "elementB" (Position 200 150)
                        |> animatePosition "elementC" (Position 100 200)
                        |> animatePosition "elementD" (Position 250 200)
                        |> animatePosition "elementE" (Position 300 100)
                        |> animatePosition "elementF" (Position 180 50)
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
                        |> animatePosition "elementA" (Position (centerX + radius) centerY) -- 0°
                        |> animatePosition "elementB" (Position (centerX + radius * 0.5) (centerY + radius * 0.866)) -- 60°
                        |> animatePosition "elementC" (Position (centerX - radius * 0.5) (centerY + radius * 0.866)) -- 120°
                        |> animatePosition "elementD" (Position (centerX - radius) centerY) -- 180°
                        |> animatePosition "elementE" (Position (centerX - radius * 0.5) (centerY - radius * 0.866)) -- 240°
                        |> animatePosition "elementF" (Position (centerX + radius * 0.5) (centerY - radius * 0.866)) -- 300°
            in
            ( { model 
                | animations = updatedAnimations
                , isAnimating = True
              }
            , Cmd.none 
            )

        AnimationComplete ->
            ( { model | isAnimating = False }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- No subscriptions needed for CSS transitions!
-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.CSS Multiple ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        positionA = getCurrentPosition "elementA" model.animations
        positionB = getCurrentPosition "elementB" model.animations
        positionC = getCurrentPosition "elementC" model.animations
        positionD = getCurrentPosition "elementD" model.animations
        positionE = getCurrentPosition "elementE" model.animations
        positionF = getCurrentPosition "elementF" model.animations
    in
    [ UI.backButton
    , UI.pageHeader "Anim.CSS Multiple Example"
    , -- Element status display
      el
        [ Font.size 14
        , Font.color Colors.textMedium
        , centerX
        ]
        (text ("6 elements animating simultaneously with CSS transitions"))
    , -- Control buttons
      UI.htmlActionButtons
        [ ( UI.Primary, ScatterElements, "Scatter" )
        , ( UI.Success, CircleFormation, "Circle Formation" )
        , ( UI.Purple, ResetPositions, "Reset" )
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
            ])
    ]


{-| Helper function to create an animated box element using the new Anim.CSS API
-}
animatedBox : String -> String -> Element.Color -> Element.Color -> Model -> Element Msg
animatedBox elementId label color1 color2 model =
    el
        ([ width (px 50)
        , height (px 50)
        , Background.gradient 
            { angle = 2.356  -- 135 degrees in radians
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
            |> List.map (\(prop, value) -> htmlAttribute (Html.Attributes.style prop value)))
        ++ [ htmlAttribute (Html.Attributes.style "transition" 
                (if model.isAnimating then
                    transitionStyles elementId model.animations
                 else
                    "none"
                ))
        , htmlAttribute (onTransitionEnd AnimationComplete)
        ])
        (el [ centerX, centerY ] (text label))