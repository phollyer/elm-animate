module ElmUI.SmoothMoveSub.Multiple.Main exposing (main)

{-| This example demonstrates MULTIPLE SIMULTANEOUS ANIMATIONS using ElmUI!

🎉 NEW FEATURES:

  - ✅ Multiple elements can animate at the same time
  - ✅ Each element has independent animation state
  - ✅ No blocking between different animations
  - ✅ Single subscription handles all animations efficiently
  - ✅ Clean API - same functions work for single or multiple

ARCHITECTURE:

  - Model tracks multiple activeAnimations: List AnimationState
  - animateTo adds new animations without stopping existing ones
  - update processes all active animations each frame
  - transform with getPosition works for any number of elements

-}

import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html
import Html.Attributes
import SmoothMoveSub exposing (animateTo, getPosition, isAnimating, setInitialPosition, transform)



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
    { smoothMove : SmoothMoveSub.Model
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        smoothMove =
            SmoothMoveSub.init
                |> setInitialPosition "element-a" 150 100
                |> setInitialPosition "element-b" 200 150
                |> setInitialPosition "element-c" 100 200
                |> setInitialPosition "element-d" 250 200
                |> setInitialPosition "element-e" 300 100
                |> setInitialPosition "element-f" 180 50
    in
    ( { smoothMove = smoothMove }, Cmd.none )



-- UPDATE


type Msg
    = AnimationFrame Float
    | ScatterElements
    | ResetPositions
    | CircleFormation
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AnimationFrame deltaMs ->
            let
                updatedSmoothMove =
                    SmoothMoveSub.step deltaMs model.smoothMove
            in
            ( { model | smoothMove = updatedSmoothMove }, Cmd.none )

        ScatterElements ->
            let
                updatedSmoothMove =
                    model.smoothMove
                        |> animateTo "element-a" 320 80
                        |> animateTo "element-b" 80 280
                        |> animateTo "element-c" 280 220
                        |> animateTo "element-d" 400 180
                        |> animateTo "element-e" 60 120
                        |> animateTo "element-f" 350 320
            in
            ( { model | smoothMove = updatedSmoothMove }, Cmd.none )

        ResetPositions ->
            let
                updatedSmoothMove =
                    model.smoothMove
                        |> animateTo "element-a" 150 100
                        |> animateTo "element-b" 200 150
                        |> animateTo "element-c" 100 200
                        |> animateTo "element-d" 250 200
                        |> animateTo "element-e" 300 100
                        |> animateTo "element-f" 180 50
            in
            ( { model | smoothMove = updatedSmoothMove }, Cmd.none )

        CircleFormation ->
            let
                centerX =
                    225

                centerY =
                    180

                radius =
                    90

                -- 6 elements evenly spaced around circle (60 degrees apart)
                updatedSmoothMove =
                    model.smoothMove
                        |> animateTo "element-a" (centerX + radius) centerY
                        -- 0°
                        |> animateTo "element-b" (centerX + radius * 0.5) (centerY + radius * 0.866)
                        -- 60°
                        |> animateTo "element-c" (centerX - radius * 0.5) (centerY + radius * 0.866)
                        -- 120°
                        |> animateTo "element-d" (centerX - radius) centerY
                        -- 180°
                        |> animateTo "element-e" (centerX - radius * 0.5) (centerY - radius * 0.866)
                        -- 240°
                        |> animateTo "element-f" (centerX + radius * 0.5) (centerY - radius * 0.866)

                -- 300°
            in
            ( { model | smoothMove = updatedSmoothMove }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    SmoothMoveSub.subscriptions model.smoothMove AnimationFrame



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveSub Multiple ElmUI Example" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        positionA =
            getPosition "element-a" model.smoothMove |> Maybe.withDefault { x = 150, y = 100 }

        positionB =
            getPosition "element-b" model.smoothMove |> Maybe.withDefault { x = 200, y = 150 }

        positionC =
            getPosition "element-c" model.smoothMove |> Maybe.withDefault { x = 100, y = 200 }

        positionD =
            getPosition "element-d" model.smoothMove |> Maybe.withDefault { x = 250, y = 200 }

        positionE =
            getPosition "element-e" model.smoothMove |> Maybe.withDefault { x = 300, y = 100 }

        positionF =
            getPosition "element-f" model.smoothMove |> Maybe.withDefault { x = 180, y = 50 }

        -- isAnimating only takes the model, checks if any element is animating
        isMoving =
            isAnimating model.smoothMove
    in
    [ UI.backButton
    , UI.pageHeader "SmoothMoveSub Multiple Example"
    , UI.techInfo
        [ paragraph []
            [ text "This example demonstrates the SmoothMoveSub module coordinating "
            , el [ Font.semiBold ] (text "multiple elements simultaneously")
            , text " with subscription-based animations. Each element receives "
            , el [ Font.semiBold ] (text "frame-rate independent updates")
            , text ", ensuring smooth formation control and synchronized movement patterns across different device capabilities."
            ]
        , paragraph []
            [ text "Perfect for complex choreographed animations where "
            , el [ Font.semiBold ] (text "precise timing synchronization")
            , text " and real-time positioning control are essential requirements."
            ]
        ]
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
                [ el [ Font.size 14, Font.medium, Font.color Colors.warning ] (text "E")
                , el [ Font.size 10, Font.color Colors.textMedium ]
                    (text ("(" ++ String.fromInt (round positionE.x) ++ "," ++ String.fromInt (round positionE.y) ++ ")"))
                ]
            , column
                [ spacing 6 ]
                [ el [ Font.size 14, Font.medium, Font.color Colors.success ] (text "F")
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
        , htmlAttribute (Html.Attributes.class "responsive-animation-container")
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
                    , Html.Attributes.style "background-color" "#3B82F6"
                    , Html.Attributes.style "border-radius" "8px"
                    , Html.Attributes.style "transform" (transform positionA.x positionA.y)
                    , Html.Attributes.style "transition" "none"
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "14px"
                    ]
                    [ Html.text "A" ]
                , -- Element B (Green)
                  Html.div
                    [ Html.Attributes.id "element-b"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background-color" "#10B981"
                    , Html.Attributes.style "border-radius" "8px"
                    , Html.Attributes.style "transform" (transform positionB.x positionB.y)
                    , Html.Attributes.style "transition" "none"
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "14px"
                    ]
                    [ Html.text "B" ]
                , -- Element C (Purple)
                  Html.div
                    [ Html.Attributes.id "element-c"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background-color" "#A855F7"
                    , Html.Attributes.style "border-radius" "8px"
                    , Html.Attributes.style "transform" (transform positionC.x positionC.y)
                    , Html.Attributes.style "transition" "none"
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "14px"
                    ]
                    [ Html.text "C" ]
                , -- Element D (Red)
                  Html.div
                    [ Html.Attributes.id "element-d"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background-color" "#F56565"
                    , Html.Attributes.style "border-radius" "8px"
                    , Html.Attributes.style "transform" (transform positionD.x positionD.y)
                    , Html.Attributes.style "transition" "none"
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "14px"
                    ]
                    [ Html.text "D" ]
                , -- Element E (Orange)
                  Html.div
                    [ Html.Attributes.id "element-e"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background-color" "#FB923C"
                    , Html.Attributes.style "border-radius" "8px"
                    , Html.Attributes.style "transform" (transform positionE.x positionE.y)
                    , Html.Attributes.style "transition" "none"
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "14px"
                    ]
                    [ Html.text "E" ]
                , -- Element F (Teal)
                  Html.div
                    [ Html.Attributes.id "element-f"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background-color" "#22C55E"
                    , Html.Attributes.style "border-radius" "8px"
                    , Html.Attributes.style "transform" (transform positionF.x positionF.y)
                    , Html.Attributes.style "transition" "none"
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "14px"
                    ]
                    [ Html.text "F" ]
                ]
            )
        )
    ]
