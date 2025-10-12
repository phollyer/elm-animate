module ElmUI.SmoothMoveSub.Basic.Main exposing (main)

{-| This example demonstrates SmoothMoveSub using ElmUI - subscription-based positioning with automatic state management.

BENEFITS:

  - ✅ No need to track AnimationState in your model
  - ✅ No need to track element positions in your model
  - ✅ No need to handle animation completion manually
  - ✅ No need to pass Position data around in messages
  - ✅ Library manages ALL state automatically
  - ✅ Simple animateTo and subscriptions calls
  - ✅ Get positions with transform when needed

DEVELOPER EXPERIENCE:

  - Keep only a SmoothMoveSub.Model in your model
  - Call animateTo to begin animations (automatic current position)
  - Subscribe with SmoothMoveSub.subscriptions for smooth updates (just deltaMs!)
  - Use transform for CSS transforms with getPosition!
  - Use getPosition when you need the actual position values
  - Library handles everything else automatically!

-}

import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, moveDown, moveUp, padding, paddingXY, paragraph, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import SmoothMoveSub exposing (animateTo, getPosition, init, isAnimating, setInitialPosition, subscriptions, transform)



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
    { smoothMove : SmoothMoveSub.Model
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { smoothMove = SmoothMoveSub.init }
    , Cmd.none
    )



-- UPDATE


type Msg
    = StartMove Float Float
    | AnimationFrame Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartMove x y ->
            let
                updatedSmoothMove =
                    animateTo "moving-box" x y model.smoothMove
            in
            ( { model | smoothMove = updatedSmoothMove }, Cmd.none )

        AnimationFrame deltaMs ->
            let
                updatedSmoothMove =
                    SmoothMoveSub.step deltaMs model.smoothMove
            in
            ( { model | smoothMove = updatedSmoothMove }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    SmoothMoveSub.subscriptions model.smoothMove AnimationFrame



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveSub Basic ElmUI Example" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        position =
            getPosition "moving-box" model.smoothMove |> Maybe.withDefault { x = 0, y = 0 }

        isMoving =
            isAnimating model.smoothMove
    in
    [ UI.backButton
    , UI.pageHeader "SmoothMoveSub Basic Example"
    , UI.techInfo
        [ paragraph []
            [ text "This example demonstrates the SmoothMoveSub module, which provides "
            , el [ Font.semiBold ] (text "subscription-based positioning")
            , text " with frame-rate independent animations. It offers "
            , el [ Font.semiBold ] (text "real-time updates")
            , text " via onAnimationFrameDelta subscriptions, ensuring smooth element transitions across different device capabilities."
            ]
        , paragraph []
            [ text "Perfect for applications requiring "
            , el [ Font.semiBold ] (text "precise timing control")
            , text " and multiple simultaneous animations with automatic state management."
            ]
        ]
    , -- Position display
      el
        [ Font.size 14
        , Font.color Colors.textMedium
        , centerX
        ]
        (text ("Position: (" ++ String.fromInt (round position.x) ++ ", " ++ String.fromInt (round position.y) ++ ")"))
    , -- Buttons for predefined moves
      UI.htmlActionButtons
        [ ( UI.Primary, StartMove 100 100, "Move to (100, 100)" )
        , ( UI.Success, StartMove 300 200, "Move to (300, 200)" )
        , ( UI.Purple, StartMove 0 0, "Return to Origin" )
        ]
    , -- Animation area with moving box
      el
        [ width (fill |> Element.maximum 500)
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
        , htmlAttribute (Html.Attributes.style "overflow" "hidden")
        , htmlAttribute (Html.Attributes.class "responsive-animation-container")
        ]
        (el
            [ width (px 50)
            , height (px 50)
            , Background.color Colors.primary
            , Border.rounded 8
            , htmlAttribute (Html.Attributes.id "moving-box")
            , htmlAttribute (Html.Attributes.style "position" "absolute")
            , htmlAttribute (Html.Attributes.style "transform" (transform position.x position.y))
            , htmlAttribute (Html.Attributes.style "transition" "none")
            ]
            (text "")
        )
    ]
