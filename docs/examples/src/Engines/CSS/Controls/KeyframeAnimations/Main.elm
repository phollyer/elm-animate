module Engines.CSS.Controls.KeyframeAnimations.Main exposing (main)

import Anim.Engine.CSS as CSS
import Browser exposing (Document)
import Common.Animations.Controls as Controls exposing (elementId)
import Common.Colors as Colors
import Common.UI as UI
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


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.CSS Keyframe Animation Controls Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ -- Add the generated keyframes to the DOM
      html <|
        CSS.keyframesStyleNodeFor elementId model.animState
    , header
    , controlsTable
    , controlButtons
    , animationArea model.animAreaSize model.animState
    ]


header : Element Msg
header =
    column
        [ centerX
        , spacing 8
        ]
        [ UI.pageHeader "CSS Engine Controls"
        , UI.pageHeader "for"
        , UI.pageHeader "Keyframe Animations"
        ]



-- Animation Area


animationArea : { width : Int, height : Int } -> CSS.AnimState -> Element Msg
animationArea size animState =
    el
        [ width <|
            px size.width
        , height <|
            px size.height
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
    <|
        animatedBall animState


animatedBall : CSS.AnimState -> Element Msg
animatedBall animState =
    el
        ([ width (px 50)
         , height (px 50)
         , htmlAttribute (Html.Attributes.style "position" "relative")
         ]
            -- Add the generated animation styles to the element
            -- This is how the browser knows to apply the keyframes animation to this element
            ++ List.map htmlAttribute
                (CSS.keyframesStyles elementId animState)
        )
        (el [ centerX, centerY, Font.size 50 ] (text "🏀"))



-- Controls Table


controlsTable : Element Msg
controlsTable =
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
            [ controlDescription 0 "🏀 Animate" "Drop the ball"
            , controlDescription 1 "⏹️ Stop" "Jump instantly to end state and stop"
            , controlDescription 1 "⏸️ Pause" "Pause animation at current position"
            , controlDescription 1 "▶️ Resume" "Continue paused animation"
            , controlDescription 1 "⏮️ Reset" "Jump instantly to start state and stop"
            , controlDescription 1 "🔄 Restart" "Reset to start, then begin animation again"
            ]
        ]


controlDescription : Int -> String -> String -> Element Msg
controlDescription borderWidth control description =
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



-- Buttons


controlButtons : Element Msg
controlButtons =
    row
        [ spacing 12, centerX ]
        [ buttons
            [ ( UI.Primary, Animate, "🏀 Animate" )
            , ( UI.Warning, Stop, "⏹️ Stop" )
            ]
        , buttons
            [ ( UI.Success, Pause, "⏸️ Pause" )
            , ( UI.Success, Resume, "▶️ Resume" )
            ]
        , buttons
            [ ( UI.Purple, Reset, "⏮️ Reset" )
            , ( UI.Purple, Restart, "🔄 Restart" )
            ]
        ]


buttons : List ( UI.ButtonStyle, Msg, String ) -> Element Msg
buttons =
    column [ spacing 12 ] << List.map button


button : ( UI.ButtonStyle, msg, String ) -> Element msg
button =
    UI.htmlButton
        >> html
        >> el [ centerX ]
