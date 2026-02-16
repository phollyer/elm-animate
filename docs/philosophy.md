# Philosophy

## One Animation — Multiple Engines

There are many different approaches to creating animations on the web, and many good Elm packages that target each approach. If all approaches were equal, you could probably pick an Elm package and stick with it.

But they're not all equal.

There are CSS transitions, CSS keyframes, subscription-based animations, the Web Animations API, WebGL... each with different strengths, different performance characteristics, and different use cases.

**Lots of different ways of creating the same thing - an animation.**

### The Problem

Each different animation approach comes with its own learning curve and complexities, as does each different Elm package - and because each Elm package only targets one approach:

    changing approaches =
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

Define your animations once. Use them everywhere.

```elm
-- Define once
fadeIn : AnimBuilder -> AnimBuilder
fadeIn =
    Opacity.for "entranceAnim"
        >> Opacity.from 0
        >> Opacity.to 1
        >> Opacity.duration 300
        >> Opacity.build

-- Use with any engine
Transitions.animate model.animState fadeIn

Keyframes.animate model.animState fadeIn

Sub.animate model.animState fadeIn

WAAPI.animate model.animState <|
    WAAPI.forElement "elementId" >> fadeIn
```

Elm Animate abstracts away the differences in each approach so you can focus on your task at hand rather than a new API.

When requirements change — and they always do — you can switch engines without rewriting your animations.

**One mental model - multiple Engines.**

## Why This Matters

Teams evolve. Projects grow. Performance requirements change.

What starts as simple hover effects might need to become complex choreographed sequences. What works on desktop might need optimization for mobile. What was fine with CSS might need the precision of the Web Animations API.

With Elm Animate, you're not locked in. Your animation logic stays stable while you choose the right engine for your needs.

**Learn once. Use everywhere. Adapt when needed.**

## Next Steps

Ready to add Elm Animate to your Elm app?

[Installation →](getting-started/installation.md){ .md-button .md-button--primary }
