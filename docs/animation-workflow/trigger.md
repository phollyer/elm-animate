# Triggering Animations

Once you've [built](build.md), [initialized](init.md) and setup your view ready to [render](render.md) your animation - you next need to trigger it. Triggering is where the engine processes your configuration and computes the animation data, storing the results in `AnimState` ready for rendering.

## Two Ways to Trigger

| Function | State Tracking | Use When |
| -------- | -------------- | -------- |
| `animate` | Yes — engine tracks property values | Sequencing, redirecting, or controlling animations |
| `fireAndForget` | No — starts fresh each time | Simple one-shot animations |

With `animate`, you maintain an `AnimState` in your model that the engine updates in your `update` function.

With `fireAndForget`, every call creates a new state — there's no continuity between triggers, and nothing to add to `update`.

See [Engine Overview](../engines/overview.md#animate-vs-fireandforget) for a detailed comparison of when to use each.

## Using `animate`

The `animate` function processes your animation configuration and merges the computed data into your existing `AnimState`. The pattern is the same across all engines:

??? example "View Source Code"

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
        ( { model | animState = Transitions.fireAndForget fadeIn }
        , Cmd.none
        )
        ```

    === "Keyframes"

        ```elm
        ( { model | animState = Keyframes.fireAndForget fadeIn }
        , Cmd.none
        )
        ```

    === "WAAPI"

        ```elm
        ( model
        , WAAPI.fireAndForget waapiCommand fadeIn
        )
        ```

    There is no Sub example because being a subscription based Engine, it is naturally state-based so `fireAndForget` just wouldn't make sense, therefore the Sub Engine does not have a `fireAndForget` option.

Note that `fireAndForget` does not take an `AnimState` as a parameter — it creates a fresh state each time, or in the case of WAAPI - a fresh `Cmd`.

The benefit of `fireAndForget` is that you don't 'pollute' your `update` function with animation messages required to update the Engine state.

The drawback for **CSS engines** is that `animState` can only handle a single `fireAndForget` call at a time. Each call creates a fresh state, overwriting previous styles - which may not be what you want if animations are still running. To solve this, you can use a different `AnimState` for each element and the animations that run on it.

**WAAPI** doesn't have this limitation. The JavaScript runtime tracks animations per-element and per-property, so multiple concurrent `fireAndForget` calls work fine - as long as they target different elements or different properties. If you animate the same property on the same element, the new animation replaces the running one.

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
                        , dataAnimState = Transitions.fireAndForget dataFadeIn 
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
                        , dataAnimState = Keyframes.fireAndForget dataFadeIn 
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
                            WAAPI.animate model.animState buttonPress
                    in
                    ( { model | animState = newAnimState }, cmd )

                GotDataReceived data ->
                    ( { model | data = data }
                    , WAAPI.fireAndForget waapiCommand dataFadeIn
                    )
        ```

### On Page Load

To animate immediately when the page loads, you need to trigger in `init`. For some engines this is a simple process, for others not so:

??? example "View Source Code"

    === "Transitions"
        
        !!! warning "CSS Transitions can't animate on page load"
            CSS Transitions require a state change between renders. Triggering in `init` means no state change — the element appears at the final state immediately because the browser has no initial `transition` state to animate from. To animate with Transitions on page load, trigger in a subsequent message after the first render.

        ```elm
        init _ =
            ( { animState = Transitions.init [ Opacity.init "boxAnim" 0 ] }
            , Process.sleep 50
                |> Task.perform (always StartFadeIn)
            )

        update msg model =
            case msg of
                StartFadeIn ->
                    ( { model | animState = Transitions.fireAndForget fadeIn }
                    , Cmd.none
                    )
                
                ...
        ```

        The initial Property values are used in the view for first render, then 50ms after first render the animation will begin.

        This works, but it's not ideal.

    === "Keyframes"

        With `animate`:

        ```elm
        init _ =
            let
                animState =
                    Keyframes.init [ Opacity.init "boxAnim" 0 ]
            in
            ( { animState = Keyframes.animate animState fadeIn }, Cmd.none )
        ```

        And with `fireAndForget`:

        ```elm
        init _ =
            ( { animState = Keyframes.fireAndForget fadeIn }, Cmd.none )
        ```

        Both work fine, the `@keyframes` rules are added to the DOM on first render.

    === "Sub"

        With `animate`:

        ```elm
        init _ =
            let
                animState =
                    Sub.init [ Opacity.init "boxAnim" 0 ]
            in
            ( { animState = Sub.animate animState fadeIn }, Cmd.none )
        ```

        This works fine. The initial property values are used for first render, and the animation starts in the first update loop.

    === "WAAPI"

        With `animate`:

        ```elm
        init _ =
            let
                animState =
                    WAAPI.init waapiCommand waapiEvent <|
                        [ Opacity.init "box" 0 ]
                
                ( newAnimState, cmd ) =
                    WAAPI.animate animState fadeIn
            in
            ( { animState = newAnimState }, cmd )
        ```

        And with `fireAndForget`:

        ```elm
        init _ =
            ( { animState =
                    WAAPI.init waapiCommand waapiEvent <|
                        [ Opacity.init "box" 0 ]
              }
              , WAAPI.fireAndForget waapiCommand fadeIn
            )
        ```

        Both work fine. The initial property values are used for first render, and the animation command is processed immediately after.


### Not in `view`

??? warning "Why not?"
    You might be tempted to call `fireAndForget` directly in your view:

    ```elm
    view model =
        let
            boxAnimState = Transitions.fireAndForget fadeIn
        in
        div
            []
            [ div
                (Transitions.attributes "boxAnim" boxAnimState)
                [ text "I'm animated wrongly" ]
            ]
    ```

    This works, but the builder functions run on **every render**, creating unnecessary GC pressure. The view should be a pure function of model state. Prefer triggering in `update` or `init`.

## Triggering Mid-Flight

What happens when you trigger an animation while another animation is already running on the same element? See [Mid-Flight Interruptions](../concepts/interruptions.md) for how each engine handles this.

## Next Steps

Now that you understand the animation workflow, learn how to control your animations.

[Controlling Animations →](../concepts/controlling-animations.md){ .md-button .md-button--primary }
