# Triggering Animations

Once you've [built](build.md), [initialized](init.md) and setup your view ready to [render](render.md) your animation - you next need to trigger it.

## Using `animate`

The `animate` function is what does all the heavy lifting. It processes your animation configuration and merges the computed data into your existing `AnimState`. The call-site pattern is the same across all engines - the only difference are some return types:

??? example "View Source Code"

    === "Transition"

        ```elm
        ( { model | animState = Transition.animate model.animState fadeIn }
        , Cmd.none
        )
        ```

    === "Keyframe"

        ```elm
        ( { model | animState = Keyframe.animate model.animState fadeIn }
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
            ( animState, cmd ) =
                WAAPI.animate model.animState fadeIn
        in
        ( { model | animState = animState }
        , cmd
        )
        ```

        WAAPI uses JavaScript ports, so `animate` returns both the updated state and a `cmd` that sends the animation data to JS.

    === "ScrollTimeline"

        ```elm
        (model
        , ScrollTimeline.animate motionCmd fadeIn
        )
        ```

        ScrollTimeline uses JavaScript ports, and no `AnimState`, so `animate` simply returns a `cmd` that sends the animation data to JS.

    === "ViewTimeline"

        ```elm
        (model
        , ViewTimeline.animate motionCmd fadeIn
        )
        ```

        ViewTimeline uses JavaScript ports, and no `AnimState`, so `animate` simply returns a `cmd` that sends the animation data to JS.


## When to Trigger

### In Response to Events

Most animations trigger in response to user action events or application events. Trigger these in `update`:

??? example "View Source Code"

    === "Transition"

        ```elm
        update msg model =
            case msg of
                GotButtonClick ->
                    ( { model | animState = Transition.animate model.animState buttonPress }
                    , Cmd.none
                    )

                GotDataReceived data ->
                    ( { model 
                        | data = data
                        , dataAnimState = Transition.animate model.dataAnimState dataFadeIn 
                      }
                    , Cmd.none
                    )
        ```

    === "Keyframe"

        ```elm
        update msg model =
            case msg of
                GotButtonClick ->
                    ( { model | animState = Keyframe.animate model.animState buttonPress }
                    , Cmd.none
                    )

                GotDataReceived data ->
                    ( { model 
                        | data = data
                        , dataAnimState = Keyframe.animate model.dataAnimState dataFadeIn 
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
                        ( animState, cmd ) =
                            WAAPI.animate model.animState buttonPress
                    in
                    ( { model | animState = animState }
                    , cmd 
                    )

                GotDataReceived data ->
                    let
                        ( animState, cmd ) =
                            WAAPI.animate model.animState dataFadeIn
                    in
                    ( { model | animState = animState }
                    , cmd
                    )
        ```

    === "ScrollTimeline"

        ```elm
        update msg model =
            case msg of
                GotButtonClick ->
                    ( model
                    , ScrollTimeline.animate motionCmd graphAnim 
                    )

                GotDataReceived data ->
                    ( { model | data = data }
                    , ScrollTimeline.animate motionCmd dataPresentationAnim 
                    )
        ```

    === "ViewTimeline"

        ```elm
        update msg model =
            case msg of
                GotButtonClick ->
                    ( model
                    , ViewTimeline.animate motionCmd graphAnim 
                    )

                GotDataReceived data ->
                    ( { model | data = data }
                    , ViewTimeline.animate motionCmd dataPresentationAnim 
                    )
        ```

### On Page Load

To animate immediately when the page loads, you need to trigger in `init`. For most engines this is a simple process, for the Transition Engine not so:

??? example "View Source Code"

    === "Transition"
        
        ❌ **Behaviour**: The element appears at the final state, with no animation.

        📖 See [Transition Engine - How CSS Transition Work](../engines/transition.md#how-css-transitions-work) for more info.        

        ```elm
        init =
            let
                animState =
                    Transition.init [ Opacity.init "boxAnim" 0 ]
            in
            ( { animState = Transition.animate animState fadeIn }
            , Cmd.none 
            )
        ```

    === "Keyframe"

        ✅ **Behaviour**: The `@keyframes` rules are added to the DOM on first render when you apply the `styleNode` function in your view, the browser will then run them immediately.

        ```elm
        init =
            let
                animState =
                    Keyframe.init [ Opacity.init "boxAnim" 0 ]
            in
            ( { animState = Keyframe.animate animState fadeIn }
            , Cmd.none
            )
        ```

    === "Sub"

        ✅ **Behaviour**: The initial property values are used for first render, and the animation starts in the first update loop.

        ```elm
        init =
            let
                animState =
                    Sub.init [ Opacity.init "boxAnim" 0 ]
            in
            ( { animState = Sub.animate animState fadeIn }
            , Cmd.none 
            )
        ```

    === "WAAPI"

        ✅ **Behaviour**: The initial property values are used for first render, and the animation starts in the first update loop after JS receives the data in `cmd`.

        ```elm
        init =
            let
                animState =
                    WAAPI.init motionCmd motionMsg <|
                        [ Opacity.init "box" 0 ]
                
                ( animState, cmd ) =
                    WAAPI.animate animState fadeIn
            in
            ( { animState = animState }
            , cmd 
            )
        ```

    === "ScrollTimeline"

        ✅ **Behaviour**: The animation is registered in the first update loop after JS receives the animation data, and then plays in relation to user scroll position.

        ```elm
        init =
            ( { model | ... }
            , ScrollTimeline.animate motionCmd fadeIn 
            )
        ```

    === "ViewTimeline"

        ✅ **Behaviour**: The animation is registered in the first update loop after JS receives the animation data, and then plays in relation to it's position in the viewport.

        ```elm
        init =
            ( { model | ... }
            , ViewTimeline.animate motionCmd fadeIn 
            )
        ```


### **Not in `view`**

You could do this:

??? example "View Source Code"

    ```elm
    view model =
        let
            boxAnimState = Transition.animate (Transition.init []) fadeIn
        in
        div
            []
            [ div
                (Transition.attributes "boxAnim" boxAnimState)
                [ text "I'm animated wrongly" ]
            ]
    ```

It works, but the builder functions run on **every render**, creating unnecessary GC pressure. The view should be a pure function of model state. Prefer triggering in `update` or `init`.

## Triggering Mid-Flight

What happens when you trigger an animation while another animation is already running on the same element? See [Mid-Flight Interruptions](../concepts/interrupting-animations.md) for how each engine handles this.

## Next Steps

Now that you can trigger animations, learn how to react to their lifecycle events.

[React →](react.md){ .md-button .md-button--primary }
