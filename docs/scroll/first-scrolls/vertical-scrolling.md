--8<-- [start:desc]
Simple vertical scrolling to elment id's.
--8<-- [end:desc]

--8<-- [start:examples]
??? example "View Example"
    === "Cmd"

        <iframe src="../../../examples/src/Scroll/Cmd/FirstScroll/index.html" class="example-iframe example-iframe--lg" loading="lazy"></iframe>

    === "Task"

        <iframe src="../../../examples/src/Scroll/Task/FirstScroll/index.html" class="example-iframe example-iframe--lg" loading="lazy"></iframe>

    === "Sub"

        <iframe src="../../../examples/src/Scroll/Sub/FirstScroll/index.html" class="example-iframe example-iframe--lg" loading="lazy"></iframe>

--8<-- [end:examples]

--8<-- [start:code]

??? example "View Source Code"

    === "Cmd"

        ```elm
        --8<-- "docs/examples/src/Scroll/Cmd/FirstScroll/Main.elm"
        ```

    === "Task"

        ```elm
        --8<-- "docs/examples/src/Scroll/Task/FirstScroll/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Scroll/Sub/FirstScroll/Main.elm"
        ```

--8<-- [end:code]

--8<-- [start:breaking-it-down]

??? example "Breaking It Down"

    There are three common steps for fire-and-forget scrolls, and extra state steps when you want results or live progress.

    Cmd uses Build -> Render -> Trigger.
    Task adds Initialize and React.
    Sub adds Initialize, Subscribe, and React.

    ### 1. Build

    Scrolls are defined as reusable functions that transform a `ScrollBuilder`:

    ??? example "View Source Code"

        === "Cmd"

            ```elm
            --8<-- "docs/examples/src/Scroll/Cmd/FirstScroll/Main.elm:build"
            ```

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/FirstScroll/Main.elm:build"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/FirstScroll/Main.elm:build"
            ```

        Notice how all three engines use the exact same builder pipeline.

    ### 2. Initialize

    Task and Sub keep scroll-related state in the model so the UI can react to completion, errors, or progress:

    ??? example "View Source Code"

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/FirstScroll/Main.elm:model"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/FirstScroll/Main.elm:model"
            ```

    ### 3. Render

    Render a scrollable container and give it a stable `id` so the builder can target it:

    ??? example "View Source Code"

        === "Cmd"

            ```elm
            --8<-- "docs/examples/src/Scroll/Cmd/FirstScroll/Main.elm:container"
            ```

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/FirstScroll/Main.elm:render"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/FirstScroll/Main.elm:render"
            ```

        The target elements inside the container also need their own `id`s so `toElement` can find them.

    ### 4. Subscribe

    Only the Sub engine needs subscriptions so it can receive animation frame updates while a scroll is running:

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Scroll/Sub/FirstScroll/Main.elm:subscriptions"
        ```

    ### 5. Trigger

    Each engine starts the same scroll definition a little differently:

    ??? example "View Source Code"

        === "Cmd"

            ```elm
            --8<-- "docs/examples/src/Scroll/Cmd/FirstScroll/Main.elm:trigger"
            ```

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/FirstScroll/Main.elm:trigger"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/FirstScroll/Main.elm:trigger"
            ```

    ### 6. React

    Task returns a `Result`, while Sub returns frame-by-frame events that keep the model in sync:

    ??? example "View Source Code"

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/FirstScroll/Main.elm:result"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/FirstScroll/Main.elm:updateScroll"
            ```

        Task is useful when you want success/failure handling. Sub is useful when you want live progress, events, or later control over the running scroll.

--8<-- [end:breaking-it-down]
