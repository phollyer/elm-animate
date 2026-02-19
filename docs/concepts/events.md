# Events

Animation engines emit lifecycle events that let you react to state changes — starting the next animation in a sequence, updating UI, or cleaning up resources.

## Events by Engine

Each engine provides different events based on its capabilities:

| Event | Transitions | Keyframes | Sub | WAAPI |
| ----- | :---------: | :-------: | :-: | :---: |
| Started | ✓ | ✓ | ✓ | ✓ |
| Ended | ✓ | ✓ | ✓ | ✓ |
| Cancelled | ✓ | ✓ | ✓ | ✓ |
| Run | ✓ | | | |
| Iteration | | ✓ | | |
| Paused | | | ✓ | ✓ |
| Resumed | | | ✓ | ✓ |
| Restarted | | | ✓ | ✓ |

## Handling Events

### CSS Engines (Transitions & Keyframes)

CSS engines provide events via HTML event attributes. Add them to the element being animated:

```elm
view model =
    div 
        (Transitions.render model.animState "box"
            ++ Transitions.events "box" GotAnimEvent
        )
        [ text "Animated box" ]
```

Handle events in your update function:

```elm
type Msg
    = GotAnimEvent Transitions.AnimEvent
    | ...

update msg model =
    case msg of
        GotAnimEvent event ->
            case event of
                Transitions.Ended "box" ->
                    -- Animation finished, trigger next one
                    ( { model | animState = Transitions.animate model.animState nextAnimation }
                    , Cmd.none
                    )

                Transitions.Cancelled "box" ->
                    -- Handle interruption
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )
```

Use `handleEvent` to keep the `AnimState` in sync:

```elm
GotAnimEvent event ->
    ( { model | animState = Transitions.handleEvent event model.animState }
    , Cmd.none
    )
```

### Sub Engine

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

### WAAPI Engine

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
