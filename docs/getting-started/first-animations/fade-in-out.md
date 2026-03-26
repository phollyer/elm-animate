# Fade In/Out Example

--8<-- [start:examples]

Fade an element in and out with buttons.

=== "Transitions"

    <iframe src="../../../examples/src/Engines/Transitions/FadeInOut/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Keyframes"

    <iframe src="../../../examples/src/Engines/Keyframes/FadeInOut/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Sub"

    <iframe src="../../../examples/src/Engines/Sub/FadeInOut/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    <iframe src="../../../examples/src/Engines/WAAPI/FadeInOut/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/FadeInOut/Main.elm"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/FadeInOut/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/FadeInOut/Main.elm"
        ```
    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/FadeInOut/Main.elm"
        ```

## Breaking It Down

There are four simple steps to animating with Elm Animate. The fifth is optional for most Engines, but recommended

### 1. Build

Animations are defined as functions that transform an `AnimBuilder`:

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/FadeInOut/Main.elm:build"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/FadeInOut/Main.elm:build"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/FadeInOut/Main.elm:build"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/FadeInOut/Main.elm:build"
        ```

### 2. Initialize

Set up the initial state for your animated properties. This ensures elements render with the correct starting values before any animation runs:

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/FadeInOut/Main.elm:model"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/FadeInOut/Main.elm:model"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/FadeInOut/Main.elm:model"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/FadeInOut/Main.elm:model"
        ```

        The WAAPI Engine also requires both it's `port` functions (`waapiCommand` & `waapiEvent`). 
        
        📖 See [WAAPI Engine - Define Ports in Elm](../../engines/waapi/#3-define-ports-in-elm) for more info.

    Here, we initialize the opacity to 0 so the element starts invisible.

### 3. Render

Use the `attributes` function to apply the animation's attributes to your element:

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/FadeInOut/Main.elm:render"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/FadeInOut/Main.elm:render"
        ```

        Keyframe animations also need a `style` node with the keyframe rules. 
        
        📖 See [Keyframes Style Node](../../engines/animation/keyframes.md#keyframes-style-node) for more info.

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/FadeInOut/Main.elm:render"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/FadeInOut/Main.elm:render"
        ```

    Exactly what `attributes` returns depends on the Engine being used, the animation configuration and the current animation state.

### 4. Trigger

Engines trigger their animations with their `animate` function.

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/FadeInOut/Main.elm:trigger"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/FadeInOut/Main.elm:trigger"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/FadeInOut/Main.elm:trigger"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/FadeInOut/Main.elm:trigger"
        ```

        The WAAPI Engine also returns a `Cmd` from `animate` that sends the animation data to the [Javascript Companion](../../engines/waapi/#1-install-the-javascript-package).


### 5. Update

Keep the Engine's state updated to make use of state-tracked features.

This is a requirement for the Sub Engine, but optional for the Transitions, Keyframes and WAAPI Engines.


??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/FadeInOut/Main.elm:update"
        ```

        Not required for this animation.

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/FadeInOut/Main.elm:update"
        ```

        Not required for this animation.

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/FadeInOut/Main.elm:update"
        ```

        Always required.

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/FadeInOut/Main.elm:Msg"
        --8<-- "docs/examples/src/Engines/WAAPI/FadeInOut/Main.elm:update"
        ```

        Not required for this animation.

--8<-- [end:examples]
