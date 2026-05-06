# Installation

## Elm Package

Install the Elm package:

```bash
elm install phollyer/elm-animate
```

## WAAPI JavaScript

If you plan to use the [WAAPI Engine](animation/engines/waapi.md), [Scroll Timeline Engine](animation/engines/scroll-timeline.md), or [View Timeline Engine](animation/engines/view-timeline.md), you'll also need the JavaScript companion:

=== "CDN"

    Add the script tag before your Elm app script:

    ```html
    <script src="https://unpkg.com/elm-animate-waapi/dist/elm-animate-waapi.js"></script>
    ```

    Then initialise it:

    ```html
    <script>
        const app = Elm.Main.init({
            node: document.getElementById('app')
        });

        ElmAnimateWAAPI.init(app.ports);
    </script>
    ```

=== "npm"

    ```bash
    npm install elm-animate-waapi
    ```

    Then initialise it:

    ```javascript
    import ElmAnimateWAAPI from 'elm-animate-waapi';

    const app = Elm.Main.init({
        node: document.getElementById('app')
    });

    ElmAnimateWAAPI.init(app.ports);
    ```

=== "yarn"

    ```bash
    yarn add elm-animate-waapi
    ```

    Then initialise it:
    
    ```javascript
    import ElmAnimateWAAPI from 'elm-animate-waapi';

    const app = Elm.Main.init({
        node: document.getElementById('app')
    });

    ElmAnimateWAAPI.init(app.ports);
    ```

## Next Steps

Now that you have the package installed, let's start using it:

[Your First Animations](animation/start-here.md){ .md-button .md-button--primary }
or
[Your First Scrolls](scroll/start-here.md){ .md-button .md-button--primary }
