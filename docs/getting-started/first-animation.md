# Your First Animation

Let's create a simple **fire-and-forget** animation using the **Transitions Engine**. This is the quickest way to get started - and they're great for simple UI effects like button hovers etc.

!!! info "What is fire-and-forget?"
    A fire-and-forget animation requires no state management or subscriptions to drive it. You trigger it once, and the browser handles the rest — completion events are available if you need them.

## The Animation

We'll fade an element in and out over 2500 milliseconds.

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/GettingStarted/FirstAnimation/index.html){ .md-button target="_blank" }


## Breaking It Down

There are four simple steps to animating with Elm Animate.

### 1. Build

Animations are defined as functions that transform an `AnimBuilder`:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:fadeIn"
    ```

### 2. Initialize

Set up the initial state for your animated properties. This ensures elements render with the correct starting values before any animation runs:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:initAnimationState"
    ```
    Here, we initialize the opacity to 0 so the element starts invisible.

### 3. Render

Use the `attributes` function to apply the animation's attributes to your element:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:applyStyles"
    ```

    Exactly what `attributes` returns depends on the Engine being used, the animation configuration and the current animation state - all details you no longer need to concern yourself with 🎉.

### 4. Trigger

Engines trigger their animations with either their `animate` function if state-based, or `fireAndForget` if not state-based.

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:triggerAnimation"
    ```
    Here, we use `fireAndForget` to trigger the required animation.
    
## Next Steps

Now that you can create a simple animation, take a look at the properties you can animate.

[Properties →](properties.md){ .md-button .md-button--primary }

Or

Start your first scroll.

[First Scroll →](first-scroll.md){ .md-button .md-button--primary }

