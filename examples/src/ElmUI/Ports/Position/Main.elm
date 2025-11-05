port module ElmUI.Ports.Position.Main exposing (main)

{-| Anim.Ports Position Example using ElmUI - Element position animations using JavaScript Web Animations API

This example demonstrates smooth position transitions using port-based JavaScript integration with Web Animations API.
Perfect for high-performance animations with hardware acceleration and full platform capabilities.

FEATURES:

  - ✅ Smooth position animations (X and Y coordinates) via JavaScript ports
  - ✅ Independent axis movement (animateToX, animateToY)
  - ✅ Web Animations API integration for optimal performance
  - ✅ Predefined position targets and directional movement
  - ✅ Real-time position display with port-based updates

USAGE:

  - Use animateTo for absolute positioning (Position x y) via ports
  - Use animateToX/animateToY for single-axis movement
  - Position values are in pixels relative to container
  - JavaScript handles animation execution and progress updates

-}

import Anim exposing (Position, defaultConfig)
import Anim.Ports exposing (Model, animateTo, animateToX, animateToY, encodeAnimationCommand, getPosition, handlePropertyUpdateFromJson, init, styleProperties)
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
    , isAnimating : Bool
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.Ports.init
      , isAnimating = False
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = MoveToCorner
    | MoveToCenter
    | MoveLeft
    | MoveRight
    | MoveUp
    | MoveDown
    | StopAnimation
    | AnimationComplete String
    | PositionUpdateReceived (Result Decode.Error Anim.Ports.PropertyUpdate)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToCorner ->
            let
                ( newModel, maybeCommand ) =
                    animateTo "box" (Position 100 100) model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel, isAnimating = True }
                    , animateElement (encodeAnimationCommand command)
                    )

                Nothing ->
                    ( model, Cmd.none )

        MoveToCenter ->
            let
                ( newModel, maybeCommand ) =
                    animateTo "box" (Position 300 200) model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel, isAnimating = True }
                    , animateElement (encodeAnimationCommand command)
                    )

                Nothing ->
                    ( model, Cmd.none )

        MoveLeft ->
            let
                ( newModel, maybeCommand ) =
                    animateToX "box" 0 model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel, isAnimating = True }
                    , animateElement (encodeAnimationCommand command)
                    )

                Nothing ->
                    ( model, Cmd.none )

        MoveRight ->
            let
                ( newModel, maybeCommand ) =
                    animateToX "box" 450 model.animations

                -- 500px container - 50px box = 450px for right edge
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel, isAnimating = True }
                    , animateElement (encodeAnimationCommand command)
                    )

                Nothing ->
                    ( model, Cmd.none )

        MoveUp ->
            let
                ( newModel, maybeCommand ) =
                    animateToY "box" 0 model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel, isAnimating = True }
                    , animateElement (encodeAnimationCommand command)
                    )

                Nothing ->
                    ( model, Cmd.none )

        MoveDown ->
            let
                ( newModel, maybeCommand ) =
                    animateToY "box" 350 model.animations

                -- 400px container - 50px box = 350px for bottom edge
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel, isAnimating = True }
                    , animateElement (encodeAnimationCommand command)
                    )

                Nothing ->
                    ( model, Cmd.none )

        StopAnimation ->
            let
                ( newModel, maybeCommand ) =
                    animateTo "box" (Position 0 0) model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel, isAnimating = True }
                    , animateElement (encodeAnimationCommand command)
                    )

                Nothing ->
                    ( model, Cmd.none )

        AnimationComplete _ ->
            ( { model | isAnimating = False }
            , Cmd.none
            )

        PositionUpdateReceived result ->
            case result of
                Ok propertyUpdate ->
                    ( { model | animations = Anim.Ports.handlePropertyUpdate propertyUpdate model.animations }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )



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
    UI.createDocument "Anim.Ports Position ElmUI Example" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "Ports Position Animations"
    , -- Position display
      el
        [ Font.size 14
        , Font.color Colors.textMedium
        , centerX
        ]
        (case getPosition "box" model.animations of
            Just position ->
                text ("Position: (" ++ String.fromFloat position.x ++ ", " ++ String.fromFloat position.y ++ ")")

            Nothing ->
                text "Position: (0, 0)"
        )
    , -- Buttons for predefined moves
      UI.htmlActionButtons
        [ ( UI.Primary, MoveToCorner, "Move to (100, 100)" )
        , ( UI.Success, MoveToCenter, "Move to (300, 200)" )
        , ( UI.Purple, StopAnimation, "Return to Origin" )
        ]
    , -- Axis-specific movement buttons
      UI.htmlActionButtons
        [ ( UI.Warning, MoveLeft, "← Move Left" )
        , ( UI.Warning, MoveRight, "Move Right →" )
        , ( UI.Success, MoveUp, "↑ Move Up" )
        , ( UI.Success, MoveDown, "Move Down ↓" )
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
            ([ width (px 50)
             , height (px 50)
             , Background.color Colors.primary
             , Border.rounded 8
             , htmlAttribute (Html.Attributes.id "box")
             , htmlAttribute (Html.Attributes.style "position" "absolute")
             ]
                ++ (styleProperties "box" model.animations
                        |> List.map (\( prop, value ) -> htmlAttribute (Html.Attributes.style prop value))
                   )
            )
            (text "")
        )
    ]
