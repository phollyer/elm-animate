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
import SmoothMovePorts



-- PORTS


port animateElement : String -> Cmd msg


port stopElementAnimation : String -> Cmd msg


port positionUpdates : (Decode.Value -> msg) -> Sub msg



-- TYPES


type alias PositionUpdate =
    { elementId : String
    , x : Float
    , y : Float
    , isAnimating : Bool
    }


{-| Decoder for position updates from JavaScript
-}
positionDecoder : Decode.Decoder PositionUpdate
positionDecoder =
    Decode.map4 PositionUpdate
        (Decode.field "elementId" Decode.string)
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)
        (Decode.field "isAnimating" Decode.bool)



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
    { animations : SmoothMovePorts.Model
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with scattered positions across the container (450px × 300px)
        initialAnimations =
            SmoothMovePorts.init
                |> SmoothMovePorts.setInitialPosition "element-a" 50.0 80.0
                -- Top-left area
                |> SmoothMovePorts.setInitialPosition "element-b" 380.0 50.0
                -- Top-right area
                |> SmoothMovePorts.setInitialPosition "element-c" 120.0 220.0
                -- Bottom-left area
                |> SmoothMovePorts.setInitialPosition "element-d" 350.0 180.0
                -- Right-middle area
                |> SmoothMovePorts.setInitialPosition "element-e" 200.0 40.0
                -- Top-center area
                |> SmoothMovePorts.setInitialPosition "element-f" 80.0 140.0

        -- Left-middle area
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Scatter ->
            let
                -- Scatter elements to random positions across the animation area
                ( newAnimations1, cmd1 ) =
                    SmoothMovePorts.animateTo "element-a" 50.0 80.0 model.animations

                ( newAnimations2, cmd2 ) =
                    SmoothMovePorts.animateTo "element-b" 350.0 120.0 newAnimations1

                ( newAnimations3, cmd3 ) =
                    SmoothMovePorts.animateTo "element-c" 120.0 250.0 newAnimations2

                ( newAnimations4, cmd4 ) =
                    SmoothMovePorts.animateTo "element-d" 300.0 280.0 newAnimations3

                ( newAnimations5, cmd5 ) =
                    SmoothMovePorts.animateTo "element-e" 80.0 180.0 newAnimations4

                ( newAnimations6, cmd6 ) =
                    SmoothMovePorts.animateTo "element-f" 380.0 200.0 newAnimations5
            in
            ( { model | animations = newAnimations6 }
            , Cmd.batch
                [ animateElement (SmoothMovePorts.encodeAnimationCommand cmd1)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd2)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd3)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd4)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd5)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd6)
                ]
            )

        Reset ->
            let
                -- Return to scattered starting positions
                ( newAnimations1, cmd1 ) =
                    SmoothMovePorts.animateTo "element-a" 50.0 80.0 model.animations

                -- Top-left area
                ( newAnimations2, cmd2 ) =
                    SmoothMovePorts.animateTo "element-b" 380.0 50.0 newAnimations1

                -- Top-right area
                ( newAnimations3, cmd3 ) =
                    SmoothMovePorts.animateTo "element-c" 120.0 220.0 newAnimations2

                -- Bottom-left area
                ( newAnimations4, cmd4 ) =
                    SmoothMovePorts.animateTo "element-d" 350.0 180.0 newAnimations3

                -- Right-middle area
                ( newAnimations5, cmd5 ) =
                    SmoothMovePorts.animateTo "element-e" 200.0 40.0 newAnimations4

                -- Top-center area
                ( newAnimations6, cmd6 ) =
                    SmoothMovePorts.animateTo "element-f" 80.0 140.0 newAnimations5

                -- Left-middle area
            in
            ( { model | animations = newAnimations6 }
            , Cmd.batch
                [ animateElement (SmoothMovePorts.encodeAnimationCommand cmd1)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd2)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd3)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd4)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd5)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd6)
                ]
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

                ( newAnimations1, cmd1 ) =
                    SmoothMovePorts.animateTo "element-a" centerX (centerY - radius) model.animations

                -- Top (0°)
                ( newAnimations2, cmd2 ) =
                    SmoothMovePorts.animateTo "element-b" (centerX + radius * 0.866) (centerY - radius / 2) newAnimations1

                -- Top-right (60°)
                ( newAnimations3, cmd3 ) =
                    SmoothMovePorts.animateTo "element-c" (centerX + radius * 0.866) (centerY + radius / 2) newAnimations2

                -- Bottom-right (120°)
                ( newAnimations4, cmd4 ) =
                    SmoothMovePorts.animateTo "element-d" centerX (centerY + radius) newAnimations3

                -- Bottom (180°)
                ( newAnimations5, cmd5 ) =
                    SmoothMovePorts.animateTo "element-e" (centerX - radius * 0.866) (centerY + radius / 2) newAnimations4

                -- Bottom-left (240°)
                ( newAnimations6, cmd6 ) =
                    SmoothMovePorts.animateTo "element-f" (centerX - radius * 0.866) (centerY - radius / 2) newAnimations5

                -- Top-left (300°)
            in
            ( { model | animations = newAnimations6 }
            , Cmd.batch
                [ animateElement (SmoothMovePorts.encodeAnimationCommand cmd1)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd2)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd3)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd4)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd5)
                , animateElement (SmoothMovePorts.encodeAnimationCommand cmd6)
                ]
            )

        StopAll ->
            -- Note: Removing StopAll functionality as it's not practical for this demo
            ( model, Cmd.none )

        PositionUpdateMsg value ->
            -- Parse the position update from JavaScript
            case Decode.decodeValue positionDecoder value of
                Ok posUpdate ->
                    let
                        newAnimations =
                            SmoothMovePorts.handlePositionUpdate
                                posUpdate.elementId
                                posUpdate.x
                                posUpdate.y
                                posUpdate.isAnimating
                                model.animations
                    in
                    ( { model | animations = newAnimations }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    positionUpdates PositionUpdateMsg



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
            SmoothMovePorts.getPosition "element-a" model.animations
                |> Maybe.withDefault { x = 225, y = 100 }

        positionB =
            SmoothMovePorts.getPosition "element-b" model.animations
                |> Maybe.withDefault { x = 269, y = 130 }

        positionC =
            SmoothMovePorts.getPosition "element-c" model.animations
                |> Maybe.withDefault { x = 269, y = 170 }

        positionD =
            SmoothMovePorts.getPosition "element-d" model.animations
                |> Maybe.withDefault { x = 225, y = 200 }

        positionE =
            SmoothMovePorts.getPosition "element-e" model.animations
                |> Maybe.withDefault { x = 181, y = 170 }

        positionF =
            SmoothMovePorts.getPosition "element-f" model.animations
                |> Maybe.withDefault { x = 181, y = 130 }

        isAnimating =
            SmoothMovePorts.isAnimating model.animations
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
