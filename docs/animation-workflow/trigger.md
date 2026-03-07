# Triggering Animations

Once you've [built](build.md), [initialized](init.md) and setup your view ready to [render](render.md) your animation - you next need to trigger it. Triggering is where the engine processes your configuration and computes the animation data, storing the results in `AnimState` ready for rendering.

## Two Ways to Trigger

| Function | State Tracking | Use When |
| -------- | -------------- | -------- |
| `animate` | Yes — engine tracks property values | Sequencing, redirecting, or controlling animations |
| `fireAndForget` | No — sends animation and forgets | Simple one-shot WAAPI animations |

With `animate`, you maintain an `AnimState` in your model that the engine updates in your `update` function.

With `fireAndForget` (WAAPI only), the animation is sent to JavaScript without any Elm-side state tracking. It returns a `Cmd msg` directly — no `AnimState` needed.

### Suggested Use Cases

| Scenario | Transitions | Keyframes | Sub | WAAPI |
| -------- | :---------: | :-------: | :-: | :---: |
| One-shot, no control needed | `animate` | `animate` | `animate` | `fireAndForget` |
| Stop/reset/pause controls | `animate` | `animate` | `animate` | `animate` |
| Sequencing animations | `animate` | `animate` | `animate` | `animate` |
| Redirecting mid-flight | `animate` | | `animate` | `animate` |


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


## Using `fireAndForget` (WAAPI Only)

The WAAPI engine supports `fireAndForget` for simple animations that don't need state tracking. It sends the animation command directly to JavaScript and returns a `Cmd msg` — no `AnimState` required:

??? example "View Source Code"

    ```elm
    ( model
    , WAAPI.fireAndForget waapiCommand fadeIn
    )
    ```

The JavaScript runtime tracks animations per-element and per-property, so multiple concurrent `fireAndForget` calls work fine — as long as they target different elements or different properties. If you animate the same property on the same element, the new animation replaces the running one.

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
                        , dataAnimState = Transitions.animate model.dataAnimState dataFadeIn 
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
                        , dataAnimState = Keyframes.animate model.dataAnimState dataFadeIn 
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
                    ( { model | animState = Transitions.animate model.animState fadeIn }
                    , Cmd.none
                    )
                
                ...
        ```

        The initial Property values are used in the view for first render, then 50ms after first render the animation will begin.

        This works, but it's not ideal.

    === "Keyframes"

        ```elm
        init _ =
            let
                animState =
                    Keyframes.init [ Opacity.init "boxAnim" 0 ]
            in
            ( { animState = Keyframes.animate animState fadeIn }, Cmd.none )
        ```

        The `@keyframes` rules are added to the DOM on first render, and the browser will run them immediately.

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

        Or with `fireAndForget`:

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


The Keyframes engine is the simplest setup for animations that need to play on first render - closely followed by the Sub and WAAPI engines.

CSS transitions don't play well as 'onload' animations.


### Not in `view`

??? warning "Why not?"
    Avoid building animations directly in your view:

    ```elm
    view model =
        let
            boxAnimState = Transitions.animate (Transitions.init []) fadeIn
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
