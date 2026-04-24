--8<-- [start:desc]
Horizontal scrolling - navigate an image gallery along the X axis only.
--8<-- [end:desc]

--8<-- [start:examples]
??? example "View Example"
    === "Cmd"

        <iframe src="../../../examples/src/Engines/Scroll/Cmd/HorizontalGallery/index.html" style="width: 100%; height: 420px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Task"

        <iframe src="../../../examples/src/Engines/Scroll/Task/HorizontalGallery/index.html" style="width: 100%; height: 460px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Sub"

        <iframe src="../../../examples/src/Engines/Scroll/Sub/HorizontalGallery/index.html" style="width: 100%; height: 460px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

--8<-- [end:examples]

--8<-- [start:code]

??? example "View Source Code"

    === "Cmd"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/Cmd/HorizontalGallery/Main.elm"
        ```

    === "Task"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/Task/HorizontalGallery/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/Sub/HorizontalGallery/Main.elm"
        ```

--8<-- [end:code]

--8<-- [start:breaking-it-down]

??? example "Breaking It Down"

    === "Cmd"

        ### Build

        The key difference from a vertical scroll is `onXAxis` - without it the engine would also try to scroll vertically, which has no effect here but `onXAxis` makes the intent explicit:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Cmd/HorizontalGallery/Main.elm:build"
            ```

        No model state or subscriptions needed - fire and forget.

    === "Task"

        ### Build

        Same builder as Cmd - only the execution differs:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Task/HorizontalGallery/Main.elm:build"
            ```

        `ScrollOk` and `ScrollError` give you `containerId` and `targetElementId` on success or failure.

    === "Sub"

        ### Build

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Sub/HorizontalGallery/Main.elm:build"
            ```

        ### Subscribe

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/Sub/HorizontalGallery/Main.elm:subscriptions"
            ```

        The `Progress` event carries the live scroll position - the status bar shows the current X coordinate and overall progress percentage as the gallery animates.

--8<-- [end:breaking-it-down]
