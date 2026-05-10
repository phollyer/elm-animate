# Examples

--8<-- [start:page]

--8<-- [start:examples]

??? example "View Examples"
    === "Transition"

        ✅ **Behaviour**: Smooth redirect from current position

        <iframe src="../../../../examples/src/Animation/Transition/InterruptingAnimations/MultipleAxes/index.html" class="example-iframe example-iframe--lg" loading="lazy"></iframe>

    === "Keyframe"

        ❌ **Behaviour**: The new `@keyframes` rules for the animation replace the existing rules.

        📖 **See**: [Keyframe Engine — Interrupting Animations](/animation/engines/keyframes.md#interrupting-animations) for details.

        <iframe src="../../../../examples/src/Animation/Keyframe/InterruptingAnimations/MultipleAxes/index.html" class="example-iframe example-iframe--lg" loading="lazy"></iframe>


    === "Sub"

        ✅ **Behaviour**: Seamless interruption to new target

        <iframe src="../../../../examples/src/Animation/Sub/InterruptingAnimations/MultipleAxes/index.html" class="example-iframe example-iframe--lg" loading="lazy"></iframe>

    === "WAAPI"

        ✅ **Behaviour**: Seamless interruption to new target

        <iframe src="../../../../examples/src/Animation/WAAPI/InterruptingAnimations/MultipleAxes/index.html" class="example-iframe example-iframe--lg" loading="lazy"></iframe>

--8<-- [end:examples]

--8<-- [start:code]

??? example "View Source Code"

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Animation/Keyframe/InterruptingAnimations/MultipleAxes/Main.elm"
        ```

    === "Transition"

        ```elm
        --8<-- "docs/examples/src/Animation/Transition/InterruptingAnimations/MultipleAxes/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/InterruptingAnimations/MultipleAxes/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/InterruptingAnimations/MultipleAxes/Main.elm"
        ```

--8<-- [end:code]

--8<-- [end:page]
