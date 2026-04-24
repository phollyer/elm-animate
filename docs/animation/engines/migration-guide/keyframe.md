# Keyframe

--8<-- [start:code]

```elm
import Anim.Engine.Animation.CSS.Keyframe as Keyframe
import Anim.Opacity as Opacity

type alias Model =
    { animState : Keyframe.AnimState }

init : flags -> ( Model, Cmd Msg )
init _ =
    ( { animState = Keyframe.init [ Opacity.init "boxAnim" 0 ] }
    , Cmd.none
    )

type Msg
    = TriggerAnimation
    | GotAnimMsg Keyframe.AnimMsg

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerAnimation ->
            ( { model | animState = Keyframe.animate model.animState fadeIn }
            , cmd 
            )

        GotAnimMsg animMsg ->
            let
                ( newAnimState, event ) =
                    Keyframe.update animMsg model.animState
            in
            handleEvent event { model | animState = newAnimState }

handleEvent : Keyframe.AnimEvent -> Model -> ( Model, Cmd Msg )
handleEvent event model =
    case event of
        Keyframe.Ended _ _ "boxAnim" ->
            ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )

view : Model -> Html Msg
view model =
    div []
        [ Keyframe.styleNode model.animState
        , div
            (Keyframe.attributes "boxAnim" model.animState
                ++ Keyframe.events "boxAnim" GotAnimMsg
            )
            [ text "Content" ]
        ]
```

--8<-- [end:code]
