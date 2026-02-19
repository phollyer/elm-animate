# Triggering Animations

Once you've [built an animation](build.md), you need to trigger it. This is where your animation definition gets added to the engine's `AnimState`, making it available for rendering.

## Two Ways to Trigger

There are two functions for triggering animations:

- `animate` - for state tracked animations, requires state updates in your `update` function
- `fireAndForget` - for non-state tracked animations, no state update is required in your `update` function

The main difference between the two then, is that state tracked animations using `animate` need to have their state updated in your `update` function. `fireAndForget` animations don't because they always start with an empty state.

## Using `animate`

The `animate` function adds animations to your existing `AnimState`:

??? example "View Source Code"

    ```elm
    type Msg
        = GotStartAnimation

    update msg model =
        case msg of
            GotStartAnimation ->
                ( { model | animState = Transitions.animate model.animState fadeIn }
                , Cmd.none
                )
    ```

    The pattern is the same across all engines:

    ```elm
    -- CSS Transitions
    Transitions.animate model.animState myAnimation

    -- CSS Keyframes
    Keyframes.animate model.animState myAnimation

    -- Sub
    Sub.animate model.animState myAnimation

    -- WAAPI (also requires the element ID to apply the animation to)
    WAAPI.animate model.animState <|
        WAAPI.forElement "element-id" >> myAnimation
    ```

### WAAPI Returns a Cmd

The WAAPI Engine uses JavaScript ports to apply animations, so `animate` returns both the updated state and a command that goes off to JS. Additionally, WAAPI requires `forElement` to specify the target element ID — this is how the JavaScript side knows which DOM element to animate:

??? example "WAAPI Pattern"

    ```elm
    update msg model =
        case msg of
            GotStartAnimation ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.animate model.animState <|
                            WAAPI.forElement "element-id" 
                                >> myAnimation
                                >> WAAPI.forElement "other-element-id"
                                >> myOtherAnimation
                in
                ( { model | animState = newAnimState }
                , cmd
                )
    ```

## Using `fireAndForget`

For simple, one-shot animations that don't need state tracking:

??? example "View Source Code"

    ```elm
    -- Trigger in init for entry animations
    init _ =
        ( { animState = 
                Keyframes.fireAndForget <|
                    fadeIn >> slideIn
          }
        , Cmd.none
        )

    -- Or trigger in update in response to events
    update msg model =
        case msg of
            GotShowBox ->
                ( { model 
                    | animState = 
                        Keyframes.fireAndForget <|
                            fadeIn >> slideIn
                  }
                , Cmd.none
                )
    ```

    Fire-and-forget is ideal for:

    - Entry animations that run once on page load
    - Simple hover effects
    - Animations where you don't need control functions (pause, stop, etc.)

??? warning "Avoid triggering in your view"
    You might be tempted to call `fireAndForget` directly in your view function:

    ```elm
    -- Works, but not recommended
    view model =
        let
            boxAnimState =
                Transitions.fireAndForget <|
                    fadeIn >> slideIn
        in
        ...
    ```

    This works — the VDOM prevents actual DOM thrashing since the styles don't change. However, the builder functions and state allocation run on **every render**, creating unnecessary GC pressure. More importantly, it's un-idiomatic Elm: the view should be a pure function of model state, not a place to compute state.

    For truly trivial cases the overhead is negligible, but prefer triggering in `init` or `update` and storing the state in your model.

### When to Choose Each

You can use `animate` for all of your animations if you choose, but sometimes it's simpler and quicker to use `fireAndForget`.

| Scenario | Transitions | Keyframes | Sub | WAAPI |
| -------- | :---------: | :-------: | :-: | :---: |
| Animation runs once, no control needed | `fireAndForget` | `fireAndForget` | `animate` | `fireAndForget` |
| Simple entry animations | `fireAndForget` | `fireAndForget` | `animate` | `fireAndForget` |
| Stop/reset controls | `animate` | `animate` | `animate` | `animate` |
| Pause/resume controls | | `animate` | `animate` | `animate` |
| Sequencing animations | `animate` | `animate` | `animate` | `animate` |
| Redirecting animations mid-flight | `animate`/`fireAndForget` | | `animate` | `animate` |

## Sequencing Animations

Sequencing animations — so each begins where the previous ended — is easier with `animate` because the engine tracks state automatically.

### With `animate` (State Tracked)

The engine remembers where each animation ended, using that as the starting point for the next:

??? example "Cumulative Movement"

    ```elm
    -- Each call moves 100px further from the *current* position
    moveRight : AnimBuilder -> AnimBuilder
    moveRight =
        Translate.for "box"
            >> Translate.toX 100  -- No 'from' needed
            >> Translate.build

    -- First trigger:  0 → 100
    -- Second trigger: 100 → 200  
    -- Third trigger:  200 → 300
    ```

    Because state is tracked, you only need to specify `to`. The `from` value comes from the previous end state. Override with an explicit `from` only if you want to break the sequence.

### With `fireAndForget` (No State)

Each animation starts fresh — you must specify both `from` and `to`:

??? example "Explicit Positions"

    ```elm
    -- Must track positions yourself
    moveRight : Float -> AnimBuilder -> AnimBuilder
    moveRight currentX =
        Translate.for "box"
            >> Translate.fromX currentX
            >> Translate.toX (currentX + 100)
            >> Translate.build
    ```

    Without state tracking, there's no "previous position" to reference.

## Redirecting Mid-Flight

With **Transitions**, **Sub**, and **WAAPI**, calling `animate` while an animation is already running smoothly redirects to the new target — the engine knows the element's current position. With `fireAndForget`, you'd need to manually track positions yourself.

**Keyframes** don't support mid-flight redirection — once a keyframe animation starts, it runs to completion.

## When to Trigger

Animations are typically triggered in the `update` function in response to messages:

??? example "Common Trigger Points"

    ```elm
    update msg model =
        case msg of
            -- User interaction
            GotButtonClick ->
                ( { model | animState = Transitions.animate model.animState buttonPress }
                , Cmd.none
                )

            -- Page events
            GotPageLoaded ->
                ( { model | animState = Transitions.animate model.animState pageEntrance }
                , Cmd.none
                )

            -- External data
            GotDataReceived data ->
                ( { model 
                    | data = data
                    , animState = Transitions.animate model.animState dataFadeIn 
                  }
                , Cmd.none
                )
    ```

### Triggering in `init`

For animations that should start immediately, use **Keyframes**, **Sub**, or **WAAPI** - these engines define their own animation frames and don't rely on CSS state changes:

??? example "Init Triggering"

    ```elm
    -- Keyframes - defines its own keyframes
    init _ =
        ( { animState = Keyframes.fireAndForget fadeIn }
        , Cmd.none
        )

    -- Sub - drives animation frame-by-frame
    init _ =
        ( { animState = Sub.animate Sub.init fadeIn }
        , Cmd.none
        )

    -- WAAPI - applies keyframes via JS
    init _ =
        let
            ( animState, cmd ) =
                WAAPI.fireAndForget waapiCommand fadeIn
        in
        ( { animState = animState }, cmd )
    ```

!!! warning "CSS Transitions can't animate on init"
    CSS Transitions require a state change between renders. Setting initial state and triggering an animation in the same `init` means no transition - the element just appears at the final state. To animate with Transitions on page load, trigger in a subsequent message (e.g., after the first view renders).

!!! warning "Avoid defining all animations upfront"
    You might be tempted to define every animation for your page in a single `fireAndForget` call in `init`, then selectively apply them in your view by choosing which groups to render. While this works for CSS-based engines (Transitions, Keyframes), it has drawbacks:

    - Allocates memory for animations that may never run
    - Sub engine calculates frames for all groups, even unused ones
    - WAAPI fires JS commands immediately — elements must already exist
    - Makes it less clear *when* animations are meant to trigger

    Instead, trigger animations when they're needed.

## Triggering Multiple Animations

Compose animations together before triggering:

??? example "Multiple Animations"

    ```elm
    -- Compose, then trigger once
    update msg model =
        case msg of
            GotShowAll ->
                ( { model | animState = 
                        Transitions.animate model.animState <|
                            fadeIn "header"
                                >> slideIn "sidebar"
                                >> fadeIn "content"
                  }
                , Cmd.none
                )
    ```

Or trigger sequentially with callbacks:

??? example "Sequential Triggering"

    ```elm
    update msg model =
        case msg of
            GotStartSequence ->
                ( { model | animState = Transitions.animate model.animState (fadeIn "header") }
                , Cmd.none
                )

            GotAnimationMsg (Transitions.Ended "header") ->
                ( { model | animState = Transitions.animate model.animState (slideIn "sidebar") }
                , Cmd.none
                )
    ```

## Next Steps

Now that you've triggered an animation, you need to apply it to your elements.

[Apply Animations →](apply.md){ .md-button .md-button--primary }
