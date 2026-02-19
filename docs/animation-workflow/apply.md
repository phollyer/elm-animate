# Applying Animations

Once you've defined an animation and triggered it with an engine, you need to apply the animation to your element. All engines use the same pattern: the `attributes` function.

## The Attributes Pattern

Every animation engine provides an `attributes` function that generates HTML attributes for your element:

??? example "View Source Code"

    === "Transitions"

        ```elm
        div (Transitions.attributes "boxAnim" model.animState) [ text "I animate!" ]
        ```

    === "Keyframes"

        ```elm
        div (Keyframes.attributes "boxAnim" model.animState) [ text "I animate!" ]
        ```

    === "Sub"

        ```elm
        div (Sub.attributes "boxAnim" model.animState) [ text "I animate!" ]
        ```

    === "WAAPI"

        ```elm
        div (WAAPI.attributes "boxAnim" model.animState) [ text "I animate!" ]
        ```

The first argument is the **animation group name** - this tells the engine which animation data to look up from the `AnimState`.

## Animation Group Names

The **animation group name** is the key that connects your animation definition to your view.

??? example "View Source Code"

    ```elm
    -- Define an animation for group "boxAnim"
    fadeIn =
        Opacity.for "boxAnim"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

    -- Add fadeIn to your Engine
    Transitions.animate model.animState fadeIn

    -- Then apply it to your element
    view model =
        div (Transitions.attributes "boxAnim" model.animState) [ ... ]
    ```

    Use the group name to group multiple property animations together so that they can all be applied to the same element.

    ```elm
    -- Define another animation for group "boxAnim"
    slideIn =
        Translate.for "boxAnim"
            >> Translate.Xfrom -100
            >> Translate.toX 50
            >> Translate.build

    -- Add slideIn to your Engine too
    Transitions.animate model.animState <|
        fadeIn >> slideIn

    -- Then apply the `boxAnim` group of animations to your element (slideIn & fadeIn)
    view model =
        div (Transitions.attributes "boxAnim" model.animState) [ ... ]
    ```


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

The WAAPI Engine does not use `attributes` to drive the animation — the Web Animations API on the JS side does this instead. Therefore, the `attributes` function bookends the animation and serves two purposes:

1. **Initial state** — Renders the starting CSS immediately, preventing a flash of unstyled content before JavaScript processes the port command
2. **Final state** — Keeps the element in its final position after the animation completes

??? example "View Source Code"

    ```elm
    view model =
        div []
            [ div
                ([ id "header" ] ++ WAAPI.attributes "headerAnim" model.animState)
                [ text "I animate via WAAPI!" ]
            ]
    ```

    Note: WAAPI elements also need an `id` attribute so JavaScript can find the element to apply the animation to. The `id` must match the element ID provided in the `.forElement` call when building the animation configuration.

## Multiple Elements

You can animate multiple elements from the same `AnimState`.

??? example "View Source Code"

    ```elm
    -- Define animations for each element
    Transition.animate model.animState <|
        slideDown "header"
            >> fadeIn "content"
            >> slideUp "footer"

    view model =
        div []
            [ div (Transitions.attributes "header" model.animState) [ text "Header" ]
            , div (Transitions.attributes "content" model.animState) [ text "Content" ]
            , div (Transitions.attributes "footer" model.animState) [ text "Footer" ]
            ]
    ```

    Alternatively, one animation configuration can run on multiple elements.

    ```elm
    Transition.animate model.animState <|
        fadeIn "introAnim"

    view model =
        div []
            [ div (Transitions.attributes "introAnim" model.animState) [ text "Header" ]
            , div (Transitions.attributes "introAnim" model.animState) [ text "Content" ]
            , div (Transitions.attributes "introAnim" model.animState) [ text "Footer" ]
            ]
    ```

## Next Steps

Now that you understand how to apply animations, let's learn how to control them.

[Controlling Animations →](../concepts/controlling-animations.md){ .md-button .md-button--primary }
