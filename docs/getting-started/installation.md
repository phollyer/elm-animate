# Installation

## Elm Package

Install the Elm package:

```bash
elm install phollyer/elm-animate
```

## WAAPI JavaScript (Optional)

If you plan to use the [WAAPI Engine](../engines/waapi.md), you'll also need the JavaScript companion:

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

[Your First Animation](first-animation.md){ .md-button .md-button--primary }
or
[Your First Scroll](first-scroll.md){ .md-button .md-button--primary }
