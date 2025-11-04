module ElmUI.Sub.Multiple.Main exposing (main)

{-| This example demonstrates MULTIPLE SIMULTANEOUS ANIMATIONS using Move.Sub with ElmUI!

🎉 NEW FEATURES:

  - ✅ Multiple elements can animate at the same time
  - ✅ Each element has independent animation state
  - ✅ No blocking between different animations
  - ✅ Single subscription handles all animations efficiently
  - ✅ Clean API - same functions work for single or multiple

ARCHITECTURE:

  - Model tracks animation state for all elements in Move.Sub.Model
  - animateTo adds new animations without stopping existing ones
  - step function processes all active animations each frame
  - transform with element ID works for any number of elements

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
import Anim exposing (Position)
import Anim.Sub exposing (Model, animateTo, getPosition, isAnimating, setPosition, step, subscriptions, transform)



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
    { smoothMove : Anim.Sub.Model
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        smoothMove =
            Anim.Sub.init
                |> setPosition "element-a" (Position 150 100)
                |> setPosition "element-b" (Position 200 150)
                |> setPosition "element-c" (Position 100 200)
                |> setPosition "element-d" (Position 250 200)
                |> setPosition "element-e" (Position 300 100)
                |> setPosition "element-f" (Position 180 50)
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
                    step deltaMs model.smoothMove
            in
            ( { model | smoothMove = updatedSmoothMove }, Cmd.none )

        ScatterElements ->
            let
                updatedSmoothMove =
                    model.smoothMove
                        |> animateTo "element-a" (Position 320 80)
                        |> animateTo "element-b" (Position 80 280)
                        |> animateTo "element-c" (Position 280 220)
                        |> animateTo "element-d" (Position 400 180)
                        |> animateTo "element-e" (Position 60 120)
                        |> animateTo "element-f" (Position 350 320)
            in
            ( { model | smoothMove = updatedSmoothMove }, Cmd.none )

        ResetPositions ->
            let
                updatedSmoothMove =
                    model.smoothMove
                        |> animateTo "element-a" (Position 150 100)
                        |> animateTo "element-b" (Position 200 150)
                        |> animateTo "element-c" (Position 100 200)
                        |> animateTo "element-d" (Position 250 200)
                        |> animateTo "element-e" (Position 300 100)
                        |> animateTo "element-f" (Position 180 50)
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
                        |> animateTo "element-a" (Position (centerX + radius) centerY)
                        -- 0°
                        |> animateTo "element-b" (Position (centerX + radius * 0.5) (centerY + radius * 0.866))
                        -- 60°
                        |> animateTo "element-c" (Position (centerX - radius * 0.5) (centerY + radius * 0.866))
                        -- 120°
                        |> animateTo "element-d" (Position (centerX - radius) centerY)
                        -- 180°
                        |> animateTo "element-e" (Position (centerX - radius * 0.5) (centerY - radius * 0.866))
                        -- 240°
                        |> animateTo "element-f" (Position (centerX + radius * 0.5) (centerY - radius * 0.866))

                -- 300°
            in
            ( { model | smoothMove = updatedSmoothMove }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Anim.Sub.subscriptions AnimationFrame model.smoothMove



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "Anim.Sub Multiple ElmUI Example" UI.Basic (viewContent model)


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

        -- Check if any of the elements are animating
        isMoving =
            isAnimating "element-a" model.smoothMove
                || isAnimating "element-b" model.smoothMove
                || isAnimating "element-c" model.smoothMove
                || isAnimating "element-d" model.smoothMove
                || isAnimating "element-e" model.smoothMove
                || isAnimating "element-f" model.smoothMove
    in
    [ UI.backButton
    , UI.pageHeader "Anim.Sub Multiple Example"
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
                    , Html.Attributes.style "transform" (transform "element-a" model.smoothMove)
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
                    , Html.Attributes.style "transform" (transform "element-b" model.smoothMove)
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
                    , Html.Attributes.style "transform" (transform "element-c" model.smoothMove)
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
                    , Html.Attributes.style "transform" (transform "element-d" model.smoothMove)
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
                    , Html.Attributes.style "transform" (transform "element-e" model.smoothMove)
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
                    , Html.Attributes.style "transform" (transform "element-f" model.smoothMove)
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
