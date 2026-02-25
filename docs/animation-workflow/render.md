# Render

In order to view an animation, it needs to be rendered in your `view`. All engines provide an `attributes` function for this.

## Using `attributes`

The `attributes` function generates HTML attributes for your element.

??? example "View Source Code"

    === "Transitions"

        ```elm
        div 
            (Transitions.attributes "boxAnim" model.animState) 
            [ text "I animate!" ]
        ```

    === "Keyframes"

        ```elm
        div 
            (Keyframes.attributes "boxAnim" model.animState) 
            [ text "I animate!" ]
        ```

    === "Sub"

        ```elm
        div 
            (Sub.attributes "boxAnim" model.animState) 
            [ text "I animate!" ]
        ```

    === "WAAPI"

        ```elm
        div 
            (WAAPI.attributes "boxAnim" model.animState) 
            [ text "I animate!" ]
        ```

The first argument is the **animation group name** - this connects your animation definition to your view element. See [Animation Group Names](build.md#animation-group-names) for how to define groups when building animations.

## Engine-Specific Requirements

While the `attributes` pattern is consistent, some engines have additional view requirements:

### CSS Keyframes Engine

Keyframes animations require a `<style>` node in the DOM containing the generated `@keyframes` rules:

??? example "View Source Code"

    ```elm
    view model =
        div []
            [ Keyframes.styleNode model.animState  -- Required!
            , div
                (Keyframes.attributes "boxAnim" model.animState)
                [ text "I animate!" ]
            ]
    ```

    The `styleNode` should be placed once in your view, typically at the top level. It contains all keyframe definitions for all animation groups in that `AnimState`.

    For a more targeted `style` node, use `styleNodeFor animGroup` which only applies the keyframes for that animation group. You can add multiple `styleNodeFor`s to your DOM if so required.

    ```elm
    view model =
        div []
            [ Keyframes.styleNodeFor "headerAnim" model.animState 
            , Keyframes.styleNodeFor "sidebarAnim" model.animState
            , div
                (Keyframes.attributes "headerAnim" model.animState)
                [ text "I am a header!" ]
            , div
                (Keyframes.attributes "sidebarAnim" model.animState)
                [ text "I am a sidebar!" ]
            ]
    ```

### WAAPI Engine

WAAPI elements need an `id` attribute so JavaScript can find the DOM element. The `id` must match the element ID provided in `WAAPI.forElement` when building the animation.

??? example "View Source Code"

    ```elm
    view model =
        div []
            [ div
                (WAAPI.attributes "headerAnim" model.animState
                    ++ [ id "header" ]
                )
                [ text "I animate via WAAPI!" ]
            ]
    ```

See [WAAPI Engine](../engines/waapi.md) for details on how WAAPI handles attributes differently from other engines.

## Next Steps

Now that your elements are connected to the animation state, the next step is triggering animations.

[Trigger Animations →](trigger.md){ .md-button .md-button--primary }
