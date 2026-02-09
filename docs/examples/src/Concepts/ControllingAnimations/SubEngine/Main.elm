module Concepts.ControllingAnimations.SubEngine.Main exposing (main)

import Anim.Engine.Sub as Sub
import Browser exposing (Document)
import Common.Animations.Controls as Controls exposing (elementId)
import Common.UI as UI
import Common.View.Controls as ViewControls
import Element exposing (Element, centerX, centerY, el, height, htmlAttribute, px, text, width)
import Element.Font as Font
import Html.Attributes



-- MAIN


main : Program { window : { width : Int, height : Int } } Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : Sub.AnimState
    , animAreaSize : { width : Int, height : Int }
    }



-- INIT


init : { window : { width : Int, height : Int } } -> ( Model, Cmd Msg )
init { window } =
    let
        animAreaWidth =
            min 500 (window.width - 40)
    in
    ( { animState =
            Sub.init <|
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
    | Pause
    | Resume
    | Reset
    | Restart
    | GotSubMsg Sub.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSubMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    Sub.update subMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        Animate ->
            ( { model
                | animState = Sub.animate model.animState Controls.animate
              }
            , Cmd.none
            )

        -- --8<-- [start:stop]
        Stop ->
            ( { model | animState = Sub.stop elementId model.animState }
            , Cmd.none
            )

        -- --8<-- [end:stop]
        -- --8<-- [start:pause]
        Pause ->
            ( { model | animState = Sub.pause elementId model.animState }
            , Cmd.none
            )

        -- --8<-- [end:pause]
        -- --8<-- [start:resume]
        Resume ->
            ( { model | animState = Sub.resume elementId model.animState }
            , Cmd.none
            )

        -- --8<-- [end:resume]
        -- --8<-- [start:reset]
        Reset ->
            ( { model | animState = Sub.reset elementId model.animState }
            , Cmd.none
            )

        -- --8<-- [end:reset]
        -- --8<-- [start:restart]
        Restart ->
            ( { model | animState = Sub.restart elementId model.animState }
            , Cmd.none
            )



-- --8<-- [end:restart]
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



-- VIEW - Using ElmUI, but the same animation logic works with any view layer
--
--
-- Engine-specific view helpers


subAttributes : Sub.AnimState -> List (Element.Attribute msg)
subAttributes =
    Sub.attributes elementId >> List.map htmlAttribute



-- View Helpers


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.Sub Controls ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ ViewControls.header
        [ "Sub Engine Controls"
        ]
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


animatedBall : Sub.AnimState -> Element msg
animatedBall animState =
    el
        (subAttributes animState
            ++ [ width (px 50)
               , height (px 50)
               , htmlAttribute (Html.Attributes.style "position" "relative")
               ]
        )
        (el [ centerX, centerY, Font.size 50 ] (text "🏀"))
