# Animation Engines Overview

This page compares the engines side by side.

Use this page to choose an engine, compare featuress, and plan migrations.
For implementation details, each engine page includes the complete usage flow for that engine.

- [Transition](transition.md) - CSS transitions, simplest setup
- [Keyframe](keyframes.md) - CSS @keyframes, pause/resume support
- [Sub](sub.md) - Elm subscriptions, full Elm-side control
- [WAAPI](waapi.md) - Web Animations API, browser-native with JS
- [Scroll Timeline](scroll-timeline.md) - fire-and-forget, progress tied to container scroll
- [View Timeline](view-timeline.md) - fire-and-forget, progress tied to viewport position

## One Mental Model

All engines use the same animation builder pipeline and property modules.

You define animations the same way regardless of engine:

??? example "Shared Builder Pattern"

    ```elm
    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Opacity.for "card"
            >> Opacity.to 1
            >> Opacity.duration 400
            >> Opacity.build
    ```

What changes per engine is runtime behavior: how animations are triggered, updated, and controlled.

## Choosing an Engine

### Quick Recommendation

| Use Case | Recommended Engine |
| -------- | ------------------ |
| Simple hover/click effects | Transition |
| Entry animations and loops | Keyframe |
| Full Elm-side control and frame-level events | Sub |
| Broad feature set with browser-native playback | WAAPI |
| Animate from container scroll position | Scroll Timeline |
| Animate from viewport entry/exit position | View Timeline |

### Feature Comparison

| Feature | Transition | Keyframe | Sub | WAAPI | Scroll Timeline | View Timeline |
| ------- | :--------: | :------: | :-: | :---: | :-------------: | :-----------: |
| **Rendering** |
| Browser-native interpolation | ✓ | ✓ | | ✓ | ✓ | ✓ |
| Hardware acceleration | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| JavaScript required | | | | ✓ | ✓ | ✓ |
| **Playback** |
| Iterations | | ✓ | ✓ | ✓ | ✓ | ✓ |
| Loop forever | | ✓ | ✓ | ✓ | ✓ | ✓ |
| Alternate (ping-pong) | | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Animation Control** |
| Stop | ✓ | ✓ | ✓ | ✓ | | |
| Reset | ✓ | ✓ | ✓ | ✓ | | |
| Restart | | ✓ | ✓ | ✓ | | |
| Pause | | ✓ | ✓ | ✓ | | |
| Resume | | ✓ | ✓ | ✓ | | |
| **Events** |
| Run | ✓ | | | | | |
| Started | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Ended | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Cancelled | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Restarted | | ✓ | ✓ | ✓ | | |
| Paused | | ✓ | ✓ | ✓ | | |
| Resumed | | ✓ | ✓ | ✓ | | |
| Iteration | | ✓ | ✓ | ✓ | ✓ | ✓ |
| Progress | | | ✓ | ✓ | | |
| **Mid-Flight Access** |
| Query current values | | | ✓ | ✓ | | |
| Dynamic redirects | ✓ | | ✓ | ✓ | | |
| **Properties** |
| Custom transform order | | ✓ | ✓ | ✓ | ✓ | ✓ |
| Discrete properties | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

## Engine Families

### State-Tracked Engines

`Transition`, `Keyframe`, `Sub`, and `WAAPI` all use `AnimState`.

You initialize state, render attributes with state, and update state when engine messages arrive.

### Timeline Engines

`Scroll Timeline` and `View Timeline` are fire-and-forget.

They do not require `AnimState`.
You can optionally subscribe to lifecycle events if you need to react in `update`.

## Switching Engines

Animations are portable because builder pipelines are shared.
In most migrations, you primarily change:

- imports
- engine function calls
- return-type handling in `update`
- WAAPI/timeline ports when applicable

The same animation definition can be reused:

??? example "Portable Animation Builder"

    ```elm
    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "box"
            >> Translate.toXY 100 200
            >> Translate.duration 500
            >> Translate.build
    ```

## Next Steps

Explore each engine page for complete usage flows:

- [Transition](transition.md)
- [Keyframe](keyframes.md)
- [Sub](sub.md)
- [WAAPI](waapi.md)
- [Scroll Timeline](scroll-timeline.md)
- [View Timeline](view-timeline.md)

[Transition Engine ->](transition.md){ .md-button .md-button--primary }
