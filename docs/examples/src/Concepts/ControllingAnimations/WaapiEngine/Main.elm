port module Concepts.ControllingAnimations.WaapiEngine.Main exposing (main)

import Anim.Engine.WAAPI as WAAPI exposing (AnimBuilder)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Common.UI as UI
import Common.View.Controls as ViewControls
import Element exposing (Element, centerX, centerY, el, height, htmlAttribute, px, text, width)
import Element.Font as Font
import Html.Attributes
import Json.Encode as Encode



-- PORTS


port waapiCommand : Encode.Value -> Cmd msg


port waapiEvent : (Encode.Value -> msg) -> Sub msg



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


{-| Animation group name for tracking animation state
-}
animGroup : String
animGroup =
    "bouncingBall"


{-| DOM element ID for the animated element
-}
domId : String
domId =
    "bouncing-ball"



-- INIT


init : { window : { width : Int, height : Int } } -> ( Model, Cmd Msg )
init { window } =
    let
        animAreaWidth =
            min 500 (window.width - 40)

        xPos =
            toFloat animAreaWidth / 2 - 25

        initialAnimState =
            WAAPI.init waapiCommand waapiEvent <|
                [ Translate.initXY animGroup xPos 50 ]
    in
    ( { animState = initialAnimState
      , animAreaSize =
            { width = animAreaWidth
            , height = 350
            }
      }
    , Cmd.none
    )



-- ANIMATION


dropBall : AnimBuilder -> AnimBuilder
dropBall =
    Translate.for animGroup
        >> Translate.fromY 50
        >> Translate.toY 300
        >> Translate.speed 200
        >> Translate.easing BounceOut
        >> Translate.build



-- UPDATE


type Msg
    = Animate
    | Stop
    | Pause
    | Resume
    | Reset
    | Restart
    | GotWaapiMsg WAAPI.AnimMsg


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
                    WAAPI.animate model.animState dropBall
            in
            ( { model | animState = newAnimState }
            , animCmd
            )

        -- --8<-- [start:stop]
        Stop ->
            let
                ( newAnimState, stopCmd ) =
                    WAAPI.stop animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , stopCmd
            )

        -- --8<-- [end:stop]
        -- --8<-- [start:pause]
        Pause ->
            let
                ( newAnimState, pauseCmd ) =
                    WAAPI.pause animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , pauseCmd
            )

        -- --8<-- [end:pause]
        -- --8<-- [start:resume]
        Resume ->
            let
                ( newAnimState, resumeCmd ) =
                    WAAPI.resume animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , resumeCmd
            )

        -- --8<-- [end:resume]
        -- --8<-- [start:reset]
        Reset ->
            let
                ( newAnimState, resetCmd ) =
                    WAAPI.reset animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , resetCmd
            )

        -- --8<-- [end:reset]
        -- --8<-- [start:restart]
        Restart ->
            let
                ( newAnimState, restartCmd ) =
                    WAAPI.restart animGroup model.animState
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
    , ViewControls.animationArea model.animAreaSize <|
        animatedBall model.animState
    ]


animatedBall : WAAPI.AnimState msg -> Element msg
animatedBall animState =
    el
        (List.map htmlAttribute (WAAPI.attributes animGroup animState)
            ++ [ htmlAttribute (Html.Attributes.id domId)
               , htmlAttribute (Html.Attributes.style "position" "relative")
               , width (px 50)
               , height (px 50)
               ]
        )
        (el [ centerX, centerY, Font.size 50 ] (text "🏀"))
