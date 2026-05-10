--8<-- [start:desc]
Horizontal scrolling - navigate an image gallery along the X axis only.
--8<-- [end:desc]

--8<-- [start:examples]
??? example "View Example"
    === "Cmd"

        <iframe src="../../../examples/src/Scroll/Cmd/HorizontalGallery/index.html" class="example-iframe example-iframe--lg" loading="lazy"></iframe>

    === "Task"

        <iframe src="../../../examples/src/Scroll/Task/HorizontalGallery/index.html" class="example-iframe example-iframe--lg" loading="lazy"></iframe>

    === "Sub"

        <iframe src="../../../examples/src/Scroll/Sub/HorizontalGallery/index.html" class="example-iframe example-iframe--lg" loading="lazy"></iframe>

--8<-- [end:examples]

--8<-- [start:code]

??? example "View Source Code"

    === "Cmd"

        ```elm
        --8<-- "docs/examples/src/Scroll/Cmd/HorizontalGallery/Main.elm"
        ```

    === "Task"

        ```elm
        --8<-- "docs/examples/src/Scroll/Task/HorizontalGallery/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Scroll/Sub/HorizontalGallery/Main.elm"
        ```

--8<-- [end:code]

--8<-- [start:breaking-it-down]

??? example "Breaking It Down"

    This example follows the same workflow as the vertical scroll example, but the builder adds `onXAxis` so the gallery only moves horizontally.

    ### 1. Build

    Horizontal scrolling uses the same builder pattern, with `onXAxis` making the intended axis explicit:

    ??? example "View Source Code"

        === "Cmd"

            ```elm
            --8<-- "docs/examples/src/Scroll/Cmd/HorizontalGallery/Main.elm:build"
            ```

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/HorizontalGallery/Main.elm:build"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/HorizontalGallery/Main.elm:build"
            ```

    ### 2. Initialize

    Task and Sub keep enough model state to drive the status bar:

    ??? example "View Source Code"

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/HorizontalGallery/Main.elm:model"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/HorizontalGallery/Main.elm:model"
            ```

    ### 3. Render

    The gallery container uses horizontal overflow and fixed-width cards so there is something to scroll across:

    ??? example "View Source Code"

        === "Cmd"

            ```elm
            --8<-- "docs/examples/src/Scroll/Cmd/HorizontalGallery/Main.elm:render"
            ```

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/HorizontalGallery/Main.elm:render"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/HorizontalGallery/Main.elm:render"
            ```

    ### 4. Subscribe

    Only the Sub engine needs subscriptions to receive animation frame updates:

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Scroll/Sub/HorizontalGallery/Main.elm:subscriptions"
        ```

    ### 5. Trigger

    The navigation buttons all trigger the same builder function:

    ??? example "View Source Code"

        === "Cmd"

            ```elm
            --8<-- "docs/examples/src/Scroll/Cmd/HorizontalGallery/Main.elm:trigger"
            ```

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/HorizontalGallery/Main.elm:trigger"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/HorizontalGallery/Main.elm:trigger"
            ```

    ### 6. React

    Task reports success or failure when the scroll finishes, while Sub keeps the status bar updated with live X position and progress:

    ??? example "View Source Code"

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/HorizontalGallery/Main.elm:result"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/HorizontalGallery/Main.elm:updateScroll"
            ```

--8<-- [end:breaking-it-down]
