port module ElmUI.WAAPI.Position.Main exposing (main)

{-| Anim.Engine.WAAPI Position Example using ElmUI - Element position animations using JavaScript Web Animations API

This example demonstrates smooth position transitions using port-based JavaScript integration with Web Animations API.
Perfect for high-performance animations with hardware acceleration and full platform capabilities.

FEATURES:

  - ✅ Smooth position animations (X and Y coordinates) via JavaScript ports
  - ✅ Independent axis movement (animateToX, animateToY)
  - ✅ Web Animations API integration for optimal performance
  - ✅ Predefined position targets and directional movement
  - ✅ Real-time position display with port-based updates

USAGE:

  - Use builder pattern for animation configuration
  - Position values are in pixels relative to container
  - JavaScript handles animation execution and progress updates

-}

import Anim.Easing as Easing exposing (Easing(..))
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Common.Animations.Translate as Animations exposing (elementId)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Json.Encode as Encode



-- PORTS


port waapiCommand : Encode.Value -> Cmd msg


port waapiEvent : (Encode.Value -> msg) -> Sub msg



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
    { animationState : WAAPI.AnimState
    , isAnimating : Bool
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        ( initialAnimState, initCmd ) =
            WAAPI.animate waapiCommand WAAPI.init Animations.init
    in
    ( { animationState = initialAnimState
      , isAnimating = False
      }
    , initCmd
    )



-- UPDATE


type Msg
    = MoveToPosition1
    | MoveToPosition2
    | MoveLeft
    | MoveRight
    | MoveUp
    | MoveDown
    | ResetPosition
    | StopAnimation
    | WaapiEventReceived ( WAAPI.AnimState, Maybe WAAPI.AnimationEvent )


animate : (WAAPI.AnimBuilder -> WAAPI.AnimBuilder) -> Model -> ( Model, Cmd Msg )
animate builder model =
    let
        ( newAnimState, builderCmd ) =
            WAAPI.animate waapiCommand model.animationState builder
    in
    ( { model
        | animationState = newAnimState
        , isAnimating = True
      }
    , builderCmd
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToPosition1 ->
            animate Animations.moveToPosition1 model

        MoveToPosition2 ->
            animate Animations.moveToPosition2 model

        MoveLeft ->
            animate Animations.moveLeft model

        MoveRight ->
            animate Animations.moveRight model

        MoveUp ->
            animate Animations.moveUp model

        MoveDown ->
            animate Animations.moveDown model

        ResetPosition ->
            animate Animations.returnToOrigin model

        StopAnimation ->
            ( { model | isAnimating = False }
            , WAAPI.stop elementId waapiCommand
            )

        WaapiEventReceived ( newAnimState, maybeEvent ) ->
            let
                newModel =
                    { model | animationState = newAnimState }
            in
            case maybeEvent of
                Just WAAPI.Completed ->
                    ( { newModel | isAnimating = False }, Cmd.none )

                _ ->
                    ( newModel, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    waapiEvent (WaapiEventReceived << WAAPI.decode model.animationState)



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "WAAPI Position Example with ElmUI" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "WAAPI Position Example with ElmUI"
    , -- Animation status display
      el
        [ Font.size 14
        , Font.color Colors.textMedium
        , padding 10
        ]
        (text <|
            if model.isAnimating then
                "Animating..."

            else
                "Ready"
        )
    , -- Buttons for movement control
      UI.wrappedButtonRow
        [ ( UI.Primary, MoveToPosition1, "Move to Position 1" )
        , ( UI.Success, MoveToPosition2, "Move to Position 2" )
        , ( UI.Purple, ResetPosition, "Reset" )
        ]
    , -- Directional movement buttons
      UI.wrappedButtonRow
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
            [ width (px 50)
            , height (px 50)
            , Background.color Colors.primary
            , Border.rounded 8
            , htmlAttribute (Html.Attributes.id elementId)
            , htmlAttribute (Html.Attributes.style "position" "absolute")
            ]
            (text "")
        )
    ]
