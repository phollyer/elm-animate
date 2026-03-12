module Engines.Transitions.ControllingAnimations.Main exposing (main)

import Anim.Engine.CSS.Transitions as Transitions exposing (AnimBuilder)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Common.UI as UI
import Common.View.Controls as ViewControls
import Element exposing (Element, centerX, centerY, el, height, htmlAttribute, px, text, width)
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
    { animState : Transitions.AnimState
    , animAreaSize : { width : Int, height : Int }
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
            Transitions.init <|
                [ Translate.initXY animGroup xPos 50 ]
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
    | Reset


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate ->
            ( { model
                | animState = Transitions.animate model.animState dropBall
              }
            , Cmd.none
            )

        -- --8<-- [start:stop]
        Stop ->
            ( { model | animState = Transitions.stop animGroup model.animState }
            , Cmd.none
            )

        -- --8<-- [end:stop]
        -- --8<-- [start:reset]
        Reset ->
            ( { model | animState = Transitions.reset animGroup model.animState }
            , Cmd.none
            )



-- --8<-- [end:reset]
-- VIEW - Using ElmUI, but the same animation logic works with any view layer


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.Transitions Transition Controls Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ ViewControls.header
        [ "Transitions Engine Controls" ]
    , ViewControls.table
        [ ( 0, "🏀 Animate", "Drop the ball" )
        , ( 1, "⏹️ Stop", "Jump instantly to end state and stop" )
        , ( 1, "⏮️ Reset", "Jump instantly to start state and stop" )
        ]
    , ViewControls.buttons
        [ [ ( UI.Primary, Animate, "🏀 Animate" )
          , ( UI.Warning, Stop, "⏹️ Stop" )
          , ( UI.Purple, Reset, "⏮️ Reset" )
          ]
        ]
    , ViewControls.animationArea model.animAreaSize <|
        animatedBall model.animState
    ]


animatedBall : Transitions.AnimState -> Element msg
animatedBall animState =
    el
        (List.map htmlAttribute (Transitions.attributes animGroup animState)
            ++ [ htmlAttribute (Html.Attributes.style "position" "relative")
               , width (px 50)
               , height (px 50)
               ]
        )
        (el [ centerX, centerY, Font.size 50 ] (text "🏀"))
