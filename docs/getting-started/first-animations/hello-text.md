# Hello Text Example

--8<-- [start:examples]

The obligatory "Hello" example.

=== "Transitions"

    <iframe src="../../../examples/src/Engines/Transitions/HelloText/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Keyframes"

    <iframe src="../../../examples/src/Engines/Keyframes/HelloText/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Sub"

    <iframe src="../../../examples/src/Engines/Sub/HelloText/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    <iframe src="../../../examples/src/Engines/WAAPI/HelloText/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>


??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/HelloText/Main.elm"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/HelloText/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/HelloText/Main.elm"
        ```
    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm"
        ```

## Breaking It Down

There are four simple steps to animating with Elm Animate. The fifth is optional for most Engines, but recommended

### 1. Build

Animations are defined as functions that transform an `AnimBuilder`:

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/HelloText/Main.elm:build"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/HelloText/Main.elm:build"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/HelloText/Main.elm:build"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm:build"
        ```


### 2. Initialize

Set up the initial state for your animated properties. This ensures elements render with the correct starting values before any animation runs:

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/HelloText/Main.elm:model"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/HelloText/Main.elm:model"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/HelloText/Main.elm:model"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm:model"
        ```

        The WAAPI Engine also requires both it's `port` functions (`waapiCommand` & `waapiEvent`). For more info, see the [Engine Docs](../../engines/waapi/#3-define-ports-in-elm).

### 3. Render

Use the `attributes` function to apply the animation's attributes to your element:

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/HelloText/Main.elm:render"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/HelloText/Main.elm:render"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/HelloText/Main.elm:render"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm:render"
        ```

    Exactly what `attributes` returns depends on the Engine being used, the animation configuration and the current animation state - all details you no longer need to concern yourself with 🎉.

### 4. Trigger

Engines trigger their animations with their `animate` function.

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/HelloText/Main.elm:trigger-cmd"
        ```

        The animation is triggered 50ms after first render  so that the browser can compute the starting values for the transition. For more info see the [Engine Docs - How CSS Transitions Work](../../engines/transitions/#how-css-transitions-work).

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/HelloText/Main.elm:trigger"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/HelloText/Main.elm:trigger"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/HelloText/Main.elm:trigger"
        ```

        The Sub Engine can be triggered from the modules `init` function.

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm:trigger"
        ```

        The WAAPI Engine also returns a `Cmd` from `animate` that sends the animation data to the [Javascript Companion](../../engines/waapi/#1-install-the-javascript-package).

### 5. Update

This is a requirement for the Sub Engine, but optional for the Transitions, Keyframes and WAAPI Engines.


??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/HelloText/Main.elm:update"
        ```

        Not required for this animation.

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/HelloText/Main.elm:update"
        ```

        Not required for this animation.

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/HelloText/Main.elm:update"
        ```

        Always required.

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm:Msg"
        --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm:update"
        ```

        Not required for this animation.

--8<-- [end:examples]
