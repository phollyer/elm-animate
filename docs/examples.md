# Examples

Interactive examples demonstrating Elm Animate capabilities.

All the examples demonstrate the same animation for each of the Engines.

## First Animations

??? example "Hello Text"

    --8<-- "docs/getting-started/first-animations/hello-text.md:examples"

??? example "Fade In/Out"

    --8<-- "docs/getting-started/first-animations/fade-in-out.md:examples"


??? example "Button Hovers"

    --8<-- "docs/getting-started/first-animations/button-hovers.md:examples"

---

## Engine Examples


### Interrupting Animations

Demonstrates smooth mid-flight redirections.

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/InterruptingAnimations/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/InterruptingAnimations/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/InterruptingAnimations/Main.elm"
        ```

[:material-play-circle: Transitions](examples/src/Engines/Transitions/InterruptingAnimations/index.html){ .md-button target="_blank" }
[:material-play-circle: Sub](examples/src/Engines/Sub/InterruptingAnimations/index.html){ .md-button target="_blank" }
[:material-play-circle: WAAPI](examples/src/Engines/WAAPI/InterruptingAnimations/index.html){ .md-button target="_blank" }

---

## Concept Examples

### Controlling Animations

Interactive demonstrations of animation control functions (stop, reset, restart, pause, resume) across all engines.

??? example "View Source Code"

    === "Transitions Engine"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/ControllingAnimations/Main.elm"
        ```

    === "Keyframes Engine"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/ControllingAnimations/Main.elm"
        ```

    === "Sub Engine"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/ControllingAnimations/Main.elm"
        ```

    === "WAAPI Engine"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/ControllingAnimations/Main.elm"
        ```

[:material-play-circle: Transitions](examples/src/Engines/Transitions/ControllingAnimations/index.html){ .md-button target="_blank" }
[:material-play-circle: Keyframes](examples/src/Engines/Keyframes/ControllingAnimations/index.html){ .md-button target="_blank" }
[:material-play-circle: Sub](examples/src/Engines/Sub/ControllingAnimations/index.html){ .md-button target="_blank" }
[:material-play-circle: WAAPI](examples/src/Engines/WAAPI/ControllingAnimations/index.html){ .md-button target="_blank" }

### 3D Animations

A rotating cube with expanding sides, demonstrating GPU-accelerated 3D transforms using perspective, rotateX/Y/Z, and translateZ.

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/Animate3D/Main.elm"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/Animate3D/Main.elm"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/Animate3D/Main.elm"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/Animate3D/Main.elm"
        ```

[:material-play-circle: Transitions](examples/src/Engines/Transitions/Animate3D/index.html){ .md-button target="_blank" }
[:material-play-circle: Keyframes](examples/src/Engines/Keyframes/Animate3D/index.html){ .md-button target="_blank" }
[:material-play-circle: Sub](examples/src/Engines/Sub/Animate3D/index.html){ .md-button target="_blank" }
[:material-play-circle: WAAPI](examples/src/Engines/WAAPI/Animate3D/index.html){ .md-button target="_blank" }

## First Scrolls


??? example "Cmd"

    --8<-- "docs/getting-started/first-scrolls/cmd.md:examples"

??? example "Task"

    --8<-- "docs/getting-started/first-scrolls/task.md:examples"


??? example "Subscriptions"

    --8<-- "docs/getting-started/first-scrolls/subscriptions.md:examples"



### Controlling Scroll

Interactive demonstration of scroll control functions (stop, reset, restart, pause, resume) using the Scroll Engine.

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/ControllingScrolls/Main.elm"
    ```

[:material-play-circle: Run this example](examples/src/Engines/Scroll/ControllingScrolls//index.html){ .md-button target="_blank" }
