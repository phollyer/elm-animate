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

    animGroup : String
    animGroup = 
        "animGroup"

    fadeIn : AnimBuilder -> AnimBuilder
    fadeIn =
        Opacity.for animGroup
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.duration 500
            >> Opacity.easing CubicIn
            >> Opacity.build

    slideIn : AnimBuilder -> AnimBuilder
    slideIn =
        Translate.for animGroup
            >> Translate.fromX -50
            >> Translate.toX 0
            >> Translate.duration 500
            >> Translate.easing QuintOut
            >> Translate.build

    slideAndFade : AnimBuilder -> AnimBuilder
    slideAndFade =
        fadeIn >> slideIn
    ```

Both animations run simultaneously on the same element because they are both part of the same `animGroup`!

## Next Steps

Now that you can create a simple animation, let's get a feel for the Engines themselves.

[Animation Engines →](../concepts/engines/animation-engines.md){ .md-button .md-button--primary }
