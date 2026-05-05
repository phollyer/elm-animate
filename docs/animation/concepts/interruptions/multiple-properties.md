# Examples

--8<-- [start:page]

--8<-- [start:examples]

??? example "View Examples"
    === "Transition"

        ✅ **Behaviour**: `Translate` and `CustomColor` (`BackgroundColor`) run independently side by side.

        <iframe src="../../../../examples/src/Animation/Transition/InterruptingAnimations/MultipleProperties/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Keyframe"

        ❌ **Behaviour**: The new `@keyframes` rules for the animation replace the existing rules.

        📖 **See**: [Keyframe Engine — Interrupting Animations](/animation/engines/keyframes.md#interrupting-animations) for details.

        <iframe src="../../../../examples/src/Animation/Keyframe/InterruptingAnimations/MultipleProperties/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>


    === "Sub"

        ✅ **Behaviour**: `Translate` and `CustomColor` (`BackgroundColor`) run independently side by side.

        <iframe src="../../../../examples/src/Animation/Sub/InterruptingAnimations/MultipleProperties/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "WAAPI"

        ✅ **Behaviour**: `Translate` and `CustomColor` (`BackgroundColor`) run independently side by side.

        <iframe src="../../../../examples/src/Animation/WAAPI/InterruptingAnimations/MultipleProperties/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

--8<-- [end:examples]

--8<-- [start:code]

??? example "View Source Code"

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Animation/Keyframe/InterruptingAnimations/MultipleProperties/Main.elm"
        ```

    === "Transition"

        ```elm
        --8<-- "docs/examples/src/Animation/Transition/InterruptingAnimations/MultipleProperties/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/InterruptingAnimations/MultipleProperties/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/InterruptingAnimations/MultipleProperties/Main.elm"
        ```

--8<-- [end:code]

--8<-- [end:page]
