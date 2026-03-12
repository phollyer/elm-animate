# Your First Animations

All the examples demonstrate the same animation for each of the Engines.


## The Animation

We'll fade an element in and out over 2500 milliseconds.

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/FirstAnimation/Main.elm"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/FirstAnimation/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/FirstAnimation/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/FirstAnimation/Main.elm"
        ```

[:material-play-circle: Transitions](../examples/src/Engines/Transitions/FirstAnimation/index.html){ .md-button target="_blank" }
[:material-play-circle: Keyframes](../examples/src/Engines/Keyframes/FirstAnimation/index.html){ .md-button target="_blank" }
[:material-play-circle: Sub](../examples/src/Engines/Sub/FirstAnimation/index.html){ .md-button target="_blank" }
[:material-play-circle: WAAPI](../examples/src/Engines/WAAPI/FirstAnimation/index.html){ .md-button target="_blank" }


## Breaking It Down

There are four simple steps to animating with Elm Animate.

### 1. Build

Animations are defined as functions that transform an `AnimBuilder`:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:fadeIn"
    ```

### 2. Initialize

Set up the initial state for your animated properties. This ensures elements render with the correct starting values before any animation runs:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:initAnimationState"
    ```
    Here, we initialize the opacity to 0 so the element starts invisible.

### 3. Render

Use the `attributes` function to apply the animation's attributes to your element:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:applyStyles"
    ```

    Exactly what `attributes` returns depends on the Engine being used, the animation configuration and the current animation state - all details you no longer need to concern yourself with 🎉.

### 4. Trigger

Engines trigger their animations with their `animate` function.

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:triggerAnimation"
    ```
    Here, we use `animate` with a fresh `init` to trigger the required animation.
    
## Next Steps

Now that you can create a simple animation, take a look at the properties you can animate.

[Properties →](properties.md){ .md-button .md-button--primary }

Or

Start your first scroll.

[First Scroll →](first-scroll.md){ .md-button .md-button--primary }

