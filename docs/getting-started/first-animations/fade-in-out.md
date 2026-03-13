
--8<-- "docs/examples.md:fade-in-out"


[:material-play-circle: Transitions](../examples/src/Engines/Transitions/FadeInOut/index.html){ .md-button target="_blank" }
[:material-play-circle: Keyframes](../examples/src/Engines/Keyframes/FadeInOut/index.html){ .md-button target="_blank" }
[:material-play-circle: Sub](../examples/src/Engines/Sub/FadeInOut/index.html){ .md-button target="_blank" }
[:material-play-circle: WAAPI](../examples/src/Engines/WAAPI/FadeInOut/index.html){ .md-button target="_blank" }



## Breaking It Down

There are four simple steps to animating with Elm Animate. The fifth is optional for most Engines, but recommended

### 1. Build

Animations are defined as functions that transform an `AnimBuilder`:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/WAAPI/FadeInOut/Main.elm:fadeIn"
    ```

### 2. Initialize

Set up the initial state for your animated properties. This ensures elements render with the correct starting values before any animation runs:

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/FadeInOut/Main.elm:initAnimationState"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/FadeInOut/Main.elm:initAnimationState"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/FadeInOut/Main.elm:initAnimationState"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/FadeInOut/Main.elm:initAnimationState"
        ```

    Here, we initialize the opacity to 0 so the element starts invisible.

### 3. Render

Use the `attributes` function to apply the animation's attributes to your element:

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/FadeInOut/Main.elm:applyStyles"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/FadeInOut/Main.elm:applyStyles"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/FadeInOut/Main.elm:applyStyles"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/FadeInOut/Main.elm:applyStyles"
        ```

    Exactly what `attributes` returns depends on the Engine being used, the animation configuration and the current animation state - all details you no longer need to concern yourself with 🎉.

### 4. Trigger

Engines trigger their animations with their `animate` function.

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/FadeInOut/Main.elm:triggerAnimation"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/FadeInOut/Main.elm:triggerAnimation"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/FadeInOut/Main.elm:triggerAnimation"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/FadeInOut/Main.elm:triggerAnimation"
        ```


### 5. Update

Keep the Engine's state updated to make use of state-tracked features.

This is a requirement for the Sub Engine, but optional for the Transitions, Keyframes and WAAPI Engines.


??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/FadeInOut/Main.elm:update"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/FadeInOut/Main.elm:update"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/FadeInOut/Main.elm:update"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/FadeInOut/Main.elm:update"
        ```
