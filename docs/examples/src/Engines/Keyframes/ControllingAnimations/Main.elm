module Engines.Keyframes.ControllingAnimations.Main exposing (main)

import Anim.Engine.CSS.Keyframes as Keyframes exposing (AnimBuilder)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Common.UI as UI
import Common.View.Controls as ViewControls
import Element exposing (Element, centerX, centerY, el, height, html, htmlAttribute, px, text, width)
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
    { animState : Keyframes.AnimState
    }


animGroup : String
animGroup =
    "bouncingBall"



-- INIT


init : { window : { width : Int } } -> ( Model, Cmd Msg )
init { window } =
    let
        animAreaWidth =
            min 500 (window.width - 40)

        xPos =
            toFloat animAreaWidth / 2 - 25
    in
    ( { animState =
            Keyframes.init <|
                [ Translate.initXY animGroup xPos 50 ]
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
    | Reset
    | Restart
    | Pause
    | Resume
    | GotAnimMsg Keyframes.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate ->
            ( { model
                | animState = Keyframes.animate model.animState dropBall
              }
            , Cmd.none
            )

        ---8<-- [start:stop]
        Stop ->
            ( { model | animState = Keyframes.stop animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:stop]
        ---8<-- [start:reset]
        Reset ->
            ( { model | animState = Keyframes.reset animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:reset]
        ---8<-- [start:restart]
        Restart ->
            let
                ( newState, eventCmd ) =
                    Keyframes.restart animGroup GotAnimMsg model.animState
            in
            ( { model | animState = newState }, eventCmd )

        ---8<-- [end:restart]
        ---8<-- [start:pause]
        Pause ->
            let
                ( newState, eventCmd ) =
                    Keyframes.pause animGroup GotAnimMsg model.animState
            in
            ( { model | animState = newState }, eventCmd )

        ---8<-- [end:pause]
        ---8<-- [start:resume]
        Resume ->
            let
                ( newState, eventCmd ) =
                    Keyframes.resume animGroup GotAnimMsg model.animState
            in
            ( { model | animState = newState }, eventCmd )

        ---8<-- [end:resume]
        GotAnimMsg _ ->
            ( model, Cmd.none )



---8<-- [end:resume]
-- VIEW - Using ElmUI, but the same animation logic works with any view layer


view : Model -> Document Msg
view model =
    UI.createDocument
        "Keyframes Engine Controls Example - Elm Animate"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ html <|
        Keyframes.styleNodeFor animGroup model.animState
    , ViewControls.header
        [ "Keyframes Engine Controls" ]
    , ViewControls.buttons
        [ [ ( UI.Primary, Animate, "🏀 Animate" )
          , ( UI.Success, Pause, "⏸️ Pause" )
          ]
        , [ ( UI.Warning, Stop, "⏹️ Stop" )
          , ( UI.Success, Resume, "▶️ Resume" )
          ]
        , [ ( UI.Purple, Reset, "⏮️ Reset" )
          , ( UI.Purple, Restart, "🔄 Restart" )
          ]
        ]
    , ViewControls.animationArea <|
        animatedBall model.animState
    ]


animatedBall : Keyframes.AnimState -> Element msg
animatedBall animState =
    el
        (List.map htmlAttribute (Keyframes.attributes animGroup animState)
            ++ [ htmlAttribute (Html.Attributes.style "position" "relative")
               , width (px 50)
               , height (px 50)
               ]
        )
        (el [ centerX, centerY, Font.size 50 ] (text "🏀"))
