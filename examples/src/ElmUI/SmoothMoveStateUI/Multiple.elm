module ElmUI.SmoothMoveStateUI.Multiple exposing (main)

{-| SmoothMoveState Multiple Example using ElmUI - Multiple elements with state-based animation management.

This demonstrates how SmoothMoveState can handle multiple elements simultaneously
with convenient state management functions.

FEATURES:

  - ✅ Multiple independent animations
  - ✅ Predefined formation patterns (scatter, circle, reset)
  - ✅ Single state management for all elements
  - ✅ Built-in easing and animation control
  - ✅ Clean state-based API

-}

import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Ease
import Element exposing (Element, alignLeft, centerX, column, el, fill, height, htmlAttribute, link, maximum, padding, paddingXY, paragraph, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import SmoothMoveState



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
    { animationState : SmoothMoveState.State
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with starting positions to prevent jump to (0,0)
        initialState =
            SmoothMoveState.init
                |> SmoothMoveState.setInitialPosition "element-a" 150 100
                |> SmoothMoveState.setInitialPosition "element-b" 200 150
                |> SmoothMoveState.setInitialPosition "element-c" 100 200
                |> SmoothMoveState.setInitialPosition "element-d" 250 200
                |> SmoothMoveState.setInitialPosition "element-e" 300 100
                |> SmoothMoveState.setInitialPosition "element-f" 180 50
    in
    ( { animationState = initialState }
    , Cmd.none
    )



-- UPDATE


type Msg
    = AnimationFrame Float
    | ScatterElements
    | ResetPositions
    | CircleFormation


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AnimationFrame deltaMs ->
            ( { model | animationState = SmoothMoveState.step deltaMs model.animationState }
            , Cmd.none
            )

        ScatterElements ->
            let
                newState =
                    model.animationState
                        |> SmoothMoveState.animateTo "element-a" 320 80
                        |> SmoothMoveState.animateTo "element-b" 80 280
                        |> SmoothMoveState.animateTo "element-c" 280 220
                        |> SmoothMoveState.animateTo "element-d" 400 180
                        |> SmoothMoveState.animateTo "element-e" 60 120
                        |> SmoothMoveState.animateTo "element-f" 350 320
            in
            ( { model | animationState = newState }, Cmd.none )

        ResetPositions ->
            let
                newState =
                    model.animationState
                        |> SmoothMoveState.animateTo "element-a" 150 100
                        |> SmoothMoveState.animateTo "element-b" 200 150
                        |> SmoothMoveState.animateTo "element-c" 100 200
                        |> SmoothMoveState.animateTo "element-d" 250 200
                        |> SmoothMoveState.animateTo "element-e" 300 100
                        |> SmoothMoveState.animateTo "element-f" 180 50
            in
            ( { model | animationState = newState }, Cmd.none )

        CircleFormation ->
            let
                centerX =
                    225

                centerY =
                    180

                radius =
                    90

                -- 6 elements evenly spaced around circle (60 degrees apart)
                newState =
                    model.animationState
                        |> SmoothMoveState.animateTo "element-a" (centerX + radius) centerY
                        -- 0°
                        |> SmoothMoveState.animateTo "element-b" (centerX + radius * 0.5) (centerY + radius * 0.866)
                        -- 60°
                        |> SmoothMoveState.animateTo "element-c" (centerX - radius * 0.5) (centerY + radius * 0.866)
                        -- 120°
                        |> SmoothMoveState.animateTo "element-d" (centerX - radius) centerY
                        -- 180°
                        |> SmoothMoveState.animateTo "element-e" (centerX - radius * 0.5) (centerY - radius * 0.866)
                        -- 240°
                        |> SmoothMoveState.animateTo "element-f" (centerX + radius * 0.5) (centerY - radius * 0.866)

                -- 300°
            in
            ( { model | animationState = newState }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    SmoothMoveState.subscriptions model.animationState AnimationFrame



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveState Multiple ElmUI Example" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        positionA =
            SmoothMoveState.getPosition "element-a" model.animationState
                |> Maybe.withDefault { x = 150, y = 100 }

        positionB =
            SmoothMoveState.getPosition "element-b" model.animationState
                |> Maybe.withDefault { x = 200, y = 150 }

        positionC =
            SmoothMoveState.getPosition "element-c" model.animationState
                |> Maybe.withDefault { x = 100, y = 200 }

        positionD =
            SmoothMoveState.getPosition "element-d" model.animationState
                |> Maybe.withDefault { x = 250, y = 200 }

        positionE =
            SmoothMoveState.getPosition "element-e" model.animationState
                |> Maybe.withDefault { x = 300, y = 100 }

        positionF =
            SmoothMoveState.getPosition "element-f" model.animationState
                |> Maybe.withDefault { x = 180, y = 50 }

        isMoving =
            SmoothMoveState.isAnimating model.animationState
    in
    [ -- Back Button
      UI.backButton
    , UI.pageHeader "SmoothMoveState Multiple Example"
    , UI.techInfo
        [ paragraph []
            [ text "This example demonstrates the SmoothMoveState module handling "
            , el [ Font.semiBold ] (text "multiple independent animations")
            , text " with comprehensive state management. It showcases "
            , el [ Font.semiBold ] (text "simplified coordination")
            , text " of complex multi-element animations while preserving individual element positioning data."
            ]
        , paragraph []
            [ text "Perfect for choreographed animations, UI transitions, and formation-based layouts with "
            , el [ Font.semiBold ] (text "reduced complexity")
            , text " compared to managing individual subscription states."
            ]
        ]
    , -- Status display section will be added below
      column [ spacing 20, centerX, width fill ]
        [ -- Element status and positions (6 elements in 2 rows)
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
                    [ el [ Font.size 14, Font.medium, Font.color (rgb255 59 130 246) ] (text "A")
                    , el [ Font.size 10, Font.color (rgb255 107 114 128) ]
                        (text ("(" ++ String.fromInt (round positionA.x) ++ "," ++ String.fromInt (round positionA.y) ++ ")"))
                    ]
                , column
                    [ spacing 6 ]
                    [ el [ Font.size 14, Font.medium, Font.color (rgb255 16 185 129) ] (text "B")
                    , el [ Font.size 10, Font.color (rgb255 107 114 128) ]
                        (text ("(" ++ String.fromInt (round positionB.x) ++ "," ++ String.fromInt (round positionB.y) ++ ")"))
                    ]
                , column
                    [ spacing 6 ]
                    [ el [ Font.size 14, Font.medium, Font.color (rgb255 168 85 247) ] (text "C")
                    , el [ Font.size 10, Font.color (rgb255 107 114 128) ]
                        (text ("(" ++ String.fromInt (round positionC.x) ++ "," ++ String.fromInt (round positionC.y) ++ ")"))
                    ]
                ]
            , row
                [ spacing 25
                , centerX
                ]
                [ column
                    [ spacing 6 ]
                    [ el [ Font.size 14, Font.medium, Font.color (rgb255 245 101 101) ] (text "D")
                    , el [ Font.size 10, Font.color (rgb255 107 114 128) ]
                        (text ("(" ++ String.fromInt (round positionD.x) ++ "," ++ String.fromInt (round positionD.y) ++ ")"))
                    ]
                , column
                    [ spacing 6 ]
                    [ el [ Font.size 14, Font.medium, Font.color (rgb255 251 146 60) ] (text "E")
                    , el [ Font.size 10, Font.color (rgb255 107 114 128) ]
                        (text ("(" ++ String.fromInt (round positionE.x) ++ "," ++ String.fromInt (round positionE.y) ++ ")"))
                    ]
                , column
                    [ spacing 6 ]
                    [ el [ Font.size 14, Font.medium, Font.color (rgb255 34 197 94) ] (text "F")
                    , el [ Font.size 10, Font.color (rgb255 107 114 128) ]
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
            [ width <|
                maximum 500 fill
            , height <|
                px 400
            , paddingXY 5 0
            ]
          <|
            el
                [ width fill
                , height fill
                , centerX
                , Background.color (rgb255 255 255 255)
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
                        [ -- Element A (Blue)
                          Html.div
                            [ Html.Attributes.id "element-a"
                            , Html.Attributes.style "position" "absolute"
                            , Html.Attributes.style "width" "50px"
                            , Html.Attributes.style "height" "50px"
                            , Html.Attributes.style "background" "linear-gradient(135deg, #3B82F6, #2563EB)"
                            , Html.Attributes.style "border-radius" "12px"
                            , Html.Attributes.style "transform" (SmoothMoveState.transform positionA.x positionA.y)
                            , Html.Attributes.style "transition" "none"
                            , Html.Attributes.style "display" "flex"
                            , Html.Attributes.style "align-items" "center"
                            , Html.Attributes.style "justify-content" "center"
                            , Html.Attributes.style "color" "white"
                            , Html.Attributes.style "font-weight" "600"
                            , Html.Attributes.style "font-size" "16px"
                            ]
                            [ Html.text "A" ]
                        , -- Element B (Green)
                          Html.div
                            [ Html.Attributes.id "element-b"
                            , Html.Attributes.style "position" "absolute"
                            , Html.Attributes.style "width" "50px"
                            , Html.Attributes.style "height" "50px"
                            , Html.Attributes.style "background" "linear-gradient(135deg, #10B981, #059669)"
                            , Html.Attributes.style "border-radius" "12px"
                            , Html.Attributes.style "transform" (SmoothMoveState.transform positionB.x positionB.y)
                            , Html.Attributes.style "transition" "none"
                            , Html.Attributes.style "display" "flex"
                            , Html.Attributes.style "align-items" "center"
                            , Html.Attributes.style "justify-content" "center"
                            , Html.Attributes.style "color" "white"
                            , Html.Attributes.style "font-weight" "600"
                            , Html.Attributes.style "font-size" "16px"
                            ]
                            [ Html.text "B" ]
                        , -- Element C (Purple)
                          Html.div
                            [ Html.Attributes.id "element-c"
                            , Html.Attributes.style "position" "absolute"
                            , Html.Attributes.style "width" "50px"
                            , Html.Attributes.style "height" "50px"
                            , Html.Attributes.style "background" "linear-gradient(135deg, #A855F7, #9333EA)"
                            , Html.Attributes.style "border-radius" "12px"
                            , Html.Attributes.style "transform" (SmoothMoveState.transform positionC.x positionC.y)
                            , Html.Attributes.style "transition" "none"
                            , Html.Attributes.style "display" "flex"
                            , Html.Attributes.style "align-items" "center"
                            , Html.Attributes.style "justify-content" "center"
                            , Html.Attributes.style "color" "white"
                            , Html.Attributes.style "font-weight" "600"
                            , Html.Attributes.style "font-size" "16px"
                            ]
                            [ Html.text "C" ]
                        , -- Element D (Orange)
                          Html.div
                            [ Html.Attributes.id "element-d"
                            , Html.Attributes.style "position" "absolute"
                            , Html.Attributes.style "width" "50px"
                            , Html.Attributes.style "height" "50px"
                            , Html.Attributes.style "background" "linear-gradient(135deg, #F97316, #EA580C)"
                            , Html.Attributes.style "border-radius" "12px"
                            , Html.Attributes.style "transform" (SmoothMoveState.transform positionD.x positionD.y)
                            , Html.Attributes.style "transition" "none"
                            , Html.Attributes.style "display" "flex"
                            , Html.Attributes.style "align-items" "center"
                            , Html.Attributes.style "justify-content" "center"
                            , Html.Attributes.style "color" "white"
                            , Html.Attributes.style "font-weight" "600"
                            , Html.Attributes.style "font-size" "16px"
                            ]
                            [ Html.text "D" ]
                        , -- Element E (Red)
                          Html.div
                            [ Html.Attributes.id "element-e"
                            , Html.Attributes.style "position" "absolute"
                            , Html.Attributes.style "width" "50px"
                            , Html.Attributes.style "height" "50px"
                            , Html.Attributes.style "background" "linear-gradient(135deg, #EF4444, #DC2626)"
                            , Html.Attributes.style "border-radius" "12px"
                            , Html.Attributes.style "transform" (SmoothMoveState.transform positionE.x positionE.y)
                            , Html.Attributes.style "transition" "none"
                            , Html.Attributes.style "display" "flex"
                            , Html.Attributes.style "align-items" "center"
                            , Html.Attributes.style "justify-content" "center"
                            , Html.Attributes.style "color" "white"
                            , Html.Attributes.style "font-weight" "600"
                            , Html.Attributes.style "font-size" "16px"
                            ]
                            [ Html.text "E" ]
                        , -- Element F (Pink)
                          Html.div
                            [ Html.Attributes.id "element-f"
                            , Html.Attributes.style "position" "absolute"
                            , Html.Attributes.style "width" "50px"
                            , Html.Attributes.style "height" "50px"
                            , Html.Attributes.style "background" "linear-gradient(135deg, #EC4899, #DB2777)"
                            , Html.Attributes.style "border-radius" "12px"
                            , Html.Attributes.style "transform" (SmoothMoveState.transform positionF.x positionF.y)
                            , Html.Attributes.style "transition" "none"
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
    ]


responsiveCSS : String
responsiveCSS =
    """
    <style>
    .responsive-layout {
        min-height: 100vh;
        padding: 20px;
        box-sizing: border-box;
    }
    
    .responsive-container {
        max-width: 1200px;
        width: 100%;
        margin: 0 auto;
    }
    
    .responsive-header {
        font-size: 32px;
        line-height: 1.2;
        margin-bottom: 30px;
    }
    
    .responsive-tech-info {
        background-color: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 8px;
        padding: 16px;
        margin-bottom: 30px;
    }
    
    .responsive-buttons {
        display: flex;
        flex-wrap: wrap;
        gap: 12px;
        margin-bottom: 30px;
    }
    
    .responsive-buttons > * {
        min-height: 44px;
        min-width: 44px;
    }
    
    .responsive-paragraph {
        line-height: 1.6;
        margin-bottom: 20px;
    }
    
    /* Tablet breakpoint */
    @media (max-width: 768px) {
        .responsive-layout {
            padding: 16px;
        }
        
        .responsive-header {
            font-size: 24px;
            margin-bottom: 24px;
        }
        
        .responsive-tech-info {
            padding: 12px;
            margin-bottom: 24px;
        }
        
        .responsive-buttons {
            margin-bottom: 24px;
        }
        
        .responsive-paragraph {
            margin-bottom: 16px;
        }
    }
    
    /* Mobile breakpoint */
    @media (max-width: 480px) {
        .responsive-layout {
            padding: 12px;
        }
        
        .responsive-header {
            font-size: 20px;
            margin-bottom: 20px;
        }
        
        .responsive-tech-info {
            padding: 10px;
            margin-bottom: 20px;
        }
        
        .responsive-buttons {
            margin-bottom: 20px;
        }
        
        .responsive-paragraph {
            margin-bottom: 14px;
        }
    }
    </style>
    """
