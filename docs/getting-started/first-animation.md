# Your First Animation

Let's create a simple fire-and-forget fade-in animation using the Transitions Transitions Engine. This is the quickest way to get started.

## The Animation

We'll animate an element's opacity from 0 to 1 over 2500 milliseconds.

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/GettingStarted/FirstAnimation/index.html){ .md-button target="_blank" }

!!! note "Why Process.sleep?"
    The example uses `Process.sleep 50` to delay triggering the animation until after the initial render. Transitions **transitions** only animate **_changes_** to properties (_!important_) - if the element is created with the transition already applied, there's no change to animate. The brief delay ensures the element first renders at opacity 0, then the state change triggers the transition to opacity 1.

    This pattern is only required for page entry animations that use Transitions **transitions**. In reality, most animations will be triggered by user interaction or state changes.

    To avoid this pattern, use Transitions **keyframe animations** instead. They run as soon as the Browser renders the page.


## Breaking It Down

### 1. Define the Animation

Animations are defined as functions that transform an `AnimBuilder`:

```elm
--8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:fadeIn"
```

### 2. Create the AnimState

```elm
--8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:fireAndForget"
```

### 3. Apply Attributes

Use `Transitions.attributes` to get the HTML attributes for your element's transition:

```elm
--8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:applyStyles"
```

## Composing Animations

The real power comes from composing multiple animations:

```elm
import Anim.Property.Translate as Translate

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

Both animations run simultaneously on the same `my-box` element!

## Next Steps

Now that you can create a simple animation, let's learn about the Engines themselves.

[Animation Engines →](../concepts/engines/animation-engines.md){ .md-button .md-button--primary }
