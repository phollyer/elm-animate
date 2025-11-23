module ElmUI.Sub.Position.Main exposing (main)

{-| Anim.Sub Position Example using ElmUI - Element position animations with subscription-based timing

This example demonstrates smooth position transitions using onAnimationFrameDelta subscriptions.
Perfect for moving elements around the screen with frame-rate independent timing.

FEATURES:

  - ✅ Smooth position animations (X and Y coordinates)
  - ✅ Independent axis movement (animateToX, animateToY)
  - ✅ Frame-rate independent timing with subscriptions
  - ✅ Predefined position targets and directional movement
  - ✅ Real-time position display

USAGE:

  - Use animateTo for absolute positioning (Position x y)
  - Use animateToX/animateToY for single-axis movement
  - Position values are in pixels relative to container
  - Subscription handles frame-rate independent timing

-}

import Anim
import Anim.Properties.Position as Position
import Anim.Sub as Sub
import Anim.Timing.Easing as Easing exposing (Easing(..))
import Browser exposing (Document)
import Browser.Events
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes



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
    { animations : Sub.AnimationState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations =
            Sub.init
                |> Position.for "box"
                |> Position.toXY 0 0
                |> Position.build
                |> Sub.animate
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
    | AnimationMsg Sub.AnimationMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg |> Debug.log "Received Msg" of
        MoveToCorner ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Position.for "box"
                        |> Position.toXY 100 100
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseOut
                        |> Position.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        MoveToCenter ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Position.for "box"
                        |> Position.toXY 225 175
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        MoveLeft ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Position.for "box"
                        |> Position.toX 0
                        |> Position.speed 300.0
                        |> Position.easing Easing.BounceIn
                        |> Position.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Position.for "box"
                        |> Position.toX 450
                        |> Position.speed 300.0
                        |> Position.easing Easing.BounceOut
                        |> Position.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        MoveUp ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Position.for "box"
                        |> Position.toY 0
                        |> Position.speed 250.0
                        |> Position.easing Easing.EaseOut
                        |> Position.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        MoveDown ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Position.for "box"
                        |> Position.toY 350
                        |> Position.speed 250.0
                        |> Position.easing Easing.EaseOut
                        |> Position.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        StopAnimation ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Position.for "box"
                        |> Position.toXY 0 0
                        |> Position.speed 400.0
                        |> Position.easing Easing.EaseOut
                        |> Position.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        AnimationMsg subMsg ->
            ( { model | animations = Sub.update subMsg model.animations }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map AnimationMsg <|
        Sub.subscriptions model.animations



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "Anim.Sub Position ElmUI Example" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Subscription Position Example"
    , -- Position display
      el
        [ Font.size 14
        , Font.color Colors.textMedium
        , centerX
        ]
        (let
            pos =
                Sub.getPosition "box" model.animations
                    |> Maybe.map Position.asRecord
                    |> Maybe.withDefault { x = 0, y = 0 }
         in
         text ("Position: (" ++ String.fromInt (round pos.x) ++ ", " ++ String.fromInt (round pos.y) ++ ")")
        )
    , -- Buttons for predefined moves
      UI.wrappedButtonRow
        [ ( UI.Primary, MoveToCorner, "Move to (100, 100)" )
        , ( UI.Success, MoveToCenter, "Move to (300, 200)" )
        , ( UI.Purple, StopAnimation, "Return to Origin" )
        ]
    , -- Axis-specific movement buttons
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
            ([ width (px 50)
             , height (px 50)
             , Background.color Colors.primary
             , Border.rounded 8
             , htmlAttribute (Html.Attributes.id "box")
             , htmlAttribute (Html.Attributes.style "position" "absolute")
             ]
                ++ List.map htmlAttribute (Sub.htmlAttributes "box" model.animations)
            )
            (text "")
        )
    ]
