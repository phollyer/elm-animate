# Migration Guide

This guide helps you switch between animation engines. Because all engines share the same builder API, your animation definitions remain unchanged - only the engine integration code needs updating.


## Quick Reference Matrix

This table shows what changes when migrating between engines:

| Component | Transitions | Keyframes | Sub | WAAPI |
| --------- | :---------: | :-------: | :-: | :---: |
| **Init** | `init []` | `init []` | `init []` | `init cmd sub []` |
| **Animate** | returns `AnimState` | returns `AnimState` | returns `AnimState` | returns `(AnimState, Cmd)` |
| **Fire & Forget** | returns `AnimState` | returns `AnimState` | N/A | returns `Cmd` |
| **Subscriptions** | None | None | Required | Required |
| **Update return** | `(AnimState, AnimEvent)` | `(AnimState, AnimEvent)` | `(AnimState, List AnimEvent)` | `(AnimState, AnimEvent)` |
| **Event listeners** | Required | Required | None | None |
| **View: styleNode** | No | Required | No | No |
| **JavaScript** | None | None | None | Required |

## Migration Index

If you need to migrate, you can use the quick guides below, just select your migration path from one of the lists:

### Migrating Up (adding features)

- [Transitions → Keyframes](#transitions-keyframes) - Add pause/resume & restart controls, looping
- [Transitions → Sub](#transitions-sub) - Add pause/resume & restart controls, looping, mid-flight access
- [Transitions → WAAPI](#transitions-waapi) - Add pause/resume & restart controls, looping, mid-flight access
- [Keyframes → Sub](#keyframes-sub) - Add mid-flight access, dynamic redirects
- [Keyframes → WAAPI](#keyframes-waapi) - Add mid-flight access, dynamic redirects
- [Sub → WAAPI](#sub-waapi) - Add browser-native interpolation, `fireAndForget` convenience

### Migrating Down (simplifying)

- [WAAPI → Sub](#waapi-sub) - Regain pure Elm (no JavaScript/ports)
- [WAAPI → Keyframes](#waapi-keyframes) - Regain pure Elm (no JavaScript/ports)
- [WAAPI → Transitions](#waapi-transitions) - Regain pure Elm (no JavaScript/ports)
- [Sub → Keyframes](#sub-keyframes) - Regain browser-native interpolation, `fireAndForget` convenience
- [Sub → Transitions](#sub-transitions) - Regain browser-native interpolation, `fireAndForget` convenience
- [Keyframes → Transitions](#keyframes-transitions) - Regain mid-flight redirections


---

## Migrating Up

### Transitions → Keyframes

- **Adds**: pause/resume & restart controls, looping
- **Loses**: mid-flight redirections

**Changes required:**

- Change types from `Transitions.*` to `Keyframes.*` (AnimState, AnimMsg, AnimEvent)
- Add `Keyframes.styleNode model.animState` to your view
- Update pattern matching for events (Keyframes has `Iteration` event)

??? example "Before & After"

    **Before (Transitions):**
    ```elm
    import Anim.Engine.CSS.Transitions as Transitions
    import Anim.Opacity as Opacity

    type alias Model =
        { animState : Transitions.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Transitions.init [ Opacity.init "boxAnim" 0 ] }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg Transitions.AnimMsg

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Transitions.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

    handleEvent : Transitions.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleEvent event model =
        case event of
            Transitions.Ended "boxAnim" ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

    view : Model -> Html Msg
    view model =
        div
            (Transitions.attributes "box" model.animState
                ++ Transitions.events "box" GotAnimMsg
            )
            [ text "Content" ]
    ```

    **After (Keyframes):**
    ```elm
    import Anim.Engine.CSS.Keyframes as Keyframes
    import Anim.Opacity as Opacity

    type alias Model =
        { animState : Keyframes.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Keyframes.init [ Opacity.init "boxAnim" 0 ] }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg Keyframes.AnimMsg

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Keyframes.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

    handleEvent : Keyframes.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleEvent event model =
        case event of
            Keyframes.Ended "boxAnim" ->
                ( model, Cmd.none )

            Keyframes.Iteration "boxAnim" ->
                -- New event type for iterations
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

    view : Model -> Html Msg
    view model =
        div []
            [ Keyframes.styleNode model.animState
            , div
                (Keyframes.attributes "box" model.animState
                    ++ Keyframes.events "box" GotAnimMsg
                )
                [ text "Content" ]
            ]
    ```

---

### Transitions → Sub

- **Adds**: pause/resume & restart controls, looping, mid-flight access
- **Loses**: browser-native interpolation, `fireAndForget` convenience

**Changes required:**

- Change types from `Transitions.*` to `Sub.*` (AnimState, AnimMsg, AnimEvent)
- Add subscriptions function
- Update `update` function - events come from `Sub.update` as a `List`, not from DOM
- Replace `fireAndForget` calls with `animate`
- Remove event listeners from view (events come via subscription now)

??? example "Before & After"

    **Before (Transitions):**
    ```elm
    import Anim.Engine.CSS.Transitions as Transitions
    import Anim.Opacity as Opacity

    type alias Model =
        { animState : Transitions.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Transitions.init [ Opacity.init "boxAnim" 0 ] }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg Transitions.AnimMsg

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Transitions.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

    handleEvent : Transitions.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleEvent event model =
        case event of
            Transitions.Ended "boxAnim" ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

    view : Model -> Html Msg
    view model =
        div
            (Transitions.attributes "box" model.animState
                ++ Transitions.events "box" GotAnimMsg
            )
            [ text "Content" ]
    ```

    **After (Sub):**
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
        = GotAnimMsg Sub.AnimMsg

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update animMsg model.animState
                in
                handleEvents events { model | animState = newAnimState }

    handleEvents : List Sub.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleEvents events model =
        case events of
            [] ->
                ( model, Cmd.none )

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
            (Sub.attributes "box" model.animState)  -- No event listeners needed
            [ text "Content" ]
    ```

---

### Transitions → WAAPI

- **Adds**: pause/resume & restart controls, looping, mid-flight access
- **Loses**: pure Elm (requires JavaScript/ports)

**Changes required:**

- Add JavaScript setup (ports and WAAPI runtime)
- Change types from `Transitions.*` to `WAAPI.*` (AnimState, AnimMsg, AnimEvent)
- Define port functions and pass to `init`
- Add subscriptions function
- Update `animate` calls to handle returned `Cmd`
- Replace `fireAndForget` - it now returns `Cmd` only
- Update event handling - events have additional parameters
- Remove event listeners from view

??? example "Before & After"

    **Before (Transitions):**
    ```elm
    import Anim.Engine.CSS.Transitions as Transitions
    import Anim.Opacity as Opacity

    type alias Model =
        { animState : Transitions.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Transitions.init [ Opacity.init "boxAnim" 0 ] }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg Transitions.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Transitions.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

            TriggerAnimation ->
                ( { model | animState = Transitions.animate model.animState fadeIn }
                , Cmd.none
                )

    handleEvent : Transitions.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleEvent event model =
        case event of
            Transitions.Ended "boxAnim" ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

    view : Model -> Html Msg
    view model =
        div
            (Transitions.attributes "box" model.animState
                ++ Transitions.events "box" GotAnimMsg
            )
            [ text "Content" ]
    ```

    **After (WAAPI):**
    ```elm
    port module Main exposing (..)

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Opacity as Opacity
    import Json.Decode
    import Json.Encode

    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type alias Model =
        { animState : WAAPI.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                WAAPI.init waapiCommand waapiEvent <|
                    [ WAAPI.forElement "box"
                        >> Opacity.init "boxAnim" 0
                    ]
          }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg WAAPI.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        WAAPI.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

            TriggerAnimation ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.animate model.animState fadeIn
                in
                ( { model | animState = newAnimState }, cmd )

    handleEvent : WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleEvent event model =
        case event of
            WAAPI.Ended "boxAnim" _ _ ->
                -- WAAPI events include elementId, animGroup and EventInfo
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState

    view : Model -> Html Msg
    view model =
        div
            (WAAPI.attributes "box" model.animState)  -- No event listeners
            [ text "Content" ]
    ```

    **JavaScript setup:**
    ```html
    <script src="elm-animate-waapi.js"></script>
    <script>
        var app = Elm.Main.init({ node: document.getElementById("app") });
        ElmAnimateWAAPI.init(app.ports);
    </script>
    ```

---

### Keyframes → Sub

- **Adds**: mid-flight access, dynamic redirects
- **Loses**: browser-native interpolation, `fireAndForget` convenience

**Changes required:**

- Change types from `Keyframes.*` to `Sub.*` (AnimState, AnimMsg, AnimEvent)
- Remove `Keyframes.styleNode` from view
- Add subscriptions function
- Update `update` function - events come as a `List` now
- Replace `fireAndForget` calls with `animate`
- Remove event listeners from view

??? example "Before & After"

    **Before (Keyframes):**
    ```elm
    import Anim.Engine.CSS.Keyframes as Keyframes
    import Anim.Opacity as Opacity

    type alias Model =
        { animState : Keyframes.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Keyframes.init [ Opacity.init "boxAnim" 0 ] }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg Keyframes.AnimMsg

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Keyframes.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

    handleEvent : Keyframes.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleEvent event model =
        case event of
            Keyframes.Ended "boxAnim" ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

    view : Model -> Html Msg
    view model =
        div []
            [ Keyframes.styleNode model.animState
            , div
                (Keyframes.attributes "box" model.animState
                    ++ Keyframes.events "box" GotAnimMsg
                )
                [ text "Content" ]
            ]
    ```

    **After (Sub):**
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
        = GotAnimMsg Sub.AnimMsg

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update animMsg model.animState
                in
                handleEvents events { model | animState = newAnimState }

    handleEvents : List Sub.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleEvents events model =
        case events of
            [] ->
                ( model, Cmd.none )

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
            (Sub.attributes "box" model.animState)
            [ text "Content" ]
    ```

---

### Keyframes → WAAPI

- **Adds**: mid-flight access, dynamic redirects
- **Loses**: pure Elm (requires JavaScript/ports)

**Changes required:**

- Add JavaScript setup (ports and WAAPI runtime)
- Change types from `Keyframes.*` to `WAAPI.*` (AnimState, AnimMsg, AnimEvent)
- Remove `Keyframes.styleNode` from view
- Define port functions and pass to `init`
- Add subscriptions function
- Update `animate` calls to handle returned `Cmd`
- Update `fireAndForget` - it now returns `Cmd` only
- Update event handling - events have additional parameters
- Remove event listeners from view

??? example "Before & After"

    **Before (Keyframes):**
    ```elm
    import Anim.Engine.CSS.Keyframes as Keyframes
    import Anim.Opacity as Opacity

    type alias Model =
        { animState : Keyframes.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Keyframes.init [ Opacity.init "boxAnim" 0 ] }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg Keyframes.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Keyframes.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

            TriggerAnimation ->
                ( { model | animState = Keyframes.animate model.animState fadeIn }
                , Cmd.none
                )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

    view : Model -> Html Msg
    view model =
        div []
            [ Keyframes.styleNode model.animState
            , div
                (Keyframes.attributes "box" model.animState
                    ++ Keyframes.events "box" GotAnimMsg
                )
                [ text "Content" ]
            ]
    ```

    **After (WAAPI):**
    ```elm
    port module Main exposing (..)

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Opacity as Opacity
    import Json.Decode
    import Json.Encode

    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type alias Model =
        { animState : WAAPI.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                WAAPI.init waapiCommand waapiEvent <|
                    [ WAAPI.forElement "box"
                        >> Opacity.init "boxAnim" 0
                    ]
          }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg WAAPI.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        WAAPI.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

            TriggerAnimation ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.animate model.animState fadeIn
                in
                ( { model | animState = newAnimState }, cmd )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState

    view : Model -> Html Msg
    view model =
        div
            (WAAPI.attributes "box" model.animState)
            [ text "Content" ]
    ```

    **JavaScript setup:**
    ```html
    <script src="elm-animate-waapi.js"></script>
    <script>
        var app = Elm.Main.init({ node: document.getElementById("app") });
        ElmAnimateWAAPI.init(app.ports);
    </script>
    ```

---

### Sub → WAAPI

- **Adds**: browser-native interpolation, `fireAndForget` convenience
- **Loses**: pure Elm (requires JavaScript/ports)

**Changes required:**

- Add JavaScript setup (ports and WAAPI runtime)
- Change types from `Sub.*` to `WAAPI.*` (AnimState, AnimMsg, AnimEvent)
- Define port functions and update `init`
- Update subscriptions to use `WAAPI.subscriptions`
- Update `animate` calls to handle returned `Cmd`
- Update `update` function - `WAAPI.update` returns single event, not list

??? example "Before & After"

    **Before (Sub):**
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
        = GotAnimMsg Sub.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update animMsg model.animState
                in
                handleEvents events { model | animState = newAnimState }

            TriggerAnimation ->
                ( { model | animState = Sub.animate model.animState fadeIn }
                , Cmd.none
                )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotAnimMsg model.animState

    view : Model -> Html Msg
    view model =
        div
            (Sub.attributes "box" model.animState)
            [ text "Content" ]
    ```

    **After (WAAPI):**
    ```elm
    port module Main exposing (..)

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Opacity as Opacity
    import Json.Decode
    import Json.Encode

    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type alias Model =
        { animState : WAAPI.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                WAAPI.init waapiCommand waapiEvent <|
                    [ WAAPI.forElement "box"
                        >> Opacity.init "boxAnim" 0
                    ]
          }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg WAAPI.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        WAAPI.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

            TriggerAnimation ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.animate model.animState fadeIn
                in
                ( { model | animState = newAnimState }, cmd )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState

    view : Model -> Html Msg
    view model =
        div
            (WAAPI.attributes "box" model.animState)
            [ text "Content" ]
    ```

    **JavaScript setup:**
    ```html
    <script src="elm-animate-waapi.js"></script>
    <script>
        var app = Elm.Main.init({ node: document.getElementById("app") });
        ElmAnimateWAAPI.init(app.ports);
    </script>
    ```


---

## Migrating Down

### WAAPI → Sub

- **Adds**: pure Elm (no JavaScript/ports)
- **Loses**: browser-native interpolation, `fireAndForget` convenience

**Changes required:**

- Remove JavaScript setup (ports and WAAPI runtime)
- Change types from `WAAPI.*` to `Sub.*` (AnimState, AnimMsg, AnimEvent)
- Remove port functions from `init`
- Update subscriptions to use `Sub.subscriptions`
- Update `animate` calls - no longer returns `Cmd`
- Update `update` function - `Sub.update` returns `List AnimEvent`
- Update `fireAndForget` - not available, use `animate` instead

??? example "Before & After"

    **Before (WAAPI):**
    ```elm
    port module Main exposing (..)

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Opacity as Opacity
    import Json.Decode
    import Json.Encode

    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type alias Model =
        { animState : WAAPI.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                WAAPI.init waapiCommand waapiEvent <|
                    [ WAAPI.forElement "box"
                        >> Opacity.init "boxAnim" 0
                    ]
          }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg WAAPI.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        WAAPI.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

            TriggerAnimation ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.animate model.animState fadeIn
                in
                ( { model | animState = newAnimState }, cmd )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState

    view : Model -> Html Msg
    view model =
        div
            (WAAPI.attributes "box" model.animState)
            [ text "Content" ]
    ```

    **After (Sub):**
    ```elm
    module Main exposing (..)  -- No longer a port module

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
        = GotAnimMsg Sub.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update animMsg model.animState
                in
                handleEvents events { model | animState = newAnimState }

            TriggerAnimation ->
                ( { model | animState = Sub.animate model.animState fadeIn }
                , Cmd.none
                )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotAnimMsg model.animState

    view : Model -> Html Msg
    view model =
        div
            (Sub.attributes "box" model.animState)
            [ text "Content" ]
    ```

---

### WAAPI → Keyframes

- **Adds**: pure Elm (no JavaScript/ports)
- **Loses**: mid-flight access, dynamic redirects

**Changes required:**

- Remove JavaScript setup (ports and WAAPI runtime)
- Change types from `WAAPI.*` to `Keyframes.*` (AnimState, AnimMsg, AnimEvent)
- Remove port functions from `init`
- Remove subscriptions (or set to `Sub.none`)
- Add `Keyframes.styleNode model.animState` to view
- Add event listeners to view
- Update `animate` calls - no longer returns `Cmd`
- Update event handling - events come from DOM, not ports

??? example "Before & After"

    **Before (WAAPI):**
    ```elm
    port module Main exposing (..)

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Opacity as Opacity

    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type alias Model =
        { animState : WAAPI.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                WAAPI.init waapiCommand waapiEvent <|
                    [ WAAPI.forElement "box"
                        >> Opacity.init "boxAnim" 0
                    ]
          }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg WAAPI.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        WAAPI.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

            TriggerAnimation ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.animate model.animState fadeIn
                in
                ( { model | animState = newAnimState }, cmd )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState

    view : Model -> Html Msg
    view model =
        div
            (WAAPI.attributes "box" model.animState)
            [ text "Content" ]
    ```

    **After (Keyframes):**
    ```elm
    module Main exposing (..)  -- No longer a port module

    import Anim.Engine.CSS.Keyframes as Keyframes
    import Anim.Opacity as Opacity

    type alias Model =
        { animState : Keyframes.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Keyframes.init [ Opacity.init "boxAnim" 0 ] }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg Keyframes.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Keyframes.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

            TriggerAnimation ->
                ( { model | animState = Keyframes.animate model.animState fadeIn }
                , Cmd.none
                )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

    view : Model -> Html Msg
    view model =
        div []
            [ Keyframes.styleNode model.animState
            , div
                (Keyframes.attributes "box" model.animState
                    ++ Keyframes.events "box" GotAnimMsg
                )
                [ text "Content" ]
            ]
    ```

---

### WAAPI → Transitions

- **Adds**: pure Elm (no JavaScript/ports)
- **Loses**: pause/resume & restart controls, looping, mid-flight access

**Changes required:**

- Remove JavaScript setup (ports and WAAPI runtime)
- Change types from `WAAPI.*` to `Transitions.*` (AnimState, AnimMsg, AnimEvent)
- Remove port functions from `init`
- Remove subscriptions (or set to `Sub.none`)
- Add event listeners to view
- Update `animate` calls - no longer returns `Cmd`
- Update event handling - events come from DOM, not ports

??? example "Before & After"

    **Before (WAAPI):**
    ```elm
    port module Main exposing (..)

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Opacity as Opacity

    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type alias Model =
        { animState : WAAPI.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                WAAPI.init waapiCommand waapiEvent <|
                    [ WAAPI.forElement "box"
                        >> Opacity.init "boxAnim" 0
                    ]
          }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg WAAPI.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            TriggerAnimation ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.animate model.animState fadeIn
                in
                ( { model | animState = newAnimState }, cmd )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState

    view : Model -> Html Msg
    view model =
        div
            (WAAPI.attributes "box" model.animState)
            [ text "Content" ]
    ```

    **After (Transitions):**
    ```elm
    module Main exposing (..)  -- No longer a port module

    import Anim.Engine.CSS.Transitions as Transitions
    import Anim.Opacity as Opacity

    type alias Model =
        { animState : Transitions.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Transitions.init [ Opacity.init "boxAnim" 0 ] }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg Transitions.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Transitions.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

            TriggerAnimation ->
                ( { model | animState = Transitions.animate model.animState fadeIn }
                , Cmd.none
                )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

    view : Model -> Html Msg
    view model =
        div
            (Transitions.attributes "box" model.animState
                ++ Transitions.events "box" GotAnimMsg
            )
            [ text "Content" ]
    ```

---

### Sub → Keyframes

- **Adds**: browser-native interpolation, `fireAndForget` convenience
- **Loses**: mid-flight access, dynamic redirects

**Changes required:**

- Change types from `Sub.*` to `Keyframes.*` (AnimState, AnimMsg, AnimEvent)
- Remove subscriptions (or set to `Sub.none`)
- Add `Keyframes.styleNode model.animState` to view
- Add event listeners to view
- Update `update` function - single event instead of list

??? example "Before & After"

    **Before (Sub):**
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
        = GotAnimMsg Sub.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update animMsg model.animState
                in
                handleEvents events { model | animState = newAnimState }

            TriggerAnimation ->
                ( { model | animState = Sub.animate model.animState fadeIn }
                , Cmd.none
                )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotAnimMsg model.animState

    view : Model -> Html Msg
    view model =
        div
            (Sub.attributes "box" model.animState)
            [ text "Content" ]
    ```

    **After (Keyframes):**
    ```elm
    import Anim.Engine.CSS.Keyframes as Keyframes
    import Anim.Opacity as Opacity

    type alias Model =
        { animState : Keyframes.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Keyframes.init [ Opacity.init "boxAnim" 0 ] }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg Keyframes.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Keyframes.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

            TriggerAnimation ->
                ( { model | animState = Keyframes.animate model.animState fadeIn }
                , Cmd.none
                )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

    view : Model -> Html Msg
    view model =
        div []
            [ Keyframes.styleNode model.animState
            , div
                (Keyframes.attributes "box" model.animState
                    ++ Keyframes.events "box" GotAnimMsg
                )
                [ text "Content" ]
            ]
    ```

---

### Sub → Transitions

- **Adds**: browser-native interpolation, `fireAndForget` convenience
- **Loses**: pause/resume & restart controls, looping, mid-flight access

**Changes required:**

- Change types from `Sub.*` to `Transitions.*` (AnimState, AnimMsg, AnimEvent)
- Remove subscriptions (or set to `Sub.none`)
- Add event listeners to view
- Update `update` function - single event instead of list

??? example "Before & After"

    **Before (Sub):**
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
        = GotAnimMsg Sub.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update animMsg model.animState
                in
                handleEvents events { model | animState = newAnimState }

            TriggerAnimation ->
                ( { model | animState = Sub.animate model.animState fadeIn }
                , Cmd.none
                )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotAnimMsg model.animState

    view : Model -> Html Msg
    view model =
        div
            (Sub.attributes "box" model.animState)
            [ text "Content" ]
    ```

    **After (Transitions):**
    ```elm
    import Anim.Engine.CSS.Transitions as Transitions
    import Anim.Opacity as Opacity

    type alias Model =
        { animState : Transitions.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Transitions.init [ Opacity.init "boxAnim" 0 ] }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg Transitions.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Transitions.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

            TriggerAnimation ->
                ( { model | animState = Transitions.animate model.animState fadeIn }
                , Cmd.none
                )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

    view : Model -> Html Msg
    view model =
        div
            (Transitions.attributes "box" model.animState
                ++ Transitions.events "box" GotAnimMsg
            )
            [ text "Content" ]
    ```

---

### Keyframes → Transitions

- **Adds**: mid-flight redirections
- **Loses**: pause/resume & restart controls, looping
**Changes required:**

- Change types from `Keyframes.*` to `Transitions.*` (AnimState, AnimMsg, AnimEvent)
- Remove `Keyframes.styleNode` from view
- Update pattern matching - remove `Iteration` event handling

??? example "Before & After"

    **Before (Keyframes):**
    ```elm
    import Anim.Engine.CSS.Keyframes as Keyframes
    import Anim.Opacity as Opacity

    type alias Model =
        { animState : Keyframes.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Keyframes.init [ Opacity.init "boxAnim" 0 ] }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg Keyframes.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Keyframes.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

            TriggerAnimation ->
                ( { model | animState = Keyframes.animate model.animState fadeIn }
                , Cmd.none
                )

    handleEvent : Keyframes.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleEvent event model =
        case event of
            Keyframes.Ended "boxAnim" ->
                ( model, Cmd.none )

            Keyframes.Iteration "boxAnim" ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

    view : Model -> Html Msg
    view model =
        div []
            [ Keyframes.styleNode model.animState
            , div
                (Keyframes.attributes "box" model.animState
                    ++ Keyframes.events "box" GotAnimMsg
                )
                [ text "Content" ]
            ]
    ```

    **After (Transitions):**
    ```elm
    import Anim.Engine.CSS.Transitions as Transitions
    import Anim.Opacity as Opacity

    type alias Model =
        { animState : Transitions.AnimState }

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Transitions.init [ Opacity.init "boxAnim" 0 ] }
        , Cmd.none
        )

    type Msg
        = GotAnimMsg Transitions.AnimMsg
        | TriggerAnimation

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Transitions.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

            TriggerAnimation ->
                ( { model | animState = Transitions.animate model.animState fadeIn }
                , Cmd.none
                )

    handleEvent : Transitions.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleEvent event model =
        case event of
            Transitions.Ended "boxAnim" ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

    view : Model -> Html Msg
    view model =
        div []
            [ div
                (Transitions.attributes "box" model.animState
                    ++ Transitions.events "box" GotAnimMsg
                )
                [ text "Content" ]
            ]
    ```


---

## Common Gotchas

### Keyframes: styleNode placement

Place `styleNode` as high in your DOM as possible - ideally at the root level. If DOM diffing causes the `styleNode` to be re-rendered, the browser treats it as a new `<style>` element being inserted, which restarts all CSS keyframe animations from the beginning. At the root level, unrelated view changes are less likely to cause the `styleNode` to be reconstructed.

??? example "View Source Code"

    ```elm
    view : Model -> Html Msg
    view model =
        div []
            [ Keyframes.styleNode model.animState  -- At root level
            , viewHeader model
            , viewContent model  -- Contains animated elements
            , viewFooter model
            ]
    ```

### Sub: Events are a List

Sub's `update` returns a list of events because multiple animations can complete on the same frame. Make sure to handle all of them:

??? example "View Source Code"

    ```elm
    -- Wrong - silently drops events after the first
    GotAnimMsg animMsg ->
        let
            ( newAnimState, events ) =
                Sub.update animMsg model.animState
        in
        case events of
            [ Sub.Ended "boxAnim" ] ->
                ...
            _ ->
                ( { model | animState = newAnimState }, Cmd.none )

    -- Correct - processes every event
    GotAnimMsg animMsg ->
        let
            ( newAnimState, events ) =
                Sub.update animMsg model.animState
        in
        List.foldl handleEvent
            ( { model | animState = newAnimState }, Cmd.none )
            events
    ```

### WAAPI: Don't forget the Cmd

With WAAPI, `animate` returns `(AnimState, Cmd)`. If you forget to return the `Cmd`, no animation will play:

??? example "View Source Code"

    ```elm
    -- Wrong - animation won't play
    let
        ( newAnimState, _ ) =
            WAAPI.animate model.animState fadeIn
    in
    ( { model | animState = newAnimState }, Cmd.none )

    -- Correct
    let
        ( newAnimState, cmd ) =
            WAAPI.animate model.animState fadeIn
    in
    ( { model | animState = newAnimState }, cmd )
    ```


## Need Help?

If you run into issues during migration, check:

1. The compiler errors - Elm will catch most type mismatches
2. The individual engine documentation for detailed API reference
3. The examples in the [examples directory](../../examples/) for working code

If you have a problem you just can't solve, you can <a href="https://discourse.elm-lang.org/new-message?username=paulh" target="_blank">PM me on Discourse</a>.
