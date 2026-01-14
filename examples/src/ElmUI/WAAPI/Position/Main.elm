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
import Anim.Property.Position as Position
import Browser exposing (Document)
import Common.Animations.Position as Animations
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Json.Encode as Encode



-- PORTS


port animateElement : Encode.Value -> Cmd msg


port stopElementAnimation : Encode.Value -> Cmd msg


port positionUpdates : (Encode.Value -> msg) -> Sub msg


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
    { animationState : WAAPI.AnimState
    , isAnimating : Bool
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        ( initialAnimState, initCmd ) =
            WAAPI.animate animateElement WAAPI.init <|
                Position.initXY "box" 0 0
    in
    ( { animationState = initialAnimState
      , isAnimating = False
      }
    , initCmd
    )



-- UPDATE


type Msg
    = MoveToXY Float Float
    | MoveLeft
    | MoveRight
    | MoveUp
    | MoveDown
    | ResetPosition
    | StopAnimation
    | AnimationComplete String
    | WaapiEventReceived Encode.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToXY x y ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate animateElement model.animationState <|
                        Animations.moveToXY "box" x y
            in
            ( { model | animationState = newAnimState, isAnimating = True }
            , animCmd
            )

        MoveLeft ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate animateElement model.animationState <|
                        Animations.moveLeft "box"
            in
            ( { model | animationState = newAnimState, isAnimating = True }
            , animCmd
            )

        MoveRight ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate animateElement model.animationState <|
                        Animations.moveRight "box"
            in
            ( { model | animationState = newAnimState, isAnimating = True }
            , animCmd
            )

        MoveUp ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate animateElement model.animationState <|
                        Animations.moveUp "box"
            in
            ( { model | animationState = newAnimState, isAnimating = True }
            , animCmd
            )

        MoveDown ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate animateElement model.animationState <|
                        Animations.moveDown "box"
            in
            ( { model | animationState = newAnimState, isAnimating = True }
            , animCmd
            )

        ResetPosition ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate animateElement model.animationState <|
                        Animations.returnToOrigin "box"
            in
            ( { model | animationState = newAnimState, isAnimating = True }
            , animCmd
            )

        StopAnimation ->
            ( { model | isAnimating = False }
            , stopElementAnimation (Encode.string "box")
            )

        AnimationComplete _ ->
            ( { model | isAnimating = False }
            , Cmd.none
            )

        WaapiEventReceived newAnimState eventType ->
            let
                newModel =
                    { model | animationState = newAnimState }
            in
            case eventType of
                WAAPI.PropertyUpdate _ ->
                    -- Property data automatically applied to newAnimState
                    -- If you don't need to react to property updates, you can ignore this event
                    ( newModel, Cmd.none )

                WAAPI.AnimationUpdate animationStatus ->
                    -- Animation status with automatically updated AnimState
                    -- This is only required to update isAnimating / isPaused flags in the model
                    -- If you don't need to react to animation status changes, you can ignore this event
                    handleAnimationUpdate animationStatus newModel



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ positionUpdates WaapiEventReceived event
        , animationComplete AnimationComplete
        ]



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "Anim.Engine.WAAPI Position ElmUI Example" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Ports Position Example"
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
        [ ( UI.Primary, MoveToXY 100 100, "Move to (100, 100)" )
        , ( UI.Success, MoveToXY 300 200, "Move to (300, 200)" )
        , ( UI.Purple, ResetPosition, "Reset to Center" )
        ]
    , -- Directional movement buttons
      UI.wrappedButtonRow
        [ ( UI.Warning, MoveLeft, "← Move Left" )
        , ( UI.Warning, MoveRight, "Move Right →" )
        , ( UI.Success, MoveUp, "↑ Move Up" )
        , ( UI.Success, MoveDown, "Move Down ↓" )
        ]
    , -- Stop animation button
      UI.wrappedButtonRow
        [ ( UI.Warning, StopAnimation, "Stop Animation" )
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
            , htmlAttribute (Html.Attributes.id "box")
            , htmlAttribute (Html.Attributes.style "position" "absolute")
            ]
            (text "")
        )
    ]
