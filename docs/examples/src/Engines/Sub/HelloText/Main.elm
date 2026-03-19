module Engines.Sub.HelloText.Main exposing (main)

import Anim.Engine.Sub as Sub exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (style)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL
-- Avoid typos from hardcoding strings in multiple places


groupName : String
groupName =
    "helloText"



---8<-- [start:model]


type alias Model =
    { animState : Sub.AnimState }


init : ( Model, Cmd Msg )
init =
    ---8<-- [start:trigger]
    let
        animState =
            Sub.init
                [ Opacity.init groupName 0 ]
    in
    ( { animState = Sub.animate animState fadeIn }
    , Cmd.none
    )



---8<-- [end:trigger]
---8<-- [end:model]
-- ANIMATION
---8<-- [start:build]


fadeIn : AnimBuilder -> AnimBuilder
fadeIn =
    Opacity.for groupName
        >> Opacity.to 1
        >> Opacity.duration 5000
        >> Opacity.build



--8<-- [end:build]
-- UPDATE
---8<-- [start:update]


type Msg
    = GotSubMsg Sub.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSubMsg animMsg ->
            let
                ( animState, _ ) =
                    Sub.update animMsg model.animState
            in
            ( { model | animState = animState }
            , Cmd.none
            )



---8<-- [end:update]
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



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
        [ ---8<-- [start:render]
          div
            (Sub.attributes groupName model.animState)
            [ text "Hello World!" ]

        ---8<-- [end:render]
        ]
