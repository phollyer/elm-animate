--8<-- [start:desc]
Two-axis scrolling - navigate a large grid both horizontally and vertically to reach named regions.
--8<-- [end:desc]

--8<-- [start:examples]
??? example "View Example"
    === "Cmd"

        <iframe src="../../../examples/src/Scroll/Cmd/Spreadsheet/index.html" style="width: 100%; height: 490px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Task"

        <iframe src="../../../examples/src/Scroll/Task/Spreadsheet/index.html" style="width: 100%; height: 530px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Sub"

        <iframe src="../../../examples/src/Scroll/Sub/Spreadsheet/index.html" style="width: 100%; height: 530px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

--8<-- [end:examples]

--8<-- [start:code]

??? example "View Source Code"

    === "Cmd"

        ```elm
        --8<-- "docs/examples/src/Scroll/Cmd/Spreadsheet/Main.elm"
        ```

    === "Task"

        ```elm
        --8<-- "docs/examples/src/Scroll/Task/Spreadsheet/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Scroll/Sub/Spreadsheet/Main.elm"
        ```

--8<-- [end:code]

--8<-- [start:breaking-it-down]

??? example "Breaking It Down"

    This example uses the same workflow, but the target container scrolls on both axes and the builder adds `withOffsetXY` so sticky headers stay visible after navigation.

    ### 1. Build

    `toElement` scrolls both axes by default, and `withOffsetXY` leaves room for the sticky headers:

    ??? example "View Source Code"

        === "Cmd"

            ```elm
            --8<-- "docs/examples/src/Scroll/Cmd/Spreadsheet/Main.elm:build"
            ```

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/Spreadsheet/Main.elm:build"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/Spreadsheet/Main.elm:build"
            ```

    ### 2. Initialize

    Task and Sub keep model state for the status bar and reactive feedback:

    ??? example "View Source Code"

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/Spreadsheet/Main.elm:model"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/Spreadsheet/Main.elm:model"
            ```

    ### 3. Render

    The spreadsheet container is a scrollable CSS grid. The named regions are cells with `id`s, which is what `toElement` targets:

    ??? example "View Source Code"

        === "Cmd"

            ```elm
            --8<-- "docs/examples/src/Scroll/Cmd/Spreadsheet/Main.elm:render"
            ```

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/Spreadsheet/Main.elm:render"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/Spreadsheet/Main.elm:render"
            ```

    ### 4. Subscribe

    Only the Sub engine needs subscriptions to receive frame-by-frame updates:

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Scroll/Sub/Spreadsheet/Main.elm:subscriptions"
        ```

    ### 5. Trigger

    Each engine triggers the same scroll definition from the region buttons:

    ??? example "View Source Code"

        === "Cmd"

            ```elm
            --8<-- "docs/examples/src/Scroll/Cmd/Spreadsheet/Main.elm:trigger"
            ```

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/Spreadsheet/Main.elm:trigger"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/Spreadsheet/Main.elm:trigger"
            ```

    ### 6. React

    Task gives you completion or failure at the end of the scroll, while Sub reports live `x` and `y` coordinates plus overall progress:

    ??? example "View Source Code"

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/Spreadsheet/Main.elm:result"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/Spreadsheet/Main.elm:updateScroll"
            ```

--8<-- [end:breaking-it-down]
