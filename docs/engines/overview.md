# Animation Engines

Elm Animate provides multiple animation engines, each optimized for different use cases. All engines share the same builder API, making it easy to switch between them.

## Feature Comparison

| Feature | Transitions | Keyframes | Sub | WAAPI |
| ------- | :---------: | :-------: | :-: | :---: |
| **Rendering** |
| Browser-native interpolation | ✓ | ✓ | | ✓ |
| Hardware acceleration | ✓ | ✓ | ✓ | ✓ |
| JavaScript required | | | | ✓ |
| **Animation Control** |
| Stop | ✓ | ✓ | ✓ | ✓ |
| Reset | ✓ | ✓ | ✓ | ✓ |
| Restart | | ✓ | ✓ | ✓ |
| Pause/Resume | | ✓ | ✓ | ✓ |
| **Playback** |
| Looping/Iterations | | ✓ | | ✓ |
| Event callbacks | ✓ | ✓ | ✓ | ✓ |
| **Mid-Flight Access** |
| Query current values | | | ✓ | ✓ |
| Dynamic redirects | ✓ | | ✓ | ✓ |
| **Properties** |
| Custom transform order | ✓ | ✓ | ✓ | ✓ |
| 3D transforms | ✓ | ✓ | ✓ | ✓ |

## `animate` vs `fireAndForget`

- **`animate`** — Tracks state in `AnimState`, enabling sequencing, redirection, and control
- **`fireAndForget`** — Starts fresh each time, no state continuity

| Scenario | Transitions | Keyframes | Sub | WAAPI |
| -------- | :---------: | :-------: | :-: | :---: |
| Animation runs once, no control needed | `fireAndForget` | `fireAndForget` | `animate` | `fireAndForget` |
| Simple entry animations | `fireAndForget` | `fireAndForget` | `animate` | `fireAndForget` |
| Stop/reset controls | `animate` | `animate` | `animate` | `animate` |
| Pause/resume controls | | `animate` | `animate` | `animate` |
| Sequencing animations | `animate` | `animate` | `animate` | `animate` |
| Redirecting mid-flight | `animate`/`fireAndForget` | | `animate` | `animate` |

!!! note "Sub always uses `animate`"
    The Sub engine does not have a `fireAndForget` function, only `animate`; the Sub engine uses `subscriptions` with frame by frame `update`s, so the fire-and-forget concept does not exist in the world of subscription based animations.

## Initializing Property Configs

All Engines have an `init` function that creates the initial `AnimState`. You can optionally pass property initializers to set starting values for first render.

### Empty State

??? example "View Source Code"

    === "Transitions"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            ( { animState = Transitions.init [] }
            , Cmd.none
            )
        ```

    === "Keyframes"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            ( { animState = Keyframes.init [] }
            , Cmd.none
            )
        ```

    === "Sub"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            ( { animState = Sub.init [] }
            , Cmd.none
            )
        ```

    === "WAAPI"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            ( { animState = WAAPI.init waapiCommand waapiEvent [] }
            , Cmd.none
            )
        ```

        WAAPI requires the port functions as parameters.

### With Initial Values

Use property initializers like `Opacity.init`, `Translate.initXY`, etc. to set starting values:

??? example "View Source Code"

    === "Transitions"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            ( { animState =
                    Transitions.init
                        [ Opacity.init "box" 0
                        , Translate.initXY "box" 100 50
                        ]
              }
            , Cmd.none
            )
        ```

    === "Keyframes"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            ( { animState =
                    Keyframes.init
                        [ Opacity.init "box" 0
                        , Translate.initXY "box" 100 50
                        ]
              }
            , Cmd.none
            )
        ```

    === "Sub"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            ( { animState =
                    Sub.init
                        [ Opacity.init "box" 0
                        , Translate.initXY "box" 100 50
                        ]
              }
            , Cmd.none
            )
        ```

    === "WAAPI"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            ( { animState =
                    WAAPI.init waapiCommand waapiEvent
                        [ WAAPI.forElement "box"
                            >> Opacity.init "fadeAnim" 0
                            >> Translate.initXY "slideAnim" 100 50
                        ]
              }
            , Cmd.none
            )
        ```

        WAAPI uses `forElement` to associate initializers with DOM elements.

These values are applied in your view via `Engine.attributes`.

## Default Settings

Set default timing, easing, and delay for all properties in an animation pipeline. Individual properties can override these defaults.

??? example "View Source Code"

    === "Transitions"

        ```elm
        Transitions.animate model.animState <|
            Transitions.duration 500
                >> Transitions.easing QuintOut
                >> Transitions.delay 100
                >> myAnimation
        ```

    === "Keyframes"

        ```elm
        Keyframes.animate model.animState <|
            Keyframes.duration 500
                >> Keyframes.easing QuintOut
                >> Keyframes.delay 100
                >> myAnimation
        ```

    === "Sub"

        ```elm
        Sub.animate model.animState <|
            Sub.duration 500
                >> Sub.easing QuintOut
                >> Sub.delay 100
                >> myAnimation
        ```

    === "WAAPI"

        ```elm
        WAAPI.animate model.animState <|
            WAAPI.duration 500
                >> WAAPI.easing QuintOut
                >> WAAPI.delay 100
                >> WAAPI.forElement "box"
                >> myAnimation
        ```

## Event Handling

All engines provide animation lifecycle events. The pattern varies slightly by engine type.

### CSS Engines (Transitions & Keyframes)

CSS engines use DOM event listeners attached in the view:

??? example "View Source Code"

    === "Transitions"

        ```elm
        type Msg
            = GotTransitionEvent Transitions.AnimEvent
            | ...

        view model =
            div
                (Transitions.attributes "box" model.animState
                    ++ Transitions.events "box" GotTransitionEvent
                )
                [ text "Animated content" ]

        update msg model =
            case msg of
                GotTransitionEvent event ->
                    ( { model | animState = Transitions.handleEvent event model.animState }
                    , Cmd.none
                    )
        ```

    === "Keyframes"

        ```elm
        type Msg
            = GotKeyframeEvent Keyframes.AnimEvent
            | ...

        view model =
            div []
                [ Keyframes.styleNode model.animState
                , div
                    (Keyframes.attributes "box" model.animState
                        ++ Keyframes.events "box" GotKeyframeEvent
                    )
                    [ text "Animated content" ]
                ]

        update msg model =
            case msg of
                GotKeyframeEvent event ->
                    ( { model | animState = Keyframes.handleEvent event model.animState }
                    , Cmd.none
                    )
        ```

### Sub Engine

The Sub engine returns events from `update`:

??? example "View Source Code"

    ```elm
    type Msg
        = GotAnimMsg Sub.AnimMsg
        | ...

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
                        -- Handle completion
                        handleEvents rest model

                    _ ->
                        handleEvents rest model
    ```

### WAAPI Engine

WAAPI uses subscriptions to receive events from JavaScript:

??? example "View Source Code"

    ```elm
    type Msg
        = GotWaapiMsg WAAPI.AnimMsg
        | ...

    subscriptions model =
        WAAPI.subscriptions GotWaapiMsg model.animState

    update msg model =
        case msg of
            GotWaapiMsg subMsg ->
                let
                    ( newAnimState, event ) =
                        WAAPI.update subMsg model.animState
                in
                case event of
                    WAAPI.Ended "box" ->
                        -- Handle completion
                        ( { model | animState = newAnimState }, Cmd.none )

                    _ ->
                        ( { model | animState = newAnimState }, Cmd.none )
    ```

### Event Types

| Event | Transitions | Keyframes | Sub | WAAPI |
| ----- | :---------: | :-------: | :-: | :---: |
| Run/Started | ✓ | ✓ | ✓ | ✓ |
| Ended | ✓ | ✓ | ✓ | ✓ |
| Cancelled | ✓ | ✓ | ✓ | ✓ |
| Iteration | | ✓ | | |
| Paused | | | ✓ | ✓ |
| Resumed | | | ✓ | ✓ |
| Restarted | | | ✓ | ✓ |

## Querying Animation State

Check whether animations are running or complete:

??? example "View Source Code"

    === "Transitions"

        ```elm
        -- Any animation running?
        Transitions.anyRunning model.animState

        -- Specific element?
        Transitions.isRunning "box" model.animState

        -- Is it complete?
        Transitions.isComplete "box" model.animState  -- Maybe Bool
        ```

    === "Keyframes"

        ```elm
        -- Any animation running?
        Keyframes.anyRunning model.animState

        -- Specific element?
        Keyframes.isRunning "box" model.animState

        -- Is it complete?
        Keyframes.isComplete "box" model.animState  -- Maybe Bool
        ```

    === "Sub"

        ```elm
        -- Any animation running?
        Sub.anyRunning model.animState

        -- Specific element?
        Sub.isRunning "box" model.animState

        -- Is it complete?
        Sub.isComplete "box" model.animState  -- Maybe Bool
        ```

    === "WAAPI"

        ```elm
        -- Any animation running?
        WAAPI.anyRunning model.animState

        -- Specific element?
        WAAPI.isRunning "box" model.animState

        -- Is it complete?
        WAAPI.isComplete "box" model.animState  -- Maybe Bool
        ```

## Querying Property Values

Query the start, end, or current values of animated properties:

??? example "View Source Code"

    === "Transitions"

        ```elm
        Transitions.getStartTranslate "box" model.animState   -- Maybe { x, y, z }
        Transitions.getEndTranslate "box" model.animState     -- Maybe { x, y, z }
        Transitions.getCurrentTranslate "box" model.animState -- Maybe { x, y, z }
        ```

    === "Keyframes"

        ```elm
        Keyframes.getStartTranslate "box" model.animState   -- Maybe { x, y, z }
        Keyframes.getEndTranslate "box" model.animState     -- Maybe { x, y, z }
        Keyframes.getCurrentTranslate "box" model.animState -- Maybe { x, y, z }
        ```

    === "Sub"

        ```elm
        Sub.getStartTranslate "box" model.animState   -- Maybe { x, y, z }
        Sub.getEndTranslate "box" model.animState     -- Maybe { x, y, z }
        Sub.getCurrentTranslate "box" model.animState -- Maybe { x, y, z }
        ```

    === "WAAPI"

        ```elm
        WAAPI.getStartTranslate "box" model.animState   -- Maybe { x, y, z }
        WAAPI.getEndTranslate "box" model.animState     -- Maybe { x, y, z }
        WAAPI.getCurrentTranslate "box" model.animState -- Maybe { x, y, z }
        ```

Available for all properties: Translate, Scale, Rotate, Opacity, Size, BackgroundColor.

!!! note "Mid-flight values"
    CSS engines (Transitions, Keyframes) don't expose true mid-flight values — "current" returns start before animation and end after it starts. For true interpolated mid-flight values, use Sub or WAAPI.

## Transform Ordering

The default transform order is **Translate → Rotate → Scale**. Use `animateOrder` or `fireAndForgetOrder` for custom ordering:

??? example "View Source Code"

    === "Transitions"

        ```elm
        import Anim.Engine.CSS.Transitions as Transitions exposing (TransformOrder(..))

        Transitions.animateOrder [ Scale, Rotate, Translate ] model.animState <|
            scaleUp >> rotateLeft >> moveRight
        ```

    === "Keyframes"

        ```elm
        import Anim.Engine.CSS.Keyframes as Keyframes exposing (TransformOrder(..))

        Keyframes.animateOrder [ Scale, Rotate, Translate ] model.animState <|
            scaleUp >> rotateLeft >> moveRight
        ```

    === "Sub"

        ```elm
        import Anim.Engine.Sub as Sub exposing (TransformOrder(..))

        Sub.animateOrder [ Scale, Rotate, Translate ] model.animState <|
            scaleUp >> rotateLeft >> moveRight
        ```

    === "WAAPI"

        ```elm
        import Anim.Engine.WAAPI as WAAPI exposing (TransformOrder(..))

        WAAPI.animateOrder [ Scale, Rotate, Translate ] model.animState <|
            WAAPI.forElement "box" >> scaleUp >> rotateLeft >> moveRight
        ```

Transform order affects how combined transforms render. Rotating then translating moves along the rotated axis; translating then rotating moves along the original axis.

## Switching Engines

Because all engines share the same builder API, animations are portable:

??? example "View Source Code"

    ```elm
    -- This animation works with any engine
    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for animGroup
            >> Translate.toXY 100 200
            >> Translate.duration 500
            >> Translate.build
    ```

    === "Transitions"

        ```elm
        Transitions.fireAndForget myAnimation
        ```

    === "Keyframes"

        ```elm
        Keyframes.fireAndForget myAnimation
        ```

    === "Sub"

        ```elm
        Sub.animate model.animState myAnimation
        ```

    === "WAAPI"

        ```elm
        WAAPI.animate model.animState <|
            WAAPI.forElement "box"
                >> myAnimation
        ```

This makes it easy to start simple with one of the CSS Engines and migrate to Sub or WAAPI as your requirements grow.


## Next Steps

Now that you've learned about the animation engines, explore each engine in detail or check out the scroll engine for smooth scrolling animations.

[Scroll Engine →](scroll.md){ .md-button .md-button--primary }
