# Examples

Interactive examples demonstrating Elm Animate capabilities. Each example can be viewed and run directly in the browser.

## Getting Started

### Hello Text

--8<-- [start:hello-text]

The obligatory "Hello" example.

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

--8<-- [end:hello-text]

[:material-play-circle: Transitions](examples/src/Engines/Transitions/HelloText/index.html){ .md-button target="_blank" }
[:material-play-circle: Keyframes](examples/src/Engines/Keyframes/HelloText/index.html){ .md-button target="_blank" }
[:material-play-circle: Sub](examples/src/Engines/Sub/HelloText/index.html){ .md-button target="_blank" }
[:material-play-circle: WAAPI](examples/src/Engines/WAAPI/HelloText/index.html){ .md-button target="_blank" }


### Fade In/Out

--8<-- [start:fade-in-out]
A simple fade-in/fade-out animation.

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

--8<-- [end:fade-in-out]

[:material-play-circle: Transitions](examples/src/Engines/Transitions/FadeInOut/index.html){ .md-button target="_blank" }
[:material-play-circle: Keyframes](examples/src/Engines/Keyframes/FadeInOut/index.html){ .md-button target="_blank" }
[:material-play-circle: Sub](examples/src/Engines/Sub/FadeInOut/index.html){ .md-button target="_blank" }
[:material-play-circle: WAAPI](examples/src/Engines/WAAPI/FadeInOut/index.html){ .md-button target="_blank" }


### First Scroll

Smooth scrolling within a container element using the Scroll Engine. Great for scrollable lists, content panels, and more.

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/FirstScroll/Main.elm"
    ```

[:material-play-circle: Run this example](examples/src/Engines/Scroll/FirstScroll/index.html){ .md-button target="_blank" }

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

### Controlling Scroll

Interactive demonstration of scroll control functions (stop, reset, restart, pause, resume) using the Scroll Engine.

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/ControllingScrolls/Main.elm"
    ```

[:material-play-circle: Run this example](examples/src/Engines/Scroll/ControllingScrolls//index.html){ .md-button target="_blank" }

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
