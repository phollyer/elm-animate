module ElmUI.CSS.Position.Main exposing (main)

{-| Anim.CSS Position Example using ElmUI - Element position animations with CSS transitions

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

import Anim
import Anim.CSS as CSS exposing (AnimationState)
import Anim.Properties.Position as Position exposing (PositionBuilder)
import Anim.Timing.Delay as Delay exposing (Delay(..))
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
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animations : AnimationState
    , isAnimating : Bool
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = CSS.init
      , isAnimating = False
      }
    , Cmd.none
    )



-- UPDATE


anim : AnimationState -> PositionBuilder
anim animations =
    animations
        |> CSS.builder
        |> Anim.duration 700
        |> Anim.easing Linear
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
            let
                animationState =
                    model.animations
                        |> anim
                        |> Position.toXY x y
                        |> Position.easing Easing.QuadInOut
                        |> Position.build
                        |> CSS.animate
            in
            ( { model
                | animations = animationState
                , isAnimating = True
              }
            , Cmd.none
            )

        MoveLeft ->
            let
                animationState =
                    model.animations
                        |> anim
                        |> Position.toX 0
                        |> Position.easing Easing.SineInOut
                        |> Position.speed 100
                        |> Position.build
                        |> CSS.animate
            in
            ( { model
                | animations = animationState
                , isAnimating = True
              }
            , Cmd.none
            )

        MoveRight ->
            let
                animationState =
                    model.animations
                        |> anim
                        |> Position.toX 450
                        |> Position.easing Easing.backInOut
                        |> Position.duration 400
                        |> Position.build
                        |> CSS.animate
            in
            ( { model
                | animations = animationState
                , isAnimating = True
              }
            , Cmd.none
            )

        MoveDown ->
            let
                animationState =
                    model.animations
                        |> anim
                        |> Position.toY 350
                        |> Position.easing Easing.bounceInOut
                        |> Position.delay (Delay 1000)
                        |> Position.build
                        |> CSS.animate
            in
            ( { model
                | animations = animationState
                , isAnimating = True
              }
            , Cmd.none
            )

        MoveUp ->
            let
                animationState =
                    model.animations
                        |> anim
                        |> Position.toY 0
                        |> Position.easing Easing.circInOut
                        |> Position.build
                        |> CSS.animate
            in
            ( { model
                | animations = animationState
                , isAnimating = True
              }
            , Cmd.none
            )

        ReturnToOrigin ->
            let
                animationState =
                    model.animations
                        |> anim
                        |> Position.toXY 0 0
                        |> Position.easing Easing.elasticInOut
                        |> Position.build
                        |> CSS.animate
            in
            ( { model
                | animations = animationState
                , isAnimating = True
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( { model
                | isAnimating = False
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- No subscriptions needed for CSS transitions!
-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "Anim.CSS Position ElmUI Examples" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        currentPos =
            CSS.getElementPosition "box" model.animations
    in
    [ UI.backButton
    , UI.pageHeader "CSS Position Animations"
    , -- Position display
      el
        [ Font.size 14
        , Font.color Colors.textMedium
        , centerX
        ]
        (text ("Position: (" ++ String.fromInt (round currentPos.x) ++ ", " ++ String.fromInt (round currentPos.y) ++ ")"))
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

             -- Apply CSS styles from animation - browser handles the animation!
             ]
                ++ List.map htmlAttribute (CSS.htmlAttributes "box" model.animations)
            )
            none
        )
    ]
