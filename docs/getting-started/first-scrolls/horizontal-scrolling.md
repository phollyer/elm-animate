# Horizontal Gallery Example

--8<-- [start:examples]

Horizontal scrolling - navigate an image gallery along the X axis only.

=== "Cmd"

    <iframe src="../../../examples/src/Engines/Scroll/HorizontalGalleryCmd/index.html" style="width: 100%; height: 420px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/HorizontalGalleryCmd/Main.elm"
        ```

    ??? example "Breaking It Down"

        ### Build

        The key difference from a vertical scroll is `onXAxis` - without it the engine would also try to scroll vertically, which has no effect here but `onXAxis` makes the intent explicit:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/HorizontalGalleryCmd/Main.elm:build"
            ```

        No model state or subscriptions needed - fire and forget.

=== "Task"

    <iframe src="../../../examples/src/Engines/Scroll/HorizontalGalleryTask/index.html" style="width: 100%; height: 460px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/HorizontalGalleryTask/Main.elm"
        ```

    ??? example "Breaking It Down"

        ### Build

        Same builder as Cmd - only the execution differs:

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/HorizontalGalleryTask/Main.elm:build"
            ```

        `ScrollOk` and `ScrollError` give you `containerId` and `targetElementId` on success or failure.

=== "Sub"

    <iframe src="../../../examples/src/Engines/Scroll/HorizontalGallerySub/index.html" style="width: 100%; height: 460px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Engines/Scroll/HorizontalGallerySub/Main.elm"
        ```

    ??? example "Breaking It Down"

        ### Build

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/HorizontalGallerySub/Main.elm:build"
            ```

        ### Subscribe

        ??? example "View Source Code"

            ```elm
            --8<-- "docs/examples/src/Engines/Scroll/HorizontalGallerySub/Main.elm:subscriptions"
            ```

        The `Progress` event carries the live scroll position - the status bar shows the current X coordinate and overall progress percentage as the gallery animates.

--8<-- [end:examples]
