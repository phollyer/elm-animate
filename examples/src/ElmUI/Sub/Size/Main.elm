module ElmUI.Sub.Size.Main exposing (main)

{-| Anim.Engine.Sub Size Example using ElmUI - Width and height animations

This example demonstrates smooth size animations using browser-native Subscription-Based sizing.
Perfect for responsive layouts, emphasis animations, and dynamic element sizing.

FEATURES:

  - ✅ Smooth width and height animations
  - ✅ Hardware-accelerated size transitions
  - ✅ Multiple size configurations and timing
  - ✅ Responsive and dynamic sizing effects
  - ✅ Battery efficient browser-native transitions

-}

import Easing as Easing exposing (Easing(..))
import Anim.Engine.Sub as Sub
import Browser exposing (Document)
import Browser.Events
import Common.Animations.Size as Animations
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
    { animations : Sub.AnimState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations =
            Sub.animate Sub.init
                (Animations.sizeReset "box")
      }
    , Cmd.none
    )


type Msg
    = SizeLarge
    | SizeSquare
    | SizeReset
    | SizeWide
    | SizeTall
    | AnimationMsg Sub.AnimMsg



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SizeLarge ->
            ( { model
                | animations =
                    Sub.animate model.animations
                        (Animations.sizeLarge "box")
              }
            , Cmd.none
            )

        SizeSquare ->
            ( { model
                | animations =
                    Sub.animate model.animations
                        (Animations.sizeSquare "box")
              }
            , Cmd.none
            )

        SizeReset ->
            ( { model
                | animations =
                    Sub.animate model.animations
                        (Animations.sizeReset "box")
              }
            , Cmd.none
            )

        SizeWide ->
            ( { model
                | animations =
                    Sub.animate model.animations
                        (Animations.sizeWide "box")
              }
            , Cmd.none
            )

        SizeTall ->
            ( { model
                | animations =
                    Sub.animate model.animations
                        (Animations.sizeTall "box")
              }
            , Cmd.none
            )

        AnimationMsg animMsg ->
            let
                ( newAnimations, _ ) =
                    Sub.update animMsg model.animations
            in
            ( { model | animations = newAnimations }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions AnimationMsg model.animations



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.Sub Size ElmUI Example"
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
        [ ( UI.Primary, SizeLarge, "Large" )
        , ( UI.Warning, SizeSquare, "Square" )
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
            ++ (Sub.attributes elementId model.animations
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
