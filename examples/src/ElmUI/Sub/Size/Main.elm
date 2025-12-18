module ElmUI.Sub.Size.Main exposing (main)

{-| Anim.Sub Size Example using ElmUI - Width and height animations

This example demonstrates smooth size animations using browser-native Subscription-Based sizing.
Perfect for responsive layouts, emphasis animations, and dynamic element sizing.

FEATURES:

  - ✅ Smooth width and height animations
  - ✅ Hardware-accelerated size transitions
  - ✅ Multiple size configurations and timing
  - ✅ Responsive and dynamic sizing effects
  - ✅ Battery efficient browser-native transitions

-}

import Anim.Properties.Size as Size
import Anim.Sub as Sub
import Anim.Timing.Easing as Easing exposing (Easing(..))
import Browser exposing (Document)
import Browser.Events
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
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
    { animations : Sub.AnimationState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations =
            Sub.init
                |> Sub.builder
                |> Size.for "box"
                |> Size.toHW 100 100
                |> Size.duration 0
                |> Size.easing Easing.EaseOut
                |> Size.build
                |> Sub.animate
      }
    , Cmd.none
    )


type Msg
    = SizeUp
    | SizeDown
    | SizeReset
    | SizeWide
    | SizeTall
    | AnimationMsg Sub.AnimationMsg



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SizeUp ->
            let
                ( newWidth, newHeight ) =
                    case Sub.getSize "box" model.animations of
                        Just size ->
                            let
                                ( w, h ) =
                                    Size.toTuple size
                            in
                            ( (w * 2) |> min 400, (h * 2) |> min 300 )

                        Nothing ->
                            ( 100, 100 )
            in
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Size.for "box"
                        |> Size.toHW newHeight newWidth
                        |> Size.duration 2000
                        |> Size.easing Easing.BounceOut
                        |> Size.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        SizeDown ->
            let
                ( newWidth, newHeight ) =
                    case Sub.getSize "box" model.animations of
                        Just size ->
                            let
                                ( w, h ) =
                                    Size.toTuple size
                            in
                            ( (w / 2) |> max 50, (h / 2) |> max 50 )

                        Nothing ->
                            ( 50, 50 )
            in
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Size.for "box"
                        |> Size.toHW newHeight newWidth
                        |> Size.duration 1000
                        |> Size.easing Easing.QuadInOut
                        |> Size.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        SizeReset ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Size.for "box"
                        |> Size.toHW 150 150
                        |> Size.duration 1500
                        |> Size.easing Easing.EaseInOut
                        |> Size.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        SizeWide ->
            let
                newWidth =
                    case Sub.getSize "box" model.animations of
                        Just size ->
                            let
                                ( w, h ) =
                                    Size.toTuple size
                            in
                            (w * 2) |> max 400

                        Nothing ->
                            400
            in
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Size.for "box"
                        |> Size.toW newWidth
                        |> Size.duration 1000
                        |> Size.easing Easing.QuintInOut
                        |> Size.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        SizeTall ->
            let
                newHeight =
                    case Sub.getSize "box" model.animations of
                        Just size ->
                            let
                                ( w, h ) =
                                    Size.toTuple size
                            in
                            (h * 2) |> max 300

                        Nothing ->
                            300
            in
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Size.for "box"
                        |> Size.toH newHeight
                        |> Size.speed 400
                        |> Size.easing Easing.QuadInOut
                        |> Size.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        AnimationMsg animMsg ->
            ( { model | animations = Sub.update animMsg model.animations }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map AnimationMsg (Sub.subscriptions model.animations)



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Sub Size ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Subscription Size Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth width and height animations using browser-native Subscription-Based transitions")
    , -- Size controls
      UI.wrappedButtonRow
        [ ( UI.Primary, SizeUp, "Size Up" )
        , ( UI.Warning, SizeDown, "Size Down" )
        , ( UI.Success, SizeWide, "Wide" )
        , ( UI.Success, SizeTall, "Tall" )
        , ( UI.Purple, SizeReset, "Reset" )
        ]
    , -- Animation area with box
      el
        [ width (fill |> maximum 600)
        , height (px 400)
        , Background.color Colors.backgroundWhite
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.1
            }
        , centerX
        , htmlAttribute (Html.Attributes.style "position" "relative")
        , htmlAttribute (Html.Attributes.style "overflow" "visible")
        , htmlAttribute (Html.Attributes.style "display" "flex")
        , htmlAttribute (Html.Attributes.style "flex-direction" "column")
        , htmlAttribute (Html.Attributes.style "align-items" "center")
        , htmlAttribute (Html.Attributes.style "justify-content" "space-around")
        , htmlAttribute (Html.Attributes.style "padding" "40px")
        ]
        (el
            [ centerX
            , Element.centerY
            , width (px 200)
            , height (px 200)
            ]
            (animatedBox "box" "Size Demo" Colors.primary model)
        )
    ]


animatedBox : String -> String -> Element.Color -> Model -> Element Msg
animatedBox elementId label color model =
    el
        ([ width (px 150)
         , height (px 150)
         , Background.color color
         , Border.rounded 12
         , centerX
         , htmlAttribute (Html.Attributes.id elementId)
         , htmlAttribute (Html.Attributes.style "display" "flex")
         , htmlAttribute (Html.Attributes.style "align-items" "center")
         , htmlAttribute (Html.Attributes.style "justify-content" "center")
         ]
            ++ (Sub.htmlAttributes elementId model.animations
                    |> List.map htmlAttribute
               )
        )
        (el
            [ centerX
            , Element.centerY
            , Font.color Colors.backgroundWhite
            , Font.bold
            , Font.size 16
            ]
            (text label)
        )
