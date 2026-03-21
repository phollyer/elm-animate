
# Button Hovers Example

--8<-- [start:examples]

Three different hover techniques.

=== "Transitions"

    <iframe src="../../../examples/src/Engines/Transitions/ButtonHovers/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Keyframes"

    <iframe src="../../../examples/src/Engines/Keyframes/ButtonHovers/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Sub"

    <iframe src="../../../examples/src/Engines/Sub/ButtonHovers/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    <iframe src="../../../examples/src/Engines/WAAPI/ButtonHovers/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/ButtonHovers/Main.elm"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/ButtonHovers/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/ButtonHovers/Main.elm"
        ```
    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/ButtonHovers/Main.elm"
        ```



## Breaking It Down

There are four simple steps to animating with Elm Animate. The fifth is optional for most Engines, but recommended

### 1. Build

Animations are defined as functions that transform an `AnimBuilder`:

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/ButtonHovers/Main.elm:build"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/ButtonHovers/Main.elm:build"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/ButtonHovers/Main.elm:build"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/ButtonHovers/Main.elm:build"
        ```

### 2. Initialize

Set up the initial state for your animated properties. This ensures elements render with the correct starting values before any animation runs:

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/ButtonHovers/Main.elm:model"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/ButtonHovers/Main.elm:model"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/ButtonHovers/Main.elm:model"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/ButtonHovers/Main.elm:model"
        ```

### 3. Render

Use the `attributes` function to apply the animation's attributes to your element:

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/ButtonHovers/Main.elm:render"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/ButtonHovers/Main.elm:render"
        ```

        Keyframe animations also need a `style` node with the keyframe rules. 
        
        📖 See [Keyframes Style Node](../../engines/keyframes.md#keyframes-style-node) for more info.

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/ButtonHovers/Main.elm:render"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/ButtonHovers/Main.elm:render"
        ```

    Exactly what `attributes` returns depends on the Engine being used, the animation configuration and the current animation state.

### 4. Trigger

Engines trigger their animations with their `animate` function.

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/ButtonHovers/Main.elm:trigger"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/ButtonHovers/Main.elm:trigger"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/ButtonHovers/Main.elm:trigger"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/ButtonHovers/Main.elm:trigger"
        ```


### 5. Update

Keep the Engine's state updated to make use of state-tracked features.

This is a requirement for the Sub Engine, but optional for the Transitions, Keyframes and WAAPI Engines.


??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/ButtonHovers/Main.elm:update"
        ```

        Not required for this animation.

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/ButtonHovers/Main.elm:update"
        ```

        Not required for this animation.

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/ButtonHovers/Main.elm:Msg"
        --8<-- "docs/examples/src/Engines/Sub/ButtonHovers/Main.elm:update"
        ```

        Always required.

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/ButtonHovers/Main.elm:Msg"
        --8<-- "docs/examples/src/Engines/WAAPI/ButtonHovers/Main.elm:update"
        ```

        Not required for this animation.

--8<-- [end:examples]
