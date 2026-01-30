# Your First Animation

Let's create a simple fire-and-forget fade-in animation using the CSS Engine. This is the quickest way to get started.

## The Animation

We'll animate an element's opacity from 0 to 1 over 2500 milliseconds.

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/GettingStarted/FirstAnimation/index.html){ .md-button target="_blank" }

!!! note "Why Process.sleep?"
    The example uses `Process.sleep 50` to delay triggering the animation until after the initial render. CSS **transitions** only animate *changes* to properties - if the element is created with the transition already applied, there's no change to animate. The brief delay ensures the element first renders at opacity 0, then the state change triggers the transition to opacity 1.

    This pattern is only required for page entry animations that use CSS **transitions**. In reality, most animations will be triggered by user interaction or state changes.

    To avoid this pattern, use CSS **keyframe animations** instead. They run as soon as the Browser renders the page.


## Breaking It Down

### 1. Define the Animation

Animations are defined as functions that transform an `AnimBuilder`:

```elm
--8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:fadeIn"
```

### 2. Create the AnimState

Pass your animation through the engine's pipeline:

```elm
--8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:animState"
```

### 3. Apply Attributes

Use `CSS.transitionAttributes` to get the HTML attributes for your element's transition:

```elm
--8<-- "docs/examples/src/GettingStarted/FirstAnimation/Main.elm:applyStyles"
```

## Adding Easing

Make the animation feel more natural with an easing function:

```elm
import Anim.Easing exposing (Easing(..))

fadeIn : CSS.AnimBuilder -> CSS.AnimBuilder
fadeIn builder =
    builder
        |> Opacity.for "my-box"
        |> Opacity.from 0
        |> Opacity.to 1
        |> Opacity.duration 500
        |> Opacity.easing QuintOut    -- Smooth deceleration
        |> Opacity.build
```

## Composing Animations

The real power comes from composing multiple animations:

```elm
import Anim.Property.Translate as Translate

slideIn : CSS.AnimBuilder -> CSS.AnimBuilder
slideIn builder =
    builder
        |> Translate.for "my-box"
        |> Translate.fromX -50
        |> Translate.toX 0
        |> Translate.duration 500
        |> Translate.easing QuintOut
        |> Translate.build

slideAndFade : CSS.AnimBuilder -> CSS.AnimBuilder
slideAndFade builder =
    builder
        |> fadeIn
        |> slideIn

```

Both animations run simultaneously on the same element!

## Next Steps

- Learn about [Animation Engines](../concepts/engines.md) to choose the right one for your needs
- Explore all available [Properties](../concepts/properties.md)
- Understand [Easing Functions](../concepts/easing.md) for natural motion
