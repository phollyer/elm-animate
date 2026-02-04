module Engines.CSS.Controls.Transitions.Main exposing (main)

import Anim.Engine.CSS as CSS
import Browser exposing (Document)
import Browser.Events exposing (onResize)
import Common.Animations.Controls as Controls exposing (elementId)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, explain, fill, height, html, htmlAttribute, inFront, maximum, none, padding, paddingEach, paragraph, px, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Json.Encode as Encode
import Time



-- MAIN


main : Program { window : { width : Int, height : Int } } Model Msg
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


init : { window : { width : Int, height : Int } } -> ( Model, Cmd Msg )
init { window } =
    let
        animAreaWidth =
            min 500 (window.width - 40)

        initialAnimState =
            CSS.init <|
                [ Controls.init animAreaWidth ]
    in
    ( { animState = initialAnimState
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

        -- --8<-- [end:resume]
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
-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.CSS Controls ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.pageHeader "CSS Engine Controls"
    , column
        [ width fill
        , spacing 8
        ]
        [ paragraph
            [ width fill
            , Font.size 16
            , Font.color Colors.textMedium
            , Font.center
            ]
            [ text "Demonstrating all available Engine Controls" ]
        , paragraph
            [ width fill
            , Font.size 16
            , Font.color Colors.textMedium
            , Font.center
            ]
            [ text "for CSS Keyframe Animations" ]
        ]
    , -- Controls explanation
      column
        [ centerX
        , Border.width 1
        , Border.color Colors.borderMedium
        , Border.shadow
            { offset = ( 0, 2 )
            , size = 2
            , blur = 4
            , color = Element.rgba 0 0 0 0.1
            }
        , Background.color Colors.backgroundLight
        , Border.rounded 8
        ]
        [ el
            [ width fill
            , Border.widthEach
                { top = 0
                , right = 0
                , bottom = 1
                , left = 0
                }
            ]
          <|
            el
                [ Font.size 18
                , padding 8
                , centerX
                , Font.medium
                , Font.color Colors.textDark
                ]
                (text "🎮 Control Functions")
        , column
            [ width fill ]
            [ viewControlDescription 0 "🏀 Animate" "Drop the ball"
            , viewControlDescription 1 "⏹️ Stop" "Jump instantly to end state and stop"
            , viewControlDescription 1 "⏮️ Reset" "Jump instantly to start state and stop"
            , viewControlDescription 1 "🔄 Restart" "Reset to start, then begin animation again"
            ]
        ]
    , -- Control buttons
      row
        [ spacing 12, centerX ]
        [ buttons
            [ ( UI.Primary, Animate, "🏀 Animate" )
            , ( UI.Warning, Stop, "⏹️ Stop" )
            ]
        , buttons
            [ ( UI.Purple, Reset, "⏮️ Reset" )
            , ( UI.Purple, Restart, "🔄 Restart" )
            ]
        ]
    , -- Animation area
      el
        [ width <|
            px model.animAreaSize.width
        , height (px 350)
        , Background.color Colors.backgroundWhite
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.1
            }
        , centerX
        ]
        (el
            ([ width (px 50)
             , height (px 50)
             , htmlAttribute (Html.Attributes.style "position" "relative")
             ]
                ++ List.map htmlAttribute (CSS.transitionAttributes elementId model.animState)
            )
            (el [ centerX, centerY, Font.size 50 ] (text "🏀"))
        )
    ]


viewControlDescription : Int -> String -> String -> Element Msg
viewControlDescription borderWidth control description =
    row
        [ width fill
        , Border.widthEach
            { top = borderWidth
            , right = 0
            , bottom = 0
            , left = 0
            }
        , padding 4
        ]
        [ el
            [ Font.size 14
            , Font.medium
            , Font.color Colors.primary
            , width (px 80)
            ]
            (text control)
        , el
            [ Font.size 14
            , Font.color Colors.textMedium
            ]
            (text description)
        ]


buttons : List ( UI.ButtonStyle, Msg, String ) -> Element Msg
buttons =
    column [ spacing 12 ] << List.map button


button : ( UI.ButtonStyle, msg, String ) -> Element msg
button =
    UI.htmlButton
        >> html
        >> el [ centerX ]
