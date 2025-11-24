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

  - Use builder pattern for animation configuration
  - Position values are in pixels relative to container
  - JavaScript handles animation execution and progress updates

-}

import Anim
import Anim.Properties.Position as Position
import Anim.Ports as Ports
import Anim.Timing.Easing as Easing exposing (Easing(..))
import Browser exposing (Document)
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


port stopElement : Encode.Value -> Cmd msg


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
    { isAnimating : Bool }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { isAnimating = False }
    , Cmd.none
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
    | PositionUpdateReceived Encode.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToXY x y ->
            ( { model | isAnimating = True }
            , Anim.init
                |> Anim.for "box"
                |> Position.for "box"
                |> Position.toXY x y
                |> Position.speed 200.0
                |> Position.easing Easing.EaseOut
                |> Position.build
                |> Ports.animate animateElement
            )

        MoveLeft ->
            ( { model | isAnimating = True }
            , Anim.init
                |> Anim.for "box"
                |> Position.for "box"
                |> Position.toX 0
                |> Position.speed 300.0
                |> Position.easing Easing.BounceIn
                |> Position.build
                |> Ports.animate animateElement
            )

        MoveRight ->
            ( { model | isAnimating = True }
            , Anim.init
                |> Anim.for "box"
                |> Position.for "box"
                |> Position.toX 500
                |> Position.speed 300.0
                |> Position.easing Easing.BounceIn
                |> Position.build
                |> Ports.animate animateElement
            )

        MoveUp ->
            ( { model | isAnimating = True }
            , Anim.init
                |> Anim.for "box"
                |> Position.for "box"
                |> Position.toY 0
                |> Position.speed 250.0
                |> Position.easing Easing.EaseInOut
                |> Position.build
                |> Ports.animate animateElement
            )

        MoveDown ->
            ( { model | isAnimating = True }
            , Anim.init
                |> Anim.for "box"
                |> Position.for "box"
                |> Position.toY 300
                |> Position.speed 250.0
                |> Position.easing Easing.EaseInOut
                |> Position.build
                |> Ports.animate animateElement
            )

        ResetPosition ->
            ( { model | isAnimating = True }
            , Anim.init
                |> Anim.for "box"
                |> Position.for "box"
                |> Position.toXY 250 150
                |> Position.speed 400.0
                |> Position.easing Easing.EaseOut
                |> Position.build
                |> Ports.animate animateElement
            )

        StopAnimation ->
            ( { model | isAnimating = False }
            , stopElement (Encode.string "box")
            )

        AnimationComplete _ ->
            ( { model | isAnimating = False }
            , Cmd.none
            )

        PositionUpdateReceived _ ->
            -- Handle position updates from JavaScript if needed
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ positionUpdates PositionUpdateReceived
        , animationComplete AnimationComplete
        ]



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "Anim.Ports Position ElmUI Example" UI.Basic (viewContent model)


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
        (text <| if model.isAnimating then "Animating..." else "Ready")
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
            , htmlAttribute (Html.Attributes.style "left" "250px")  -- Default center position
            , htmlAttribute (Html.Attributes.style "top" "150px")   -- Default center position
            ]
            (text "")
        )
    ]
