# Triggering Animations

Once you've [built an animation](build.md), you need to trigger it. This is where your animation definition gets added to the engine's `AnimState`, making it available for rendering.

## Two Ways to Trigger

There are two functions for triggering animations:

| Function | Returns | Use When |
| -------- | ------- | -------- |
| `animate` | Updated `AnimState` (+ `Cmd` for WAAPI) | You need state tracking or control functions |
| `fireAndForget` | `AnimState` (+ `Cmd` for WAAPI) | Simple one-shot animations with no state tracking |

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

    -- WAAPI (returns Cmd too)
    WAAPI.animate model.animState myAnimation
    ```

### WAAPI Returns a Cmd

The WAAPI Engine uses JavaScript ports to apply animations, so `animate` returns both the updated state and a command that goes off to JS:

??? example "WAAPI Pattern"

    ```elm
    update msg model =
        case msg of
            GotStartAnimation ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.animate model.animState fadeIn
                in
                ( { model | animState = newAnimState }
                , cmd
                )
    ```

## Using `fireAndForget`

For simple, one-shot animations that don't need state tracking:

??? example "View Source Code"

    ```elm
    init _ =
        ( { animState = Transitions.fireAndForget fadeIn }
        , Cmd.none
        )
    ```

    Fire-and-forget is ideal for:

    - Entry animations that run once on page load
    - Simple hover effects
    - Animations where you don't need control functions (pause, stop, etc.)

### When to Choose Each

You can use `animate` for all of your animations if you choose, but sometimes it's simpler and quicker to use `fireAndForget`.

| Scenario | Transitions | Keyframes | Sub | WAAPI |
| -------- | :---------: | :-------: | :-: | :---: |
| Animation runs once, no control needed | `fireAndForget` | `fireAndForget` | `animate` | `fireAndForget` |
| Stop/reset controls | `animate` | `animate` | `animate` | `animate` |
| Pause/resume controls | | `animate` | `animate` | `animate` |
| Chaining animations with minimal setup | `animate` | `animate` | `animate` | `animate` |
| Redirecting animations mid-flight | `animate`/`fireAndForget` | | `animate` | `animate` |
| Simple entry animations | `fireAndForget` | `fireAndForget` | `animate` | `fireAndForget` |

!!! note "Chaining with `fireAndForget`"
    You can chain animations with `fireAndForget`, but each animation needs explicit `from` and `to` values since there's no state continuity between calls. With `animate`, the engine tracks where the previous animation ended, so you only need to specify the `to` value.

!!! note "Redirecting mid-flight"
    When you call `animate` while an animation is already running, the engine knows the element's current position and can smoothly redirect to the new target. With `fireAndForget`, there's no state tracking - you'd need to manually track positions yourself.

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
                WAAPI.fireAndForget waapiPort fadeIn
        in
        ( { animState = animState }, cmd )
    ```

!!! warning "CSS Transitions can't animate on init"
    CSS Transitions require a state change between renders. Setting initial state and triggering animation in the same `init` means no transition - the element just appears at the final state. To animate with Transitions on page load, trigger in a subsequent message (e.g., after the first view renders).

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
