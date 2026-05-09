# Installation

## Elm Package

Install the Elm package:

```bash
elm install phollyer/elm-motion
```

## WAAPI JavaScript

If you plan to use the [WAAPI Engine](animation/engines/waapi.md), [Scroll Timeline Engine](animation/engines/scroll-timeline.md), or [View Timeline Engine](animation/engines/view-timeline.md), you'll also need the JavaScript companion:

=== "CDN"

    Add the script tag before your Elm app script:

    ```html
    <script src="https://unpkg.com/@phollyer/elm-motion/elm-motion.js"></script>
    ```

    Then initialise it:

    ```html
    <script>
        const app = Elm.Main.init({
            node: document.getElementById('app')
        });

        ElmMotion.init(app.ports);
    </script>
    ```

=== "npm"

    ```bash
    npm install @phollyer/elm-motion
    ```

    Then initialise it:

    ```javascript
    import ElmMotion from '@phollyer/elm-motion';

    const app = Elm.Main.init({
        node: document.getElementById('app')
    });

    ElmMotion.init(app.ports);
    ```

=== "yarn"

    ```bash
    yarn add @phollyer/elm-motion
    ```

    Then initialise it:
    
    ```javascript
    import ElmMotion from '@phollyer/elm-motion';

    const app = Elm.Main.init({
        node: document.getElementById('app')
    });

    ElmMotion.init(app.ports);
    ```

!!! tip "See what the JavaScript companion is doing"
    `ElmMotion` is silent by default. To surface internal warnings during development or forward errors to a service in production, opt in via `ElmMotion.useConsoleReporter()` or `ElmMotion.onError(handler)`. See the [Error Reporting guide](shared/error-reporting.md) for the full API and the list of error codes.

## Tearing down and re-initialising

Most apps will call `ElmMotion.init(app.ports)` once at startup and never need to think about cleanup — completed and cancelled animations release their per-element state automatically.

For cases where the host JavaScript unmounts and replaces the Elm app within the same page — typically an Elm program embedded as a widget inside a non-Elm host (React, Vue, vanilla JS, etc.) - `ElmMotion` exposes `dispose()` a teardown counterpart to `init`:

```javascript
ElmMotion.dispose();
```

`dispose()` clears every cached animation handle and detaches from the previously-registered ports object. After it returns, you can call `ElmMotion.init(newApp.ports)` with a fresh app.

Call `dispose()` whenever the host unmounts the Elm sub-tree without immediately replacing it — that is the only signal `ElmMotion` has that the app is gone. Skip it and the per-element caches stay populated for the lifetime of the page, holding references to the now-detached DOM and preventing garbage collection.

As a convenience, calling `ElmMotion.init(newApp.ports)` with a different ports object disposes the previous state automatically and reports a `PORTS_REINITIALIZED` warning, so the immediate-replace case doesn't require an explicit `dispose()` call. Every other teardown does.

## Throttling per-frame property updates

The WAAPI, ScrollTimeline, and ViewTimeline engines emit a `propertyUpdate` event to Elm on every `requestAnimationFrame` tick while an animation is running, so subscribers reading live mid-animation values (e.g. via the `*Current` accessors on `Anim.Engine.WAAPI`) see them at the display refresh rate — 60 Hz, 120 Hz, 144 Hz, etc.

This is almost always what you want. Visual playback runs on the browser compositor and is unaffected by the emission rate; only the cadence of port traffic into Elm is. If your app runs many simultaneous animations on a high-refresh display and the resulting port traffic becomes a bottleneck, cap the rate with:

```javascript
ElmMotion.setPropertyUpdateThrottle(16);   // ~60 Hz
ElmMotion.setPropertyUpdateThrottle(33);   // ~30 Hz
ElmMotion.setPropertyUpdateThrottle(0);    // restore default (no throttle)
```

The value is the minimum interval, in milliseconds, between two `propertyUpdate` emissions for the same animation. It can be changed at any time and applies to every animation that runs after the call. Non-numeric or negative values are ignored and reported as a `THROTTLE_INVALID` warning.

## Next Steps

Now that you have the package installed, let's start using it:

[Your First Animations](animation/start-here.md){ .md-button .md-button--primary }
or
[Your First Scrolls](scroll/start-here.md){ .md-button .md-button--primary }
