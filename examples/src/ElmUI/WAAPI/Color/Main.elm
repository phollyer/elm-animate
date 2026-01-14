port module ElmUI.WAAPI.Color.Main exposing (main)

{-| Anim.Engine.CSS Color Example using ElmUI - Background color transition animations

This example demonstrates smooth color transitions using browser-native CSS animations.
Perfect for theme changes, state indicators, and dynamic color feedback.

FEATURES:

  - ✅ Smooth background color transitions
  - ✅ Hardware-accelerated color interpolation
  - ✅ Multiple color formats (hex, rgb, hsl)
  - ✅ Theme switching and state changes
  - ✅ Battery efficient browser-native transitions

-}

import Anim.Color
import Anim.Easing as Easing
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.BackgroundColor as Color
import Browser exposing (Document)
import Common.Animations.BackgroundColor as Animations
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode



-- PORTS


port animateElement : Encode.Value -> Cmd msg



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
    { animState : WAAPI.AnimState
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        ( initialAnimState, initCmd ) =
            WAAPI.animate animateElement WAAPI.init <|
                \b -> b |> Color.init "box" (Anim.Color.fromRgba { r = 149, g = 165, b = 166, a = 1 })
    in
    ( { animState = initialAnimState }
    , initCmd
    )


type Msg
    = ChangeToBlue
    | ChangeToGreen
    | ChangeToOrange
    | ChangeToRed
    | ChangeToPurple
    | ResetColor
    | NoOp



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeToBlue ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate animateElement model.animState (Animations.changeToBlue "box")
            in
            ( { model | animState = newAnimState }, animCmd )

        ChangeToGreen ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate animateElement model.animState (Animations.changeToGreen "box")
            in
            ( { model | animState = newAnimState }, animCmd )

        ChangeToOrange ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate animateElement model.animState (Animations.changeToOrange "box")
            in
            ( { model | animState = newAnimState }, animCmd )

        ChangeToRed ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate animateElement model.animState (Animations.changeToRed "box")
            in
            ( { model | animState = newAnimState }, animCmd )

        ChangeToPurple ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate animateElement model.animState (Animations.changeToPurple "box")
            in
            ( { model | animState = newAnimState }, animCmd )

        ResetColor ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate animateElement model.animState (Animations.resetColor "box")
            in
            ( { model | animState = newAnimState }, animCmd )

        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.WAAPI Color ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Ports Color Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth color transitions using browser-native CSS animations")
    , -- Color controls
      UI.wrappedButtonRow
        [ ( UI.Primary, ChangeToBlue, "Blue" )
        , ( UI.Success, ChangeToGreen, "Green" )
        , ( UI.Warning, ChangeToOrange, "Orange" )
        , ( UI.Warning, ChangeToRed, "Red" )
        , ( UI.Purple, ChangeToPurple, "Purple" )
        , ( UI.Primary, ResetColor, "Reset" )
        ]
    , -- Animation area with single colored box
      el
        [ width (fill |> maximum 600)
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
        , htmlAttribute (Html.Attributes.style "position" "relative")
        , htmlAttribute (Html.Attributes.style "overflow" "hidden")
        ]
        (el
            [ centerX
            , centerY
            , width (px 150)
            , height (px 150)
            , Background.color (rgb 0.8 0.8 0.8)
            , Border.rounded 8
            , htmlAttribute (Html.Attributes.id "box")
            , htmlAttribute (Html.Attributes.style "background-color" "#95a5a6") -- Default gray
            ]
            (el [ centerX, centerY ] (text "Color"))
        )
    ]
