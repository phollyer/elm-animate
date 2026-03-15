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

## Interrupting Animations

Demonstrates smooth mid-flight redirections.

--8<-- "docs/concepts/interruptions/examples.md:examples"

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

=== "Transitions"

    <iframe src="src/Engines/Transitions/ControllingAnimations/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Keyframes"

    <iframe src="src/Engines/Keyframes/ControllingAnimations/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Sub"

    <iframe src="src/Engines/Sub/ControllingAnimations/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    <iframe src="src/Engines/WAAPI/ControllingAnimations/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

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

=== "Transitions"

    <iframe src="src/Engines/Transitions/Animate3D/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Keyframes"

    <iframe src="src/Engines/Keyframes/Animate3D/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Sub"

    <iframe src="src/Engines/Sub/Animate3D/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    <iframe src="src/Engines/WAAPI/Animate3D/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

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

<iframe src="src/Engines/Scroll/ControllingScrolls/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>
