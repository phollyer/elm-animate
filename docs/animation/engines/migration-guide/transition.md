# Transition

--8<-- [start:code]

```elm
import Anim.Engine.CSS.Transition as Transition
import Anim.Opacity as Opacity

type alias Model =
    { animState : Transition.AnimState }

init : flags -> ( Model, Cmd Msg )
init _ =
    ( { animState = Transition.init [ Opacity.init "boxAnim" 0 ] }
    , Cmd.none
    )

type Msg
    = TriggerAnimation
    | GotAnimMsg Transition.AnimMsg

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerAnimation ->
            ( { model | animState = Transition.animate model.animState fadeIn }
            , cmd 
            )

        GotAnimMsg animMsg ->
            let
                ( animState, event ) =
                    Transition.update animMsg model.animState
            in
            handleEvent event { model | animState = animState }

handleEvent : Transition.AnimEvent -> Model -> ( Model, Cmd Msg )
handleEvent event model =
    case event of
        Transition.Ended _ _ "boxAnim" ->
            ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )

view : Model -> Html Msg
view model =
    div
        (Transition.attributes "boxAnim" model.animState
            ++ Transition.events "boxAnim" GotAnimMsg
        )
        [ text "Content" ]
```

--8<-- [end:code]
