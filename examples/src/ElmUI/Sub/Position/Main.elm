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

import Anim exposing (Position, defaultConfig)
import Anim.Sub exposing (Model, animateTo, animateToX, animateToY, getPosition, init, step, subscriptions, transform)
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
    { animations : Anim.Sub.Model
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.Sub.init
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
    | AnimationFrame Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToCorner ->
            ( { model
                | animations = animateTo "box" (Position 100 100) model.animations
              }
            , Cmd.none
            )

        MoveToCenter ->
            ( { model
                | animations = animateTo "box" (Position 225 175) model.animations
              }
            , Cmd.none
            )

        MoveLeft ->
            ( { model
                | animations = animateToX "box" 0 model.animations
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | animations = animateToX "box" 450 model.animations -- 500px container - 50px box = 450px for right edge
              }
            , Cmd.none
            )

        MoveUp ->
            ( { model
                | animations = animateToY "box" 0 model.animations
              }
            , Cmd.none
            )

        MoveDown ->
            ( { model
                | animations = animateToY "box" 350 model.animations -- 400px container - 50px box = 350px for bottom edge
              }
            , Cmd.none
            )

        StopAnimation ->
            ( { model
                | animations = animateTo "box" (Position 0 0) model.animations
              }
            , Cmd.none
            )

        AnimationFrame deltaTime ->
            ( { model
                | animations = step deltaTime model.animations
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Anim.Sub.subscriptions AnimationFrame model.animations



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "Anim.Sub Position ElmUI Example" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "Subscription-Based Position Animations"
    , -- Position display
      el
        [ Font.size 14
        , Font.color Colors.textMedium
        , centerX
        ]
        (let
            pos =
                getPosition "box" model.animations |> Maybe.withDefault { x = 0, y = 0 }
         in
         text ("Position: (" ++ String.fromInt (round pos.x) ++ ", " ++ String.fromInt (round pos.y) ++ ")")
        )
    , -- Buttons for predefined moves
      UI.htmlActionButtons
        [ ( UI.Primary, MoveToCorner, "Move to (100, 100)" )
        , ( UI.Success, MoveToCenter, "Move to (300, 200)" )
        , ( UI.Purple, StopAnimation, "Return to Origin" )
        ]
    , -- Axis-specific movement buttons
      UI.htmlActionButtons
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
            , htmlAttribute (Html.Attributes.id "box")
            , htmlAttribute (Html.Attributes.style "position" "absolute")
            , htmlAttribute (Html.Attributes.style "transform" (transform "box" model.animations))
            ]
            (text "")
        )
    ]
