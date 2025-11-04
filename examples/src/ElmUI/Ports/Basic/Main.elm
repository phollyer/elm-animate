port module ElmUI.Ports.Basic.Main exposing (main)

{-| SmoothMovePorts Basic Example using ElmUI - Web Animations API integration via JavaScript

This approach uses Elm ports to communicate with JavaScript's Web Animations API,
providing access to advanced animation features and platform-specific optimizations.

BENEFITS:

  - ✅ Access to Web Animations API features
  - ✅ Platform-specific optimizations via JavaScript
  - ✅ Complex animation composition capabilities
  - ✅ Fine-grained animation control and timing
  - ✅ Support for advanced easing functions
  - ✅ Real-time position feedback via ports

REQUIREMENTS:

  - Requires companion JavaScript file (smooth-move-ports.js)
  - Needs port definitions for Elm-JavaScript communication
  - Web Animations API support (modern browsers)

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
import Move.Ports exposing (Position, Model, init, setPosition, animateTo, getPosition, transformElement, handlePositionUpdate, handleAnimationComplete, handlePositionUpdateFromJson, encodeAnimationCommand, subscriptions, isAnimating)



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
    { animations : Move.Ports.Model
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with starting position
        initialAnimations =
            Move.Ports.init
                |> Move.Ports.setPosition "moving-box" (Position 0 0)
    in
    ( { animations = initialAnimations }
    , Cmd.none
    )



-- UPDATE


type Msg
    = MoveToCorner
    | MoveToCenter
    | StopAnimation
    | PositionUpdateMsg Decode.Value
    | AnimationCompleteMsg String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToCorner ->
            let
                ( newAnimations, maybeCommand ) =
                    animateTo "moving-box" (Position 100 100) model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newAnimations }
                    , animateElement (encodeAnimationCommand command)
                    )
                
                Nothing ->
                    ( { model | animations = newAnimations }, Cmd.none )

        MoveToCenter ->
            let
                ( newAnimations, maybeCommand ) =
                    animateTo "moving-box" (Position 300 200) model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newAnimations }
                    , animateElement (encodeAnimationCommand command)
                    )
                
                Nothing ->
                    ( { model | animations = newAnimations }, Cmd.none )

        StopAnimation ->
            let
                ( newAnimations, maybeCommand ) =
                    animateTo "moving-box" (Position 0 0) model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newAnimations }
                    , animateElement (encodeAnimationCommand command)
                    )
                
                Nothing ->
                    ( { model | animations = newAnimations }, Cmd.none )

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
        "SmoothMovePorts Basic ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        position =
            getPosition "moving-box" model.animations
                |> Maybe.withDefault (Position 0 0)

        boxIsAnimating =
            isAnimating "moving-box" model.animations
    in
    [ UI.backButton
    , UI.pageHeader "SmoothMovePorts Basic Example"
    , -- Position display
      el
        [ Font.size 14
        , Font.color Colors.textMedium
        , centerX
        ]
        (text ("Position: (" ++ String.fromInt (round position.x) ++ ", " ++ String.fromInt (round position.y) ++ ")"))
    , -- Buttons for predefined moves
      UI.htmlActionButtons
        [ ( UI.Primary, MoveToCorner, "Move to (100, 100)" )
        , ( UI.Success, MoveToCenter, "Move to (300, 200)" )
        , ( UI.Purple, StopAnimation, "Return to Origin" )
        ]
    , -- Animation area with moving box
      el
        [ width (fill |> maximum 500)
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
        , htmlAttribute (Html.Attributes.style "overflow" "hidden")
        ]
        (el
            [ width (px 50)
            , height (px 50)
            , Background.color Colors.primary
            , Border.rounded 8
            , htmlAttribute (Html.Attributes.id "moving-box")
            , htmlAttribute (Html.Attributes.style "position" "absolute")
            , htmlAttribute (Html.Attributes.style "left" (String.fromFloat position.x ++ "px"))
            , htmlAttribute (Html.Attributes.style "top" (String.fromFloat position.y ++ "px"))
            ]
            (text "")
        )
    ]
