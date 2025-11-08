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
import Anim.CSS as CSS exposing (AnimationResult)
import Anim.Easing as Easing
import Anim.Properties.Position as Position
import Browser exposing (Document)
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
    { animations : Maybe AnimationResult
    , isAnimating : Bool
    , currentPosition : { x : Float, y : Float }
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Nothing
      , isAnimating = False
      , currentPosition = { x = 200, y = 150 } -- Starting position
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
    | AnimationComplete


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToCorner ->
            let
                animationResult =
                    Anim.init "box"
                        |> Position.to { x = 100, y = 100 }
                        |> Anim.duration 700
                        |> Anim.easing Easing.easeInOutQuad
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
                , currentPosition = { x = 100, y = 100 }
              }
            , Cmd.none
            )

        MoveToCenter ->
            let
                animationResult =
                    Anim.init "box"
                        |> Position.to { x = 300, y = 200 }
                        |> Anim.duration 700
                        |> Anim.easing Easing.easeInOutQuad
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
                , currentPosition = { x = 300, y = 200 }
              }
            , Cmd.none
            )

        MoveLeft ->
            let
                animationResult =
                    Anim.init "box"
                        |> Position.to { x = 0, y = model.currentPosition.y }
                        |> Anim.duration 400
                        |> Anim.easing Easing.linear
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
                , currentPosition = { x = 0, y = model.currentPosition.y }
              }
            , Cmd.none
            )

        MoveRight ->
            let
                animationResult =
                    Anim.init "box"
                        |> Position.to { x = 450, y = model.currentPosition.y }
                        |> Anim.duration 400
                        |> Anim.easing Easing.linear
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
                , currentPosition = { x = 450, y = model.currentPosition.y }
              }
            , Cmd.none
            )

        MoveDown ->
            let
                animationResult =
                    Anim.init "box"
                        |> Position.to { x = model.currentPosition.x, y = 350 }
                        |> Anim.duration 400
                        |> Anim.easing Easing.linear
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
                , currentPosition = { x = model.currentPosition.x, y = 350 }
              }
            , Cmd.none
            )

        MoveUp ->
            let
                animationResult =
                    Anim.init "box"
                        |> Position.to { x = model.currentPosition.x, y = 50 }
                        |> Anim.duration 400
                        |> Anim.easing Easing.linear
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
                , currentPosition = { x = model.currentPosition.x, y = 50 }
              }
            , Cmd.none
            )

        StopAnimation ->
            let
                animationResult =
                    Anim.init "box"
                        |> Position.to { x = 0, y = 0 }
                        |> Anim.duration 400
                        |> Anim.easing Easing.linear
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
                , currentPosition = { x = 0, y = 0 }
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( { model
                | isAnimating = False
                , animations = Nothing
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
    UI.createDocument "Anim.CSS Position ElmUI Example" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "CSS Position Animations"
    , -- Position display
      el
        [ Font.size 14
        , Font.color Colors.textMedium
        , centerX
        ]
        (text ("Position: (" ++ String.fromInt (round model.currentPosition.x) ++ ", " ++ String.fromInt (round model.currentPosition.y) ++ ")"))
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

             -- Apply CSS styles from animation - browser handles the animation!
             ]
                ++ List.map htmlAttribute (CSS.htmlAttributes "box" model.animations AnimationComplete)
            )
            (text "")
        )
    ]
