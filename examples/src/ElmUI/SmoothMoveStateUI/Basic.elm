module ElmUI.SmoothMoveStateUI.Basic exposing (main)

{-| SmoothMoveState Basic Example using ElmUI - State-based convenience wrapper around subscription approach.

This is a simplified version of SmoothMoveSub that provides convenient state management
without requiring manual subscription handling in your main application.

BENEFITS:

  - ✅ Simple state management with helper functions
  - ✅ No need to handle subscriptions manually
  - ✅ Built-in animation frame stepping
  - ✅ Easy position tracking and transforms
  - ✅ Clean API for basic animation needs

USAGE:

  - Keep SmoothMoveState.State in your model
  - Use SmoothMoveState.step in AnimationFrame messages
  - Call SmoothMoveState.animateTo to start animations
  - Use transform and getPosition helper functions

-}

import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, paddingXY, paragraph, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import SmoothMoveState



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
    { animationState : SmoothMoveState.State
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with starting position to prevent jump to (0,0)
        initialState =
            SmoothMoveState.init
                |> SmoothMoveState.setInitialPosition "moving-box" 0 0
    in
    ( { animationState = initialState }
    , Cmd.none
    )



-- UPDATE


type Msg
    = AnimationFrame Float
    | MoveToCorner
    | MoveToCenter
    | StopAnimation


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AnimationFrame deltaMs ->
            ( { model | animationState = SmoothMoveState.step deltaMs model.animationState }
            , Cmd.none
            )

        MoveToCorner ->
            ( { model | animationState = SmoothMoveState.animateTo "moving-box" 100 100 model.animationState }
            , Cmd.none
            )

        MoveToCenter ->
            ( { model | animationState = SmoothMoveState.animateTo "moving-box" 300 200 model.animationState }
            , Cmd.none
            )

        StopAnimation ->
            ( { model | animationState = SmoothMoveState.animateTo "moving-box" 0 0 model.animationState }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    SmoothMoveState.subscriptions model.animationState AnimationFrame



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveState Basic ElmUI Example" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        position =
            SmoothMoveState.getPosition "moving-box" model.animationState
                |> Maybe.withDefault { x = 0, y = 0 }

        isMoving =
            SmoothMoveState.isAnimating model.animationState
    in
    [ UI.backButton
    , UI.pageHeader "SmoothMoveState Basic Example"
    , UI.techInfo
        [ paragraph []
            [ text "This example demonstrates the SmoothMoveState module, which provides a "
            , el [ Font.semiBold ] (text "convenience wrapper")
            , text " around the subscription-based animation system. It offers "
            , el [ Font.semiBold ] (text "simplified state management")
            , text " with helper functions while maintaining frame-rate independent positioning and smooth element transitions."
            ]
        , paragraph []
            [ text "Perfect for developers who want the power of subscription-based animations with "
            , el [ Font.semiBold ] (text "reduced boilerplate")
            , text " and easier integration into existing Elm applications."
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
        [ ( UI.Primary, MoveToCorner, "Move to (100, 100)" )
        , ( UI.Success, MoveToCenter, "Move to (300, 200)" )
        , ( UI.Purple, StopAnimation, "Return to Origin" )
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
        ]
        (el
            [ width (px 50)
            , height (px 50)
            , Background.color Colors.primary
            , Border.rounded 8
            , htmlAttribute (Html.Attributes.id "moving-box")
            , htmlAttribute (Html.Attributes.style "position" "absolute")
            , htmlAttribute (Html.Attributes.style "transform" (SmoothMoveState.transform position.x position.y))
            , htmlAttribute (Html.Attributes.style "transition" "none")
            ]
            (text "")
        )
    ]
