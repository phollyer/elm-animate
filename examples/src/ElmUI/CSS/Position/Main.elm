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
import Anim.Properties.Position as Position
import Anim.Timing.Easing as Easing
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
    { animations : Maybe AnimationState
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
                    Anim.init
                        |> Anim.duration 700
                        |> Anim.easing Easing.QuadInOut
                        |> Position.for "box"
                        |> Position.toXY x y    
                        |> Position.build
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationState
                , isAnimating = True
                , currentPosition = { x = 100, y = 100 }
              }
            , Cmd.none
            )


        MoveLeft ->
            let
                animationState =
                    Anim.init
                        |> Anim.duration 700
                        |> Anim.easing Easing.Linear
                        |> Position.for "box"
                        |> Position.duration 2000
                        |> Position.toXY 0 model.currentPosition.y
                        |> Position.build
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationState
                , isAnimating = True
                , currentPosition = { x = 0, y = model.currentPosition.y }
              }
            , Cmd.none
            )

        MoveRight ->
            let
                animationState =
                    Anim.init
                        |> Anim.duration 700
                        |> Anim.easing Easing.Linear
                        |> Position.for "box"
                        |> Position.toXY 450 model.currentPosition.y
                        |> Position.build
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationState
                , isAnimating = True
                , currentPosition = { x = 450, y = model.currentPosition.y }
              }
            , Cmd.none
            )

        MoveDown ->
            let
                animationState =
                    Anim.init
                        |> Anim.duration 700
                        |> Anim.easing Easing.Linear
                        |> Position.for "box"
                        |> Position.toXY model.currentPosition.x 350
                        |> Position.build
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationState
                , isAnimating = True
                , currentPosition = { x = model.currentPosition.x, y = 350 }
              }
            , Cmd.none
            )

        MoveUp ->
            let
                animationState =
                    Anim.init
                        |> Anim.duration 700
                        |> Anim.easing Easing.Linear
                        |> Position.for "box"
                        |> Position.toXY model.currentPosition.x 0
                        |> Position.build
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationState
                , isAnimating = True
                , currentPosition = { x = model.currentPosition.x, y = 50 }
              }
            , Cmd.none
            )

        ReturnToOrigin ->
            let
                animationState =
                    Anim.init
                        |> Anim.duration 700
                        |> Anim.easing Easing.Linear
                        |> Position.for "box"
                        |> Position.toXY 0 0
                        |> Position.build
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationState
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
    UI.createDocument "Anim.CSS Position ElmUI Examples" UI.Basic (viewContent model)


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
        [ ( UI.Primary, MoveToPosition 100 100, "Move to (100, 100)" )
        , ( UI.Success, MoveToPosition 300 200, "Move to (300, 200)" )
        , ( UI.Purple, ReturnToOrigin, "Return to Origin" )
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
                ++ List.map htmlAttribute (CSS.htmlAttributes "box" model.animations |> Debug.log "CSS Attributes")
            )
            (text "")
        )
    ]
