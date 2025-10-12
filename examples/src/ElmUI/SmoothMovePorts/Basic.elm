port module ElmUI.SmoothMovePorts.Basic exposing (main)

{-| SmoothMovePorts Basic Example using ElmUI - Web Animations API integration via JavaScript

This approach uses Elm ports to communicate with JavaScript's Web Animations API,
providing access to advanced animation features and platform-specific optimizations.

BENEFITS:

  - ✅ Access to Web Animations API features
  - ✅ Platform-specific optimizations via JavaScript
  - ✅ Complex animation composition capabilities
  - ✅ Fine-grained animation control and timing
  - ✅ Support for advanced easing functions
  - ✅ Real-time position feedback via ports

REQUIREMENTS:

  - Requires companion JavaScript file (smooth-move-ports.js)
  - Needs port definitions for Elm-JavaScript communication
  - Web Animations API support (modern browsers)

-}

-- Common UI imports

import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, alignLeft, centerX, column, el, fill, height, htmlAttribute, layout, link, maximum, padding, paddingXY, paragraph, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Json.Decode as Decode
import SmoothMovePorts



-- PORTS


port animateElement : String -> Cmd msg


port stopElementAnimation : String -> Cmd msg


port positionUpdates : (Decode.Value -> msg) -> Sub msg



-- TYPES


type alias PositionUpdate =
    { elementId : String
    , x : Float
    , y : Float
    , isAnimating : Bool
    }


{-| Decoder for position updates from JavaScript
-}
positionDecoder : Decode.Decoder PositionUpdate
positionDecoder =
    Decode.map4 PositionUpdate
        (Decode.field "elementId" Decode.string)
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)
        (Decode.field "isAnimating" Decode.bool)



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
    { animations : SmoothMovePorts.Model
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with starting position
        initialAnimations =
            SmoothMovePorts.init
                |> SmoothMovePorts.setInitialPosition "moving-box" 0 0
    in
    ( { animations = initialAnimations }
    , Cmd.none
    )



-- UPDATE


type Msg
    = MoveToCorner
    | MoveToCenter
    | StopAnimation
    | PositionUpdateMsg Decode.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToCorner ->
            let
                ( newAnimations, command ) =
                    SmoothMovePorts.animateTo "moving-box" 100 100 model.animations
            in
            ( { model | animations = newAnimations }
            , animateElement (SmoothMovePorts.encodeAnimationCommand command)
            )

        MoveToCenter ->
            let
                ( newAnimations, command ) =
                    SmoothMovePorts.animateTo "moving-box" 300 200 model.animations
            in
            ( { model | animations = newAnimations }
            , animateElement (SmoothMovePorts.encodeAnimationCommand command)
            )

        StopAnimation ->
            let
                ( newAnimations, command ) =
                    SmoothMovePorts.animateTo "moving-box" 0 0 model.animations
            in
            ( { model | animations = newAnimations }
            , animateElement (SmoothMovePorts.encodeAnimationCommand command)
            )

        PositionUpdateMsg value ->
            -- Parse the position update from JavaScript
            case Decode.decodeValue positionDecoder value of
                Ok posUpdate ->
                    let
                        newAnimations =
                            SmoothMovePorts.handlePositionUpdate
                                posUpdate.elementId
                                posUpdate.x
                                posUpdate.y
                                posUpdate.isAnimating
                                model.animations
                    in
                    ( { model | animations = newAnimations }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    positionUpdates PositionUpdateMsg



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "SmoothMovePorts Basic ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        position =
            SmoothMovePorts.getPosition "moving-box" model.animations
                |> Maybe.withDefault { x = 0, y = 0 }

        isAnimating =
            SmoothMovePorts.isAnimating model.animations
    in
    [ UI.backButton
    , UI.pageHeader "SmoothMovePorts Basic Example"
    , UI.techInfo
        [ paragraph
            [ Font.size 16
            , Font.color Colors.textMedium
            , width fill
            ]
            [ text "This example demonstrates the SmoothMovePorts module, which integrates with the "
            , el [ Font.semiBold ] (text "Web Animations API")
            , text " through JavaScript ports. This approach provides access to "
            , el [ Font.semiBold ] (text "platform-specific optimizations")
            , text " and advanced animation features not available through pure Elm."
            ]
        , paragraph
            [ Font.size 16
            , Font.color Colors.textMedium
            , width fill
            ]
            [ text "Perfect for complex animations requiring "
            , el [ Font.semiBold ] (text "native performance")
            , text " and advanced timing controls beyond what CSS transitions can provide."
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
        [ width (fill |> maximum 500)
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
            , htmlAttribute (Html.Attributes.style "left" (String.fromFloat position.x ++ "px"))
            , htmlAttribute (Html.Attributes.style "top" (String.fromFloat position.y ++ "px"))
            ]
            (text "")
        )
    ]
