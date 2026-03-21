module Engines.Scroll.ControllingScrolls.Main exposing (main)

import Anim.Engine.Scroll as Scroll
import Anim.Engine.Scroll.Builder as ScrollTo
import Anim.Extra.Easing exposing (Easing(..))
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Common.View.Controls as ViewControls
import Element exposing (Element, centerX, centerY, clip, column, el, fill, height, htmlAttribute, padding, paddingXY, paragraph, px, rgb255, rgba255, row, scrollbarY, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = always init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { scrollState : Scroll.AnimState
    }


containerId : String
containerId =
    "scroll-container"


targetId : String
targetId =
    "scroll-target"



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { scrollState = Scroll.init
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ScrollAnimate
    | Stop
    | Pause
    | Resume
    | Reset
    | Restart
    | GotScrollMsg Scroll.AnimMsg
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GotScrollMsg scrollMsg ->
            let
                ( newScrollState, _, scrollCmd ) =
                    Scroll.update GotScrollMsg scrollMsg model.scrollState
            in
            ( { model | scrollState = newScrollState }
            , scrollCmd
            )

        ScrollAnimate ->
            let
                ( newScrollState, scrollCmd ) =
                    Scroll.animate GotScrollMsg model.scrollState scrollAnimation
            in
            ( { model | scrollState = newScrollState }
            , scrollCmd
            )

        ---8<-- [start:stop]
        Stop ->
            let
                ( newScrollState, scrollCmd ) =
                    Scroll.stopContainer containerId GotScrollMsg model.scrollState
            in
            ( { model | scrollState = newScrollState }
            , scrollCmd
            )

        ---8<-- [end:stop]
        ---8<-- [start:pause]
        Pause ->
            ( { model | scrollState = Scroll.pauseContainer containerId model.scrollState }
            , Cmd.none
            )

        ---8<-- [end:pause]
        ---8<-- [start:resume]
        Resume ->
            ( { model | scrollState = Scroll.resumeContainer containerId model.scrollState }
            , Cmd.none
            )

        ---8<-- [end:resume]
        ---8<-- [start:reset]
        Reset ->
            let
                ( newScrollState, scrollCmd ) =
                    Scroll.resetContainer containerId GotScrollMsg model.scrollState
            in
            ( { model | scrollState = newScrollState }
            , scrollCmd
            )

        ---8<-- [end:reset]
        ---8<-- [start:restart]
        Restart ->
            let
                ( newScrollState, scrollCmd ) =
                    Scroll.restartContainer containerId GotScrollMsg model.scrollState
            in
            ( { model | scrollState = newScrollState }
            , scrollCmd
            )



---8<-- [end:restart]
-- ANIMATION


scrollAnimation : Scroll.AnimBuilder -> Scroll.AnimBuilder
scrollAnimation =
    ScrollTo.forContainer containerId
        >> ScrollTo.toElement targetId
        >> ScrollTo.speed 200
        >> ScrollTo.easing BounceOut
        >> ScrollTo.build



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Scroll.subscriptions GotScrollMsg model.scrollState



-- VIEW - Using ElmUI, but the scroll engine works with any view layer
--        since it targets DOM elements directly.
--
--        All the scroll animation logic is handled by the engine in your
--        update function, there is nothing Engine-specific to add to your
--        view layer.


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.Scroll Controls ElmUI Example"
        UI.Container
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ ViewControls.header
        [ "Scroll Engine Controls"
        ]
    , ViewControls.table
        [ ( 0, "📜 Scroll", "Scroll to target element" )
        , ( 1, "⏹️ Stop", "Jump instantly to target position" )
        , ( 1, "⏸️ Pause", "Pause scroll at current position" )
        , ( 1, "▶️ Resume", "Continue paused scroll" )
        , ( 1, "⏮️ Reset", "Jump instantly to start position" )
        , ( 1, "🔄 Restart", "Reset to start, then scroll again" )
        ]
    , ViewControls.buttons
        [ [ ( UI.Primary, ScrollAnimate, "📜 Scroll" )
          , ( UI.Warning, Stop, "⏹️ Stop" )
          ]
        , [ ( UI.Success, Pause, "⏸️ Pause" )
          , ( UI.Success, Resume, "▶️ Resume" )
          ]
        , [ ( UI.Purple, Reset, "⏮️ Reset" )
          , ( UI.Purple, Restart, "🔄 Restart" )
          ]
        ]
    , scrollableContainer model
    ]


scrollableContainer : Model -> Element msg
scrollableContainer model =
    el [ width fill, htmlAttribute (Html.Attributes.class "scroll-container-wrapper") ] <|
        el
            [ htmlAttribute (Html.Attributes.id containerId)
            , width fill
            , height (px 350)
            , Border.width 2
            , Border.color Colors.borderMedium
            , Border.rounded 12
            , Background.color Colors.backgroundWhite
            , Border.shadow
                { offset = ( 0, 4 )
                , size = 0
                , blur = 20
                , color = rgba255 0 0 0 0.1
                }
            , scrollbarY
            ]
        <|
            content


content : Element msg
content =
    column
        [ width fill
        , spacing 20
        , padding 20
        ]
        (List.concat
            [ [ contentSection "📍 Start" "This is the beginning of the scrollable content." Colors.primary ]
            , List.indexedMap
                (\i _ ->
                    contentSection
                        ("Section " ++ String.fromInt (i + 1))
                        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
                        Colors.textMedium
                )
                (List.repeat 5 ())
            , [ targetSection ]
            , List.indexedMap
                (\i _ ->
                    contentSection
                        ("Section " ++ String.fromInt (i + 7))
                        "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris."
                        Colors.textMedium
                )
                (List.repeat 3 ())
            , [ contentSection "📍 End" "This is the end of the scrollable content." Colors.primary ]
            ]
        )


contentSection : String -> String -> Element.Color -> Element msg
contentSection title description_ color =
    column
        [ width fill
        , spacing 8
        , paddingXY 16 12
        , Background.color Colors.backgroundLight
        , Border.rounded 8
        ]
        [ el [ Font.bold, Font.color color, Font.size 16 ] (text title)
        , paragraph [ Font.size 14, Font.color Colors.textMedium ] [ text description_ ]
        ]


targetSection : Element msg
targetSection =
    column
        [ width fill
        , spacing 8
        , paddingXY 16 12
        , Background.color (Element.rgb255 255 243 224)
        , Border.rounded 8
        , Border.width 2
        , Border.color (Element.rgb255 255 152 0)
        , htmlAttribute (Html.Attributes.id targetId)
        ]
        [ el [ Font.bold, Font.color (Element.rgb255 230 81 0), Font.size 18 ] (text "🎯 Target Section")
        , paragraph [ Font.size 14, Font.color Colors.textMedium ] [ text "This is the scroll target. The scroll animation will bring this section into view." ]
        ]
