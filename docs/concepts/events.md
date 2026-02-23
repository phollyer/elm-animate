# Events

Animation engines produce lifecycle events when animations start, end, get interrupted, or change state. These events let you chain animations, update the UI, or clean up resources.

All engines share the same pattern: call `update` with the animation message, get back a tuple of new state and event(s) to react to:

??? example "View Source Code"

    ```elm
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Engine.update animMsg model.animState
                in
                reactToEvent event { model | animState = newAnimState }
    ```

The only difference is **Sub returns a list** of events (multiple animations can change state per frame), while others return a single event.


## Events by Engine

### Native Events

These events come directly from the underlying technology - CSS DOM events or Web Animations API callbacks:

| Event | Transitions | Keyframes | WAAPI |
| ----- | :---------: | :-------: | :---: |
| Started | ✓ | ✓ | ✓ |
| Ended | ✓ | ✓ | ✓ |
| Cancelled | ✓ | ✓ | ✓ |
| Run | ✓ | | |
| Iteration | | ✓ | |


### Engine-Generated Events

These events are generated internally by the engine. The Sub engine generates all its events this way, while Keyframes and WAAPI generate control-related events when you call `pause`, `resume`, or `restart`:

| Event | Keyframes | Sub | WAAPI |
| ----- | :-------: | :-: | :---: |
| Started | | ✓ | |
| Ended | | ✓ | |
| Cancelled | | ✓ | |
| Paused | ✓* | ✓ | ✓ |
| Resumed | ✓* | ✓ | ✓ |
| Restarted | ✓* | ✓ | ✓ |
| Changed | | | ✓ |

\* To generate these events, use `pauseCmd`, `resumeCmd` or `restartCmd`. See [Keyframe Event Variants](../engines/keyframes.md#event-variants) for more info.

## Receiving Events

How you receive events depends on the engine - DOM events vs subscriptions:

| Engine | Event Source | Setup |
| ------ | ------------ | ----- |
| Transitions | DOM events | Add `events` to animated elements |
| Keyframes | DOM events | Add `events` to animated elements |
| Sub | Internal tracking | Add `subscriptions` to your app |
| WAAPI | JavaScript ports | Add `subscriptions` to your app |


### DOM-Based Setup (Transitions, Keyframes)

Add the `events` helper to your animated elements:

??? example "View Source Code"

    === "Transitions"

        ```elm
        view model =
            div 
                (Transitions.attributes "box" model.animState
                    ++ Transitions.events "box" GotAnimMsg
                )
                [ text "Animated box" ]
        ```


    === "Keyframes"

        ```elm
        view model =
            div 
                (Keyframes.attributes "box" model.animState
                    ++ Keyframes.events "box" GotAnimMsg
                )
                [ text "Animated box" ]
        ```


### Subscription-Based Setup (Sub, WAAPI)

Wire up subscriptions:

??? example "View Source Code"

    === "Sub"
        ```elm
        subscriptions : Model -> Sub Msg
        subscriptions model =
            Sub.subscriptions GotAnimMsg model.animState
        ```

    === "WAAPI"
        ```elm
        subscriptions : Model -> Sub Msg
        subscriptions model =
            WAAPI.subscriptions GotAnimMsg model.animState
        ```


### Handling the Update

All engines use the same update pattern. The only difference is Sub returns `List AnimEvent`:

??? example "View Source Code"

    === "Transitions / Keyframes / WAAPI"

        ```elm
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Engine.update animMsg model.animState
                in
                reactToEvent event { model | animState = newAnimState }
        ```

    === "Sub (returns List)"

        ```elm
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update animMsg model.animState

                    applyEvent event ( m, cmd ) =
                        let
                            ( newModel, newCmd ) =
                                reactToEvent event m
                        in
                        ( newModel, Cmd.batch [ cmd, newCmd ] )
                in
                List.foldl applyEvent ( { model | animState = newAnimState }, Cmd.none ) events
        ```


## Reacting to Events

Pattern match on the event to build complex animation sequences and behaviors.


### Sequential Animations

Chain animations by starting the next one when the current ends:

??? example "View Source Code"

    ```elm
    reactToEvent : Transitions.AnimEvent -> Model -> ( Model, Cmd Msg )
    reactToEvent event model =
        case event of
            Transitions.Ended "step1" ->
                ( { model | animState = Transitions.animate model.animState step2Animation }
                , Cmd.none
                )

            Transitions.Ended "step2" ->
                ( { model | animState = Transitions.animate model.animState step3Animation }
                , Cmd.none
                )

            _ ->
                ( model, Cmd.none )
    ```


### Cleanup on Completion

Remove temporary state when animations finish:

??? example "View Source Code"

    ```elm
    reactToEvent : Keyframes.AnimEvent -> Model -> ( Model, Cmd Msg )
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

??? example "View Source Code"

    ```elm
    reactToEvent : WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
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

Fired when a transition starts running, before any delay. Useful for tracking the exact moment a transition becomes "live."


### Iteration (Keyframes only)

Fired at the end of each iteration for looping animations. Useful for tracking progress through multi-iteration animations or triggering effects on each loop.


### Paused / Resumed

Fired when animations are paused or resumed via the `pause` and `resume` control functions.

- **Sub & WAAPI**: Events fire automatically
- **Keyframes**: Use `pauseCmd` / `resumeCmd` to receive events through `update`
- **Transitions**: Cannot be paused/resumed once started

??? example "View Source Code"

    ```elm
    -- Keyframes: use pauseCmd to get the event
    Pause ->
        let
            ( newState, cmd ) =
                Keyframes.pauseCmd "box" GotAnimMsg model.animState
        in
        ( { model | animState = newState }, cmd )

    -- The Paused event flows through update normally
    ```


### Restarted

Fired when an animation is restarted from the beginning via the `restart` control function.

- **Sub & WAAPI**: Events fire automatically
- **Keyframes**: Use `restartCmd` to receive events through `update`
- **Transitions**: Cannot be restarted/replayed without a state change, see [How Transitions Work](../engines/transitions.md#how-css-transitions-work)


### Changed (WAAPI only)

Fired on each animation frame (~60fps) with the current progress value (0.0 to 1.0). Use sparingly — this fires frequently and is best for progress indicators or debugging rather than complex logic.


## Next Steps

Now that you understand how to react to animation events, explore the properties you can animate.

[Properties →](properties.md){ .md-button .md-button--primary }
