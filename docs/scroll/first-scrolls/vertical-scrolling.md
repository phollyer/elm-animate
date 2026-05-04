--8<-- [start:desc]
Simple vertical scrolling to elment id's.
--8<-- [end:desc]

--8<-- [start:examples]
??? example "View Example"
    === "Cmd"

        <iframe src="../../../examples/src/Engines/Scroll/Cmd/FirstScroll/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Task"

        <iframe src="../../../examples/src/Engines/Scroll/Task/FirstScroll/index.html" style="width: 100%; height: 550px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Sub"

        <iframe src="../../../examples/src/Engines/Scroll/Sub/FirstScroll/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

--8<-- [end:examples]

--8<-- [start:code]

??? example "View Source Code"

    === "Cmd"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/Cmd/FirstScroll/Main.elm"
        ```

    === "Task"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/Task/FirstScroll/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/Sub/FirstScroll/Main.elm"
        ```

--8<-- [end:code]

--8<-- [start:breaking-it-down]

??? example "Breaking It Down"

    === "Cmd"

        ### 1. Build

        Scrolls are defined as functions that transform an `AnimBuilder`:
        
        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Cmd/FirstScroll/Main.elm:build"
            ```
        ### 2. Create the Container

        The container needs an `id` and `overflow-y: auto` so it can scroll:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Cmd/FirstScroll/Main.elm:container"
            ```

        ### 3. Trigger

        Execute the scroll from your update function. `animate` takes a completion message and the scroll configuration:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Cmd/FirstScroll/Main.elm:trigger"
            ```

        No model state or subscriptions needed - the engine handles everything.

    === "Task"

        ### 1. Build

        The scroll builder is piped into `Scroll.animate` followed by `Task.attempt` to convert it into a `Cmd`:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Task/FirstScroll/Main.elm:build"
            ```

        - `Scroll.animate` - returns a `Task ScrollError (List ScrollOk)` instead of a `Cmd`
        - `Task.attempt` - converts the Task into a Cmd, delivering the result as a `Result`

        ### 2. Initialize

        Since we're handling results, the model tracks scroll status:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Task/FirstScroll/Main.elm:model"
            ```

        ### 3. Trigger

        Trigger the scroll and set the status to `Scrolling`:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Task/FirstScroll/Main.elm:trigger"
            ```

        ### 4. Handle the Result

        When the scroll completes, you get a `Result` with either `List ScrollOk` (all completed scrolls, in order) or `ScrollError` (containing the container ID, target element ID, and DOM error):

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Task/FirstScroll/Main.elm:result"
            ```

        Tasks are also composable - you can chain multiple scrolls with `Task.andThen`, or combine them with other Tasks.

    === "Sub"

        ### 1. Build

        The scroll animation is defined as a function that transforms an `AnimBuilder` - this is the same builder pattern used by all the animation engines:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Sub/FirstScroll/Main.elm:build"
            ```

        ### 2. Initialize

        Store the `AnimState` in your model:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Sub/FirstScroll/Main.elm:model"
            ```

        ### 3. Subscribe

        Wire up the subscriptions so the engine receives animation frame updates:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Sub/FirstScroll/Main.elm:subscriptions"
            ```

        ### 4. Trigger

        Use `Scroll.animate` to start the scroll. It returns both the updated `AnimState` and a `Cmd`:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Sub/FirstScroll/Main.elm:trigger"
            ```

        ### 5. Update

        Handle the engine's internal messages to keep the animation state in sync:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Sub/FirstScroll/Main.elm:updateScroll"
            ```

        Because the animation state lives in your model, you can query and control it at any time. See [Controlling Scrolls](/scroll/concepts/controlling-scroll.md) for pause, resume, stop, reset, and restart.

--8<-- [end:breaking-it-down]
