# Cmd Example

--8<-- [start:examples]

=== "Cmd"
    The simplest approach - fire-and-forget scrolling.

    <iframe src="../../../examples/src/Engines/Scroll/FirstScrollCmd/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/FirstScrollCmd/Main.elm"
        ```

    ??? example "Breaking It Down"

        ### 1. Build

        Scrolls use the same builder pattern as animations. Start with `forContainer` to target a scrollable element, then chain the scroll configuration:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/FirstScrollCmd/Main.elm:build"
            ```

        - `Scroll.animate` - executes the scroll as a fire-and-forget `Cmd`
        - `forContainer` - specifies which scrollable element to scroll (by ID)
        - `toElement` - the target element to scroll into view (by ID)
        - `duration` - how long the scroll takes in milliseconds
        - `easing` - the easing function for natural motion
        - `build` - finalizes the scroll configuration

        ### 2. Create the Container

        The container needs an `id` and `overflow-y: auto` so it can scroll:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/FirstScrollCmd/Main.elm:container"
            ```

        ### 3. Trigger

        Execute the scroll from your update function. `animate` takes a completion message and the scroll configuration:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/FirstScrollCmd/Main.elm:trigger"
            ```

        No model state or subscriptions needed - the engine handles everything.

=== "Task"


    Composable scrolling with success/failure handling.

    <iframe src="../../../examples/src/Engines/Scroll/FirstScrollTask/index.html" style="width: 100%; height: 550px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/FirstScrollTask/Main.elm"
        ```

    ??? example "Breaking It Down"

        ### 1. Build

        The scroll builder is piped into `Scroll.animate` followed by `Task.attempt` to convert it into a `Cmd`:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/FirstScrollTask/Main.elm:build"
            ```

        - `Scroll.animate` - returns a `Task ScrollError ScrollOk` instead of a `Cmd`
        - `Task.attempt` - converts the Task into a Cmd, delivering the result as a `Result`

        ### 2. Initialize

        Since we're handling results, the model tracks scroll status:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/FirstScrollTask/Main.elm:model"
            ```

        ### 3. Trigger

        Trigger the scroll and set the status to `Scrolling`:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/FirstScrollTask/Main.elm:trigger"
            ```

        ### 4. Handle the Result

        When the scroll completes, you get a `Result` with either `ScrollOk` (containing the target description) or `ScrollError` (containing the container ID, target element ID, and DOM error):

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/FirstScrollTask/Main.elm:result"
            ```

        Tasks are also composable - you can chain multiple scrolls with `Task.andThen`, or combine them with other Tasks.

=== "Sub"


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
