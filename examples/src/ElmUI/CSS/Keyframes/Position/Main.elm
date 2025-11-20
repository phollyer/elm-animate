module ElmUI.CSS.Keyframes.Position.Main exposing (main)

{-| Anim.CSS Position Example using ElmUI - Element position animations with CSS keyframes

This example demonstrates smooth position animations using browser-native CSS keyframes.
Perfect for moving elements around the screen with hardware acceleration and complex timing control.

FEATURES:

  - ✅ Smooth position animations using CSS keyframes (X and Y coordinates)
  - ✅ Independent axis movement (animateToX, animateToY)
  - ✅ Hardware-accelerated CSS transforms with fine-grained control
  - ✅ Predefined position targets and directional movement
  - ✅ Real-time position display
  - ✅ Complex animation composition and timing

USAGE:

  - Use animatePosition for absolute positioning (Position x y)
  - Use animateToX/animateToY for single-axis movement
  - Position values are in pixels relative to container
  - Keyframes provide precise control over animation timing and composition

-}

import Anim
import Anim.CSS as CSS
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
import Html
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
    { animations : CSS.AnimationState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = CSS.init }
    , Cmd.none
    )



-- UPDATE


elementId : String
elementId =
    "box"


anim : CSS.AnimationState -> Position.Builder
anim animations =
    animations
        |> CSS.builder
        |> Anim.duration 700
        |> Anim.easing Linear
        |> Position.for elementId


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
                        |> anim
                        |> Position.toXY x y
                        |> Position.easing (Easing.Bezier 0.3 0 0.7 0)
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
                        |> anim
                        |> Position.toX 0
                        |> Position.duration 1000
                        |> Position.easing Easing.ElasticOut
                        |> Position.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | animations =
                    model.animations
                        |> anim
                        |> Position.toX 450
                        |> Position.duration 1000
                        |> Position.easing Easing.ElasticIn
                        |> Position.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        MoveDown ->
            ( { model
                | animations =
                    model.animations
                        |> anim
                        |> Position.toY 350
                        --|> Position.delay 1000
                        |> Position.duration 1000
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
                        |> anim
                        |> Position.toY 0
                        |> Position.easing Easing.ElasticInOut
                        |> Position.duration 1000
                        |> Position.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        ReturnToOrigin ->
            ( { model
                | animations =
                    model.animations
                        |> anim
                        |> Position.toXY 0 0
                        |> Position.easing Easing.ElasticInOut
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
        "Anim.CSS Position Keyframes ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ Element.html (CSS.keyframesStyleNodeFor elementId model.animations)
    , UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "CSS Keyframes Position Animations"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        , width (fill |> maximum 600)
        ]
        (paragraph []
            [ text "Smooth position animations using browser-native CSS keyframes with precise timing control" ]
        )
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
            [ width (px 50)
            , height (px 50)
            , Background.color Colors.primary
            , Border.rounded 8
            , htmlAttribute (Html.Attributes.id elementId)
            , htmlAttribute (Html.Attributes.style "position" "absolute")
            , htmlAttribute (CSS.animationStyleAttribute elementId model.animations |> Debug.log "Animation Style")
            ]
            none
        )
    ]
