module ElmUI.Scroll.Container.Position.X.Main exposing (main)

import Anim.Action.Scroll as ScrollAction
import Anim.Engine.Scroll as Scroll
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, clipX, column, el, fill, height, htmlAttribute, padding, paddingEach, paddingXY, paragraph, px, rgb255, row, scrollbarX, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { scrollAnimations : Scroll.AnimState
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { scrollAnimations = Scroll.init }, Cmd.none )


scrollToElement : String -> Cmd Msg
scrollToElement targetId =
    Scroll.init
        |> Scroll.builder
        |> Scroll.speed 500
        |> ScrollAction.forContainer "horizontal-scroll-container"
        |> ScrollAction.toElement targetId
        |> ScrollAction.build
        |> Scroll.toCmd NoOp


scrollToX : Float -> Cmd Msg
scrollToX xPos =
    Scroll.init
        |> Scroll.builder
        |> Scroll.speed 500
        |> ScrollAction.forContainer "horizontal-scroll-container"
        |> ScrollAction.toX xPos
        |> ScrollAction.onXAxisWithOffset 20
        |> ScrollAction.build
        |> Scroll.toCmd NoOp



-- UPDATE


type Msg
    = NoOp
    | ScrollAnimationMsg Scroll.AnimationMsg
    | ScrollToCard Int
    | ScrollToStart
    | ScrollToEnd


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ScrollAnimationMsg scrollMsg ->
            let
                ( newScrollState, scrollCmd ) =
                    Scroll.update ScrollAnimationMsg scrollMsg model.scrollAnimations
            in
            ( { model | scrollAnimations = newScrollState }
            , scrollCmd
            )

        ScrollToCard cardNum ->
            ( model, scrollToElement ("card-" ++ String.fromInt cardNum) )

        ScrollToStart ->
            ( model, scrollToX 0 )

        ScrollToEnd ->
            ( model, scrollToX 10000 )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Scroll.subscriptions ScrollAnimationMsg model.scrollAnimations



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveScroll Horizontal Container ElmUI Example" UI.HorizontalContainer (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ -- Back Button
      UI.backButtonWithPath "../../../../index.html"
    , UI.pageHeader "ElmUI & Scroll Container X Example"
    , -- Navigation Buttons
      column
        [ spacing 16
        , centerX
        ]
        [ UI.wrappedButtonRow
            (List.range 1 10
                |> List.map
                    (\i ->
                        ( case i of
                            1 ->
                                UI.Primary

                            2 ->
                                UI.Success

                            3 ->
                                UI.Purple

                            4 ->
                                UI.Warning

                            5 ->
                                UI.Primary

                            6 ->
                                UI.Success

                            7 ->
                                UI.Purple

                            8 ->
                                UI.Warning

                            9 ->
                                UI.Primary

                            _ ->
                                UI.Success
                        , ScrollToCard i
                        , "Card " ++ String.fromInt i
                        )
                    )
            )
        , row
            [ spacing 16
            , centerX
            ]
            [ UI.actionButton UI.Primary ScrollToStart "← Start"
            , UI.actionButton UI.Primary ScrollToEnd "End →"
            ]
        ]
    , -- Horizontal Scroll Container
      el
        [ width fill
        , height (px 400)
        , Background.color Colors.backgroundWhite
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.15
            }
        , htmlAttribute (Html.Attributes.id "horizontal-scroll-container")
        , htmlAttribute (Html.Attributes.class "scroll-container")
        , scrollbarX
        ]
        (row
            [ spacing 20
            , paddingXY 30 30

            --, width (px 2000)
            ]
            (List.range 1 10
                |> List.map viewCard
            )
        )
    ]


viewCard : Int -> Element Msg
viewCard cardNum =
    column
        [ width (px 280)
        , height (px 320)
        , spacing 16
        , htmlAttribute (Html.Attributes.id ("card-" ++ String.fromInt cardNum))
        , Background.color (UI.getCardColor cardNum)
        , paddingXY 24 20
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 2 )
            , size = 0
            , blur = 4
            , color = Element.rgba 0 0 0 0.1
            }
        ]
        [ -- Card Header
          el
            [ Font.size 20
            , Font.semiBold
            , Font.color Colors.backgroundWhite
            , centerX
            ]
            (text ("Card " ++ String.fromInt cardNum))
        , -- Card Content
          column
            [ spacing 12
            , width fill
            , height fill
            ]
            [ paragraph
                [ Font.size 14
                , Font.color Colors.backgroundWhite
                , width fill
                ]
                [ text ("This is card number " ++ String.fromInt cardNum ++ ". ")
                , text "Each card demonstrates horizontal scrolling within a constrained container element."
                ]
            , paragraph
                [ Font.size 14
                , Font.color Colors.backgroundWhite
                , width fill
                ]
                [ text "The X axis scrolling smoothly navigates between cards using precise positioning calculations."
                ]
            , -- Navigation buttons within card
              row
                [ spacing 8
                , centerX
                ]
                [ if cardNum > 1 then
                    Input.button
                        [ Font.size 12
                        , Font.color Colors.backgroundWhite
                        , Font.medium
                        , paddingXY 12 6
                        , Border.rounded 4
                        , Background.color (Element.rgba 255 255 255 0.2)
                        , Border.width 1
                        , Border.color (Element.rgba 255 255 255 0.3)
                        ]
                        { onPress = Just (ScrollToCard (cardNum - 1))
                        , label = text "← Prev"
                        }

                  else
                    el [] (text "")
                , if cardNum < 10 then
                    Input.button
                        [ Font.size 12
                        , Font.color Colors.backgroundWhite
                        , Font.medium
                        , paddingXY 12 6
                        , Border.rounded 4
                        , Background.color (Element.rgba 255 255 255 0.2)
                        , Border.width 1
                        , Border.color (Element.rgba 255 255 255 0.3)
                        ]
                        { onPress = Just (ScrollToCard (cardNum + 1))
                        , label = text "Next →"
                        }

                  else
                    el [] (text "")
                ]
            ]
        ]
