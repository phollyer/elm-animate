# Philosophy

## One Animation — Multiple Engines

There are many different approaches to creating animations on the web, and many good Elm packages that target each approach. If all approaches were equal, you could probably pick an Elm package and stick with it.

But they're not all equal.

There are CSS transitions, CSS keyframes, subscription-based animations, the Web Animations API, WebGL... each with different strengths, different performance characteristics, and different use cases.

**Lots of different ways of creating the same thing - an animation.**

### The Problem

Each different animation approach comes with its own learning curve and complexities, as does each different Elm package - and because each Elm package only targets one approach:

    changingApproaches =
        new ElmPackage
            >> new API
            >> new MentalModel

Imagine you've learned and are using an Elm package for CSS transitions. It's working well. Then further down the line, your team decides to start using the Web Animations API too for better performance and playback control.

Now you have another animation approach to learn about. Another Elm package to learn. A different API. A different way of thinking about animations.

**Two different mental models for essentially the same thing - an animation.**

### The Solution

Elm Animate provides a singular, composable builder API to build animation configurations, and multiple engines that consume those configurations and output animations to their own specialty target:

- **CSS Transitions**
- **CSS Keyframes**
- **Sub**
- **WAAPI**

Define your animations once.


??? example "View Source Code"

    ```elm
    -- Define once
    fadeIn : AnimBuilder -> AnimBuilder
    fadeIn =
        Opacity.for "entranceAnim"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.duration 300
            >> Opacity.build
    ```

Then use with any engine.

??? example "View Source Code"

    === "Transitions"

        ```elm
        Transitions.animate model.animState fadeIn
        ```

    === "Keyframes"

        ```elm
        Keyframes.animate model.animState fadeIn
        ```

    === "Sub"

        ```elm
        Sub.animate model.animState fadeIn
        ```

    === "WAAPI"

        ```elm
        WAAPI.animate model.animState fadeIn
        ```

Elm Animate abstracts away the differences in each approach so you can focus on your task at hand rather than a new API - the same animation configurations work with every Engine.

When requirements change — and they always do — you can switch engines without rewriting your animations.

**One mental model - multiple Engines.**

## Why This Matters

Teams evolve. Projects grow. Performance requirements change.

What starts as simple hover effects might need to become complex choreographed sequences. What works on desktop might need optimization for mobile. What was fine with CSS might need the precision of the Web Animations API.

With Elm Animate, you're not locked in. Your animation logic stays stable while you choose the right engine for your needs.

**Learn once. Use everywhere. Adapt when needed.**

## And One More Thing

If animation is about smoothly interpolating values over time, why stop at CSS properties?

Scroll position is just another value. The Scroll Engines apply the same philosophy — smooth, configurable, eased movement — to viewport and container scrolling.

**Same mental model. Different target.**

## Next Steps

Ready to add Elm Animate to your Elm app?

[Installation →](getting-started/installation.md){ .md-button .md-button--primary }

Or, continue reading and learn how to create your first animation or scroll.

[Your First Animations](getting-started/first-animations.md){ .md-button .md-button--primary }
or
[Your First Scrolls](getting-started/first-scrolls.md){ .md-button .md-button--primary }
