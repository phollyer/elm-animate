# React

After [triggering](trigger.md) an animation, you'll often want to react to its lifecycle - chain a follow-up animation when one ends, update UI state, or clean up resources.

## The Pattern

All engines share the same approach: call `update` with the animation message, get back the new state and an event to react to:

??? example "View Source Code"

    === "Transition"

        ```elm
        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                GotAnimMsg animMsg ->
                    let
                        ( newAnimState, event ) =
                            Transition.update animMsg model.animState
                    in
                    reactToEvent event { model | animState = newAnimState }
        ```

    === "Keyframe"

        ```elm
        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                GotAnimMsg animMsg ->
                    let
                        ( newAnimState, event ) =
                            Keyframe.update animMsg model.animState
                    in
                    reactToEvent event { model | animState = newAnimState }
        ```

    === "Sub (returns List)"

        ```elm
        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
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
        **Sub returns a list** of events (multiple animations can change state per frame).

    === "WAAPI"

        ```elm
        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                GotAnimMsg animMsg ->
                    let
                        ( newAnimState, event ) =
                            WAAPI.update animMsg model.animState
                    in
                    reactToEvent event { model | animState = newAnimState }
        ```


## Receiving Events

How you receive events depends on the engine - DOM events vs subscriptions:

| Engine | Event Source | Setup |
| ------ | ------------ | ----- |
| Transition | DOM events | Add `events` to animated elements |
| Keyframe | DOM events | Add `events` to animated elements |
| Sub | Internal tracking | Add `subscriptions` to your app |
| WAAPI | JavaScript ports | Add `subscriptions` to your app |


### DOM-Based Setup (Transition, Keyframe)

Add the `events` helper to your animated elements:

??? example "View Source Code"

    === "Transition"

        ```elm
        view model =
            div 
                (Transition.attributes "box" model.animState
                    ++ Transition.events "box" GotAnimMsg
                )
                [ text "Animated box" ]
        ```


    === "Keyframe"

        ```elm
        view model =
            div 
                (Keyframe.attributes "box" model.animState
                    ++ Keyframe.events "box" GotAnimMsg
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


## Events by Engine

### Native Events

These events come directly from the underlying technology - CSS DOM events or Web Animations API callbacks:

| Event | Transition | Keyframe | WAAPI |
| ----- | :---------: | :-------: | :---: |
| Run | ✓ | | |
| Started | ✓ | ✓ | |
| Ended | ✓ | ✓ | ✓ |
| Cancelled | ✓ | ✓ | ✓ |
| Iteration | | ✓ | |


### Engine-Generated Events

These events are generated internally by the engine:

| Event | Keyframe | Sub | WAAPI |
| ----- | :-------: | :-: | :---: |
| Started | | ✓ | ✓ |
| Ended | | ✓ | |
| Cancelled | | ✓ | |
| Paused | ✓ | ✓ | ✓ |
| Resumed | ✓ | ✓ | ✓ |
| Restarted | ✓ | ✓ | ✓ |
| Iteration | | ✓ | ✓ |
| Progress | | ✓ | ✓ |


??? info "Full Event Table"

    | Event | Transition | Keyframe | Sub | WAAPI |
    | ----- | :---------: | :-------: | :-: | :---: |
    | Run | ✓ | | | |
    | Started | ✓ | ✓ | ✓ | ✓ |
    | Ended | ✓ | ✓ | ✓ | ✓ |
    | Cancelled | ✓ | ✓ | ✓ | ✓ |
    | Iteration | | ✓ | ✓ | ✓ |
    | Paused | | ✓ | ✓ | ✓ |
    | Resumed | | ✓ | ✓ | ✓ |
    | Restarted | | ✓ | ✓ | ✓ |
    | Progress | | | ✓ | ✓ |


## Event Reference

### Run

Fired when a transition starts running, before any delay. Useful for tracking the exact moment a transition becomes "live."

### Started

Fired when an animation begins playing. For CSS engines, this fires after any configured delay has elapsed.


### Ended

Fired when an animation completes naturally, reaching its end state.


### Cancelled

Fired when an animation is interrupted before completion:

- Another animation targets the same property
- The element is removed from the DOM
- `stop` or `reset` is called on the animation


### Iteration

Fired at the end of each iteration for looping animations. Useful for tracking progress through multi-iteration animations or triggering effects on each loop.


### Paused

Fired when animations are paused with the `pause` control function.

### Resumed

Fired when animations are resumed with the `resume` control function.


### Restarted

Fired when an animation is restarted from the beginning with the `restart` control function.


### Progress

Fired on each animation frame (~60fps) with the current progress value (0.0 to 1.0). Use sparingly - this fires frequently and is intended for progress indicators or debugging rather than complex logic.


## Next Steps

Now that you understand the full animation workflow, learn more about the Engines and what they can do.

[Engines Overview →](../engines/overview.md){ .md-button .md-button--primary }
