# Examples

--8<-- [start:page]

--8<-- [start:examples]

??? example "View Examples"
    === "Transition"

        ✅ **Behaviour**: Smooth redirect from current position

        <iframe src="../../../examples/src/Engines/Animation/Transition/InterruptingAnimations/MultipleAxes/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Keyframe"

        ❌ **Behaviour**: The new `@keyframes` rules for the animation replace the existing rules.

        📖 **See**: [Keyframe Engine — Interrupting Animations](../../engines/animation/keyframes.md#interrupting-animations) for details.

        <iframe src="../../../examples/src/Engines/Animation/Keyframe/InterruptingAnimations/MultipleAxes/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>


    === "Sub"

        ✅ **Behaviour**: Seamless interruption to new target

        <iframe src="../../../examples/src/Engines/Animation/Sub/InterruptingAnimations/MultipleAxes/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "WAAPI"

        ✅ **Behaviour**: Seamless interruption to new target

        <iframe src="../../../examples/src/Engines/Animation/WAAPI/InterruptingAnimations/MultipleAxes/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

--8<-- [end:examples]

--8<-- [start:code]

??? example "View Source Code"

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Engines/Animation/Keyframe/InterruptingAnimations/MultipleAxes/Main.elm"
        ```

    === "Transition"

        ```elm
        --8<-- "docs/examples/src/Engines/Animation/Transition/InterruptingAnimations/MultipleAxes/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Animation/Sub/InterruptingAnimations/MultipleAxes/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/Animation/WAAPI/InterruptingAnimations/MultipleAxes/Main.elm"
        ```

--8<-- [end:code]

--8<-- [end:page]
