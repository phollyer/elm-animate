# Examples

Interactive examples demonstrating Elm Animate capabilities. Each example can be viewed and run directly in the browser.

## Getting Started

### First Animation

A simple fade-in/fade-out animation.

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

[:material-play-circle: Transitions](examples/src/Engines/Transitions/FirstAnimation/index.html){ .md-button target="_blank" }
[:material-play-circle: Keyframes](examples/src/Engines/Keyframes/FirstAnimation/index.html){ .md-button target="_blank" }
[:material-play-circle: Sub](examples/src/Engines/Sub/FirstAnimation/index.html){ .md-button target="_blank" }
[:material-play-circle: WAAPI](examples/src/Engines/WAAPI/FirstAnimation/index.html){ .md-button target="_blank" }

### First Scroll

Smooth scrolling within a container element using the Scroll Engine. Great for scrollable lists, content panels, and more.

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstScroll/Main.elm"
    ```

[:material-play-circle: Run this example](examples/src/GettingStarted/FirstScroll/index.html){ .md-button target="_blank" }

---

## Engine Examples

### Basic Usage

A simple fade in animation.

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/BasicUsage/Main.elm"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/BasicUsage/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/BasicUsage/Main.elm"
        ```
    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/BasicUsage/Main.elm"
        ```


[:material-play-circle: Transitions](examples/src/Engines/Transitions/BasicUsage/index.html){ .md-button target="_blank" }
[:material-play-circle: Keyframes](examples/src/Engines/Keyframes/BasicUsage/index.html){ .md-button target="_blank" }
[:material-play-circle: Sub](examples/src/Engines/Sub/BasicUsage/index.html){ .md-button target="_blank" }
[:material-play-circle: WAAPI](examples/src/Engines/WAAPI/BasicUsage/index.html){ .md-button target="_blank" }

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
        --8<-- "docs/examples/src/Concepts/ControllingAnimations/TransitionsEngine/Main.elm"
        ```

    === "Keyframes Engine"

        ```elm
        --8<-- "docs/examples/src/Concepts/ControllingAnimations/KeyframesEngine/Main.elm"
        ```

    === "Sub Engine"

        ```elm
        --8<-- "docs/examples/src/Concepts/ControllingAnimations/SubEngine/Main.elm"
        ```

    === "WAAPI Engine"

        ```elm
        --8<-- "docs/examples/src/Concepts/ControllingAnimations/WaapiEngine/Main.elm"
        ```

[:material-play-circle: Transitions](examples/src/Concepts/ControllingAnimations/TransitionsEngine/index.html){ .md-button target="_blank" }
[:material-play-circle: Keyframes](examples/src/Concepts/ControllingAnimations/KeyframesEngine/index.html){ .md-button target="_blank" }
[:material-play-circle: Sub](examples/src/Concepts/ControllingAnimations/SubEngine/index.html){ .md-button target="_blank" }
[:material-play-circle: WAAPI](examples/src/Concepts/ControllingAnimations/WaapiEngine/index.html){ .md-button target="_blank" }

### Controlling Scroll

Interactive demonstration of scroll control functions (stop, reset, restart, pause, resume) using the Scroll Engine.

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/ScrollEngine/Main.elm"
    ```

[:material-play-circle: Run this example](examples/src/Concepts/ControllingAnimations/ScrollEngine/index.html){ .md-button target="_blank" }

### 3D Animations

A rotating cube with expanding sides, demonstrating GPU-accelerated 3D transforms using perspective, rotateX/Y/Z, and translateZ.

??? example "View Source Code"

    === "Html"

        ```elm
        --8<-- "docs/examples/src/Concepts/Animate3D/Html/Main.elm"
        ```

    === "ElmUI"

        ```elm
        --8<-- "docs/examples/src/Concepts/Animate3D/ElmUI/Main.elm"
        ```

[:material-play-circle: Run Html example](examples/src/Concepts/Animate3D/Html/index.html){ .md-button target="_blank" } [:material-play-circle: Run ElmUI example](examples/src/Concepts/Animate3D/ElmUI/index.html){ .md-button target="_blank" }
