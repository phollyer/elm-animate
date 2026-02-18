# Animation Engines

Elm Animate provides multiple animation engines, each optimized for different use cases. All engines share the same builder API, making it easy to switch between them.

## Feature Comparison

| Feature | Transitions | Keyframes | Sub | WAAPI |
| ------- | ----------- | --------- | --- | ----- |
| **Rendering** |
| Browser-native rendering | ✓ | ✓ | | ✓ |
| Hardware acceleration | ✓ | ✓ | ✓ | ✓ |
| JavaScript required | | | | ✓ |
| **Animation Control** |
| Stop | ✓ | ✓ | ✓ | ✓ |
| Reset | ✓ | ✓ | ✓ | ✓ |
| Restart | | ✓ | ✓ | ✓ |
| Pause/Resume | | ✓ | ✓ | ✓ |
| **Playback** |
| Looping/Iterations | | ✓ | | ✓ |
| Event callbacks | ✓ | ✓ | ✓ | ✓ |
| **Mid-Flight Access** |
| Query current values | | | ✓ | ✓ |
| Dynamic redirects | ✓ | | ✓ | ✓ |
| **Properties** |
| Custom transform order | ✓ | ✓ | ✓ | ✓ |
| 3D transforms | ✓ | ✓ | ✓ | ✓ |

## Switching Engines

Because all engines share the same builder API, animations are portable:

??? example "View Source Code"

    ```elm
    -- This animation works with any engine
    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for animGroup
            >> Translate.toXY 100 200
            >> Translate.duration 500
            >> Translate.build

    -- Use with CSS.Transitions
    Transitions.fireAndForget myAnimation

    -- Use with CSS.Keyframes
    Keyframes.fireAndForget myAnimation

    -- Use with Sub
    Sub.animate model.animState myAnimation

    -- Use with WAAPI
    WAAPI.animate model.animState <|
        WAAPI.forElement "elementId"
            >> myAnimation
    ```

This makes it easy to start simple with the one of the CSS Engines and migrate to Sub or WAAPI as your requirements grow.


## Next Steps

Now that you've learned about the animation engines, explore each engine in detail or check out the scroll engine for smooth scrolling animations.

[Scroll Engine →](scroll.md){ .md-button .md-button--primary }
