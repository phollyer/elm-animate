# Your First Animation

Let's create a simple **fire-and-forget** fade-in animation using the **Transitions Engine**. This is the quickest way to get started.

!!! info "What is fire-and-forget?"
    A fire-and-forget animation runs once without requiring ongoing state management. You trigger it, and it completes on its own—no subscriptions, no update messages, no cleanup needed.

## The Animation

We'll animate an element's opacity from 0 to 1 over 2500 milliseconds.

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/GettingStarted/FirstAnimation/index.html){ .md-button target="_blank" }

!!! note "Why Process.sleep?"
    The example uses `Process.sleep 50` to delay triggering the animation until after the initial render. **Transitions** only animate **changes** to properties — if the element is created with the transition already applied, there's no change to animate. The brief delay ensures the element first renders at opacity 0, then the state change triggers the transition to opacity 1.

    This pattern is only required for page entry animations using transitions. In practice, most animations are triggered by user interaction or state changes, so you won't need this delay.

    To avoid this pattern, use **CSS Keyframe animations** instead — they run as soon as the browser renders the page.


## Breaking It Down

### 1. Define the Animation

Animations are defined as functions that transform an `AnimBuilder`:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:fadeIn"
    ```

### 2. Create the AnimState

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:fireAndForget"
    ```

### 3. Apply Attributes

Use `Transitions.attributes` to get the HTML attributes for your element's transition:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:applyStyles"
    ```

## Composing Animations

The real power comes from composing multiple animations. Since each animation is just a function that transforms an `AnimBuilder`, you can compose them with `>>`:

??? example "View Source Code"

    ```elm
    import Anim.Engine.CSS.Transitions exposing (AnimBuilder)
    import Anim.Extra.Easing exposing (Easing(..))
    import Anim.Property.Opacity as Opacity
    import Anim.Property.Translate as Translate

    fadeIn : AnimBuilder -> AnimBuilder
    fadeIn =
        Opacity.for "my-box"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.duration 500
            >> Opacity.easing CubicIn
            >> Opacity.build

    slideIn : AnimBuilder -> AnimBuilder
    slideIn =
        Translate.for "my-box"
            >> Translate.fromX -50
            >> Translate.toX 0
            >> Translate.duration 500
            >> Translate.easing QuintOut
            >> Translate.build

    slideAndFade : AnimBuilder -> AnimBuilder
    slideAndFade =
        fadeIn >> slideIn
    ```

Both animations run simultaneously on the same `my-box` element because they target the same element ID!

## Next Steps

Now that you can create a simple animation, let's learn about the Engines themselves.

[Animation Engines →](../concepts/engines/animation-engines.md){ .md-button .md-button--primary }
