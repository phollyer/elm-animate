module Concepts.ControllingAnimations.TransitionsEngine.Main exposing (main)

import Anim.Engine.CSS.Transitions as CSS
import Browser exposing (Document)
import Common.Animations.Controls as Controls exposing (elementId)
import Common.Colors as Colors
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
-- VIEW - Using ElmUI, but the same animation logic works with any view layer
--
--
-- Engine-specific view helpers


transitionAttributes : CSS.AnimState -> List (Element.Attribute msg)
transitionAttributes =
    CSS.attributes elementId >> List.map htmlAttribute



-- View Helpers


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.CSS Transition Controls Example"
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


animatedBall : CSS.AnimState -> Element msg
animatedBall animState =
    el
        (transitionAttributes animState
            ++ [ width (px 50)
               , height (px 50)
               , htmlAttribute (Html.Attributes.style "position" "relative")
               ]
        )
        (el [ centerX, centerY, Font.size 50 ] (text "🏀"))
