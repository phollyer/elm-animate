# Installation

## Elm Package

Install the Elm package:

```bash
elm install phollyer/elm-animate
```

## WAAPI JavaScript (Optional)

If you plan to use the [WAAPI Engine](animation/engines/waapi.md), [Scroll Timeline Engine](animation/engines/scroll-timeline.md), or [View Timeline Engine](animation/engines/view-timeline.md), you'll also need the JavaScript companion:

=== "npm"

    ```bash
    npm install elm-animate-waapi
    ```

=== "yarn"

    ```bash
    yarn add elm-animate-waapi
    ```

Then include it in your JavaScript:

```javascript
import ElmAnimateWaapi from 'elm-animate-waapi';

const app = Elm.Main.init({
    node: document.getElementById('app')
});

ElmAnimateWaapi.init(app.ports);
```

## Next Steps

Now that you have the package installed, let's start using it:

[Your First Animations](animation/first-animations.md){ .md-button .md-button--primary }
or
[Your First Scrolls](scroll/first-scrolls.md){ .md-button .md-button--primary }
