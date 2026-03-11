module Engines.Sub.BasicUsage.Main exposing (main)

import Anim.Engine.Sub as Sub
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (style)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL
-- Avoid typos from hardcoding strings in multiple places


groupName : String
groupName =
    "helloText"


type alias Model =
    { animState : Sub.AnimState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        initialAnimState =
            Sub.init
                [ Opacity.init groupName 0 ]
    in
    ( { animState = Sub.animate initialAnimState fadeIn }
    , Cmd.none
    )



-- ANIMATION


fadeIn : Sub.AnimBuilder -> Sub.AnimBuilder
fadeIn =
    Opacity.for groupName
        >> Opacity.to 1
        >> Opacity.duration 5000
        >> Opacity.build



-- UPDATE


type Msg
    = GotAnimationUpdate Sub.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimationUpdate animationMsg ->
            let
                ( newAnimState, _ ) =
                    Sub.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotAnimationUpdate model.animState



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "font-size" "48px"
        , style "font-weight" "bold"
        , style "height" "100vh"
        , style "width" "100vw"
        ]
        [ div
            (Sub.attributes groupName model.animState)
            [ text "Hello World!" ]
        ]
