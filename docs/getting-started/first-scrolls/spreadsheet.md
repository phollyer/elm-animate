# Spreadsheet Example

--8<-- [start:examples]

Two-axis scrolling - navigate a large grid both horizontally and vertically to reach named regions.

=== "Cmd"

    <iframe src="../../../examples/src/Engines/Scroll/SpreadsheetCmd/index.html" style="width: 100%; height: 490px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/SpreadsheetCmd/Main.elm"
        ```

    ??? example "Breaking It Down"

        ### Build

        `toElement` works on both axes by default - the engine calculates the target element's position and scrolls the container to bring it into view:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/SpreadsheetCmd/Main.elm:build"
            ```

        ### Grid

        The spreadsheet is a CSS grid with sticky column headers and row numbers. Named regions are cells that have an `id` attribute, which is what `toElement` targets:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/SpreadsheetCmd/Main.elm:grid"
            ```

=== "Task"

    <iframe src="../../../examples/src/Engines/Scroll/SpreadsheetTask/index.html" style="width: 100%; height: 530px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/SpreadsheetTask/Main.elm"
        ```

    ??? example "Breaking It Down"

        ### Build

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/SpreadsheetTask/Main.elm:build"
            ```

        `ScrollError` will fire if the target element ID does not exist in the DOM - useful for catching typos or stale references to grid cells.

=== "Sub"

    <iframe src="../../../examples/src/Engines/Scroll/SpreadsheetSub/index.html" style="width: 100%; height: 530px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/SpreadsheetSub/Main.elm"
        ```

    ??? example "Breaking It Down"

        ### Build

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/SpreadsheetSub/Main.elm:build"
            ```

        ### Subscribe

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/SpreadsheetSub/Main.elm:subscriptions"
            ```

        Because the scroll moves on both axes simultaneously, the `Progress` event reports both `x` and `y` coordinates in real time. The status bar shows both values updating as the grid scrolls to its target.

--8<-- [end:examples]
