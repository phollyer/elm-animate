# Render

In order to play an animation, it needs to be rendered in your `view`. All engines provide an `attributes` function for this.

## Using `attributes`

The `attributes` function generates HTML attributes for your element.

??? example "View Source Code"

    === "Transition"

        ```elm
        div 
            (Transition.attributes "boxAnim" model.animState) 
            [ text "I animate!" ]
        ```

    === "Keyframe"

        ```elm
        div 
            (Keyframe.attributes "boxAnim" model.animState) 
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

The first argument is the **animation group name** - this connects your animation definition to your view element.

📖 See [Animation Group Names](build.md#animation-group-names) for more on defining groups when building animations.

## Engine-Specific Requirements

While the `attributes` pattern is consistent across all Engines, the Keyframe Engine has an additional requirement.

### CSS Keyframe Engine

Keyframe animations require a `<style>` node in the DOM containing the generated `@keyframes` rules:

??? example "View Source Code"

    ```elm
    view model =
        div []
            [ Keyframe.styleNode model.animState  -- Required!
            , div
                (Keyframe.attributes "boxAnim" model.animState)
                [ text "I animate!" ]
            ]
    ```

    `styleNode` produces all the `@keyframes` rules for all animations in `animState`.

    For a more targeted `style` node, use `styleNodeFor animGroup` which only applies the keyframes for that animation group. You can add multiple `styleNodeFor`s to your DOM if so required.

    ```elm
    view model =
        div []
            [ Keyframe.styleNodeFor "headerAnim" model.animState 
            , Keyframe.styleNodeFor "sidebarAnim" model.animState
            , div
                (Keyframe.attributes "headerAnim" model.animState)
                [ text "I am a header!" ]
            , div
                (Keyframe.attributes "sidebarAnim" model.animState)
                [ text "I am a sidebar!" ]
            ]
    ```

#### A Place at the Top

The `@keyframes` `<style>` node should be placed in your view **at a stable top level**.

If any `@keyframes` rules are inside a part of the DOM that gets re-rendered (a conditional branch, a list, etc.), Elm's virtual DOM diff may remove and re-add them - and when the browser sees "new" `@keyframes` rules, it restarts any animations using them - so be mindful where you put them and, unless you have a real need, place them as high up your DOM tree as you can.

## Next Steps

Now that your view is setup ready to render your animations, the next step is triggering them.

[Trigger Animations →](trigger.md){ .md-button .md-button--primary }
