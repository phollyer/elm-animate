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

## Scroll Driven Timeline Polyfill (Optional)

The JavaScript companion now handles this automatically.

- `npm` / `yarn` usage: `scroll-timeline-polyfill` is installed as a dependency of `elm-animate-waapi` and auto-loaded only when native timeline APIs are missing.
- CDN usage (`elm-animate-waapi.js`): the helper will try to load the same polyfill from `unpkg` when needed.

This keeps native implementations on modern browsers while providing a fallback where needed, without extra setup in most projects.

## Next Steps

Now that you have the package installed, let's start using it:

[Your First Animations](animation/first-animations.md){ .md-button .md-button--primary }
or
[Your First Scrolls](scroll/first-scrolls.md){ .md-button .md-button--primary }
