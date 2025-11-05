port module ElmUI.Ports.Rotation.Main exposing (main)

{-| Anim.CSS Rotation Example using ElmUI - Rotation transformation animations

This example demonstrates smooth rotation animations using browser-native CSS transforms.
Perfect for loading spinners, interactive elements, and dynamic orientation changes.

FEATURES:

  - ✅ Smooth rotation animations in degrees
  - ✅ Hardware-accelerated transform rotations
  - ✅ Multiple rotation directions and speeds
  - ✅ Continuous spinning and specific angle targeting
  - ✅ Battery efficient browser-native transforms

-}

import Anim exposing (RotationValue, defaultConfig)
import Anim.Ports exposing (Model, animateRotation, encodeAnimationCommand, handlePropertyUpdateFromJson, init, styleProperties)
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode



-- PORTS


port animateElement : Encode.Value -> Cmd msg


port stopElement : Encode.Value -> Cmd msg


port positionUpdates : (Decode.Value -> msg) -> Sub msg


port animationComplete : (String -> msg) -> Sub msg



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
    { animations : Anim.Ports.Model
    }


type Msg
    = Rotate45
    | Rotate90
    | Rotate180
    | RotateLeft
    | RotateRight
    | ResetRotation
    | AnimationComplete String
    | PositionUpdateReceived (Result Decode.Error Anim.Ports.PropertyUpdate)



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Rotate45 ->
            let
                ( newModel, maybeCommand ) =
                    animateRotation "box" 45 model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel }
                    , animateElement (encodeAnimationCommand command)
                    )

                Nothing ->
                    ( model, Cmd.none )

        Rotate90 ->
            let
                ( newModel, maybeCommand ) =
                    animateRotation "box" 90 model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel }
                    , animateElement (encodeAnimationCommand command)
                    )

                Nothing ->
                    ( model, Cmd.none )

        Rotate180 ->
            let
                ( newModel, maybeCommand ) =
                    animateRotation "box" 180 model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel }
                    , animateElement (encodeAnimationCommand command)
                    )

                Nothing ->
                    ( model, Cmd.none )

        RotateLeft ->
            let
                ( newModel, maybeCommand ) =
                    animateRotation "box" -90 model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel }
                    , animateElement (encodeAnimationCommand command)
                    )

                Nothing ->
                    ( model, Cmd.none )

        RotateRight ->
            let
                ( newModel, maybeCommand ) =
                    animateRotation "box" 90 model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel }
                    , animateElement (encodeAnimationCommand command)
                    )

                Nothing ->
                    ( model, Cmd.none )

        ResetRotation ->
            let
                ( newModel, maybeCommand ) =
                    animateRotation "box" 0 model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel }
                    , animateElement (encodeAnimationCommand command)
                    )

                Nothing ->
                    ( model, Cmd.none )

        AnimationComplete _ ->
            ( model, Cmd.none )

        PositionUpdateReceived result ->
            case result of
                Ok propertyUpdate ->
                    ( { model | animations = Anim.Ports.handlePropertyUpdate propertyUpdate model.animations }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.Ports.init
      }
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ positionUpdates (PositionUpdateReceived << handlePropertyUpdateFromJson)
        , animationComplete AnimationComplete
        ]



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Ports Rotation ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "Ports Rotation Animations"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth rotation transformations using hardware-accelerated CSS transforms")
    , -- Rotation controls
      UI.htmlActionButtons
        [ ( UI.Success, Rotate45, "45°" )
        , ( UI.Warning, Rotate90, "90°" )
        , ( UI.Primary, Rotate180, "180°" )
        , ( UI.Success, RotateLeft, "← 90°" )
        , ( UI.Purple, ResetRotation, "Reset" )
        ]
    , -- Animation area with boxes
      el
        [ width (fill |> maximum 600)
        , height (px 400)
        , Background.color Colors.backgroundWhite
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.1
            }
        , centerX
        , htmlAttribute (Html.Attributes.style "position" "relative")
        , htmlAttribute (Html.Attributes.style "overflow" "visible")
        , htmlAttribute (Html.Attributes.style "display" "flex")
        , htmlAttribute (Html.Attributes.style "flex-direction" "column")
        , htmlAttribute (Html.Attributes.style "align-items" "center")
        , htmlAttribute (Html.Attributes.style "justify-content" "space-around")
        , htmlAttribute (Html.Attributes.style "padding" "40px")
        ]
        (el
            [ centerX
            , Element.centerY
            , width (px 200)
            , height (px 200)
            ]
            (rotatingElement "box" "→" "Rotation Demo" Colors.primary model)
        )
    ]


rotatingElement : String -> String -> String -> Element.Color -> Model -> Element Msg
rotatingElement elementId symbol label color model =
    el
        ([ width (px 150)
         , height (px 150)
         , Background.color color
         , Border.rounded 12
         , centerX
         , htmlAttribute (Html.Attributes.id elementId)
         , htmlAttribute (Html.Attributes.style "transform-origin" "center")
         , htmlAttribute (Html.Attributes.style "display" "flex")
         , htmlAttribute (Html.Attributes.style "align-items" "center")
         , htmlAttribute (Html.Attributes.style "justify-content" "center")
         ]
            ++ (styleProperties elementId model.animations
                    |> List.map (\( prop, value ) -> htmlAttribute (Html.Attributes.style prop value))
               )
        )
        (column
            [ centerX
            , Element.centerY
            , spacing 8
            ]
            [ el
                [ centerX
                , Font.color Colors.backgroundWhite
                , Font.bold
                , Font.size 32
                ]
                (text symbol)
            , el
                [ centerX
                , Font.color Colors.backgroundWhite
                , Font.size 14
                ]
                (text label)
            ]
        )
