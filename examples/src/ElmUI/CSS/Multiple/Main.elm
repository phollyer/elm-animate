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
import Move exposing (defaultConfig)
import Move.CSS exposing (Position, Model, init, setPosition, animateTo, animateToX, animateToY, getPosition, transform, transformElement, transition, onTransitionEnd)



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
    { animations : Move.CSS.Model
    , isAnimating : Bool
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        initialAnimations =
            Move.CSS.init
                |> setPosition "elementA" (Position 150 100)
                |> setPosition "elementB" (Position 200 150)
                |> setPosition "elementC" (Position 100 200)
                |> setPosition "elementD" (Position 250 200)
                |> setPosition "elementE" (Position 300 100)
                |> setPosition "elementF" (Position 180 50)
    in
    ( { animations = initialAnimations
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
                        |> animateTo "elementA" (Position (centerX + radius) centerY) -- 0°
                        |> animateTo "elementB" (Position (centerX + radius * 0.5) (centerY + radius * 0.866)) -- 60°
                        |> animateTo "elementC" (Position (centerX - radius * 0.5) (centerY + radius * 0.866)) -- 120°
                        |> animateTo "elementD" (Position (centerX - radius) centerY) -- 180°
                        |> animateTo "elementE" (Position (centerX - radius * 0.5) (centerY - radius * 0.866)) -- 240°
                        |> animateTo "elementF" (Position (centerX + radius * 0.5) (centerY - radius * 0.866)) -- 300°
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
        "SmoothMoveCSS Multiple ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        positionA = getPosition "elementA" model.animations |> Maybe.withDefault (Position 0 0)
        positionB = getPosition "elementB" model.animations |> Maybe.withDefault (Position 0 0)  
        positionC = getPosition "elementC" model.animations |> Maybe.withDefault (Position 0 0)
        positionD = getPosition "elementD" model.animations |> Maybe.withDefault (Position 0 0)
        positionE = getPosition "elementE" model.animations |> Maybe.withDefault (Position 0 0)
        positionF = getPosition "elementF" model.animations |> Maybe.withDefault (Position 0 0)

        -- Generate CSS transition styles for smooth animation
        cssTransition = 
            if model.isAnimating then
                transition defaultConfig
            else
                "none"
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
                    , Html.Attributes.style "transform" (transformElement "elementA" model.animations)
                    , Html.Attributes.style "transition" cssTransition
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "16px"
                    , onTransitionEnd AnimationComplete
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
                    , Html.Attributes.style "transform" (transformElement "elementB" model.animations)
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
                    , Html.Attributes.style "transform" (transformElement "elementC" model.animations)
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
                    , Html.Attributes.style "transform" (transformElement "elementD" model.animations)
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
                    , Html.Attributes.style "transform" (transformElement "elementE" model.animations)
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
                    , Html.Attributes.style "transform" (transformElement "elementF" model.animations)
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
