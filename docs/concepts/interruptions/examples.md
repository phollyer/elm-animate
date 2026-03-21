# Examples

--8<-- [start:single-property-examples]

=== "Keyframes"

    ❌ **Behaviour**: The new `@keyframes` rules for the animation replace the existing rules. 

    📖 **See**: [Keyframes Engine — Interrupting Animations](../engines/keyframes.md#interrupting-animations) for details.

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

--8<-- [end:single-property-examples]


--8<-- [start:multiple-properties-examples]

=== "Keyframes"

    ❌ **Behaviour**: The new `@keyframes` rules for the animation replace the existing rules.

    📖 **See**: [Keyframes Engine — Interrupting Animations](../engines/keyframes.md#interrupting-animations) for details.

    <iframe src="../../../examples/src/Engines/Keyframes/InterruptingAnimations/MultipleProperties/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Transitions"

    ✅ **Behaviour**: `Translate` and `BackgroundColor` run independently side by side.

    <iframe src="../../../examples/src/Engines/Transitions/InterruptingAnimations/MultipleProperties/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Sub"

    ✅ **Behaviour**: `Translate` and `BackgroundColor` run independently side by side.

    <iframe src="../../../examples/src/Engines/Sub/InterruptingAnimations/MultipleProperties/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    ✅ **Behaviour**: `Translate` and `BackgroundColor` run independently side by side.

    <iframe src="../../../examples/src/Engines/WAAPI/InterruptingAnimations/MultipleProperties/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>


??? example "View Source Code"

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/InterruptingAnimations/MultipleProperties/Main.elm"
        ```

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/InterruptingAnimations/MultipleProperties/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/InterruptingAnimations/MultipleProperties/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/InterruptingAnimations/MultipleProperties/Main.elm"
        ```

--8<-- [end:multiple-properties-examples]


--8<-- [start:translate-examples]

=== "Keyframes"

    ❌ **Behaviour**: The new `@keyframes` rules for the animation replace the existing rules.

    📖 **See**: [Keyframes Engine — Interrupting Animations](../engines/keyframes.md#interrupting-animations) for details.

    <iframe src="../../../examples/src/Engines/Keyframes/InterruptingAnimations/Translate/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Transitions"

    ✅ **Behaviour**: Smooth redirect from current position

    <iframe src="../../../examples/src/Engines/Transitions/InterruptingAnimations/Translate/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Sub"

    ✅ **Behaviour**: Seamless interruption to new target

    <iframe src="../../../examples/src/Engines/Sub/InterruptingAnimations/Translate/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    ✅ **Behaviour**: Seamless interruption to new target

    <iframe src="../../../examples/src/Engines/WAAPI/InterruptingAnimations/Translate/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>


??? example "View Source Code"

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/InterruptingAnimations/Translate/Main.elm"
        ```

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/InterruptingAnimations/Translate/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/InterruptingAnimations/Translate/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/InterruptingAnimations/Translate/Main.elm"
        ```

--8<-- [end:translate-examples]


--8<-- [start:translate-freeze-examples]

=== "Sub"

    ✅ **Behaviour**: Frozen axis holds its current position while the other axis animates to the new target

    <iframe src="../../../examples/src/Engines/Sub/InterruptingAnimations/TranslateFreeze/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    ✅ **Behaviour**: Frozen axis holds its current position while the other axis animates to the new target

    <iframe src="../../../examples/src/Engines/WAAPI/InterruptingAnimations/TranslateFreeze/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>


??? example "View Source Code"

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/InterruptingAnimations/TranslateFreeze/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/InterruptingAnimations/TranslateFreeze/Main.elm"
        ```

--8<-- [end:translate-freeze-examples]
