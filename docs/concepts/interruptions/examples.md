# Examples

--8<-- [start:translate-examples]

=== "Keyframes"

    ❌ **Behaviour**: Jump to end value, animate from there.

    📖 **See**: [Keyframes Engine — Interrupting Animations](../engines/keyframes.md#interrupting-animations) for details.

    <iframe src="../../../examples/src/Engines/Keyframes/InterruptingAnimations/Translate/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Transitions"

    ⁉️ **Behaviour**: Transition to new target while current animations continue. 
    
    📖 **See**: [Transitions Engine — Interrupting Animations](../engines/transitions.md#interrupting-animations) for details.

    <iframe src="../../../examples/src/Engines/Transitions/InterruptingAnimations/Translate/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Sub"

    ✅ Seamless interruption to new target

    <iframe src="../../../examples/src/Engines/Sub/InterruptingAnimations/Translate/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    ✅ Seamless interruption to new target

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


--8<-- [start:multi-property-examples]

=== "Keyframes"

    ❌ All properties restart — rotate and color jump back to their starting values, See [Keyframes Engine — Interrupting Animations](../engines/keyframes.md#interrupting-animations) for why.

    <iframe src="../../../examples/src/Engines/Keyframes/InterruptingAnimations/MultiProperty/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Transitions"

    ⁉️ Rotate and color continue to their targets while translate redirects, see [Transitions Engine — Interrupting Animations](../engines/transitions.md#interrupting-animations) for details.

    <iframe src="../../../examples/src/Engines/Transitions/InterruptingAnimations/MultiProperty/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Sub"

    ✅ Rotate and color continue to their targets while translate redirects

    <iframe src="../../../examples/src/Engines/Sub/InterruptingAnimations/MultiProperty/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    ✅ Rotate and color continue to their targets while translate redirects

    <iframe src="../../../examples/src/Engines/WAAPI/InterruptingAnimations/MultiProperty/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>


??? example "View Source Code"

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/InterruptingAnimations/MultiProperty/Main.elm"
        ```

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/InterruptingAnimations/MultiProperty/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/InterruptingAnimations/MultiProperty/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/InterruptingAnimations/MultiProperty/Main.elm"
        ```

--8<-- [end:multi-property-examples]
