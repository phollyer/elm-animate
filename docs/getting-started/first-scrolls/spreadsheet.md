--8<-- [start:desc]
Two-axis scrolling - navigate a large grid both horizontally and vertically to reach named regions.
--8<-- [end:desc]

--8<-- [start:examples]
??? example "View Example"
    === "Cmd"

        <iframe src="../../../examples/src/Engines/Scroll/Cmd/Spreadsheet/index.html" style="width: 100%; height: 490px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Task"

        <iframe src="../../../examples/src/Engines/Scroll/Task/Spreadsheet/index.html" style="width: 100%; height: 530px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Sub"

        <iframe src="../../../examples/src/Engines/Scroll/Sub/Spreadsheet/index.html" style="width: 100%; height: 530px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

--8<-- [end:examples]

--8<-- [start:code]

??? example "View Source Code"

    === "Cmd"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/Cmd/Spreadsheet/Main.elm"
        ```

    === "Task"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/Task/Spreadsheet/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/Sub/Spreadsheet/Main.elm"
        ```

--8<-- [end:code]

--8<-- [start:breaking-it-down]

??? example "Breaking It Down"

    === "Cmd"

        ### Build

        `toElement` works on both axes by default - the engine calculates the target element's position and scrolls the container to bring it into view:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Cmd/Spreadsheet/Main.elm:build"
            ```

        ### Grid

        The spreadsheet is a CSS grid with sticky column headers and row numbers. Named regions are cells that have an `id` attribute, which is what `toElement` targets:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Cmd/Spreadsheet/Main.elm:grid"
            ```

    === "Task"

        ### Build

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Task/Spreadsheet/Main.elm:build"
            ```

        `ScrollError` will fire if the target element ID does not exist in the DOM - useful for catching typos or stale references to grid cells.

    === "Sub"

        ### Build

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Sub/Spreadsheet/Main.elm:build"
            ```

        ### Subscribe

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Sub/Spreadsheet/Main.elm:subscriptions"
            ```

        Because the scroll moves on both axes simultaneously, the `Progress` event reports both `x` and `y` coordinates in real time. The status bar shows both values updating as the grid scrolls to its target.

--8<-- [end:breaking-it-down]
