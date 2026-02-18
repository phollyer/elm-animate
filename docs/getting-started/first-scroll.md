# Your First Scroll

Let's create a simple **fire-and-forget** scroll animation using the **Scroll Engine**. We'll scroll within a container element - great for scrollable lists, content panels, and more.

!!! info "What is fire-and-forget scrolling?"
    Fire-and-forget scrolling uses `toCmd` to execute the scroll immediately. You trigger it once, the engine handles the animation, and you receive a completion callback. No state management needed.

## The Scroll

We'll scroll to different sections within a scrollable container.

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstScroll/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/GettingStarted/FirstScroll/index.html){ .md-button target="_blank" }

## Breaking It Down

### 1. Define the Scroll

Scrolls use the same builder pattern as animations:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstScroll/Main.elm:scrollBuilder"
    ```

- `forContainer` - specifies which scrollable element to scroll (by ID)
- `toElement` - the target element to scroll into view (by ID)
- `duration` - how long the scroll takes in milliseconds
- `easing` - the easing function for natural motion
- `build` - finalizes the scroll configuration

### 2. Create the Container

The container needs an `id` and overflow scrolling:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstScroll/Main.elm:container"
    ```

### 3. Trigger the Scroll

Execute the scroll from your update function:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstScroll/Main.elm:scrollToTop"
    ```

## Next Steps

Now that you can create a scroll animation, let's learn how to control them.

[Controlling Scrolls →](../concepts/controlling-scroll.md){ .md-button .md-button--primary }

!!! tip "Need element animations?"
    Check out [Your First Animation](first-animation.md) to learn about CSS and WAAPI animations.
