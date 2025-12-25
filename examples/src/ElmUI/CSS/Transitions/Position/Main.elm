module ElmUI.CSS.Transitions.Position.Main exposing (main)

{-| Anim.Engine.CSS Position Example using ElmUI - Element position animations with CSS transitions

This example demonstrates smooth position transitions using browser-native CSS transforms.
Perfect for moving elements around the screen with hardware acceleration and battery efficiency.

FEATURES:

  - ✅ Smooth position animations (X and Y coordinates)
  - ✅ Independent axis movement (animateToX, animateToY)
  - ✅ Hardware-accelerated CSS transforms
  - ✅ Predefined position targets and directional movement
  - ✅ Real-time position display

USAGE:

  - Use animatePosition for absolute positioning (Position x y)
  - Use animateToX/animateToY for single-axis movement
  - Position values are in pixels relative to container
  - Browser handles all animation timing and optimization

-}

import Anim.Engine.CSS as CSS
import Anim.Properties.Position as Position
import Anim.Timing.Delay as Delay
import Anim.Timing.Easing as Easing exposing (Easing(..))
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, none, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
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
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { animations : CSS.AnimState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = CSS.init }
    , Cmd.none
    )



-- UPDATE


toPositionBuilder : CSS.AnimState -> Position.Builder
toPositionBuilder animations =
    animations
        |> CSS.builder
        |> CSS.duration 700
        |> CSS.easing Linear
        |> Position.for "box"


type Msg
    = MoveToPosition Float Float
    | MoveLeft
    | MoveRight
    | MoveUp
    | MoveDown
    | ReturnToOrigin
    | AnimationComplete


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToPosition x y ->
            ( { model
                | animations =
                    model.animations
                        |> toPositionBuilder
                        |> Position.toXY x y
                        |> Position.easing Easing.BounceInOut
                        |> Position.speed 200
                        |> Position.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        MoveLeft ->
            ( { model
                | animations =
                    model.animations
                        |> toPositionBuilder
                        |> Position.toX 0
                        |> Position.easing Easing.BounceOut
                        |> Position.duration 500
                        |> Position.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | animations =
                    model.animations
                        |> toPositionBuilder
                        |> Position.toX 450
                        |> Position.duration 800
                        |> Position.easing Easing.BounceIn
                        |> Position.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        MoveDown ->
            ( { model
                | animations =
                    model.animations
                        |> toPositionBuilder
                        |> Position.toY 350
                        |> Position.delay 1000
                        |> Position.duration 500
                        |> Position.easing Easing.ElasticInOut
                        |> Position.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        MoveUp ->
            ( { model
                | animations =
                    model.animations
                        |> toPositionBuilder
                        |> Position.toY 0
                        |> Position.easing Easing.ElasticIn
                        |> Position.duration 500
                        |> Position.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        ReturnToOrigin ->
            ( { model
                | animations =
                    model.animations
                        |> toPositionBuilder
                        |> Position.toXY 0 0
                        |> Position.easing Easing.ElasticOut
                        |> Position.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.CSS Position ElmUI Examples"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "ElmUI & CSS Transitions Position Example"
    , -- Buttons for predefined moves
      UI.wrappedButtonRow
        [ ( UI.Primary, MoveToPosition 100 100, "Move to (100, 100)" )
        , ( UI.Success, MoveToPosition 300 200, "Move to (300, 200)" )
        , ( UI.Purple, ReturnToOrigin, "Return to Origin" )
        ]
    , -- Axis-specific movement buttons
      UI.wrappedButtonRow
        [ ( UI.Warning, MoveLeft, "← Move Left" )
        , ( UI.Warning, MoveRight, "Move Right →" )
        , ( UI.Success, MoveUp, "↑ Move Up" )
        , ( UI.Success, MoveDown, "Move Down (with delay 1000ms) ↓" )
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
                -- Apply CSS styles for the animation
                ++ List.map htmlAttribute (CSS.htmlAttributes "box" model.animations)
            )
            none
        )
    ]
