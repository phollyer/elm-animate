# Examples

--8<-- [start:page]

--8<-- [start:examples]

??? example "View Examples"

    === "Keyframes"

        ❌ **Behaviour**: The new `@keyframes` rules for the animation replace the existing rules. 

        📖 **See**: [Keyframes Engine — Interrupting Animations](../../engines/animation/keyframes.md#interrupting-animations) for details.

        <iframe src="../../../examples/src/Engines/Keyframes/InterruptingAnimations/SingleProperty/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Transitions"

        ✅ **Behaviour**: Smooth redirect from current mid-flight value to new end target value

        <iframe src="../../../examples/src/Engines/Transitions/InterruptingAnimations/SingleProperty/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Sub"

        ✅ **Behaviour**: Smooth redirect from current mid-flight value to new end target value

        <iframe src="../../../examples/src/Engines/Sub/InterruptingAnimations/SingleProperty/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "WAAPI"

        ✅ **Behaviour**: Smooth redirect from current mid-flight value to new end target value

        <iframe src="../../../examples/src/Engines/WAAPI/InterruptingAnimations/SingleProperty/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

--8<-- [end:examples]

--8<-- [start:code]

??? example "View Source Code"

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/InterruptingAnimations/SingleProperty/Main.elm"
        ```

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/InterruptingAnimations/SingleProperty/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/InterruptingAnimations/SingleProperty/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/InterruptingAnimations/SingleProperty/Main.elm"
        ```

--8<-- [end:code]

--8<-- [end:page]
