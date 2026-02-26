# Triggering Animations

Once you've [built](build.md), [initialized](init.md) and [rendered](render.md) your animation you need to trigger it. Triggering is where the engine processes your configuration and computes the animation data, storing the results in `AnimState` ready for rendering.

## Two Ways to Trigger

| Function | State Tracking | Use When |
| -------- | -------------- | -------- |
| `animate` | Yes — engine tracks property values | Sequencing, redirecting, or controlling animations |
| `fireAndForget` | No — starts fresh each time | Simple one-shot animations |

With `animate`, you maintain an `AnimState` in your model that the engine updates. With `fireAndForget`, every call creates a new state — there's no continuity between triggers.

See [Engine Overview](../engines/overview.md#animate-vs-fireandforget) for a detailed comparison of when to use each.

## Using `animate`

The `animate` function processes your animation configuration and merges the computed data into your existing `AnimState`. The pattern is the same across all engines:

??? example "View Source Code"

    Pattern: `Engine.animate animState (\ builder -> builder)`

    === "Transitions"

        ```elm
        ( { model | animState = Transitions.animate model.animState fadeIn }
        , Cmd.none
        )
        ```

    === "Keyframes"

        ```elm
        ( { model | animState = Keyframes.animate model.animState fadeIn }
        , Cmd.none
        )
        ```

    === "Sub"

        ```elm
        ( { model | animState = Sub.animate model.animState fadeIn }
        , Cmd.none
        )
        ```

    === "WAAPI"

        ```elm
        let
            ( newAnimState, cmd ) =
                WAAPI.animate model.animState fadeIn
        in
        ( { model | animState = newAnimState }
        , cmd
        )
        ```

        WAAPI uses JavaScript ports, so `animate` returns both the updated state and a `cmd` that sends the animation data to JS.


## Using `fireAndForget`

For simple animations that don't need state tracking:

??? example "View Source Code"

    === "Transitions"

        ```elm
        update msg model =
            case msg of
                GotShowBox ->
                    ( { model 
                      | animState =
                          Transitions.fireAndForget <|
                              fadeIn >> slideIn
                      }
                    , Cmd.none
                    )
        ```

    === "Keyframes"

        ```elm
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

    === "WAAPI"

        ```elm
        update msg model =
            case msg of
                GotShowBox ->
                    let
                        ( animState, cmd ) =
                            WAAPI.fireAndForget waapiCommand <|
                                fadeIn >> slideIn
                    in
                    ( { model | animState = animState }, cmd )
        ```

    There is no Sub example, because being a subscription based Engine it is naturally state-based so `fireAndForget` just wouldn't make sense.

Note that `fireAndForget` does not take an `AnimState` as a parameter — it creates a fresh state each time.

## When to Trigger

### In Response to Events

Most animations trigger in response to user action events or application events. Trigger these in `update`:

??? example "View Source Code"

    === "Transitions"

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

    === "Keyframes"

        ```elm
        update msg model =
            case msg of
                GotButtonClick ->
                    ( { model | animState = Keyframes.animate model.animState buttonPress }
                    , Cmd.none
                    )

                GotDataReceived data ->
                    ( { model 
                        | data = data
                        , animState = Keyframes.animate model.animState dataFadeIn 
                      }
                    , Cmd.none
                    )
        ```

    === "Sub"

        ```elm
        update msg model =
            case msg of
                GotButtonClick ->
                    ( { model | animState = Sub.animate model.animState buttonPress }
                    , Cmd.none
                    )

                GotDataReceived data ->
                    ( { model 
                        | data = data
                        , animState = Sub.animate model.animState dataFadeIn 
                      }
                    , Cmd.none
                    )
        ```

    === "WAAPI"

        ```elm
        update msg model =
            case msg of
                GotButtonClick ->
                    let
                        ( newAnimState, cmd ) =
                            WAAPI.animate model.animState <|
                                WAAPI.forElement "button" >> buttonPress
                    in
                    ( { model | animState = newAnimState }, cmd )

                GotDataReceived data ->
                    let
                        ( newAnimState, cmd ) =
                            WAAPI.animate model.animState <|
                                WAAPI.forElement "data-container" >> dataFadeIn
                    in
                    ( { model | data = data, animState = newAnimState }, cmd )
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

        For WAAPI, use `awaitLoad` with the `Loaded` event to avoid flash:

        ```elm
        init _ =
            let
                animState =
                    WAAPI.init waapiCommand waapiEvent
                        [ WAAPI.forElement "element-id"
                            >> Opacity.init "fadeAnim" 0
                        ]
            in
            ( { animState = animState }
            , WAAPI.awaitLoad animState
            )

        update msg model =
            case msg of
                GotWaapiMsg subMsg ->
                    let
                        ( animState, event ) =
                            WAAPI.update subMsg model.animState
                    in
                    case event of
                        WAAPI.Loaded ->
                            -- JS is ready, trigger onload animations

                        _ ->
                            ( { model | animState = animState }, Cmd.none )
        ```

        The `Loaded` event signals that JavaScript is ready to receive animation commands, making it safe to animate without any flash. See [WAAPI Onload Animations](../engines/waapi.md#onload-animations) for details.

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

Now that you understand the animation workflow, learn how to control your animations.

[Controlling Animations →](../concepts/controlling-animations.md){ .md-button .md-button--primary }
