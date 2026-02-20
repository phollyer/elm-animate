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

## `animate` vs `fireAndForget`

- **`animate`** — Tracks state in `AnimState`, enabling sequencing, redirection, and control
- **`fireAndForget`** — Starts fresh each time, no state continuity

| Scenario | Transitions | Keyframes | Sub | WAAPI |
| -------- | :---------: | :-------: | :-: | :---: |
| Animation runs once, no control needed | `fireAndForget` | `fireAndForget` | `animate` | `fireAndForget` |
| Simple entry animations | `fireAndForget` | `fireAndForget` | `animate` | `fireAndForget` |
| Stop/reset controls | `animate` | `animate` | `animate` | `animate` |
| Pause/resume controls | | `animate` | `animate` | `animate` |
| Sequencing animations | `animate` | `animate` | `animate` | `animate` |
| Redirecting mid-flight | `animate`/`fireAndForget` | | `animate` | `animate` |

!!! note "Sub always uses `animate`"
    The Sub engine does not have a `fireAndForget` function, only `animate`; the Sub engine uses `subscriptions` with frame by frame `update`s, so the fire-and-forget concept does not exist in the world of subscription based animations.

## Initializing Property Configs

All Engines have an `init` function that should be used to set the initial property values that will be used for first render then first trigger.

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
    ```

    === "Transitions"

        ```elm
        Transitions.fireAndForget myAnimation
        ```

    === "Keyframes"

        ```elm
        Keyframes.fireAndForget myAnimation
        ```

    === "Sub"

        ```elm
        Sub.animate model.animState myAnimation
        ```

    === "WAAPI"

        ```elm
        WAAPI.animate model.animState <|
            WAAPI.forElement "elementId"
                >> myAnimation
        ```

This makes it easy to start simple with one of the CSS Engines and migrate to Sub or WAAPI as your requirements grow.


## Next Steps

Now that you've learned about the animation engines, explore each engine in detail or check out the scroll engine for smooth scrolling animations.

[Scroll Engine →](scroll.md){ .md-button .md-button--primary }
