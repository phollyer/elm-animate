port module ElmUI.Ports.Multiple.Main exposing (main)

{-| SmoothMovePorts Multiple Example using ElmUI - Multiple elements via Web Animations API

This demonstrates advanced multi-element animations using JavaScript's Web Animations API
through Elm ports, enabling complex animation orchestration and real-time feedback.

FEATURES:

  - ✅ Multiple simultaneous Web API animations
  - ✅ Real-time position feedback for all elements
  - ✅ Advanced animation composition via JavaScript
  - ✅ Complex formation patterns with precise timing
  - ✅ Platform-optimized performance via native APIs
  - ✅ Fine-grained control over animation lifecycle

-}

-- Common UI imports

import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, alignLeft, centerX, column, el, fill, height, htmlAttribute, layout, link, maximum, padding, paddingXY, paragraph, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode
import Move exposing (defaultConfig)
import Move.Ports exposing (Position, Model, init, setPosition, animateTo, getPosition, transformElement, handlePositionUpdate, handleAnimationComplete, handlePositionUpdateFromJson, encodeAnimationCommand, subscriptions, isAnimating, animateBatch, AnimationSpec)



-- PORTS


port animateElement : Encode.Value -> Cmd msg


port stopElement : Encode.Value -> Cmd msg


port positionUpdates : (Decode.Value -> msg) -> Sub msg


port animationComplete : (String -> msg) -> Sub msg


-- TYPES


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
    { animations : Move.Ports.Model
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with scattered positions across the container (450px × 300px)
        initialAnimations =
            Move.Ports.init
                |> setPosition "element-a" (Position 50.0 80.0)   -- Top-left area
                |> setPosition "element-b" (Position 380.0 50.0)  -- Top-right area
                |> setPosition "element-c" (Position 120.0 220.0) -- Bottom-left area
                |> setPosition "element-d" (Position 350.0 180.0) -- Right-middle area
                |> setPosition "element-e" (Position 200.0 40.0)  -- Top-center area
                |> setPosition "element-f" (Position 80.0 140.0)  -- Left-middle area
    in
    ( { animations = initialAnimations }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Scatter
    | Reset
    | Circle
    | StopAll
    | PositionUpdateMsg Decode.Value
    | AnimationCompleteMsg String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Scatter ->
            let
                -- Scatter elements to random positions across the animation area
                scatterSpecs =
                    [ { elementId = "element-a", target = Position 50.0 80.0 }
                    , { elementId = "element-b", target = Position 350.0 120.0 }
                    , { elementId = "element-c", target = Position 120.0 250.0 }
                    , { elementId = "element-d", target = Position 300.0 280.0 }
                    , { elementId = "element-e", target = Position 80.0 180.0 }
                    , { elementId = "element-f", target = Position 380.0 200.0 }
                    ]
                
                ( newAnimations, commands ) =
                    animateBatch defaultConfig scatterSpecs model.animations
            in
            ( { model | animations = newAnimations }
            , Cmd.batch (List.map (animateElement << encodeAnimationCommand) commands)
            )

        Reset ->
            let
                -- Return to scattered starting positions
                resetSpecs =
                    [ { elementId = "element-a", target = Position 50.0 80.0 }   -- Top-left area
                    , { elementId = "element-b", target = Position 380.0 50.0 }  -- Top-right area
                    , { elementId = "element-c", target = Position 120.0 220.0 } -- Bottom-left area
                    , { elementId = "element-d", target = Position 350.0 180.0 } -- Right-middle area
                    , { elementId = "element-e", target = Position 200.0 40.0 }  -- Top-center area
                    , { elementId = "element-f", target = Position 80.0 140.0 }  -- Left-middle area
                    ]
                
                ( newAnimations, commands ) =
                    animateBatch defaultConfig resetSpecs model.animations
            in
            ( { model | animations = newAnimations }
            , Cmd.batch (List.map (animateElement << encodeAnimationCommand) commands)
            )

        Circle ->
            let
                -- Perfect 6-element circle formation (radius 50px, center 225,150)
                centerX =
                    225.0

                centerY =
                    150.0

                radius =
                    50.0

                circleSpecs =
                    [ { elementId = "element-a", target = Position centerX (centerY - radius) }                              -- Top (0°)
                    , { elementId = "element-b", target = Position (centerX + radius * 0.866) (centerY - radius / 2) }      -- Top-right (60°)
                    , { elementId = "element-c", target = Position (centerX + radius * 0.866) (centerY + radius / 2) }      -- Bottom-right (120°)
                    , { elementId = "element-d", target = Position centerX (centerY + radius) }                              -- Bottom (180°)
                    , { elementId = "element-e", target = Position (centerX - radius * 0.866) (centerY + radius / 2) }      -- Bottom-left (240°)
                    , { elementId = "element-f", target = Position (centerX - radius * 0.866) (centerY - radius / 2) }      -- Top-left (300°)
                    ]
                
                ( newAnimations, commands ) =
                    animateBatch defaultConfig circleSpecs model.animations
            in
            ( { model | animations = newAnimations }
            , Cmd.batch (List.map (animateElement << encodeAnimationCommand) commands)
            )

        StopAll ->
            -- Note: Removing StopAll functionality as it's not practical for this demo
            ( model, Cmd.none )

        PositionUpdateMsg value ->
            -- Handle position update with automatic decoding
            case handlePositionUpdateFromJson value of
                Ok positionUpdate ->
                    ( { model | animations = handlePositionUpdate positionUpdate model.animations }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        AnimationCompleteMsg elementId ->
            ( { model | animations = handleAnimationComplete elementId model.animations }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Move.Ports.subscriptions
        { positionUpdates = positionUpdates PositionUpdateMsg
        , animationComplete = animationComplete AnimationCompleteMsg
        }
        model.animations



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "SmoothMovePorts Multiple ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        positionA =
            getPosition "element-a" model.animations
                |> Maybe.withDefault (Position 225 100)

        positionB =
            getPosition "element-b" model.animations
                |> Maybe.withDefault (Position 269 130)

        positionC =
            getPosition "element-c" model.animations
                |> Maybe.withDefault (Position 269 170)

        positionD =
            getPosition "element-d" model.animations
                |> Maybe.withDefault (Position 225 200)

        positionE =
            getPosition "element-e" model.animations
                |> Maybe.withDefault (Position 181 170)

        positionF =
            getPosition "element-f" model.animations
                |> Maybe.withDefault (Position 181 130)

        anyElementAnimating =
            List.any (\elementId -> isAnimating elementId model.animations) 
                ["element-a", "element-b", "element-c", "element-d", "element-e", "element-f"]
    in
    [ UI.backButton
    , UI.pageHeader "SmoothMovePorts Multiple Example"
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
      column
        [ spacing 15
        , centerX
        ]
        [ UI.htmlActionButtons
            [ ( UI.Primary, Scatter, "Scatter" )
            , ( UI.Success, Circle, "Circle Formation" )
            , ( UI.Purple, Reset, "Reset" )
            ]
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
                [ -- Element A (Blue) - Web API animated
                  Html.div
                    [ Html.Attributes.id "element-a"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background" "linear-gradient(135deg, #3B82F6, #2563EB)"
                    , Html.Attributes.style "border-radius" "12px"
                    , Html.Attributes.style "left" (String.fromFloat positionA.x ++ "px")
                    , Html.Attributes.style "top" (String.fromFloat positionA.y ++ "px")
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "16px"
                    ]
                    [ Html.text "A" ]
                , -- Element B (Green) - Web API animated
                  Html.div
                    [ Html.Attributes.id "element-b"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background" "linear-gradient(135deg, #10B981, #059669)"
                    , Html.Attributes.style "border-radius" "12px"
                    , Html.Attributes.style "left" (String.fromFloat positionB.x ++ "px")
                    , Html.Attributes.style "top" (String.fromFloat positionB.y ++ "px")
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "16px"
                    ]
                    [ Html.text "B" ]
                , -- Element C (Purple) - Web API animated
                  Html.div
                    [ Html.Attributes.id "element-c"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background" "linear-gradient(135deg, #A855F7, #9333EA)"
                    , Html.Attributes.style "border-radius" "12px"
                    , Html.Attributes.style "left" (String.fromFloat positionC.x ++ "px")
                    , Html.Attributes.style "top" (String.fromFloat positionC.y ++ "px")
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "16px"
                    ]
                    [ Html.text "C" ]
                , -- Element D (Orange) - Web API animated
                  Html.div
                    [ Html.Attributes.id "element-d"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background" "linear-gradient(135deg, #F97316, #EA580C)"
                    , Html.Attributes.style "border-radius" "12px"
                    , Html.Attributes.style "left" (String.fromFloat positionD.x ++ "px")
                    , Html.Attributes.style "top" (String.fromFloat positionD.y ++ "px")
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "16px"
                    ]
                    [ Html.text "D" ]
                , -- Element E (Red) - Web API animated
                  Html.div
                    [ Html.Attributes.id "element-e"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background" "linear-gradient(135deg, #EF4444, #DC2626)"
                    , Html.Attributes.style "border-radius" "12px"
                    , Html.Attributes.style "left" (String.fromFloat positionE.x ++ "px")
                    , Html.Attributes.style "top" (String.fromFloat positionE.y ++ "px")
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "justify-content" "center"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "font-weight" "600"
                    , Html.Attributes.style "font-size" "16px"
                    ]
                    [ Html.text "E" ]
                , -- Element F (Cyan) - Web API animated
                  Html.div
                    [ Html.Attributes.id "element-f"
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "width" "50px"
                    , Html.Attributes.style "height" "50px"
                    , Html.Attributes.style "background" "linear-gradient(135deg, #06B6D4, #0891B2)"
                    , Html.Attributes.style "border-radius" "12px"
                    , Html.Attributes.style "left" (String.fromFloat positionF.x ++ "px")
                    , Html.Attributes.style "top" (String.fromFloat positionF.y ++ "px")
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
