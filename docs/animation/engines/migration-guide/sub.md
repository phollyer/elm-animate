# Sub

--8<-- [start:code]

```elm
import Anim.Engine.Sub as Sub
import Anim.Opacity as Opacity

type alias Model =
    { animState : Sub.AnimState }

init : flags -> ( Model, Cmd Msg )
init _ =
    ( { animState = Sub.init [ Opacity.init "boxAnim" 0 ] }
    , Cmd.none
    )

type Msg
    = TriggerAnimation
    | GotAnimMsg Sub.AnimMsg
    

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerAnimation ->
            ( { model | animState = Sub.animate model.animState fadeIn }
            , cmd 
            )

        GotAnimMsg animMsg ->
            let
                ( animState, events ) =
                    Sub.update animMsg model.animState
            in
            handleEvents events <|
                ( { model | animState = animState }
                , Cmd.none
                )

handleEvents : List Sub.AnimEvent -> (Model, Cmd Msg) -> ( Model, Cmd Msg )
handleEvents events (model, cmd) =
    case events of
        [] ->
            ( model, cmd )

        event :: rest ->
            case event of
                Sub.Ended "boxAnim" ->
                    handleEvents rest model

                _ ->
                    handleEvents rest model

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotAnimMsg model.animState

view : Model -> Html Msg
view model =
    div
        (Sub.attributes "boxAnim" model.animState)
        [ text "Content" ]
```

--8<-- [end:code]
