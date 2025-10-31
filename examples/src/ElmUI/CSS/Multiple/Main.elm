module ElmUI.CSS.Multiple.Main exposing (main)

{-| SmoothMoveCSS Multiple Example using ElmUI - Multiple elements with native CSS transitions

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
import Element exposing (Element, alignLeft, centerX, column, el, fill, height, htmlAttribute, layout, maximum, padding, paddingXY, paragraph, px, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import SmoothMoveCSS



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
    { positions : 
        { elementA : { x : Float, y : Float }
        , elementB : { x : Float, y : Float }
        , elementC : { x : Float, y : Float }
        , elementD : { x : Float, y : Float }
        , elementE : { x : Float, y : Float }
        , elementF : { x : Float, y : Float }
        }
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { positions = 
          { elementA = { x = 150, y = 100 }
          , elementB = { x = 200, y = 150 }
          , elementC = { x = 100, y = 200 }
          , elementD = { x = 250, y = 200 }
          , elementE = { x = 300, y = 100 }
          , elementF = { x = 180, y = 50 }
          }
      }
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
            ( { model | positions = 
                  { elementA = { x = 80, y = 60 }
                  , elementB = { x = 320, y = 80 }
                  , elementC = { x = 40, y = 300 }
                  , elementD = { x = 380, y = 260 }
                  , elementE = { x = 60, y = 120 }
                  , elementF = { x = 350, y = 320 }
                  }
              }
            , Cmd.none 
            )

        ResetPositions ->
            ( { model | positions = 
                  { elementA = { x = 150, y = 100 }
                  , elementB = { x = 200, y = 150 }
                  , elementC = { x = 100, y = 200 }
                  , elementD = { x = 250, y = 200 }
                  , elementE = { x = 300, y = 100 }
                  , elementF = { x = 180, y = 50 }
                  }
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
            ( { model | positions = 
                  { elementA = { x = centerX + radius, y = centerY } -- 0°
                  , elementB = { x = centerX + radius * 0.5, y = centerY + radius * 0.866 } -- 60°
                  , elementC = { x = centerX - radius * 0.5, y = centerY + radius * 0.866 } -- 120°
                  , elementD = { x = centerX - radius, y = centerY } -- 180°
                  , elementE = { x = centerX - radius * 0.5, y = centerY - radius * 0.866 } -- 240°
                  , elementF = { x = centerX + radius * 0.5, y = centerY - radius * 0.866 } -- 300°
                  }
              }
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
        "SmoothMoveCSS Multiple ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        positionA = model.positions.elementA
        positionB = model.positions.elementB  
        positionC = model.positions.elementC
        positionD = model.positions.elementD
        positionE = model.positions.elementE
        positionF = model.positions.elementF

        -- Generate CSS transition styles for smooth animation
        cssTransition = SmoothMoveCSS.transition
    in
    [ UI.backButton
    , UI.pageHeader "SmoothMoveCSS Multiple Example"
    , -- Element status and positions (6 elements in 2 rows)
      column
        [ spacing 20
        , centerX
        ]
        [ row
            [ spacing 25
            , centerX
            ]
            [ column
                [ spacing 6 ]
                [ el [ Font.size 14, Font.medium, Font.color Colors.primary ] (text "A")
                , el [ Font.size 10, Font.color Colors.textMedium ]
                    (text ("(" ++ String.fromInt (round positionA.x) ++ "," ++ String.fromInt (round positionA.y) ++ ")"))
                ]
            , column
                [ spacing 6 ]
                [ el [ Font.size 14, Font.medium, Font.color Colors.success ] (text "B")
                , el [ Font.size 10, Font.color Colors.textMedium ]
                    (text ("(" ++ String.fromInt (round positionB.x) ++ "," ++ String.fromInt (round positionB.y) ++ ")"))
                ]
            , column
                [ spacing 6 ]
                [ el [ Font.size 14, Font.medium, Font.color Colors.purple ] (text "C")
                , el [ Font.size 10, Font.color Colors.textMedium ]
                    (text ("(" ++ String.fromInt (round positionC.x) ++ "," ++ String.fromInt (round positionC.y) ++ ")"))
                ]
            ]
        , row
            [ spacing 25
            , centerX
            ]
            [ column
                [ spacing 6 ]
                [ el [ Font.size 14, Font.medium, Font.color Colors.warning ] (text "D")
                , el [ Font.size 10, Font.color Colors.textMedium ]
                    (text ("(" ++ String.fromInt (round positionD.x) ++ "," ++ String.fromInt (round positionD.y) ++ ")"))
                ]
            , column
                [ spacing 6 ]
                [ el [ Font.size 14, Font.medium, Font.color Colors.warningDark ] (text "E")
                , el [ Font.size 10, Font.color Colors.textMedium ]
                    (text ("(" ++ String.fromInt (round positionE.x) ++ "," ++ String.fromInt (round positionE.y) ++ ")"))
                ]
            , column
                [ spacing 6 ]
                [ el [ Font.size 14, Font.medium, Font.color Colors.successDark ] (text "F")
                , el [ Font.size 10, Font.color Colors.textMedium ]
                    (text ("(" ++ String.fromInt (round positionF.x) ++ "," ++ String.fromInt (round positionF.y) ++ ")"))
                ]
            ]
        ]
    , -- Control buttons
              UI.htmlActionButtons
        [ ( UI.Primary, ScatterElements, "Scatter" )
        , ( UI.Success, CircleFormation, "Circle Formation" )
        , ( UI.Purple, ResetPositions, "Reset" )
        ]
    , -- Animation area with moving elements
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
        (Element.html
            (Html.div
                [ Html.Attributes.style "position" "relative"
                , Html.Attributes.style "width" "100%"
                , Html.Attributes.style "height" "100%"
                ]
                [ -- Element A (Blue) - CSS transition managed
                  Html.div
                    [ Html.Attributes.id "element-a"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background" "linear-gradient(135deg, #3B82F6, #2563EB)"
                    , Html.Attributes.style "border-radius" "12px"
                    , Html.Attributes.style "transform" (SmoothMoveCSS.transform positionA.x positionA.y)
                    , Html.Attributes.style "transition" cssTransition
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "16px"
                    ]
                    [ Html.text "A" ]
                , -- Element B (Green) - CSS transition managed
                  Html.div
                    [ Html.Attributes.id "element-b"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background" "linear-gradient(135deg, #10B981, #059669)"
                    , Html.Attributes.style "border-radius" "12px"
                    , Html.Attributes.style "transform" (SmoothMoveCSS.transform positionB.x positionB.y)
                    , Html.Attributes.style "transition" cssTransition
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "16px"
                    ]
                    [ Html.text "B" ]
                , -- Element C (Purple) - CSS transition managed
                  Html.div
                    [ Html.Attributes.id "element-c"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background" "linear-gradient(135deg, #A855F7, #9333EA)"
                    , Html.Attributes.style "border-radius" "12px"
                    , Html.Attributes.style "transform" (SmoothMoveCSS.transform positionC.x positionC.y)
                    , Html.Attributes.style "transition" cssTransition
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "16px"
                    ]
                    [ Html.text "C" ]
                , -- Element D (Orange) - CSS transition managed
                  Html.div
                    [ Html.Attributes.id "element-d"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background" "linear-gradient(135deg, #F97316, #EA580C)"
                    , Html.Attributes.style "border-radius" "12px"
                    , Html.Attributes.style "transform" (SmoothMoveCSS.transform positionD.x positionD.y)
                    , Html.Attributes.style "transition" cssTransition
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "16px"
                    ]
                    [ Html.text "D" ]
                , -- Element E (Red) - CSS transition managed
                  Html.div
                    [ Html.Attributes.id "element-e"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background" "linear-gradient(135deg, #EF4444, #DC2626)"
                    , Html.Attributes.style "border-radius" "12px"
                    , Html.Attributes.style "transform" (SmoothMoveCSS.transform positionE.x positionE.y)
                    , Html.Attributes.style "transition" cssTransition
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "16px"
                    ]
                    [ Html.text "E" ]
                , -- Element F (Pink) - CSS transition managed
                  Html.div
                    [ Html.Attributes.id "element-f"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background" "linear-gradient(135deg, #EC4899, #DB2777)"
                    , Html.Attributes.style "border-radius" "12px"
                    , Html.Attributes.style "transform" (SmoothMoveCSS.transform positionF.x positionF.y)
                    , Html.Attributes.style "transition" cssTransition
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "16px"
                    ]
                    [ Html.text "F" ]
                ]
            )
        )
    ]
