port module HTML.SmoothMovePorts.Basic exposing (main)

import Browser
import Html exposing (Html, button, div, h1, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import SmoothMovePorts



-- PORTS --


port animateElement : String -> Cmd msg


port stopElementAnimation : String -> Cmd msg


port positionUpdates : (Decode.Value -> msg) -> Sub msg



-- MODEL --


type alias Model =
    { animations : SmoothMovePorts.Model
    }


type Msg
    = MoveToCorner
    | MoveToCenter
    | StopAnimation
    | PositionUpdateMsg Decode.Value


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with starting position to prevent jump to (0,0)
        initialAnimations =
            SmoothMovePorts.init
                |> SmoothMovePorts.setInitialPosition "box" 50 50
    in
    ( { animations = initialAnimations
      }
    , Cmd.none
    )



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToCorner ->
            let
                ( newAnimations, command ) =
                    SmoothMovePorts.animateTo "box" 300 200 model.animations
            in
            ( { model | animations = newAnimations }
            , animateElement (SmoothMovePorts.encodeAnimationCommand command)
            )

        MoveToCenter ->
            let
                ( newAnimations, command ) =
                    SmoothMovePorts.animateTo "box" 175 125 model.animations
            in
            ( { model | animations = newAnimations }
            , animateElement (SmoothMovePorts.encodeAnimationCommand command)
            )

        StopAnimation ->
            let
                ( newAnimations, maybeElementId ) =
                    SmoothMovePorts.stopAnimation "box" model.animations
            in
            case maybeElementId of
                Just elementId ->
                    ( { model | animations = newAnimations }
                    , stopElementAnimation (SmoothMovePorts.encodeStopCommand elementId)
                    )

                Nothing ->
                    ( { model | animations = newAnimations }, Cmd.none )

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



-- DECODERS --


type alias PositionUpdate =
    { elementId : String
    , x : Float
    , y : Float
    , isAnimating : Bool
    }


positionDecoder : Decode.Decoder PositionUpdate
positionDecoder =
    Decode.map4 PositionUpdate
        (Decode.field "elementId" Decode.string)
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)
        (Decode.field "isAnimating" Decode.bool)



-- VIEW --


view : Model -> Html Msg
view model =
    let
        position =
            SmoothMovePorts.getPosition "box" model.animations
                |> Maybe.withDefault { x = 150, y = 100 }

        animatingText =
            if SmoothMovePorts.isAnimating model.animations then
                "Animating with Web Animations API..."

            else
                "Idle"
    in
    div [ style "padding" "20px" ]
        [ h1 [] [ text "SmoothMovePorts Example - Web Animations API" ]
        , div []
            [ text ("Status: " ++ animatingText)
            , text (" | Position: (" ++ String.fromFloat position.x ++ ", " ++ String.fromFloat position.y ++ ")")
            ]
        , div [ style "margin" "20px 0" ]
            [ button [ onClick MoveToCorner ] [ text "Move to Corner (300, 200)" ]
            , button [ onClick MoveToCenter, style "margin-left" "10px" ] [ text "Move to Center (150, 100)" ]
            , button [ onClick StopAnimation, style "margin-left" "10px" ] [ text "Stop Animation" ]
            ]
        , div
            [ style "position" "relative"
            , style "width" "400px"
            , style "height" "300px"
            , style "border" "2px solid #ccc"
            , style "margin-top" "20px"
            , style "background-color" "#f9f9f9"
            ]
            [ div
                [ Html.Attributes.id "box" -- IMPORTANT: The element needs this ID for JavaScript
                , style "position" "absolute"
                , style "width" "50px"
                , style "height" "50px"
                , style "background-color" "#9C27B0"
                , style "border-radius" "8px"
                , style "transform" (SmoothMovePorts.transformElement "box" model.animations)
                , style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "color" "white"
                , style "font-weight" "bold"
                ]
                [ text "JS" ]
            ]
        , div [ style "margin-top" "20px", style "font-size" "14px", style "color" "#666" ]
            [ text "✅ Uses Web Animations API for hardware acceleration"
            , Html.br [] []
            , text "✅ Leverages native browser optimization"
            , Html.br [] []
            , text "✅ Elm ports provide type-safe JavaScript integration"
            , Html.br [] []
            , text "✅ Smooth animations with precise control"
            , Html.br [] []
            , Html.br [] []
            , text "⚠️  Don't forget to include smooth-move-ports.js and call SmoothMovePorts.init(app.ports)"
            ]
        ]



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    positionUpdates PositionUpdateMsg



-- MAIN --


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
