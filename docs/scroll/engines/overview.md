# Scroll Engines Overview

This page compares the scroll engines side by side.

Use this page to choose an engine, compare features, and plan migrations.
For implementation details, each engine page includes the complete usage flow for that engine.

- [Cmd](cmd.md) - fire-and-forget scrolling, simplest setup
- [Task](task.md) - task-based scrolling with typed errors
- [Sub](sub.md) - state-tracked scrolling with full Elm-side control

## One Mental Model

All scroll engines use the same scroll builder pipeline from `Scroll.Builder`.

You define scrolls the same way regardless of engine:

??? example "Shared Builder Pattern"

    ```elm
    scrollToSection : String -> AnimBuilder -> AnimBuilder
    scrollToSection sectionId =
        Scroll.forDocument
            >> Scroll.toElement sectionId
            >> Scroll.speed 300
            >> Scroll.build
    ```

What changes per engine is runtime behavior: how scrolls are triggered, how results are returned, and how much control you have mid-scroll.

## Choosing an Engine

### Quick Recommendation

| Use Case | Recommended Engine |
| -------- | ------------------ |
| Simple jump/scroll interactions | Cmd |
| Task composition and typed error handling | Task |
| Mid-scroll control, events, and state queries | Sub |

### Feature Comparison

| Feature | Cmd | Task | Sub |
| ------- | :-: | :--: | :-: |
| **Execution** |
| Fire-and-forget `Cmd` | ✓ | | |
| Returns `Task` | | ✓ | |
| Requires state in model | | | ✓ |
| **Error Handling** |
| Typed errors | | ✓ | |
| Continue-through-failure mode | | ✓ | |
| **Control** |
| Stop | | | ✓ |
| Pause / Resume | | | ✓ |
| Reset / Restart | | | ✓ |
| **Events** |
| Started | | | ✓ |
| Ended | | | ✓ |
| Progress | | | ✓ |
| Stopped | | | ✓ |
| Paused / Resumed | | | ✓ |
| Restarted | | | ✓ |
| **Queries** |
| Current position | | | ✓ |
| Running state | | | ✓ |

## Engine Families

### Fire-and-Forget Engines

`Cmd` and `Task` are stateless at runtime.

You define a scroll builder and trigger it. `Cmd` returns a command directly, while `Task` returns a `Task` you can compose and convert to `Cmd`.

### State-Tracked Engine

`Sub` stores `ScrollState` in your model.

You subscribe for frame updates, process scroll messages in `update`, and can control or query scrolls while they are running.

## Timing Model

`Cmd` and `Task` pre-calculate frame steps and execute DOM writes sequentially. In busy UIs or on high-refresh displays, perceived duration can drift from the nominal duration.

`Sub` uses frame updates (`onAnimationFrameDelta`) with delta-time interpolation, so timing is frame-rate independent and closely matches configured duration.

If timing precision matters, prefer [Sub](sub.md).

[Check your display's refresh rate](../../tools/fps-test.html){ target="_blank" }

## Switching Engines

Scroll builders are portable because the builder API is shared.
In most migrations, you primarily change:

- imports
- trigger function and return handling (`Cmd`, `Task`, or `( ScrollState, Cmd msg )`)
- `update` / `subscriptions` wiring (for `Sub`)

The same builder can be reused:

??? example "Portable Scroll Builder"

    ```elm
    scrollToTop : AnimBuilder -> AnimBuilder
    scrollToTop =
        Scroll.forContainer "results-panel"
            >> Scroll.toTop
            >> Scroll.duration 350
            >> Scroll.build
    ```

## Next Steps

Explore each engine page for complete usage flows:

- [Cmd](cmd.md)
- [Task](task.md)
- [Sub](sub.md)

[Cmd Engine ->](cmd.md){ .md-button .md-button--primary }
