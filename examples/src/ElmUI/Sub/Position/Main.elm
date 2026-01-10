module ElmUI.Sub.Position.Main exposing (main)

{-| Anim.Engine.Sub Position Example using ElmUI - Element position animations with subscription-based timing

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

import Anim.Easing as Easing exposing (Easing(..))
import Anim.Engine.Sub as Sub
import Anim.Property.Position as Position
import Browser exposing (Document)
import Browser.Events
import Common.Animations.Position as Animations
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
    { animations : Sub.AnimState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations =
            Sub.init
                |> Sub.builder
                |> Position.initXY "box" 0 0
                |> Sub.animate
      }
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
    | AnimationMsg Sub.AnimationMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToXY x y ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Position.for "box"
                        |> Position.toXY x y
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseOut
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
                        |> Animations.moveLeft "box"
                        |> Sub.animate
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Animations.moveRight "box"
                        |> Sub.animate
              }
            , Cmd.none
            )

        MoveUp ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Animations.moveUp "box"
                        |> Sub.animate
              }
            , Cmd.none
            )

        MoveDown ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Animations.moveDown "box"
                        |> Sub.animate
              }
            , Cmd.none
            )

        ResetPosition ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Animations.returnToOrigin "box"
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
    Sub.subscriptions AnimationMsg model.animations



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "Anim.Engine.Sub Position ElmUI Example" UI.Basic (viewContent model)


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
                Sub.getCurrentPosition "box" model.animations
                    |> Maybe.withDefault { x = 0, y = 0, z = 0 }
         in
         text ("Position: (" ++ String.fromInt (round pos.x) ++ ", " ++ String.fromInt (round pos.y) ++ ")")
        )
    , -- Buttons for predefined moves
      UI.wrappedButtonRow
        [ ( UI.Primary, MoveToXY 100 100, "Move to (100, 100)" )
        , ( UI.Primary, MoveToXY 300 200, "Move to (300, 200)" )
        , ( UI.Purple, ResetPosition, "Return to Origin" )
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
