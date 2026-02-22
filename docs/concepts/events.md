# Events

CSS Transitions, Keyframe Animations, and the Web Animations API all produce events during an animation's lifecycle. These events notify you when animations start, end, get interrupted, or change state — letting you chain animations in sequence, update the UI, or clean up resources.

How you receive these events depends on the engine:

**DOM-based engines** (Transitions, Keyframes) produce native browser events. You capture them by adding event attributes to your animated elements, then handle them in your update function. This mirrors how you'd handle click or input events in Elm.

**Subscription-based engine** (Sub) computes events internally by tracking animation progress on each frame. Because it processes all animations simultaneously, its `update` function returns a list of events — multiple animations can start, end, or change state in a single frame.

**Port-based engine** (WAAPI) receives events from the JavaScript Web Animations API via ports. The browser fires animation lifecycle events (Started, Ended, Changed, etc.), which JavaScript captures and routes to Elm through subscriptions. Control events like Paused, Resumed, and Restarted are generated when you call the corresponding control functions.


## Events by Engine

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


## Receiving Events

### DOM-Based Engines (Transitions, Keyframes)

Add event listeners to your animated elements with the `events` function, then handle the resulting messages in your update function:

??? example "View Source Code"

    === "Transitions"

        ```elm
        type Msg
            = GotTransitionMsg Transitions.AnimMsg
            | ...

        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                GotTransitionMsg animMsg ->
                    { model | animState = Transitions.update animMsg model.animState }
                        |> reactToEvent animMsg

        view : Model -> Html Msg
        view model =
            div 
                (Transitions.attributes "box" model.animState
                    ++ Transitions.events "box" GotTransitionMsg
                )
                [ text "Animated box" ]
        ```

    === "Keyframes"

        ```elm
        type Msg
            = GotKeyframeMsg Keyframes.AnimMsg
            | ...

        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                GotKeyframeMsg animMsg ->
                    { model | animState = Keyframes.update animMsg model.animState }
                        |> reactToEvent animMsg

        view : Model -> Html Msg
        view model =
            div 
                (Keyframes.attributes "box" model.animState
                    ++ Keyframes.events "box" GotKeyframeMsg
                )
                [ text "Animated box" ]
        ```


### Subscription-Based Engine (Sub)

Subscribe to animation frame updates. The `update` function returns both the new state and a list of events that occurred during that frame:

??? example "View Source Code"

    ```elm
    type Msg
        = GotSubMsg Sub.AnimMsg
        | ...

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotSubMsg subMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update subMsg model.animState
                in
                { model | animState = newAnimState }
                    |> reactToEvents events

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotSubMsg model.animState
    ```

Sub returns a list because multiple animations can change state on the same frame. Process them with a fold:

??? example "View Source Code"

    ```elm
    reactToEvents : List Sub.AnimMsg -> Model -> ( Model, Cmd Msg )
    reactToEvents events model =
        List.foldl reactToEvent ( model, Cmd.none ) events

    reactToEvent : Sub.AnimMsg -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
    reactToEvent event ( model, cmd ) =
        case event of
            Sub.Ended "fadeIn" ->
                ( model, Cmd.batch [ cmd, startSlideAnimation ] )

            _ ->
                ( model, cmd )
    ```


### Port-Based Engine (WAAPI)

Subscribe to receive events from the JavaScript companion. The `update` function returns both the new state and the event that triggered the update:

```elm
type Msg
    = GotWaapiMsg WAAPI.AnimMsg
    | ...

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotWaapiMsg waapiMsg ->
            let
                ( newAnimState, event ) =
                    WAAPI.update waapiMsg model.animState
            in
            { model | animState = newAnimState }
                |> reactToEvent event

subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState
```


## Reacting to Events

Once you're receiving events, you can react to them to build complex animation sequences and behaviors.


### Sequential Animations

Chain animations by starting the next one when the current ends:

```elm
reactToEvent : Transitions.AnimMsg -> Model -> ( Model, Cmd Msg )
reactToEvent event model =
    case event of
        Transitions.Ended "step1" ->
            let
                newAnimState =
                    Transitions.animate model.animState step2Animation
            in
            ( { model | animState = newAnimState }, Cmd.none )

        Transitions.Ended "step2" ->
            let
                newAnimState =
                    Transitions.animate model.animState step3Animation
            in
            ( { model | animState = newAnimState }, Cmd.none )

        _ ->
            ( model, Cmd.none )
```


### State Machine Transitions

Use events to drive state machine transitions:

```elm
type AnimationPhase
    = Idle
    | FadingIn
    | Visible
    | FadingOut

reactToEvent : Keyframes.AnimMsg -> Model -> ( Model, Cmd Msg )
reactToEvent event model =
    case ( event, model.phase ) of
        ( Keyframes.Ended "fadeIn", FadingIn ) ->
            ( { model | phase = Visible }, Cmd.none )

        ( Keyframes.Ended "fadeOut", FadingOut ) ->
            ( { model | phase = Idle }, Cmd.none )

        _ ->
            ( model, Cmd.none )
```


### Cleanup on Completion

Remove temporary state when animations finish:

```elm
reactToEvent : Keyframes.AnimMsg -> Model -> ( Model, Cmd Msg )
reactToEvent event model =
    case event of
        Keyframes.Ended "notification" ->
            ( { model | notification = Nothing }, Cmd.none )

        Keyframes.Cancelled "notification" ->
            ( { model | notification = Nothing }, Cmd.none )

        _ ->
            ( model, Cmd.none )
```


### Progress Tracking (WAAPI)

The WAAPI engine sends `Changed` events during animation, letting you track real-time progress:

```elm
reactToEvent : WAAPI.AnimMsg -> Model -> ( Model, Cmd Msg )
reactToEvent event model =
    case event of
        WAAPI.Changed _ _ { progress } ->
            ( { model | progressBar = progress }, Cmd.none )

        WAAPI.Ended _ _ _ ->
            ( { model | progressBar = 1.0 }, Cmd.none )

        _ ->
            ( model, Cmd.none )
```


## Event Reference

### Started

Fired when an animation begins playing. For CSS engines, this fires after any configured delay has elapsed.


### Ended

Fired when an animation completes naturally, reaching its end state.


### Cancelled

Fired when an animation is interrupted before completion:

- Another animation targets the same property
- The element is removed from the DOM
- `stop` or `reset` is called on the animation


### Run (Transitions only)

Fired when a transition starts running, after the delay but before property changes begin. Useful for tracking the exact moment a transition becomes "live."


### Iteration (Keyframes only)

Fired at the end of each iteration for looping animations. Useful for tracking progress through multi-iteration animations or triggering effects on each loop.


### Paused / Resumed (Sub & WAAPI only)

Fired when animations are paused or resumed via the `pause` and `resume` control functions. CSS engines don't support programmatic pause/resume, so they don't emit these events.


### Restarted (Sub & WAAPI only)

Fired when an animation is restarted from the beginning via the `restart` control function.


### Changed (WAAPI only)

Fired on each animation frame (~60fps) with the current progress value (0.0 to 1.0). Use sparingly — this fires frequently and is best for progress indicators or debugging rather than complex logic.


## Next Steps

Now that you understand how to react to animation events, explore the properties you can animate.

[Properties →](properties.md){ .md-button .md-button--primary }
