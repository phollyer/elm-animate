# Subscriptions Example

--8<-- [start:examples]

Stateful, controllable, interruptable scrolling.

<iframe src="../../../examples/src/Engines/Scroll/FirstScrollSub/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/FirstScrollSub/Main.elm"
    ```

??? example "Breaking It Down"

    ### 1. Build

    The scroll animation is defined as a function that transforms an `AnimBuilder` - this is the same builder pattern used by all the animation engines:

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/FirstScrollSub/Main.elm:build"
        ```

    ### 2. Initialize

    Store the `AnimState` in your model:

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/FirstScrollSub/Main.elm:model"
        ```

    ### 3. Subscribe

    Wire up the subscriptions so the engine receives animation frame updates:

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/FirstScrollSub/Main.elm:subscriptions"
        ```

    ### 4. Trigger

    Use `Scroll.animate` to start the scroll. It returns both the updated `AnimState` and a `Cmd`:

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/FirstScrollSub/Main.elm:trigger"
        ```

    ### 5. Update

    Handle the engine's internal messages to keep the animation state in sync:

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/FirstScrollSub/Main.elm:updateScroll"
        ```

    Because the animation state lives in your model, you can query and control it at any time. See [Controlling Scrolls](../../concepts/controlling-scroll.md) for pause, resume, stop, reset, and restart.

--8<-- [end:examples]
