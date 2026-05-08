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
    <script src="https://unpkg.com/@phollyer/elm-motion/dist/elm-motion.js"></script>
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

## Next Steps

Now that you have the package installed, let's start using it:

[Your First Animations](animation/start-here.md){ .md-button .md-button--primary }
or
[Your First Scrolls](scroll/start-here.md){ .md-button .md-button--primary }
