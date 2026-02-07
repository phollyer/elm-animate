port module Engines.WAAPI.Controls.Main exposing (main)

import Anim.Engine.WAAPI as WAAPI
import Browser exposing (Document)
import Common.Animations.Controls as Controls exposing (elementId)
import Common.UI as UI
import Common.View.Controls as ViewControls
import Element exposing (Element, centerX, centerY, el, height, htmlAttribute, px, text, width)
import Element.Font as Font
import Html.Attributes
import Json.Encode as Encode



-- PORTS


port waapiCommand : Encode.Value -> Cmd msg


port waapiSubscriptions : (Encode.Value -> msg) -> Sub msg



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
    { animState : WAAPI.AnimState Msg
    , animAreaSize : { width : Int, height : Int }
    }



-- INIT


init : { window : { width : Int, height : Int } } -> ( Model, Cmd Msg )
init { window } =
    let
        animAreaWidth =
            min 500 (window.width - 40)

        ( initialAnimState, initCmd ) =
            WAAPI.init waapiCommand waapiSubscriptions <|
                [ Controls.init animAreaWidth ]
    in
    ( { animState = initialAnimState
      , animAreaSize =
            { width = animAreaWidth
            , height = 350
            }
      }
    , initCmd
    )



-- UPDATE


type Msg
    = Animate
    | Stop
    | Pause
    | Resume
    | Reset
    | Restart
    | GotWaapiMsg WAAPI.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotWaapiMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    WAAPI.update subMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        Animate ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate model.animState Controls.animate
            in
            ( { model | animState = newAnimState }
            , animCmd
            )

        -- --8<-- [start:stop]
        Stop ->
            let
                ( newAnimState, stopCmd ) =
                    WAAPI.stop elementId model.animState
            in
            ( { model | animState = newAnimState }
            , stopCmd
            )

        -- --8<-- [end:stop]
        -- --8<-- [start:pause]
        Pause ->
            let
                ( newAnimState, pauseCmd ) =
                    WAAPI.pause elementId model.animState
            in
            ( { model | animState = newAnimState }
            , pauseCmd
            )

        -- --8<-- [end:pause]
        -- --8<-- [start:resume]
        Resume ->
            let
                ( newAnimState, resumeCmd ) =
                    WAAPI.resume elementId model.animState
            in
            ( { model | animState = newAnimState }
            , resumeCmd
            )

        -- --8<-- [end:resume]
        -- --8<-- [start:reset]
        Reset ->
            let
                ( newAnimState, resetCmd ) =
                    WAAPI.reset elementId model.animState
            in
            ( { model | animState = newAnimState }
            , resetCmd
            )

        -- --8<-- [end:reset]
        -- --8<-- [start:restart]
        Restart ->
            let
                ( newAnimState, restartCmd ) =
                    WAAPI.restart elementId model.animState
            in
            ( { model | animState = newAnimState }
            , restartCmd
            )



-- --8<-- [end:restart]
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



-- VIEW - Using ElmUI, but the same animation logic works with any view layer


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.WAAPI Controls ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ ViewControls.header
        [ "WAAPI Engine Controls"
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
    , ViewControls.animationArea model.animAreaSize animatedBall
    ]


animatedBall : Element msg
animatedBall =
    el
        [ -- The WAAPI engine requires an id attribute to target the element for animation
          -- The JS side will use this id to identify the element to animate, 
          -- and to manage animation state for that element
          htmlAttribute (Html.Attributes.id elementId)
        , width (px 50)
        , height (px 50)
        , htmlAttribute (Html.Attributes.style "position" "relative")
        ]
        (el [ centerX, centerY, Font.size 50 ] (text "🏀"))
