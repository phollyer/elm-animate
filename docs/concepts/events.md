# Events

CSS Transitions, Keyframe Animations, and the Web Animations API all produce events during an animation's lifecycle. These events notify you when animations start, end, get interrupted, or change state — letting you chain animations in sequence, update the UI, or clean up resources.

How you receive these events depends on the engine:

**DOM-based engines** (Transitions, Keyframes) produce native browser events. You capture them by adding event attributes to your animated elements, then handle them in your update function. This mirrors how you'd handle click or input events in Elm.

**Subscription-based engine** (Sub) computes events internally by tracking animation progress on each frame. Because it processes all animations simultaneously, its `update` function returns a list of events - multiple animations can start, end, or change state in a single frame.

**Port-based engine** (WAAPI) receives events from the JavaScript Web Animations API via ports. The browser fires animation lifecycle events (Started, Ended, Changed, etc.), which JavaScript captures and routes to Elm through subscriptions. Control events like Paused, Resumed, and Restarted are generated when you call the corresponding control functions.

## Events by Engine

Each engine provides different events based on its capabilities:

| Event | Transitions | Keyframes | Sub | WAAPI |
| ----- | :---------: | :-------: | :-: | :---: |
| Started | ✓ | ✓ | ✓ | ✓ |
| Ended | ✓ | ✓ | ✓ | ✓ |
| Cancelled | ✓ | ✓ | ✓ | ✓ |
| Restarted | | | ✓ | ✓ |
| Paused | | | ✓ | ✓ |
| Resumed | | | ✓ | ✓ |
| Run | ✓ | | | |
| Iteration | | ✓ | | |
| Changed | | | | ✓ |

## Setting Up Events

How you set up events varies by Engine.

??? example "View Source Code"

    === "Transitions"

        CSS Transitions provide events via HTML event attributes - use the `events` function to add them to the element being animated.

        ```elm
        view model =
            div 
                (Transitions.attributes "box" model.animState
                    ++ Transitions.events "box" GotAnimEvent
                )
                [ text "Animated box" ]
        ```

    === "Keyframes"

        CSS Keyframes provide events via HTML event attributes - use the `events` function to add them to the element being animated.

        ```elm
        view model =
            div 
                (Keyframes.render model.animState "box"
                    ++ Keyframes.events "box" GotAnimEvent
                )
                [ text "Animated box" ]
        ```


    === "Sub"

        Sub animations do not emit events in the same way that CSS animations do, so there is nothing to attach to your view. Instead, because the Sub engine manages animation state internally, it's `update` function will, based on the current internal state, return a list of ephemoral `AnimEvent`s. The list may be empty.

        ```elm
        type Msg
            = GotSubMsg Sub.AnimMsg
            | ...

        update : Msg -> Model -> (Model, Cmd Msg)
        update msg model =
            case msg of
                GotSubMsg subMsg ->
                    let
                        ( newAnimState, events ) =
                            Sub.update subMsg model.animState
                    in
                    ({ model | animState = newAnimState }, Cmd.none)

        subscriptions : Model -> Sub Msg
        subscriptions model =
            Sub.subscriptions GotSubMsg model.animState        
        ```

        Sub returns a list because it processes all animations on each frame — multiple animations can start, end, or change state simultaneously in a single update.

    === "WAAPI"

        The WAAPI engine receives events from the JS Web Animations API that is actually running the animation, so there is nothing to add to your view. Instead, animation lifecycle events are routed from JS, through `subscriptions` to your `update` function.

        ```elm
        type Msg
            = GotWaapiMsg WAAPI.AnimMsg
            | ...

        update msg model =
            case msg of
                GotWaapiMsg waapiMsg ->
                    let
                        ( newAnimState, event ) =
                            WAAPI.update waapiMsg model.animState
                    in
                    ({ model | animState = newAnimState }, Cmd.none)

        subscriptions : Model -> Sub Msg
        subscriptions model =
            WAAPI.subscriptions GotWaapiMsg model.animState 
        ```


## Handling Events

??? example "View Source Code"

    === "Transitions"

        Handle events in your update function with `handleEvent` - this keeps your `animState` in sync with the animations running in the view.

        ```elm
        type Msg
            = GotAnimEvent Transitions.AnimEvent
            | ...

        update msg model =
            case msg of
                GotAnimEvent event ->
                    ( { model | animState = Transitions.handleEvent event model.animState }
                    , Cmd.none
                    )
        ```

    === "Keyframes"

        Handle events in your update function with `handleEvent` - this keeps your `animState` in sync with the animations running in the view.

        ```elm
        type Msg
            = GotAnimEvent Transitions.AnimEvent
            | ...

        update msg model =
            case msg of
                GotAnimEvent event ->
                    ( { model | animState = Keyframes.handleEvent event model.animState }
                    , Cmd.none
                    )
        ```

    === "Sub"

        Sub animations do not emit events in the same way the CSS engines do.

        ```elm
        type Msg
            = GotSubMsg Sub.AnimMsg
            | ...

        update msg model =
            case msg of
                GotSubMsg subMsg ->
                    let
                        ( newAnimState, events ) =
                            Sub.update subMsg model.animState
                    in
                    ({ model | animState = newAnimState }
                    , Cmd.none
                    )
        ```

    === "WAAPI"

        WAAPI returns an optional event from its `update` function:

        ```elm
        type Msg
            = GotWaapiMsg WAAPI.AnimMsg
            | ...

        update msg model =
            case msg of
                GotWaapiMsg waapiMsg ->
                    let
                        ( newAnimState, maybeEvent ) =
                            WAAPI.update waapiMsg model.animState
                    in
                    handleEvent maybeEvent { model | animState = newAnimState }

        handleEvent : Maybe WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
        handleEvent maybeEvent model =
            case maybeEvent of
                Just (WAAPI.Ended "box") ->
                    ( model, startNextAnimation )

                Just (WAAPI.Cancelled _) ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )
        ```

## Reacting To Events


=== "Sub"

    Sub returns events from its `update` function:

    ```elm
    type Msg
        = GotSubMsg Sub.AnimMsg
        | ...

    update msg model =
        case msg of
            GotSubMsg subMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update subMsg model.animState
                in
                handleEvents events { model | animState = newAnimState }

    handleEvents : List Sub.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleEvents events model =
        List.foldl handleEvent ( model, Cmd.none ) events

    handleEvent : Sub.AnimEvent -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
    handleEvent event ( model, cmd ) =
        case event of
            Sub.Ended "box" ->
                ( model, Cmd.batch [ cmd, startNextAnimation ] )

            Sub.Paused _ ->
                ( model, cmd )

            _ ->
                ( model, cmd )
    ```


## Event Details

### Started

Fired when an animation begins. For CSS engines, this fires after any delay.

### Ended

Fired when an animation finishes naturally — reaching its end state.

### Cancelled

Fired when an animation is interrupted before completion. This can happen when:

- Another animation targets the same property
- The element is removed from the DOM
- `stop` or `reset` is called

### Run (Transitions only)

Fired when a transition starts running, after the delay but before actual property changes. Useful for tracking when the transition is "live."

### Iteration (Keyframes only)

Fired at the end of each iteration for looping animations. Useful for tracking progress through repeated animations.

### Paused / Resumed (Sub & WAAPI)

Fired when animations are paused or resumed via control functions. CSS engines don't support pause/resume, so they don't emit these events.

### Restarted (Sub & WAAPI)

Fired when an animation is restarted from the beginning.

## Common Patterns

### Sequential Animations

Trigger the next animation when the current one ends:

```elm
GotAnimEvent (Transitions.Ended "step1") ->
    ( { model | animState = Transitions.animate model.animState step2Animation }
    , Cmd.none
    )

GotAnimEvent (Transitions.Ended "step2") ->
    ( { model | animState = Transitions.animate model.animState step3Animation }
    , Cmd.none
    )
```

### Cleanup on Completion

Remove temporary state when animations finish:

```elm
GotAnimEvent (Keyframes.Ended "notification") ->
    ( { model | notification = Nothing }
    , Cmd.none
    )
```

### Tracking Animation State

Use events to track whether animations are running:

```elm
type Model =
    { animState : Keyframes.AnimState
    , isAnimating : Bool
    }

update msg model =
    case msg of
        GotAnimEvent (Keyframes.Started _) ->
            ( { model | isAnimating = True }, Cmd.none )

        GotAnimEvent (Keyframes.Ended _) ->
            ( { model | isAnimating = False }, Cmd.none )

        GotAnimEvent (Keyframes.Cancelled _) ->
            ( { model | isAnimating = False }, Cmd.none )

        _ ->
            ( model, Cmd.none )
```

## Next Steps

Now that you understand how to react to events, let's take a closer look at the available properties that you can animate.

[Properties →](properties.md){ .md-button .md-button--primary }
