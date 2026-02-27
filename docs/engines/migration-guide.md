# Migration Guide

This guide helps you switch between animation engines. Because all engines share the same builder API, your animation definitions remain unchanged - only the engine integration code needs updating.


## Quick Reference Matrix

This table shows what changes need to be made when migrating between engines:

| Component | Transitions | Keyframes | Sub | WAAPI |
| --------- | ----------- | --------- | --- | ----- |
| **Init** | `init []` | `init []` | `init []` | `init cmd sub []` |
| **Animate** | returns `AnimState` | returns `AnimState` | returns `AnimState` | returns `(AnimState, Cmd)` |
| **Fire & Forget** | returns `AnimState` | returns `AnimState` | ❌ N/A | returns `Cmd` |
| **Subscriptions** | ❌ None | ❌ None | ✅ Required | ✅ Required |
| **Events via** | DOM listeners | DOM listeners | `update` return | Port subscription |
| **View: styleNode** | ❌ No | ✅ Required | ❌ No | ❌ No |
| **JavaScript** | ❌ None | ❌ None | ❌ None | ✅ Required |

## Migration Checklists

### Transitions → Keyframes

Keyframes adds looping, pause/resume, and restart capabilities.

**Changes required:**

- Change import from `Anim.Engine.CSS.Transitions` to `Anim.Engine.CSS.Keyframes`
- Add `Keyframes.styleNode model.animState` to your view
- Change event type from `Transitions.AnimEvent` to `Keyframes.AnimEvent`
- Change message handler from `Transitions.handleEvent` to `Keyframes.handleEvent`

??? example "Before & After"

    **Before (Transitions):**
    ```elm
    import Anim.Engine.CSS.Transitions as Transitions

    view model =
        div
            (Transitions.attributes "box" model.animState
                ++ Transitions.events "box" GotAnimEvent
            )
            [ text "Content" ]
    ```

    **After (Keyframes):**
    ```elm
    import Anim.Engine.CSS.Keyframes as Keyframes

    view model =
        div []
            [ Keyframes.styleNode model.animState  -- Add this
            , div
                (Keyframes.attributes "box" model.animState
                    ++ Keyframes.events "box" GotAnimEvent
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
- Change message type to handle `Sub.AnimMsg`
- Change `update` function to handle events - they now come from `Sub.update`, not DOM
- Replace `fireAndForget` calls with `animate` instead
- Remove event listeners from view (events come via subscription now)

??? example "Before & After"

    **Before (Transitions):**
    ```elm
    import Anim.Engine.CSS.Transitions as Transitions

    type Msg
        = GotAnimEvent Transitions.AnimEvent
        | ...

    subscriptions _ =
        Sub.none

    update msg model =
        case msg of
            GotAnimEvent event ->
                ( { model | animState = Transitions.handleEvent event model.animState }
                , Cmd.none
                )

    view model =
        div
            (Transitions.attributes "box" model.animState
                ++ Transitions.events "box" GotAnimEvent
            )
            [ text "Content" ]
    ```

    **After (Sub):**
    ```elm
    import Anim.Engine.Sub as Sub

    type Msg
        = GotAnimMsg Sub.AnimMsg
        | ...

    subscriptions model =
        Sub.subscriptions GotAnimMsg model.animState

    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update animMsg model.animState
                in
                handleEvents events <|
                    ({ model | animState = newAnimState }, Cmd.none)

    handleEvents : List Sub.AnimEvent -> (Model, Cmd Msg) -> (Model, Cmd Msg)
    handleEvents events (model, cmd) =
        case events of
            [] ->
                ( model, cmd )

            event :: rest ->
                case event of
                    Sub.Ended "box" ->
                        -- Handle completion, then continue
                        boxAnimEnded (model, cmd)
                            |> handleEvents rest

                    _ ->
                        handleEvents rest (model, cmd)

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
- Define port functions and add to `init`
- Add subscriptions function
- Update `animate` calls to handle returned `Cmd`
- Replace `fireAndForget` - it now returns `Cmd` only
- Update `update` function for port-based events
- Remove event listeners from view

??? example "Before & After"

    **Before (Transitions):**
    ```elm
    import Anim.Engine.CSS.Transitions as Transitions

    type Msg
        = GotAnimEvent Transitions.AnimEvent

    init _ =
        ( { animState = Transitions.init [] }, Cmd.none )

    subscriptions _ =
        Sub.none

    update msg model =
        case msg of
            GotAnimEvent event ->
                ( { model | animState = Transitions.handleEvent event model.animState }
                , Cmd.none
                )

            TriggerAnimation ->
                ( { model | animState = Transitions.animate model.animState fadeIn }
                , Cmd.none
                )

    view model =
        div
            (Transitions.attributes "box" model.animState
                ++ Transitions.events "box" GotAnimEvent
            )
            [ text "Content" ]
    ```

    **After (WAAPI):**
    ```elm
    port module Main exposing (..)

    import Anim.Engine.WAAPI as WAAPI

    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type Msg
        = GotWaapiMsg WAAPI.AnimMsg

    init _ =
        ( { animState = WAAPI.init waapiCommand waapiEvent [] }, Cmd.none )

    subscriptions model =
        WAAPI.subscriptions GotWaapiMsg model.animState

    update msg model =
        case msg of
            GotWaapiMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        WAAPI.update animMsg model.animState
                in
                case event of
                    WAAPI.Ended "box" ->
                        -- Handle completion
                        ( { model | animState = newAnimState }, Cmd.none )

                    _ ->
                        ( { model | animState = newAnimState }, Cmd.none )

            TriggerAnimation ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.animate model.animState fadeIn
                in
                ( { model | animState = newAnimState }, cmd )

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
- Change message type to handle `Sub.AnimMsg`
- Update `update` function - events come from `Sub.update`
- Remove `fireAndForget` calls - use `animate` instead
- Remove event listeners from view

---

### Keyframes → WAAPI

**Changes required:**

- Add JavaScript setup (ports and WAAPI runtime)
- Change import from `Anim.Engine.CSS.Keyframes` to `Anim.Engine.WAAPI`
- Remove `Keyframes.styleNode` from view
- Define port functions and add to `init`
- Add subscriptions function
- Update `animate` calls to handle returned `Cmd`
- Update `fireAndForget` - it now returns `Cmd` only
- Update `update` function for port-based events
- Remove event listeners from view

---

### Sub → WAAPI

**Changes required:**

- Add JavaScript setup (ports and WAAPI runtime)
- Change import from `Anim.Engine.Sub` to `Anim.Engine.WAAPI`
- Define port functions and update `init`
- Update subscriptions to use `WAAPI.subscriptions`
- Update `animate` calls to handle returned `Cmd`
- Update `update` function - `WAAPI.update` returns single event, not list


## Common Gotchas

### WAAPI: Don't forget the Cmd

With WAAPI, `animate` returns `(AnimState, Cmd)`. If you forget to return the `Cmd`, no animation will play:

```elm
-- ❌ Wrong - animation won't play
( { model | animState = Tuple.first (WAAPI.animate model.animState fadeIn) }
, Cmd.none
)

-- ✅ Correct
let
    ( newAnimState, cmd ) =
        WAAPI.animate model.animState fadeIn
in
( { model | animState = newAnimState }, cmd )
```

### Sub: Events are a List

Sub's `update` returns a list of events (multiple properties can complete simultaneously). Handle them all:

```elm
-- ❌ Wrong - only handles first event
let
    ( newAnimState, events ) =
        Sub.update animMsg model.animState
in
case List.head events of
    Just (Sub.Ended "box") -> ...

-- ✅ Correct - handles all events
handleEvents events { model | animState = newAnimState }
```

### Keyframes: styleNode placement

The `styleNode` must be rendered before the animated elements, or animations won't apply on the first frame:

```elm
-- ❌ Wrong - styleNode after animated element
div []
    [ div (Keyframes.attributes "box" model.animState) [ ... ]
    , Keyframes.styleNode model.animState
    ]

-- ✅ Correct - styleNode first
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
