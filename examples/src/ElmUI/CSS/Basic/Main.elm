module ElmUI.CSS.Basic.Main exposing (main)

{-| SmoothMoveCSS Basic Example using ElmUI - Native browser CSS transitions for optimal performance

This approach uses browser-native CSS transitions for hardware acceleration and battery efficiency.
Perfect for simple transitions where you want maximum performance with minimal JavaScript overhead.

BENEFITS:

  - ✅ Hardware acceleration via native CSS transitions
  - ✅ Battery efficient (browser optimizes automatically)
  - ✅ Simple API - just apply CSS styles directly
  - ✅ No animation frame subscriptions needed
  - ✅ Smooth 60fps animations with browser optimization
  - ✅ Automatic performance scaling based on device capabilities

USAGE:

  - Update position in your model when you want to animate
  - Use SmoothMoveCSS.transform to generate CSS transform styles
  - Use SmoothMoveCSS.transition to generate CSS transition styles
  - Browser handles all animation timing and optimization

-}

import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import SmoothMoveCSS



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
    { position : { x : Float, y : Float }
    , isAnimating : Bool
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { position = { x = 0, y = 0 }
      , isAnimating = False
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = MoveToCorner
    | MoveToCenter
    | StopAnimation
    | AnimationComplete


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToCorner ->
            ( { model 
                | position = { x = 100, y = 100 }
                , isAnimating = True
              }
            , Cmd.none
            )

        MoveToCenter ->
            ( { model 
                | position = { x = 300, y = 200 }
                , isAnimating = True
              }
            , Cmd.none
            )

        StopAnimation ->
            ( { model 
                | position = { x = 0, y = 0 }
                , isAnimating = True
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( { model | isAnimating = False }
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
    UI.createDocument "SmoothMoveCSS Basic ElmUI Example" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "SmoothMoveCSS Basic Example"
    , -- Position display
      el
        [ Font.size 14
        , Font.color Colors.textMedium
        , centerX
        ]
        (text ("Position: (" ++ String.fromInt (round model.position.x) ++ ", " ++ String.fromInt (round model.position.y) ++ ")"))
    , -- Buttons for predefined moves
      UI.htmlActionButtons
        [ ( UI.Primary, MoveToCorner, "Move to (100, 100)" )
        , ( UI.Success, MoveToCenter, "Move to (300, 200)" )
        , ( UI.Purple, StopAnimation, "Return to Origin" )
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
            , htmlAttribute (Html.Attributes.id "moving-box")
            , htmlAttribute (Html.Attributes.style "position" "absolute")

            -- Apply CSS transition styles directly - browser handles the animation!
            , htmlAttribute (Html.Attributes.style "transform" (SmoothMoveCSS.transform model.position.x model.position.y))
            , htmlAttribute (Html.Attributes.style "transition" 
                (if model.isAnimating then
                    SmoothMoveCSS.transition
                 else
                    "none"
                ))
            
            -- CSS transition event handler - fires when animation completes
            , htmlAttribute (SmoothMoveCSS.onTransitionEnd AnimationComplete)
            ]
            (text "")
        )
    ]
