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

- [Transitions to Keyframes](#transitions-keyframes) - Add looping, iterations
- [Transitions to Sub](#transitions-sub) - Add full Elm control, mid-flight access
- [Transitions to WAAPI](#transitions-waapi) - Add browser-native performance, full control
- [Keyframes to Sub](#keyframes-sub) - Add mid-flight value access, Elm-side control
- [Keyframes to WAAPI](#keyframes-waapi) - Add browser-native performance
- [Sub to WAAPI](#sub-waapi) - Add browser-native interpolation

### Migrating Down (simplifying)

- [WAAPI to Sub](#waapi-sub) - Remove JavaScript dependency
- [WAAPI to Keyframes](#waapi-keyframes) - Remove subscriptions, simpler setup
- [WAAPI to Transitions](#waapi-transitions) - Simplest possible setup
- [Sub to Keyframes](#sub-keyframes) - Remove subscriptions, use CSS animations
- [Sub to Transitions](#sub-transitions) - Simplest possible setup
- [Keyframes to Transitions](#keyframes-transitions) - Remove styleNode, simpler setup


---

## Migrating Up

### Transitions → Keyframes

Keyframes adds looping, pause/resume, and restart capabilities.

**Changes required:**

- Change import from `Anim.Engine.CSS.Transitions` to `Anim.Engine.CSS.Keyframes`
- Add `Keyframes.styleNode model.animState` to your view (before animated elements)
- Change types from `Transitions.AnimMsg` / `Transitions.AnimEvent` to `Keyframes.AnimMsg` / `Keyframes.AnimEvent`
- Update pattern matching for events (Keyframes has `Iteration` event)

??? example "Before & After"

    **Before (Transitions):**
    ```elm
    import Anim.Engine.CSS.Transitions as Transitions

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
            Transitions.Ended "box" ->
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
            Keyframes.Ended "box" ->
                ( model, Cmd.none )

            Keyframes.Iteration "box" ->
                -- New event type for iterations
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

    view : Model -> Html Msg
    view model =
        div []
            [ Keyframes.styleNode model.animState  -- Add this first
            , div
                (Keyframes.attributes "box" model.animState
                    ++ Keyframes.events "box" GotAnimMsg
                )
                [ text "Content" ]
            ]
    ```

---

### Transitions → Sub

Sub gives you full Elm-side control and true mid-flight value access.

**Changes required:**

- Change import from `Anim.Engine.CSS.Transitions` to `Anim.Engine.Sub`
- Add subscriptions function
- Change message type from `Transitions.AnimMsg` to `Sub.AnimMsg`
- Update `update` function - events come from `Sub.update` as a `List`, not from DOM
- Replace `fireAndForget` calls with `animate`
- Remove event listeners from view (events come via subscription now)

??? example "Before & After"

    **Before (Transitions):**
    ```elm
    import Anim.Engine.CSS.Transitions as Transitions

    type Msg
        = GotAnimMsg Transitions.AnimMsg

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

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
            Transitions.Ended "box" ->
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

    **After (Sub):**
    ```elm
    import Anim.Engine.Sub as Sub

    type Msg
        = GotAnimMsg Sub.AnimMsg

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotAnimMsg model.animState

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
                    Sub.Ended "box" ->
                        handleEvents rest model

                    _ ->
                        handleEvents rest model

    view : Model -> Html Msg
    view model =
        div
            (Sub.attributes "box" model.animState)  -- No event listeners needed
            [ text "Content" ]
    ```

---

### Transitions → WAAPI

WAAPI provides browser-native performance with full control capabilities.

**Changes required:**

- Add JavaScript setup (ports and WAAPI runtime)
- Change import from `Anim.Engine.CSS.Transitions` to `Anim.Engine.WAAPI`
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

    type Msg
        = GotAnimMsg Transitions.AnimMsg
        | TriggerAnimation

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Transitions.init [] }, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

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
            Transitions.Ended "box" ->
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

    **After (WAAPI):**
    ```elm
    port module Main exposing (..)

    import Anim.Engine.WAAPI as WAAPI
    import Json.Decode
    import Json.Encode

    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type Msg
        = GotAnimMsg WAAPI.AnimMsg
        | TriggerAnimation

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = WAAPI.init waapiCommand waapiEvent [] }, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState

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
            WAAPI.Ended "box" _ _ ->
                -- WAAPI events include animationId and EventInfo
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

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

**Changes required:**

- Change import from `Anim.Engine.CSS.Keyframes` to `Anim.Engine.Sub`
- Remove `Keyframes.styleNode` from view
- Add subscriptions function
- Change message type from `Keyframes.AnimMsg` to `Sub.AnimMsg`
- Update `update` function - events come as a `List` now
- Replace `fireAndForget` calls with `animate`
- Remove event listeners from view

??? example "Before & After"

    **Before (Keyframes):**
    ```elm
    import Anim.Engine.CSS.Keyframes as Keyframes

    type Msg
        = GotAnimMsg Keyframes.AnimMsg

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Keyframes.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

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

    type Msg
        = GotAnimMsg Sub.AnimMsg

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotAnimMsg model.animState

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update animMsg model.animState
                in
                handleEvents events { model | animState = newAnimState }

    view : Model -> Html Msg
    view model =
        div
            (Sub.attributes "box" model.animState)
            [ text "Content" ]
    ```

---

### Keyframes → WAAPI

**Changes required:**

- Add JavaScript setup (ports and WAAPI runtime)
- Change import from `Anim.Engine.CSS.Keyframes` to `Anim.Engine.WAAPI`
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

    type Msg
        = GotAnimMsg Keyframes.AnimMsg
        | TriggerAnimation

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Keyframes.init [] }, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

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
    import Json.Decode
    import Json.Encode

    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type Msg
        = GotAnimMsg WAAPI.AnimMsg
        | TriggerAnimation

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = WAAPI.init waapiCommand waapiEvent [] }, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState

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

**Changes required:**

- Add JavaScript setup (ports and WAAPI runtime)
- Change import from `Anim.Engine.Sub` to `Anim.Engine.WAAPI`
- Define port functions and update `init`
- Update subscriptions to use `WAAPI.subscriptions`
- Update `animate` calls to handle returned `Cmd`
- Update `update` function - `WAAPI.update` returns single event, not list

??? example "Before & After"

    **Before (Sub):**
    ```elm
    import Anim.Engine.Sub as Sub

    type Msg
        = GotAnimMsg Sub.AnimMsg
        | TriggerAnimation

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Sub.init [] }, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotAnimMsg model.animState

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
    import Json.Decode
    import Json.Encode

    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type Msg
        = GotAnimMsg WAAPI.AnimMsg
        | TriggerAnimation

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = WAAPI.init waapiCommand waapiEvent [] }, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState

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

Remove JavaScript dependency while keeping full Elm-side control.

**Changes required:**

- Remove JavaScript setup (ports and WAAPI runtime)
- Change import from `Anim.Engine.WAAPI` to `Anim.Engine.Sub`
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
    import Json.Decode
    import Json.Encode

    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type Msg
        = GotAnimMsg WAAPI.AnimMsg
        | TriggerAnimation

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = WAAPI.init waapiCommand waapiEvent [] }, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState

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

    type Msg
        = GotAnimMsg Sub.AnimMsg
        | TriggerAnimation

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Sub.init [] }, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotAnimMsg model.animState

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

    view : Model -> Html Msg
    view model =
        div
            (Sub.attributes "box" model.animState)
            [ text "Content" ]
    ```

---

### WAAPI → Keyframes

Remove JavaScript and subscriptions, use CSS @keyframes.

**Changes required:**

- Remove JavaScript setup (ports and WAAPI runtime)
- Change import from `Anim.Engine.WAAPI` to `Anim.Engine.CSS.Keyframes`
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

    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type Msg
        = GotAnimMsg WAAPI.AnimMsg
        | TriggerAnimation

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = WAAPI.init waapiCommand waapiEvent [] }, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState

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

    type Msg
        = GotAnimMsg Keyframes.AnimMsg
        | TriggerAnimation

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Keyframes.init [] }, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

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

Simplest possible setup - no JavaScript, no subscriptions, no styleNode.

**Changes required:**

- Remove JavaScript setup (ports and WAAPI runtime)
- Change import from `Anim.Engine.WAAPI` to `Anim.Engine.CSS.Transitions`
- Remove port functions from `init`
- Remove subscriptions (or set to `Sub.none`)
- Add event listeners to view
- Update `animate` calls - no longer returns `Cmd`
- Update event handling - events come from DOM, not ports
- Note: Loses looping/iterations capability

??? example "Before & After"

    **Before (WAAPI):**
    ```elm
    port module Main exposing (..)

    import Anim.Engine.WAAPI as WAAPI

    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type Msg
        = GotAnimMsg WAAPI.AnimMsg
        | TriggerAnimation

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = WAAPI.init waapiCommand waapiEvent [] }, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            TriggerAnimation ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.animate model.animState fadeIn
                in
                ( { model | animState = newAnimState }, cmd )

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

    type Msg
        = GotAnimMsg Transitions.AnimMsg
        | TriggerAnimation

    init : flags -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Transitions.init [] }, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

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

Remove subscriptions, use CSS @keyframes instead.

**Changes required:**

- Change import from `Anim.Engine.Sub` to `Anim.Engine.CSS.Keyframes`
- Remove subscriptions (or set to `Sub.none`)
- Add `Keyframes.styleNode model.animState` to view
- Add event listeners to view
- Update `update` function - single event instead of list
- Note: Loses mid-flight value access (`get*Current` functions)

??? example "Before & After"

    **Before (Sub):**
    ```elm
    import Anim.Engine.Sub as Sub

    type Msg
        = GotAnimMsg Sub.AnimMsg
        | TriggerAnimation

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotAnimMsg model.animState

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

    view : Model -> Html Msg
    view model =
        div
            (Sub.attributes "box" model.animState)
            [ text "Content" ]
    ```

    **After (Keyframes):**
    ```elm
    import Anim.Engine.CSS.Keyframes as Keyframes

    type Msg
        = GotAnimMsg Keyframes.AnimMsg
        | TriggerAnimation

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

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

Simplest setup - no subscriptions, no styleNode.

**Changes required:**

- Change import from `Anim.Engine.Sub` to `Anim.Engine.CSS.Transitions`
- Remove subscriptions (or set to `Sub.none`)
- Add event listeners to view
- Update `update` function - single event instead of list
- Note: Loses mid-flight value access and looping/iterations

??? example "Before & After"

    **Before (Sub):**
    ```elm
    import Anim.Engine.Sub as Sub

    type Msg
        = GotAnimMsg Sub.AnimMsg
        | TriggerAnimation

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotAnimMsg model.animState

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

    view : Model -> Html Msg
    view model =
        div
            (Sub.attributes "box" model.animState)
            [ text "Content" ]
    ```

    **After (Transitions):**
    ```elm
    import Anim.Engine.CSS.Transitions as Transitions

    type Msg
        = GotAnimMsg Transitions.AnimMsg
        | TriggerAnimation

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.none

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

Simplest setup - remove styleNode.

**Changes required:**

- Change import from `Anim.Engine.CSS.Keyframes` to `Anim.Engine.CSS.Transitions`
- Remove `Keyframes.styleNode` from view
- Change types from `Keyframes.AnimMsg` / `Keyframes.AnimEvent` to `Transitions.AnimMsg` / `Transitions.AnimEvent`
- Update pattern matching - remove `Iteration` event handling
- Note: Loses looping/iterations capability

??? example "Before & After"

    **Before (Keyframes):**
    ```elm
    import Anim.Engine.CSS.Keyframes as Keyframes

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
            Keyframes.Ended "box" ->
                ( model, Cmd.none )

            Keyframes.Iteration "box" ->
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
            Transitions.Ended "box" ->
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

### Sub: Events are a List

Sub's `update` returns a list of events (multiple properties can complete simultaneously). Handle them all:

??? example "View Source Code"

    ```elm
    -- Wrong - only handles first event
    let
        ( newAnimState, events ) =
            Sub.update animMsg model.animState
    in
    case List.head events of
        Just (Sub.Ended "box") -> ...

    -- Correct - handles all events
    handleEvents events { model | animState = newAnimState }
    ```

### Keyframes: styleNode placement

The `styleNode` must be rendered before the animated elements, or animations won't apply on the first frame:

```elm
-- Wrong - styleNode after animated element
div []
    [ div (Keyframes.attributes "box" model.animState) [ ... ]
    , Keyframes.styleNode model.animState
    ]

-- Correct - styleNode first
div []
    [ Keyframes.styleNode model.animState
    , div (Keyframes.attributes "box" model.animState) [ ... ]
    ]
```


## Need Help?

If you run into issues during migration, check:

1. The compiler errors - Elm will catch most type mismatches
2. The individual engine documentation for detailed API reference
3. The examples in the [examples directory](../../examples/) for working code
