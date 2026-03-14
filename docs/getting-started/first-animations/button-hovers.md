
# Fade In/Out Example

--8<-- [start:examples]

Three different hover techniques.

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


--8<-- [end:examples]


--8<-- [start:breaking-it-down]

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
        --8<-- "docs/examples/src/Engines/Keyframes/ButtonHovers/Main.elm:fadeIn"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/ButtonHovers/Main.elm:fadeIn"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/ButtonHovers/Main.elm:fadeIn"
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
        --8<-- "docs/examples/src/Engines/Keyframes/ButtonHovers/Main.elm:initAnimationState"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/ButtonHovers/Main.elm:initAnimationState"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/ButtonHovers/Main.elm:initAnimationState"
        ```

    Here, we initialize the opacity to 0 so the element starts invisible.

### 3. Render

Use the `attributes` function to apply the animation's attributes to your element:

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/ButtonHovers/Main.elm:render"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/ButtonHovers/Main.elm:applyStyles"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/ButtonHovers/Main.elm:applyStyles"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/ButtonHovers/Main.elm:applyStyles"
        ```

    Exactly what `attributes` returns depends on the Engine being used, the animation configuration and the current animation state - all details you no longer need to concern yourself with 🎉.

### 4. Trigger

Engines trigger their animations with their `animate` function.

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/ButtonHovers/Main.elm:trigger"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/ButtonHovers/Main.elm:triggerAnimation"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/ButtonHovers/Main.elm:triggerAnimation"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/ButtonHovers/Main.elm:triggerAnimation"
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
        --8<-- "docs/examples/src/Engines/Sub/ButtonHovers/Main.elm:update"
        ```

        Always required.

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/ButtonHovers/Main.elm:Msg"
        --8<-- "docs/examples/src/Engines/WAAPI/ButtonHovers/Main.elm:update"
        ```

        Not required for this animation.

--8<-- [end:breaking-it-down]
