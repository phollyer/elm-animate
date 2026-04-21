# Cmd Example

--8<-- [start:examples]

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

--8<-- [end:examples]
