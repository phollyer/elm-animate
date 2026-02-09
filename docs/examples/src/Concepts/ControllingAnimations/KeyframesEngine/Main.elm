module Concepts.ControllingAnimations.KeyframesEngine.Main exposing (main)

import Anim.Engine.CSS.Keyframes as CSS
import Browser exposing (Document)
import Common.Animations.Controls as Controls exposing (elementId)
import Common.Colors as Colors
import Common.UI as UI
import Common.View.Controls as ViewControls
import Element exposing (Element, centerX, centerY, column, el, explain, fill, height, html, htmlAttribute, inFront, maximum, none, padding, paddingEach, paragraph, px, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes



-- MAIN


main : Program { window : { width : Int } } Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    { animState : CSS.AnimState
    , animAreaSize : { width : Int, height : Int }
    }



-- INIT


init : { window : { width : Int } } -> ( Model, Cmd Msg )
init { window } =
    let
        animAreaWidth =
            min 500 (window.width - 40)
    in
    ( { animState =
            CSS.init <|
                [ Controls.init animAreaWidth ]
      , animAreaSize =
            { width = animAreaWidth
            , height = 350
            }
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Animate
    | Stop
    | Reset
    | Restart
    | Pause
    | Resume


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate ->
            ( { model
                | animState = CSS.animate model.animState Controls.animate
              }
            , Cmd.none
            )

        -- --8<-- [start:stop]
        Stop ->
            ( { model | animState = CSS.stop elementId model.animState }
            , Cmd.none
            )

        -- --8<-- [end:stop]
        -- --8<-- [start:reset]
        Reset ->
            ( { model | animState = CSS.reset elementId model.animState }
            , Cmd.none
            )

        -- --8<-- [end:reset]
        -- --8<-- [start:restart]
        Restart ->
            ( { model | animState = CSS.restart elementId model.animState }
            , Cmd.none
            )

        -- --8<-- [end:restart]
        -- --8<-- [start:pause]
        Pause ->
            ( { model | animState = CSS.pause elementId model.animState }
            , Cmd.none
            )

        -- --8<-- [end:pause]
        -- --8<-- [start:resume]
        Resume ->
            ( { model | animState = CSS.resume elementId model.animState }
            , Cmd.none
            )



-- --8<-- [end:resume]
-- VIEW - Using ElmUI, but the same animation logic works with any view layer
--
--
-- Engine-specific view helpers


keyframesNode : CSS.AnimState -> Element msg
keyframesNode =
    CSS.styleNodeFor elementId >> html


keyframesStyles : CSS.AnimState -> List (Element.Attribute msg)
keyframesStyles =
    CSS.attributes elementId >> List.map htmlAttribute



-- View Helpers


view : Model -> Document Msg
view model =
    UI.createDocument
        "Keyframes Engine Controls Example - Elm Animate"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ keyframesNode model.animState
    , ViewControls.header
        [ "Keyframes Engine Controls" ]
    , ViewControls.table
        [ ( 0, "🏀 Animate", "Drop the ball" )
        , ( 1, "⏹️ Stop", "Jump instantly to end state and stop" )
        , ( 1, "⏸️ Pause", "Pause animation at current position" )
        , ( 1, "▶️ Resume", "Continue paused animation" )
        , ( 1, "⏮️ Reset", "Jump instantly to start state and stop" )
        , ( 1, "🔄 Restart", "Reset to start, then begin animation again" )
        ]
    , ViewControls.buttons
        [ [ ( UI.Primary, Animate, "🏀 Animate" )
          , ( UI.Warning, Stop, "⏹️ Stop" )
          ]
        , [ ( UI.Success, Pause, "⏸️ Pause" )
          , ( UI.Success, Resume, "▶️ Resume" )
          ]
        , [ ( UI.Purple, Reset, "⏮️ Reset" )
          , ( UI.Purple, Restart, "🔄 Restart" )
          ]
        ]
    , ViewControls.animationArea model.animAreaSize <|
        animatedBall model.animState
    ]


animatedBall : CSS.AnimState -> Element msg
animatedBall animState =
    el
        (keyframesStyles animState
            ++ [ width (px 50)
               , height (px 50)
               , htmlAttribute (Html.Attributes.style "position" "relative")
               ]
        )
        (el [ centerX, centerY, Font.size 50 ] (text "🏀"))
