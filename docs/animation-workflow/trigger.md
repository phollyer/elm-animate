# Triggering Animations

Once you've [built an animation](build.md), you need to trigger it. Triggering is where the engine processes your configuration and computes the animation data, storing the results in AnimState ready for rendering.

## Two Ways to Trigger

| Function | State Tracking | Use When |
| -------- | -------------- | -------- |
| `animate` | Yes — engine tracks property values | Sequencing, redirecting, or controlling animations |
| `fireAndForget` | No — starts fresh each time | Simple one-shot animations |

With `animate`, you maintain an `AnimState` in your model that the engine updates. With `fireAndForget`, every call creates a new state — there's no continuity between triggers.

See [Engine Overview](../engines/overview.md#animate-vs-fireandforget) for a detailed comparison of when to use each.

## Using `animate`

The `animate` function processes your animation configuration and merges the computed data into your existing `AnimState`:

??? example "View Source Code"

    ```elm
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

    -- WAAPI (also requires the element ID)
    WAAPI.animate model.animState <|
        WAAPI.forElement "element-id" >> myAnimation
    ```

### WAAPI Returns a Cmd

WAAPI uses JavaScript ports, so `animate` returns both the updated state and a command. It also requires `forElement` to specify which DOM element to animate:

??? example "WAAPI Pattern"

    ```elm
    update msg model =
        case msg of
            GotStartAnimation ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.animate model.animState <|
                            WAAPI.forElement "header" 
                                >> fadeIn
                                >> slideDown
                                >> WAAPI.forElement "sidebar"
                                >> fadeIn
                                >> slideRight
                in
                ( { model | animState = newAnimState }
                , cmd
                )
    ```

    The "header" element will `fadeIn` and `slideDown`; the "sidebar" element will `fadeIn` and `slideRight`. The returned `cmd` sends these animations to JavaScript via ports.

## Using `fireAndForget`

For simple animations that don't need state tracking:

??? example "View Source Code"

    ```elm
    -- In init
    init _ =
        ( { animState = Keyframes.fireAndForget (fadeIn >> slideIn) }
        , Cmd.none
        )

    -- Or in update
    update msg model =
        case msg of
            GotShowBox ->
                ( { model | animState = Keyframes.fireAndForget (fadeIn >> slideIn) }
                , Cmd.none
                )
    ```

    Note that `fireAndForget` does not take an `AnimState` as a parameter.

## When to Trigger

### In Response to Events

Most animations trigger in response to user action events or application events. Trigger these in `update`:

??? example "View Source Code"

    ```elm
    update msg model =
        case msg of
            GotButtonClick ->
                ( { model | animState = Transitions.animate model.animState buttonPress }
                , Cmd.none
                )

            GotDataReceived data ->
                ( { model 
                    | data = data
                    , animState = Transitions.animate model.animState dataFadeIn 
                  }
                , Cmd.none
                )
    ```

### On Page Load

To animate immediately when the page loads, trigger in `init` using **Keyframes**, **Sub**, or **WAAPI**:

??? example "View Source Code"

    === "Keyframes"

        ```elm
        init _ =
            ( { animState = Keyframes.fireAndForget fadeIn }, Cmd.none )
        ```

    === "Sub"

        ```elm
        init _ =
            let
                animState =
                    Sub.init
                        [ Opacity.init 0 ]
            in
            ( { animState = Sub.animate animState fadeIn }, Cmd.none )
        ```

    === "WAAPI"

        ```elm
        init _ =
            let
                ( animState, cmd ) =
                    WAAPI.fireAndForget waapiCommand <|
                        WAAPI.forElement "element-id" >> fadeIn
            in
            ( { animState = animState }, cmd )
        ```

!!! warning "CSS Transitions can't animate on page load"
    CSS Transitions require a state change between renders. Triggering in `init` means no state change — the element appears at the final state immediately because the browser has no initial `transition` state to animate from. To animate with Transitions on page load, trigger in a subsequent message after the first render.

### Not in `view`

??? warning "Why not?"
    You might be tempted to call `fireAndForget` directly in your view:

    ```elm
    view model =
        let
            boxAnimState = Transitions.fireAndForget (fadeIn >> slideIn)
        in
        ...
    ```

    This works, but the builder functions run on **every render**, creating unnecessary GC pressure. The view should be a pure function of model state. Prefer triggering in `update` or `init`.

## Triggering Mid-Flight

What happens when you call `animate` while an animation is already running? See [Mid-Flight Interruptions](../concepts/interruptions.md) for how each engine handles this.

## Next Steps

Now that you've triggered an animation, you need to apply it to your elements.

[Apply Animations →](apply.md){ .md-button .md-button--primary }
