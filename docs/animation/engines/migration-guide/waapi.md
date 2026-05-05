# WAAPI

--8<-- [start:page]
--8<-- [start:code]

```elm
port module Main exposing (..)

import Anim.Engine.WAAPI as WAAPI
import Anim.Opacity as Opacity
import Json.Decode
import Json.Encode

port waapiCommand : Json.Encode.Value -> Cmd msg
port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

type alias Model =
    { animState : WAAPI.AnimState Msg }

init : flags -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            WAAPI.init waapiCommand waapiEvent <|
                [ Opacity.init "boxAnim" 0 ]
        }
    , Cmd.none
    )

type Msg
    = TriggerAnimation
    | GotAnimMsg WAAPI.AnimMsg

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerAnimation ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState fadeIn
            in
            ( { model | animState = animState }
            , cmd 
            )

        GotAnimMsg animMsg ->
            let
                ( animState, event ) =
                    WAAPI.update animMsg model.animState
            in
            handleEvent event { model | animState = animState }

handleEvent : WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
handleEvent event model =
    case event of
        WAAPI.Ended "boxAnim" ->
            ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )

subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotAnimMsg model.animState

view : Model -> Html Msg
view model =
    div
        (WAAPI.attributes "boxAnim" model.animState)
        [ text "Content" ]
```

--8<-- [end:code]

--8<-- [start:js]
**JavaScript setup:**

```html
<script src="elm-animate-waapi.js"></script>
<script>
    var app = Elm.Main.init({ node: document.getElementById("app") });
    ElmAnimateWAAPI.init(app.ports);
</script>
```

--8<-- [end:js]
--8<-- [end:page]

