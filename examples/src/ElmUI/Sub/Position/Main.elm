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

import Anim.Extra.Easing as Easing exposing (Easing(..))
import Anim.Engine.Sub as Sub
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Browser.Events
import Common.Animations.Translate as Animations
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
            Sub.animate Sub.init
                (Translate.initXY "box" 0 0)
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
    | AnimationMsg Sub.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToXY x y ->
            ( { model
                | animations =
                    Sub.animate model.animations
                        (Translate.for "box"
                            >> Translate.toXY x y
                            >> Translate.speed 200.0
                            >> Translate.easing Easing.EaseOut
                            >> Translate.build
                        )
              }
            , Cmd.none
            )

        MoveLeft ->
            ( { model
                | animations =
                    Sub.animate model.animations
                        Animations.moveLeft
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | animations =
                    Sub.animate model.animations
                        Animations.moveRight
              }
            , Cmd.none
            )

        MoveUp ->
            ( { model
                | animations =
                    Sub.animate model.animations
                        Animations.moveUp
              }
            , Cmd.none
            )

        MoveDown ->
            ( { model
                | animations =
                    Sub.animate model.animations
                        Animations.moveDown
              }
            , Cmd.none
            )

        ResetPosition ->
            ( { model
                | animations =
                    Sub.animate model.animations
                        Animations.returnToOrigin
              }
            , Cmd.none
            )

        AnimationMsg subMsg ->
            let
                ( newAnimations, _ ) =
                    Sub.update subMsg model.animations
            in
            ( { model | animations = newAnimations }
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
                Sub.getCurrentTranslate "box" model.animations
                    |> Maybe.withDefault { x = 0, y = 0, z = 0 }
         in
         text ("Translate: (" ++ String.fromInt (round pos.x) ++ ", " ++ String.fromInt (round pos.y) ++ ")")
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
                ++ List.map htmlAttribute (Sub.attributes "box" model.animations)
            )
            (text "")
        )
    ]
